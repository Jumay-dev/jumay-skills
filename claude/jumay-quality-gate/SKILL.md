---
name: jumay-quality-gate
description: Post-implementation verification gate — takes work an executor claims is finished and independently proves or disproves every claim with the orchestrator's own commands (signatures, evidence, commits on origin, fixes really in code, CI on the exact head), then runs a regression review over the fix diff and returns PASS or BLOCKED with a routed fix list. Use when an agent reports a task complete, before undrafting a PR, before merging, or when the user asks to "gate", "close out", or "verify" finished work. Does not implement or fix — it verifies and routes.
---

# Jumay Quality Gate

The closing gate for any implementation cycle. An executor says it is done; this
skill decides whether that is true. It runs `docs/quality-gate.md` (G1–G8, G13)
as **executable checks**, not as review opinions.

**Iron rule (G7): a self-report is never evidence.** Every claim below is
confirmed with your own command, or it is not confirmed. "Idle" is not done, a
completion marker is not work, and a green summary from the agent that wrote the
code proves nothing.

This skill **never fixes product code**. It verifies and routes.

## Inputs

- **Target**: PR number/URL, or a branch/worktree (default: current worktree's
  branch vs its PR base).
- **The claim list**: what the executor said it did — commits, fixes, evidence,
  validation, thread replies. Itemize it. An unstated claim cannot be checked;
  if the agent gave only prose, extract the checkable assertions first.
- Optional: expected evidence set, the review findings this round was meant to
  close.

## Phase 0 — Resolve and record

1. Resolve the worktree that OWNS the branch (stacked-PR convention, G8). Note
   any uncommitted state — a dirty tree at gate time is itself a finding.
2. `git fetch origin <base>` and record:

```sh
BASE=$(gh pr view "$PR" --json baseRefName -q .baseRefName)
git fetch origin "$BASE" --quiet
MB=$(git merge-base HEAD "origin/$BASE")          # G3 provenance
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse "origin/$BRANCH" 2>/dev/null)
PRHEAD=$(gh pr view "$PR" --json headRefOid -q .headRefOid)
```

3. `[ "$LOCAL" = "$REMOTE" ] && [ "$REMOTE" = "$PRHEAD" ]` — if these three
   disagree, every downstream check is against the wrong head. Resolve first.

**Done when:** base, merge-base, and a single agreed head sha are recorded.

## Phase 1 — G1 signatures

```sh
git log --format='%h %G? %an %s' "origin/$BASE..HEAD"
git config --local --list | grep -iE 'sign|gpg'   # MUST be empty
```

Every new commit shows `G`. Any `N`, `E`, or `U`, or any local signing override,
means an agent bypassed the signer → **`BLOCKED-SIGNING`**, stop the gate here
and report. Do not "fix" it by re-signing on the agent's behalf; the executor
re-commits.

GitHub's own merge commits show `E` (signed with GitHub's key, not in your
keyring) — that is expected on merged PRs and is not a violation. Check the
commits the branch ADDED.

## Phase 2 — Claimed artifacts exist

For every commit sha the executor claimed:

```sh
git cat-file -e "$SHA^{commit}"                        # exists locally
git merge-base --is-ancestor "$SHA" "origin/$BRANCH"   # actually pushed
```

A sha that exists locally but is not an ancestor of the remote branch was never
pushed — a very common false completion (G5: markers embed a variable artifact
precisely so you can check it). Claimed PR URLs must resolve to a real PR on the
expected head.

## Phase 3 — G2 evidence intact

If the work carries PR evidence (screenshots, overlays, parity tables):

- The full evidence set is present in the PR body at the CURRENT head.
- The capture-commit note equals the pushed head — stale captures are not
  evidence for this head.
- The body validator passes (e.g. `codex/jumay-parity/scripts/validate-pr-body.js`).
- Any removal is valid ONLY as remove-AND-regenerate, and must be reported
  explicitly. A body edit that quietly dropped images is a **BLOCKED** finding,
  not a nit — this rule exists because an executor stripped all 10 images from a
  PR body during a review-response task and reported it in one clause.

## Phase 4 — G7 claims vs reality

Take the claim list item by item.

**Fixes are really in the code.** Read or grep the cited lines for every
CRITICAL claim. An agent that says "fixed the stale read" while the read is
still at hook render has not fixed it (G14).

**Validation actually passes.** Spot-run at minimum the typecheck; do not accept
a pasted green log. Verify by exit code, never by grepping possibly-coloured
output.

**Review threads.** Counted and classified in Phase 7, not here. Do not accept
an agent's summary of what it answered.

**CI on the exact head.** `gh pr checks "$PR"` — confirm the run is against the
recorded head sha, not an older one.

