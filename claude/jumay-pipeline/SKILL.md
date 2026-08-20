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
  ① investigation  ⇄  ② specification  →  ③ implementation
                                                  ↓
  ⑦ review response  ←  ⑥ pr  ←  ⑤ commit  ←  ④ selfreview
        └──────────── code changes re-enter ③ ────────────┘
```

Two loops: `①⇄②` bounds scope before work starts, `⑦→③` carries review back
through it. Everything else runs forward once.

## Stage / skill map

Visual control surface. `always` loads on entry; `if` loads only when the
condition holds. `docs/quality-gate.md` rules are cited by number, not restated.

| # | Stage | Entrypoint | Always | Conditional |
|---|---|---|---|---|
| ① | Investigation | `stages/1-investigation.md` | — | `$jumay-worktree` *(reading a branch/PR)* · `figma:figma-design-to-code` *(Figma URL)* · G3 *(diff provenance)* |
| ② | Specification | `stages/2-specification.md` | G19 | `$jumay-parity` §Success Gate *(parity ticket)* |
| ③ | Implementation | `stages/3-implementation.md` | `$jumay-worktree` · `$jumay-implementation-guardrails` | `$jumay-parity` *(design parity)* · `/jumay-figma-implement` *(Figma feature)* · `$jumay-oneshot` *(generic ticket→PR)* · `/herdr-agents` + `/fleet-orchestrator` *(fanning out)* · G8 *(stacked)* |
| ④ | Selfreview | `stages/4-selfreview.md` | `$jumay-implementation-guardrails` §Self-Review · `/jumay-ci-preflight` | `/jumay-dual-review` *(1 target)* · `/jumay-herdr-review` *(N targets)* · G17 *(new tests)* · G13 *(flagged gaps)* |
| ⑤ | Commit | `stages/5-commit.md` | `/jumay-commit` · G1 · G8 *(fetch before base)* | `gh stack` *(stacked PR)* |
| ⑥ | PR | `stages/6-pr.md` | `/jumay-pr-writeup` | `/jumay-quality-gate` *(before undraft/merge)* · `/jumay-review-message` *(Slack handoff)* · G2 *(evidence)* |
| ⑦ | Review response | `stages/7-review-response.md` | `/jumay-review-reply` · `/jumay-quality-gate` §Phase 7 | `$jumay-parity` §Review-Response *(policy)* · G3 *(deletion claims)* · G2 *(evidence)* |

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
| ② Specification | `findings.md` |
| ③ Implementation | `spec.md` *(the contract)* + `findings.md` §File map only |
| ④ Selfreview | `spec.md` + the diff. **Not** the implementer's reasoning — see G4 |
| ⑤ Commit | the diff + `selfreview.md` verdict |
| ⑥ PR | `spec.md` + the commits + evidence paths |
| ⑦ Review response | `spec.md` + the threads. **Not** the reasoning behind the code they flag |

`spec.md` is the only artifact that carries the whole way through.

## Where this does not apply

- **Investigating a bug with no known cause** — use `/investigate` first, then
  enter at ① with its output as findings.
- **Reviewing someone else's PR** — that is `/jumay-dual-review` or
  `/jumay-herdr-review` standalone, not this flow.
- **A one-line fix.** Stages ③→⑤→⑥. Skipping is fine; skipping *silently* is not.
- **Review arrived on an already-merged PR.** Enter at ⑦, but fix forward from a
  fresh branch — never force-push a merged branch.
