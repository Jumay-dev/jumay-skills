---
name: jumay-address-review
description: Handle review comments on a PR end to end — verify every finding before acting on it, check it is actually in this diff, route it to the branch that owns the file, fix behind checked exit codes, reply, then resolve. Use when Greptile, Devin, Codex or a human reviews a PR and you are the author, when a bot files findings you suspect are wrong, when threads sit replied-but-unresolved, or when asked to "address the review", "handle the comments", or "close out the review round". Reply wording is /jumay-review-reply; thread enumeration is /jumay-quality-gate Phase 7.
---

# Jumay Address Review

Bots are right about **half** the time. A review comment is a hypothesis, not a
work item — and the expensive failures in this workflow all come from acting on
one before testing it.

**Scope:** the judgement and the process. The *wording* of a reply is
`/jumay-review-reply` (six verdicts, hard length budget) — do not restate it
here. Enumeration and count reconciliation are `/jumay-quality-gate` Phase 7.
Whether to comply, push back, or self-resolve is `$jumay-parity`
§Review-Response. Quality-gate rules are cited by number from
`docs/quality-gate.md`.

The round, in order: **enumerate → verify → route → decide → fix → reply →
resolve**. Never start at "fix".

## 1. Enumerate

Fetch every thread on every PR in the stack, with bodies, unpaginated
(`/jumay-quality-gate` Phase 7 owns the reconciliation rules):

```sh
gh api graphql -f query='
  query($owner:String!,$repo:String!,$pr:Int!){
    repository(owner:$owner,name:$repo){
      pullRequest(number:$pr){
        reviewThreads(first:100){ nodes{
          id isResolved isOutdated path line
          comments(first:50){ nodes{ databaseId author{login} body } } } } } } }
' -F owner=OWNER -F repo=REPO -F pr=<pr>
```

`id` is the thread node id (needed to resolve); `databaseId` is the comment id
(needed to reply to or delete a single comment). Fetch both now — going back for
them mid-round is how the wrong id gets used.

## 2. Verify the finding — three checks, every time

### Is the premise true?

Open the rule or file the comment cites and read it. Quote it back either way.

- A missing `text-balance` on a heading, cited against the repo's typography
  rule: the rule existed and said exactly that. **Real** — fixed.
- `defaultOpen = false` flagged under a "no default args" rule: reading the rule
  showed it scopes to *required-decision* parameters (`limit`, `env`), not
  uncontrolled-component state seeds, and a sibling component in the design
  system declared the identical pair. **False positive** — pushed back with the
  quoted scope plus the sibling, and the bot replied agreeing.
- A P1 "this feature is never rendered" on a component deliberately left unwired
  until a later PR in the stack: the factual claim was true, the **severity** was
  wrong. Verify the claim and the severity separately.

A citation is not evidence. `$jumay-parity` §Review-Response says the same for
design values: re-derive from the source before editing what a reviewer flags.

### Is it actually in this diff?

Line numbers shift. A finding can be right about the code and wrong about the PR:

```sh
gh pr diff <pr> | grep -n '<symbol>'          # empty = the PR never touched it
gh pr diff <pr> --name-only | grep -F '<path>'
```

Two Devin findings on one PR were pre-existing code the PR never touched — right
rule, wrong PR. A shared type the PR *consumed* but did not modify is the same
case: changing it ripples into already-shipped surfaces. Reply that it is
out of scope, name where it belongs, and do not edit it here (G3 — the same
provenance discipline that stops a stale base reading as deletions).

### Who owns the file?

In a stack, a PR's diff shows files belonging to the un-merged PRs **below** it.
The lowest PR that touches a path owns it (G8):

```sh
for n in <lower-pr> <this-pr>; do
  echo "== $n"; gh pr diff "$n" --name-only | grep -F '<path>'
done
```

Fix it on the owning branch and say so on the thread. Fixing it where it was
reported lands the same change twice and the two copies diverge. Shared code
goes on the lowest common branch so every stack picks it up on rebase
(`docs/rules/converge-duplicates.md` rule 4 in repos that carry it).

## 3. Decide who decides

Some threads are not yours to close. A reviewer saying *"happy with either, just
want it deliberate"* is asking the **PR owner** to choose, not the agent.

| Decide yourself | Ask the owner |
| --- | --- |
| A rule is quoted and the code violates it | Public API / prop shape changes |
| A bug with a reproducible failure | Cross-PR sequencing in a stack |
| A typo, a dead import, a missing test | Copy with no design source |
| The premise is provably false | a11y trade-offs with two defensible reads |

Fix everything unambiguous first — do not block the round on the questions. Then
put the open ones to the owner in one batch, and reply on the thread **once the
answer exists**, so the thread carries a decision rather than a menu.

## 4. Fix — with the gates checked

The fix round is a normal implementation round: `$jumay-implementation-guardrails`
applies, G4 requires a regression re-review of the fix diff, and G17 requires any
new assertion to be shown **failing against the pre-fix code** before it counts.

Four traps that made a "green" fix round lie:

**Gate on exit codes, never on chaining.** A commit went up behind a failing
suite because the commands were `;`-chained and no status was ever read:

```sh
pnpm exec tsc --noEmit;  st_tsc=$?
pnpm exec vitest run;    st_test=$?
[ "$st_tsc" -eq 0 ] && [ "$st_test" -eq 0 ] || { echo "BLOCKED"; exit 1; }
```

