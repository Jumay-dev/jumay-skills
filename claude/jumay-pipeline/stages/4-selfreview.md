# Stage 4 — Selfreview

Prove the work is done before anyone else looks at it. Two different actors run
here — do not collapse them.

## Load

| | Skill | When |
|---|---|---|
| always | `$jumay-implementation-guardrails` §Self-Review Checklist | the executor's own pass |
| always | `/jumay-ci-preflight` | typecheck+lint+tests is a **subset** of CI, not the set (G16) |
| if | `/jumay-dual-review` | one target, or no herdr session |
| if | `/jumay-herdr-review` | several targets, or you want panes to dig into |
| if | `docs/quality-gate.md` G17 | you wrote tests to pin a fix |
| if | `docs/quality-gate.md` G13 | review flagged an untested user-reachable branch |

## Entry

`spec.md` + the diff. **Not** the implementer's reasoning — a reviewer who
inherits the author's justification reviews the justification, not the code (G4).

## Do

1. **Executor pass** — the guardrails self-review checklist against your own diff.
2. **CI parity (G16)** — enumerate every job in `.github/workflows`, run each one
   that runs locally. Name the ones that could not be checked; an unrun gate is
   an unknown, not a pass.
3. **Different-actor pass (G4)** — dual-review or herdr-review. The re-review
   must be something that did not write the code. Self-review alone never
   satisfies G4, no matter how thorough.
4. **G17 — a new test must fail against the old code.** Copy the pre-fix logic to
   a sibling module and run the new test against it. A test that passes both ways
   is decoration. This applies hardest to tests *you asked for* — those carry the
   assumption of coverage without the proof.
5. **G13 — close flagged untested branches now**, before the surface reaches QA.
   A flagged coverage gap on a reachable branch is a scheduled incident.
6. **Red gate? Establish provenance before fixing (G18).** Does the flagged file
   exist on your branch? Does the gate fail on the base independently? An
   inherited failure is reported, not fixed.

## Progress

Append one line per step, so the run is visible without reading your pane:

```sh
echo "PROGRESS selfreview <what you are doing now>" >> "$PIPELINE_DIR/<ticket>/progress.log"
```

The dashboard renders the last line. A log that stops moving for five minutes
shows as quiet — which is the signal to check the agent, not the artifact.

## Exit gate

- Every runnable CI gate ran; unrunnable ones are named explicitly.
- A different actor reviewed the diff and its findings are resolved or routed.
- Every new test demonstrated failing against the old code.

## Out

`selfreview.md` — gates run, gates skipped and why, findings and their routing.
