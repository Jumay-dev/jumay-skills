---
name: jumay-pr-writeup
description: Write a PR title and description in Mike's house style — conventional-commit title with the Linear key, and a body of exactly Closes / Problem / What this does / Screenshots / QA steps. Use when opening a PR, rewriting a bloated PR body, or when asked to "write the PR description", "fix the PR body", or "open the PR". Also tells you where the material that does NOT belong in the body should go instead.
---

# Jumay PR Write-up

A PR body describes **the change**. It does not defend the work, narrate the
process, or restate what CI already proves.

Derived from a real edit: a 68-line body was cut to 21 lines. Everything that
survived described the change; everything that was cut described the *making* of
the change. Match that.

## Title

```
type(scope): short description (FE-1234)
```

- Conventional Commits. `feat`, `fix`, `docs`, `refactor`, `chore`, `test`,
  `perf`, `build`, `ci`.
- **scope** is the product area (`borrow`, `earn`, `lend`, `liquidity`,
  `private-credit`, `portfolio`, `reserve`, `assets`), not the file or layer.
- Linear key(s) in parens at the end, comma-separated for several. Omit only
  when there is genuinely no issue.
- The repo squash-merges, so this title becomes the commit on master. Write it
  as the changelog line it will become. It also means the PR title, not the local
  commit message, is what lands — retitling the PR is enough.
- **Scope a multi-PR initiative by its own name.** When a stack of PRs builds one
  feature, give them all a shared scope so a reviewer scanning open PRs sees one
  effort without opening any of them, and `git log --grep` finds the whole thing
  afterwards.

  ```
  feat(cash-balance): add transaction destinations and projected yield (FET1-1459)
  fix(cash-balance): show the form heading on both tabs (FET1-1460)
  feat(cash-balance): add the deposit rate and yield summary (FET1-1379)
  ```

  This deliberately adds a scope the repo has not used before, which is fine — the
  initiative *is* a product area, and the alternatives are worse: a `Cash Balance:`
  prefix inside the subject costs a double colon in every changelog line, and
  dropping the conventional-commit prefix to mirror the ticket titles breaks from
  every other commit on master.

  Check what is already in use before picking a name, so you extend the vocabulary
  rather than duplicating it:
  `git log --oneline -60 | grep -oE '^[a-f0-9]+ [a-z]+\([a-z-]+\)'`.
  Nothing in CI lints the title — this is convention, so it is on you to keep the
  stack consistent once the first PR sets the scope.
- Check the target repo's `CLAUDE.md` / `CONTRIBUTING.md` first — if it states a
  convention, that wins over this file.

## Body — these five parts, in this order, and nothing else

### 1. `Closes FE-1234`

First line. Bare. No heading.

### 2. `## Problem`

What was broken, in past tense, from the user's side. Concretely:

- Quote the actual user-visible string if there is one (blockquote it).
- Name the entry points that hit it, so a reviewer can reproduce.
- One line on scope if it generalises ("Multi-debt loans dead-ended the same
  way").

Do not explain the code path here. Do not name the functions. A reviewer who has
never opened the file should understand the symptom.

### 3. `## What this does`

**One paragraph.** What the change is, and what follows from it. Name the shared
component or pattern being reused if that is the essence of the change. End with
the consequence chain if there is one ("borrow power, price, LTV, simulation and
the submit reserve all follow the selected asset").

Not a bullet list of every file. Not a design rationale.

### 4. `## Screenshots`

Required for anything user-visible. A markdown table, one column per state,
`<img … width="320">` per cell:

```markdown
| Multiple assets (closed) | Selector open | Single asset |
|---|---|---|
| <img src="…" width="320"> | <img src="…" width="320"> | <img src="…" width="320"> |
```

Capture states, not one hero shot: the new affordance, its open/active state,
and the degenerate case (empty, single-option, error). One line of prose under
the table only if a state needs a caveat.

Upload with `gh image`. On a private repo the default browser session 404s —
use the authorized session:

```bash
TOKEN=$(~/.codex/bin/gh-image-token.sh) || exit 1
GH_SESSION_TOKEN="$TOKEN" gh image --repo <owner>/<repo> shot1.png shot2.png
```

Verify each URL returns 200 **with that same session** before trusting it;
anonymous curl 404s on a private repo even for a valid asset.

#### Video, when a still cannot show the change

Load speed, a transition, an animation, scroll behaviour — a screenshot proves
none of these. Attach a clip instead, under the same `## Screenshots` heading. A
player has no alt text, so label it on the line above:

```markdown
**Loan page cold load — master (left) vs this PR (right)**

https://github.com/user-attachments/assets/…

Median of 5 interleaved loads per side; one master outlier at 0.9s settled excluded.
```

Put the bare attachment URL on its own line — that is the form GitHub renders as
a player — and open the rendered body to confirm it plays before moving on.

Tooling: `agent-browser` records, `ffmpeg` joins and captions, `ffprobe` checks
length. Check up front — `command -v agent-browser ffmpeg ffprobe` — and if
ffmpeg is missing, ask the user to run `! brew install ffmpeg` rather than
shipping an un-captioned single clip.

- **Record from `about:blank`** so the load itself is in frame:
  `agent-browser open about:blank && agent-browser record start ./a.webm && agent-browser open <url>`,
  wait until settled, `agent-browser record stop`.
- **Before/after is one clip, side by side.** Record the base preview and the PR
  preview with the same viewport and the same navigation, then
  `ffmpeg -i before.webm -i after.webm -filter_complex "[0:v][1:v]hstack=inputs=2" -c:v libx264 -pix_fmt yuv420p out.mp4`,
  with a `drawtext` label on each side. Keep the two navigations aligned to the
  same start frame, or the comparison is the offset, not the change.
- **Caption load speed with measured numbers** — first byte, first paint,
  settled, HTML size — read via `agent-browser eval` from the Navigation and Paint
  Timing APIs of *that exact load*, never from a different run.
- **One load per side is not evidence.** Record several loads per side,
  interleaved (base, PR, base, PR…) so network drift hits both equally, and show
  the median one. A single load can catch an outlier and reverse the story — a
  rare fast base load once made a faster PR look slower. State the sample size
  and any excluded outlier under the video.
- **Check every clip's length with `ffprobe`** before choosing one:
  `ffprobe -v error -show_entries format=duration -of csv=p=0 a.webm`.
  `agent-browser record` sometimes cuts clips short, and a truncated clip
  silently drops the slow part of the load.
- **Convert to mp4** (H.264, `yuv420p`) before uploading; upload with the same
  `gh image` session as screenshots and verify the URL the same way.
- **Show the clip to the user before posting it.**

### 5. `## QA steps`

How a reviewer reproduces the change by hand. Required. CI proves the code is
correct; it does not prove the feature does what the ticket asked, and the
reviewer is the one who checks that.

Numbered, imperative, each step with its expected result. Lead with the state the
reviewer needs — a step they cannot reach is worse than no step at all.

**Open with a direct preview link, deep enough to land on the change.** Cloudflare
posts branch previews on every PR; a bare origin makes the reviewer navigate there
themselves, and they will land somewhere else or give up. Link the exact page, with
whatever params the state needs:

```markdown
https://<branch>-frontend.kmno.workers.dev/earn/lend/steakhouse-usdc/vault-overview?DEBUG_WALLET=<address>
https://<branch>-storybook.kmno.workers.dev/?path=/story/widgets-depositformratesummary--populated
```

Rules that make the link actually work:

- **Verify it before pasting.** `curl -o /dev/null -w '%{http_code}'`, following
  redirects. A 307 means you have the pre-redirect form — paste the target so the
  reviewer lands in one hop. Give it a generous timeout: a page that fans out to
  portfolio queries can take 6s+ and a short `--max-time` reports `000`, which is
  curl giving up, not the server failing.
- **Use a real route.** Confirm the path against `src/routes/` rather than memory —
  a plausible-looking wrong path 404s and burns the reviewer's trust in the rest of
  the body.
- **Use real data.** Slugs and addresses from `*.fixture.ts` are invented and 404 in
  production. Pull them from the same source the app reads.
- **Storybook: verify the story id against the deployed `index.json`**, not the
  `title:` in the source. Link `/?path=/story/<id>` — the canonical shareable form.
- **A debug wallet beats "connect a wallet first"** when the state needs one. It is a
  root search param retained across navigation, so it survives in-page navigation.
- **When there is genuinely nothing to preview, say so and say why.** A model-only or
  refactor-only PR should state that plainly and name the PR where the change becomes
  visible. Silence reads as an oversight; an explicit "no UI surface, renders at
  FE-xxxx" reads as a decision.
- **In a stack, link the surface that actually changed.** A component added bottom-up
  has no app surface until its wiring PR — link Storybook and say the app preview is
  unchanged by design, rather than linking an app page where nothing differs.

```markdown
**Prerequisites:** wallet connected, on a loan you hold.

1. Open `/borrow/loan/<market>/<obligation>` — page loads, no form open.
2. Add `?action=repay` and reload — the Repay form opens.
3. Switch to Borrow in the panel — the URL becomes `?action=borrow`.
4. Close the form — `action` drops out of the URL.
```

Happy path is the floor. Add the one or two negative cases the change actually
guards (a bad param value, an empty state) — not an exhaustive matrix, which is
what the tests are for.

Keep it to a couple of minutes of clicking. If reproducing needs seeded on-chain
state, a funded wallet, or a feature flag, say so in the prerequisites rather
than letting the reviewer discover it at step 4.

This is **not** the cut "testing section" below: that rule bans reporting *your*
test results, which CI already shows. This section is instructions for someone
else to exercise the change.

## Cut these — and put them where they belong

These are the sections that got deleted. The information is not worthless, it is
**misplaced**:

| Do not put in the PR body | Where it goes |
| --- | --- |
| "Shared code touched, reviewers start here" | The diff shows it. If a shared change is genuinely risky, say so in a review thread or ask a reviewer directly. |
| Architecture rationale, why approach A over B | Commit message body, or a reply on the review thread that asks |
| Known limitations, edge cases not handled | Linear tickets. Link them from the ticket, not the PR. |
| Test counts, "108 files / 960 tests pass" | CI is the evidence. Self-reported counts are noise at best. (Manual repro steps are different — they belong in `## QA steps`.) |
| Typecheck/lint status | Same. |
| Review history, rounds, what earlier revisions got wrong | Nowhere. It is process, not change. |
| Changed test expectations with justification | The review thread where it was raised, or the commit message |
| "Not verified against live data because …" | Tell the human directly, in chat or a review comment. It needs a decision, and a PR body is not where decisions get made. |

Rule of thumb: **if a sentence exists to pre-empt a reviewer's objection, cut
it.** Let them object, then answer on the thread. That is what threads are for.

## Never hard-wrap the prose

GitHub renders PR bodies and comments with GFM line breaks **on**: a single
newline inside a paragraph becomes a `<br>`, not a space. Prose wrapped at 80
columns therefore renders as a ragged column roughly half the width of the
description area — every line breaking where your editor broke it, not where the
reader's viewport does.

**One paragraph, one line**, however long. Let the browser wrap it.

```markdown
The status reading carries three states — confirmed, seen, unseen — and a settlement built on it consults the transaction's signed lifetime before calling an unseen signature dead.
```

not

```markdown
The status reading carries three states — confirmed, seen, unseen — and a
settlement built on it consults the transaction's signed lifetime before
calling an unseen signature dead.
```

This is invisible in the file you are composing and in `gh pr view`, which
prints the raw source — it only shows up in the browser, which is where the
reviewer reads it. Check the rendered page, or check that no prose line in the
body is short enough to have been wrapped by hand.

Applies to every numbered QA step and bullet too: keep each item on one line.
Blank lines between blocks are unaffected — those are real paragraph breaks and
you still need them.

Where hard line breaks ARE the intent — a table row, a list, an address block —
they work exactly as written. The rule is about prose.

**The same rendering applies to review-thread replies and issue comments**, so
it binds `jumay-review-reply` and anything else that posts to GitHub.

## Bot-appended blocks

Review bots (Devin and friends) append their own HTML blocks between markers
like `<!-- devin-review-badge-begin -->`. Leave them alone. When rewriting a
body, preserve any bot block verbatim at the end, or the bot will re-add it and
you will have two.

## Editing an existing body

```bash
gh pr view <n> --json body --jq '.body' > /tmp/pr-body.md
# edit, preserving any bot-appended block at the end
gh pr edit <n> --body-file /tmp/pr-body.md
```

Never lose the screenshot table when rewriting. Evidence is never removed
without same-task regeneration (quality gate G2) — if a shot is stale, retake it
at the current head, do not just delete it.

## Checklist

- [ ] Title is `type(scope): description (FE-xxxx)` and reads as a changelog line
- [ ] Title scopes the initiative when the PR is one of a stack, and matches the scope its siblings use
- [ ] Body is `Closes` + Problem + What this does + Screenshots + QA steps, in that order
- [ ] No test counts, no limitations section, no review history
- [ ] Problem quotes the real user-visible symptom
- [ ] "What this does" is one paragraph
- [ ] Screenshots cover the states, uploaded via the authorized session, each 200
- [ ] Motion changes carry a labelled clip: side-by-side, captioned from the same load, median of interleaved runs, length checked, shown to the user first
- [ ] QA steps open with a verified direct preview link (real route, real data, one hop), or say explicitly why there is nothing to preview
- [ ] QA steps cover the happy path, name their prerequisites, and state expected results
- [ ] Any bot-appended block preserved verbatim
- [ ] No hard-wrapped prose — each paragraph, QA step and bullet is one line