Never chain a commit behind a test run. Never grep possibly-coloured output for
"pass" — read `$?` (G7).

**Know the flaky suite.** Some suites (storybook runners under load) fail a
*different* case on each run. Re-run the single file in isolation, then re-run
the suite, before blaming your change — and believe CI over a local run.

**Do not add a warning to the baseline.** A lint gate that passes CI with
`--max-warnings=999` still has a fixed pre-existing count; adding one is a
regression CI will not catch. Count before and after:

```sh
pnpm exec oxlint --format github src | grep -c '^::warning'
```

**Do not overturn scored evidence silently.** A reviewer asked for a fixed height
to become a max height; the change broke a story assertion a parity sweep had
deliberately added after matching the Figma frame. The right move: revert, put
both readings on the thread, let the humans rule, implement once they have.
Related — a Figma frame bakes exactly **one** state, so matching it geometrically
can encode a baked state as a rule. Say that on the thread instead of choosing.

Then: `/jumay-ci-preflight` before pushing (G16), `/jumay-commit` to commit
signed (G1). Replies name a **pushed** sha, so push first.

## 5. Reply — after re-reading the thread

Shape, verdicts and length budget: `/jumay-review-reply`. Two rules that belong
to the *process*, not the text:

**Re-read the thread immediately before you post.** A human reviewer rejected an
option four minutes before a reply went up saying that option had been taken.
Cost: a wrong commit, a wrong reply, a revert, and a deleted comment. The check
is two seconds:

```sh
gh api "repos/OWNER/REPO/pulls/<pr>/comments" --paginate \
  --jq '.[] | select(.id==<comment_id> or .in_reply_to_id==<comment_id>)
        | "\(.created_at) \(.user.login): \(.body[0:200])"'

gh api "repos/OWNER/REPO/pulls/<pr>/comments/<comment_id>/replies" \
  -f body='Fixed in <sha>. …'
```

**Retract, do not paper over.** When a reply is overtaken by events, delete it
and post a correct one — an obsolete reply left standing reads as a settled
thread:

```sh
gh api -X DELETE "repos/OWNER/REPO/pulls/comments/<comment_id>"
```

## 6. Resolve — answered is not resolved

Nine threads across three PRs once sat replied-but-unresolved, each one reading
as open work to every reviewer who opened the PR. `$jumay-parity`
§Review-Response is the policy: reply naming the fixing commit, **then** resolve.

Resolve only a thread whose answer you have checked yourself (G7):

| Resolve | Leave for the reviewer |
| --- | --- |
| You complied literally and the fix is on origin | You reinterpreted the ask |
| You proved the premise false and said how | You addressed it partly |
| The thread was a question you answered fully | It needs an owner decision |

```sh
gh api graphql -f query='
  mutation($id:ID!){ resolveReviewThread(input:{threadId:$id}){
    thread{ isResolved } } }' -f id='<thread node id>'
```

Machine-verify closure at the **final** head, after the last push's checks and
bot runs have finished — bots open new threads late:

```sh
gh api graphql -f query='query($o:String!,$r:String!,$n:Int!){
  repository(owner:$o,name:$r){pullRequest(number:$n){
    reviewThreads(first:100){nodes{isResolved}}}}}' \
  -f o=OWNER -f r=REPO -F n=<pr> \
  --jq '[.data.repository.pullRequest.reviewThreads.nodes[]
         | select(.isResolved==false)] | length'
```

Require **0**, or list every remaining thread with its rationale in the report.
`isOutdated: true` does not mean resolved.

> `/jumay-quality-gate` Phase 7 deliberately does **not** call this mutation: a
> gate that resolves the threads it is auditing has audited nothing. Resolution
> is the author's action, taken here, and the gate then verifies the count.

## 7. Promised a follow-up? File it before you resolve

A reply once said "filing as follow-up" and filed nothing; the ticket appeared
later and the reply had to be edited to name it. `Deferred → <ticket>` means the
ticket exists at the moment the reply posts.

## Shell traps that make verification lie

Both of these fail **silently** — they return success while checking nothing.

- **zsh eats `$VAR:path`.** `$BR:apps/foo` is parsed as the `:a`-style modifier
  and greps a different path. Always brace it: `${BR}:apps/foo`.
- **Unquoted scalar paths lint nothing.** `pnpm exec oxlint $PATHS` from a
  single scalar exits 0 having examined zero files. Use an array and confirm the
  output names your files:

```sh
paths=(src/foo.tsx src/bar.tsx)
pnpm exec oxlint --format github "${paths[@]}"
```

## Checklist

- [ ] Every thread on every stack PR enumerated with bodies, nothing truncated.
- [ ] Every cited rule opened and read; premise **and** severity judged.
- [ ] Every finding confirmed present in this PR's diff (`gh pr diff | grep`).
- [ ] Every fix routed to the branch that owns the file (G8).
- [ ] Owner-decision threads batched and asked, not guessed.
- [ ] Each gate's exit code read individually; no commit chained behind a test.
- [ ] Lint warning count unchanged; new assertions proven red first (G17).
- [ ] Thread re-read immediately before the reply posted.
- [ ] Overtaken replies deleted, not left standing.
- [ ] Promised tickets filed before the thread was resolved.
- [ ] Unresolved count is 0 at the final head, or each remainder is justified.
