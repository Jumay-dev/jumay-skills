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
  as the changelog line it will become.
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

### 5. `## QA steps`

How a reviewer reproduces the change by hand. Required. CI proves the code is
correct; it does not prove the feature does what the ticket asked, and the
reviewer is the one who checks that.

Numbered, imperative, each step with its expected result. Lead with the state the
reviewer needs — a step they cannot reach is worse than no step at all.

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
- [ ] Body is `Closes` + Problem + What this does + Screenshots + QA steps, in that order
- [ ] No test counts, no limitations section, no review history
- [ ] Problem quotes the real user-visible symptom
- [ ] "What this does" is one paragraph
- [ ] Screenshots cover the states, uploaded via the authorized session, each 200
- [ ] QA steps cover the happy path, name their prerequisites, and state expected results
- [ ] Any bot-appended block preserved verbatim
