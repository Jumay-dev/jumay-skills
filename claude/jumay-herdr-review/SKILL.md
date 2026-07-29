---
name: jumay-herdr-review
description: Multi-target dual-agent code review in herdr panes — for each target (PR or branch) a Claude pane and a Codex pane independently review the diff against the quality gate, then each rules on the findings the other caught but it missed, and the orchestrator converges them into one verified, routed report per target. N targets run as parallel pairs, never queued. Use when the user names several PRs/branches for a herdr review panel, or wants reviewer panes they can dig into afterward. For a single target, or with no herdr session, use jumay-dual-review instead.
---

# Jumay Herdr Review — a reviewer pair per target

You are the **conductor**. For each **target** (a PR or branch) you stand up a
**pair** of independent reviewers — a **Claude pane** above a **Codex pane** —
over that target's diff, make each rule on what the other caught but it
**missed**, verify every survivor yourself, and converge each pair into one
routed report. **N targets = N pairs, side by side, all reviewing at once** —
never queue targets through one pair; horizontal scaling is the point.

## Which review skill

| | |
|---|---|
| One target, or no herdr session | **`jumay-dual-review`** — subagent + `codex exec`, in-process, works anywhere |
| Several targets, or you want panes to dig into afterward | **this skill** |

Both bind `docs/quality-gate.md` (G1–G15). Neither restates it — load it.

## Preconditions

1. `[ "$HERDR_ENV" = 1 ]` and `$HERDR_PANE_ID` non-empty — otherwise stop and
   tell the user this skill needs a herdr session (offer `jumay-dual-review`).
2. `herdr status` reports version **>= 0.7.0**. PR targets also need `gh`.
3. Load `docs/quality-gate.md` from this skills repo, and the target repo's own
   rule docs (`docs/rules/*.md`, root `REVIEW.md`).

All pane mechanics — `start_agent`, `dispatch`, `await_file`, pane-id handling —
come from the **`herdr-agents`** skill. Do not re-derive them here.

## 1. Resolve the targets

Collect **every** target the user named and give each a short slug (`pr123`,
`fix-auth`). Slugs feed agent names: `[a-z][a-z0-9_-]{0,31}`, unique among live
agents — check `herdr agent list` for collisions from a concurrent run.

Each target gets its own **detached worktree**, so parallel checkouts cannot
stomp each other or the user's working tree (a dirty tree is fine; it is never
touched):

```bash
REPO=$(git rev-parse --show-toplevel); REV=$(mktemp -d)
# PR n:    BASE=$(cd "$REPO" && gh pr view <n> --json baseRefName -q .baseRefName)
#          git -C "$REPO" fetch origin "$BASE"
#          git -C "$REPO" fetch origin "pull/<n>/head"
#          git -C "$REPO" worktree add --detach "$REV/wt-<slug>" FETCH_HEAD
# branch:  BASE = the PR base, else main/master, else what the user named
#          git -C "$REPO" fetch origin "$BASE"
#          git -C "$REPO" fetch origin "<branch>"
#          git -C "$REPO" worktree add --detach "$REV/wt-<slug>" FETCH_HEAD
```

**Fetch the target ref in its OWN fetch.** `FETCH_HEAD` resolves to the FIRST
ref of the last fetch, so combining base+target in one fetch checks out the
base and silently yields an empty diff.

**G3 preflight (do this yourself, once per target).** Record
`git -C "$REV/wt-<slug>" merge-base HEAD origin/$BASE` and whether the base has
gained files since. Upstream additions appear as deletions in a stale-base diff,
and a reviewer pane WILL flag them as "this PR deletes X" unless the brief says
otherwise. Put the merge-base and any known stale-base paths in the brief.

Review range per target: `origin/$BASE...HEAD` inside its worktree.

**Done when:** every target has a worktree, a non-empty
`git -C "$REV/wt-<slug>" diff origin/<base>...HEAD`, and a recorded merge-base.

## 2. Stand up the pairs — a column per target

You keep the full-height left column; each target gets one column beside you,
Claude on top, Codex below. Split from **your own** pane so the grid lands in
the tab the user is looking at.

```bash
sp(){ herdr pane split "$1" --direction "$2" --ratio "$3" --cwd "$4" --no-focus \
        | jq -r '.result.pane.pane_id'; }
inv(){ awk "BEGIN{printf \"%.4f\", 1/$1}"; }

set -- <slug1> <slug2> …                 # targets, left→right
N=$#
COLS=("$(sp "$HERDR_PANE_ID" right "$(inv $((N+1)))" "$REPO")")
for ((c=N; c>1; c--)); do COLS+=("$(sp "${COLS[-1]}" right "$(inv $c)" "$REPO")"); done

for col in "${COLS[@]}"; do
  slug=$1; shift; WT="$REV/wt-$slug"
  bot=$(sp "$col" down 0.5 "$WT")
  start_agent "claude-$slug" claude "$col"
  start_agent "codex-$slug"  codex  "$bot" -- -m gpt-5.6-sol -c model_reasoning_effort=xhigh
  herdr pane rename "$col" "claude-$slug"; herdr pane rename "$bot" "codex-$slug"
done
```

`--ratio` is the fraction **kept by the pane you split**. Point each pane's
`--cwd` at that target's worktree. `start_agent` absorbs the `agent_pane_busy`
race and blocks until the agent is ready. Verify the codex model flag is current
before relying on it.

**Done when:** all 2N panes report an agent, each carries its
`claude-<slug>` / `codex-<slug>` name, and you hold the name→pane map.

## 3. Independent review — dispatch everything, then confirm

One single-line brief per pane (Codex gets the same brief with `codex` in the
file name and sentinel). The brief carries the quality gate as **review
lenses** — without them the panes review generically and miss the money-path
failures this repo exists to catch:

```bash
BRIEF="Code review. Run: git -C $WT diff origin/$BASE...HEAD — review ONLY those changes; read changed files in $WT for context. The merge-base is $MB: files ADDED to $BASE after it appear as deletions in this diff and are NOT this PR's doing — never flag them (G3). Cover correctness, security, data-loss, concurrency, API misuse, PLUS: authoritative bounds min'd with every binding constraint and buffered for drift, never rebuilt from a snapshot ratio (G9); errors distinguishing proven-not-executed from ambiguous-after-broadcast, never offering retry as safe after broadcast (G10); missing data rendered as explicit unknown, never coerced to zero or a confident placeholder (G11); external DTOs validated and deserialized ONCE at the fetch boundary, Decimal-first for money, fixtures wire-faithful (G12); values captured at render but consumed at submit re-read at action time (G14); deprecated SDK surfaces confined to the narrowest boundary, expensive shared resources behind one cached query (G15). Write every finding to $REV/$SLUG-claude.tmp, one per line: 'path:line — SEVERITY — issue — why it is wrong'. If the review is clean write the single line NO-FINDINGS. Then mv it to $REV/$SLUG-claude.md and print exactly: REVIEW-DONE-$SLUG-claude"
```

**Fan all 2N briefs out in parallel** with the backgrounded `dispatch` +
failure reap from `herdr-agents` — never a sequential foreground loop.
`dispatch` confirms intake (the token counter moved); an agent that comes back
`DISPATCH-FAIL` or `DISPATCH-NO-INTAKE` is **unbriefed**, and you must never
converge a pair around it.

Then `await_file` each finding file **in the background**. Mark any pane that
times out as failed and say so in the report — never converge a pair around a
file that does not exist.

**The deliverable file is the only trustworthy completion signal.** The sentinel
is in the brief you dispatched, so `pane wait-output --match` fires on the
echoed prompt the instant you send it. Match the variable form
(`--regex 'REVIEW-DONE-[a-z0-9_-]+-(claude|codex)'`) or skip output-matching and
poll the file.

Every deliverable here is an idempotent **tmp+mv overwrite** — that is what
makes `dispatch`'s retry safe. Never switch any of them to appends.

**Done when:** for the pair you are converging, both finding files exist and you
have read them.

## 4–8. Converge each pair as it finishes — no barrier

The moment ONE pair's two files exist, converge that pair while the others are
still reviewing.

**4 · Split agreed vs contested.** Match the two lists by **location +
underlying issue** — same bug worded differently is a match, substance not
string. Both found it → **agreed**. One found it → **contested**, a blind spot
for the pane that missed it. Write the other pane's exclusives, numbered, to
`$REV/$SLUG-for-claude.md` / `$REV/$SLUG-for-codex.md`.
*Done when every finding sits in exactly one bucket.*

**5 · Cross-examine the blind spots.** Skip a pane whose `for-*` file is empty.
Same atomic contract — full set to `.tmp`, then `mv`, **never an append**: an
appended file is readable half-finished the moment the first line lands, and a
retry would duplicate.

```bash
X="Another reviewer flagged issues you missed, numbered in $REV/$SLUG-for-claude.md. For each, verify against the code in $WT. Write the FULL verdict set to $REV/$SLUG-claude-verdicts.tmp, one line per finding: 'N — AGREE|DISAGREE — one-line reason' — every number must have exactly one line. Then mv it to $REV/$SLUG-claude-verdicts.md and print exactly: VALIDATE-DONE-$SLUG-claude"
```

`dispatch`, then gate on the verdict files of the panes you actually dispatched
to. *Done when every contested finding has a verdict from the pane that missed it.*

**6 · Orchestrator verification (G7) — never skip.** Panes are agents; their
self-reports are not evidence. Before any finding reaches the user:
- **Read the cited code yourself** for every CRITICAL. Kill or downgrade
  findings that misread guards, reactivity, or units — "nothing re-renders" is
  often really "re-renders within ~5s"; report the true window.
- Re-check any deletion or scope-creep claim against the recorded merge-base
  (G3), even though the brief warned about it.
- Check overlap with prior review threads and with fixes already landed
  elsewhere in the stack — a finding can be true on this head and already fixed
  on a neighbouring branch, which makes it a sync, not a code fix.
- Calibrate confidence: verified-in-code 8–10, plausible-unverified ≤6,
  suppress <4 unless severity would be critical.

**7 · Report + routing (G8).** One merged, severity-ordered report **per
target**, delivered as that pair converges. Tag each finding:
- **agreed** — both found it independently (highest confidence),
- **confirmed** — one found it, the other ruled AGREE,
- **disputed** — ruled DISAGREE; present both sides in one line so the user
  adjudicates. Never silently drop a disputed finding.

Then a **routing plan**: which worktree/branch owns each fix per the stacked-PR
convention, what is answer-only, what needs a user decision. This skill reviews
and routes; it does not commit, push, or resolve human review threads. Fixes go
to the owning executor with the standing constraints (G1 signing, G2 evidence,
G5 markers).

**8 · Regression re-review (G4).** When fixes come back, re-run a SCOPED pass
over only the changed lines of the fix commits — both panes get the fix diff,
the original findings, and "find what the fixes broke". Warm panes make this
cheap. A fix round without a regression pass is not closed.

## Cleanup

Panes stay open so the user can dig in. Their shells sit **inside** the
worktrees, so clean up in order once the user confirms they are done:

1. close (or repoint) the reviewer panes,
2. `git -C "$REPO" worktree remove "$REV/wt-<slug>"` per target,
3. remove `$REV` — only once its reports are saved elsewhere.
