---
name: jumay-pipeline
description: Entrypoint for the seven-stage development flow — investigation → specification → implementation → selfreview → commit → PR → review response. Loads one stage entrypoint at a time, each declaring the skills that stage needs, so context stays scoped to the current stage instead of the whole workflow. Use when starting a ticket, when asked which stage comes next or which skills a stage uses, or when resuming work mid-flow. Also the map: the stage/skill table below is the visual control surface for the whole system.
---

# Jumay Pipeline

The flow every ticket runs through. Each stage has **its own entrypoint file**
under `stages/` that names the skills that stage loads. You load **one stage
file at a time** — that is the whole point. Loading all seven is the failure mode
this replaces.

```
  1 investigation  ⇄  2 specification  →  3 implementation
                                                  ↓
  7 review response  ←  6 pr  ←  5 commit  ←  4 selfreview
        │
        └→ code changes re-enter 3
```

Two loops: `1⇄2` bounds scope before work starts, `7→3` carries review back
through it. Everything else runs forward once.

## Stage / skill map

Visual control surface. `always` loads on entry; `if` loads only when the
condition holds. `docs/quality-gate.md` rules are cited by number, not restated.

| # | Stage | Entrypoint | Always | Conditional |
|---|---|---|---|---|
| 1 | Investigation | `stages/1-investigation.md` | — | `$jumay-worktree` *(reading a branch/PR)* · `figma:figma-design-to-code` *(Figma URL)* · G3 *(diff provenance)* |
| 2 | Specification | `stages/2-specification.md` | `fe-spec-tickets` *(mandated house format)* · G19 | `$jumay-parity` §Success Gate *(parity ticket)* |
| 3 | Implementation | `stages/3-implementation.md` | `$jumay-worktree` · `$jumay-implementation-guardrails` | `$jumay-parity` *(design parity)* · `/jumay-figma-implement` *(Figma feature)* · `$jumay-oneshot` *(generic ticket→PR)* · `/herdr-agents` + `/fleet-orchestrator` *(fanning out)* · G8 *(stacked)* |
| 4 | Selfreview | `stages/4-selfreview.md` | `$jumay-implementation-guardrails` §Self-Review · `/jumay-ci-preflight` | `/jumay-dual-review` *(1 target)* · `/jumay-herdr-review` *(N targets)* · G17 *(new tests)* · G13 *(flagged gaps)* |
| 5 | Commit | `stages/5-commit.md` | `/jumay-commit` · G1 · G8 *(fetch before base)* | `gh stack` *(stacked PR)* |
| 6 | PR | `stages/6-pr.md` | `/jumay-pr-writeup` | `/jumay-quality-gate` *(before undraft/merge)* · `/jumay-review-message` *(Slack handoff)* · G2 *(evidence)* |
| 7 | Review response | `stages/7-review-response.md` | `/jumay-review-reply` · `/jumay-quality-gate` §Phase 7 | `$jumay-parity` §Review-Response *(policy)* · G3 *(deletion claims)* · G2 *(evidence)* |

## Running a stage

1. **Read the stage entrypoint file. Only that one.**
2. Load the skills its `Always` column names; check each `if` condition and
   load only what applies.
3. Do the stage's work.
4. Check the stage's **Exit gate** with your own commands (G7 — a self-report
   is not evidence). Failed gate means you stay in the stage.
5. Write the stage's artifact, then move to the next entrypoint.

## Watching a run

```sh
claude/jumay-pipeline/scripts/pipeline-status.sh          # live, all tickets
claude/jumay-pipeline/scripts/pipeline-status.sh --once   # one frame, for logs
```

One row per ticket: seven stage glyphs (done / spinning / pending), the active
stage's last progress line, and any herdr pane whose label names the ticket.

It reads three sources and asks no agent anything:

| Source | Gives |
|---|---|
| `progress.log` — `PROGRESS <stage> <message>` lines | the authoritative stage and what is happening inside it |
| stage artifacts in the run directory | the fallback stage, when no log exists yet |
| `herdr agent list` | pane liveness, matched by label |

**You cannot scrape intent — instrument it.** A pane's status line proves an
agent is working, never what on. That is why each stage entrypoint requires a
`PROGRESS` line per step: it is the same discipline as G5's completion markers,
applied to the middle of a stage rather than its end.

## Run directory

Stage artifacts live in `${PIPELINE_DIR:-$HOME/.pipeline}/<ticket>/` — **outside
the repo**, so they cannot be accidentally staged and they survive
`git worktree remove`. One directory per ticket.

## What carries forward

The compression rule. On entering a stage you get **its declared inputs and
nothing else** — not the previous stage's transcript.

| Entering | Carries in |
|---|---|
| 2 Specification | `findings.md` |
| 3 Implementation | `spec.md` *(the contract)* + `findings.md` §File map only |
| 4 Selfreview | `spec.md` + the diff. **Not** the implementer's reasoning — see G4 |
| 5 Commit | the diff + `selfreview.md` verdict |
| 6 PR | `spec.md` + the commits + evidence paths |
| 7 Review response | `spec.md` + the threads. **Not** the reasoning behind the code they flag |

`spec.md` is the only artifact that carries the whole way through.

## Where this does not apply

- **A feature request with no ticket yet** — that is `fe-spec-tickets`
  (`Kamino-Finance/almanack`), which turns a request or a Figma design into
  Linear tickets from a product point of view and explicitly does not read the
  codebase. Its output is the ticket that enters at stage 1. This pipeline
  consumes its **format** at stage 2; it does not run its workflow.
- **Investigating a bug with no known cause** — use `/investigate` first, then
  enter at 1 with its output as findings.
- **Reviewing someone else's PR** — that is `/jumay-dual-review` or
  `/jumay-herdr-review` standalone, not this flow.
- **A one-line fix.** Stages 3→5→6. Skipping is fine; skipping *silently* is not.
- **Review arrived on an already-merged PR.** Enter at 7, but fix forward from a
  fresh branch — never force-push a merged branch.