**Mergeability.** GitHub's `mergeable` flag goes stale after squash-merges and
retargets. A locally clean `git merge-tree` plus an ancestor check overrides a
`CONFLICTING` flag — poll or nudge, do not churn the branch.

## Phase 5 — G3 provenance and G13 flagged gaps

- Re-check any "this PR deletes X / removes infrastructure" claim against `$MB`.
  Files ADDED to the base after the merge-base appear as deletions in a
  stale-base diff and are not this PR's doing.
- Any coverage gap a previous review flagged on a **user-reachable** branch must
  be closed (test + behavior) before this gate passes. A flagged untested branch
  is a scheduled incident, not an observation — one escaped to QA on exactly the
  branch a specialist had flagged.

## Phase 6 — G4 regression review

Fixes introduce regressions at the same rate as features, so the fix diff gets
its own review by something that did not write it:

```sh
git diff "$FIRST_FIX_COMMIT^..HEAD"    # only what this round changed
```

- Several targets, in a herdr session → **`jumay-herdr-review`**.
- One target, or no herdr → **`jumay-dual-review`**.

Hand it the fix diff, the original findings, and the framing "find what these
fixes broke". A fix round without this pass is **not closed**.

## Phase 7 — Review threads answered

The verdict can block on unresolved threads, so something has to enumerate them.
Do it here, across **every PR in the stack** — a finding raised on a base branch
is often fixed in a child, and no GitHub view shows that.

```sh
# Resolution state — REST comments cannot tell you isResolved.
gh api graphql -f query='
  query($owner:String!,$repo:String!,$pr:Int!){
    repository(owner:$owner,name:$repo){
      pullRequest(number:$pr){
        reviewThreads(first:100){ nodes{ isResolved isOutdated path line
          comments(first:50){ nodes{ author{login} body } } } } } } }
' -F owner=OWNER -F repo=REPO -F pr=$PR

# Bodies carry the claimed count ("found N potential issues") to reconcile against.
gh api "repos/$REPO/pulls/$PR/reviews" --paginate
```

Reconcile the count a review body claims against the inline threads you actually
fetched. If a body says "found 8 potential issues" and you are holding 3, you are
holding 3.

Five traps, each observed in the wild:

1. **A green bot check is not an empty review.** Devin's check passed on a PR
   carrying 8 comments. Never infer thread state from `gh pr checks`.
2. **Never truncate the fetch.** `--paginate` with no `head`/`tail`. A piped
   `head -120` is how the 8-vs-3 above happened.
3. **`outdated`/`position` is not relevance.** A thread showed `outdated=false`
   against a file the PR had deleted. Classify by reading current code.
4. **Bots do not re-review every push.** Unchanged IDs and counts after a fix
   mean *not re-run*, not *still broken* — and not *fixed* either.
5. **A reply is not a resolution.** Threads stay open until a human resolves
   them. Resolving requires the GraphQL `resolveReviewThread` mutation, and this
   skill does not call it: an agent resolving threads against its own work hides
   history from the reviewer.

Emit a ledger per PR — thread, one-line finding, and one of **fixed** (name the
commit), **partly** (state what remains), **open**, or **stale** (the code it
cites is gone). Classify against current code with your own grep; a fix claimed
in a reply is a self-report, and G7 says that is not evidence.

Reply on the thread for anything fixed or partly fixed, naming the commit and
stating residuals plainly. A "fixed" reply that omits a known residual is worse
than no reply — it retires a thread a reviewer would still want.

**Done when:** every thread in every stack PR carries a status, claimed counts
reconcile with fetched counts, and anything still **open** is named in the
verdict as `BLOCKED-UNADDRESSED`.

## Phase 8 — Verdict

Report one of:

- **PASS** — every claim independently confirmed. State what you verified and
  how, not that the agent said so.
- **BLOCKED** — list the failed invariant(s) by ID (`BLOCKED-SIGNING`, evidence
  stripped, unpushed sha, red CI, `BLOCKED-UNADDRESSED` review threads, open
  regression). Nothing merges or undrafts on a BLOCKED gate.

Then a **routing plan (G8)**: which worktree/branch owns each fix per the
stacked-PR convention, which items are answer-only, which need a user decision.
Cross-branch duplicate fixes need a reconciliation plan naming the canonical
side BEFORE both land. Never sync upward while a lower branch has unverified
signatures (G1) or stripped evidence (G2).

Re-gate after fixes come back — a gate is a loop, not a checkpoint.

## Constraints

- Read-only on product code. This skill blocks and routes; the owning executor
  fixes.
- Submodules are never staged, modified, or gated as in-scope.
- Report honestly: a check you could not run is UNVERIFIED, never PASS. Partial
  coverage stated plainly beats a confident green.
