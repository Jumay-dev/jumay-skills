# ③ Implementation

Build exactly what `spec.md` says, in an isolated worktree.

## Load

| | Skill | When |
|---|---|---|
| always | `$jumay-worktree` | every task starts in a fresh tree |
| always | `$jumay-implementation-guardrails` | load **before** editing, not after |
| if | `$jumay-parity` | design-parity ticket — it owns the whole parity workflow |
| if | `/jumay-figma-implement` | Figma feature via the five-phase agent pipeline |
| if | `$jumay-oneshot` | generic ticket→PR, no design surface |
| if | `/herdr-agents` + `/fleet-orchestrator` | more than one ticket in flight |
| if | `docs/quality-gate.md` G8 | stacked PR — fixes land in the branch that owns the file |

## Entry

`spec.md` + `findings.md` **File map**. Not the investigation transcript.

## Do

1. **`git fetch origin master` FIRST**, then base off the freshly fetched
   `origin/master` — never a stale local `master`, which resurrects a
   squash-merged parent's commits as conflicts and makes ④ read them as
   deletions (G3/G8). Stacked work bases off the explicit parent, added with
   `gh stack add`.
2. **Preserve the existing data-flow shape** unless the spec requires changing
   it. A large structural rewrite on an integration ticket is a smell.
3. **Implement narrowly.** Follow repo `AGENTS.md`/`CLAUDE.md`. Nothing outside
   the spec's AC; nothing the Non-goals excluded.
4. **Capture the evidence the spec pre-declared** while the environment is live.
   Recapturing at ⑥ is how evidence ends up stale or missing (G2).
5. **Verify command outcomes by exit code**, not by reading output optimistically.

## Parallel safety

One ticket per worktree, one agent per ticket. Never two agents on one ticket.
Fanning out: check port collisions before spawning — N Storybooks all want 6006.

## Progress

Append one line per step, so the run is visible without reading your pane:

```sh
echo "PROGRESS implementation <what you are doing now>" >> "$PIPELINE_DIR/<ticket>/progress.log"
```

The dashboard renders the last line. A log that stops moving for five minutes
shows as quiet — which is the signal to check the agent, not the artifact.

## Exit gate

- Every AC in `spec.md` has a corresponding change you can point to.
- Nothing staged from submodules or artifact directories.
- Typecheck passes locally (the full gate list is ④'s job, not a reason to skip
  the cheap one here).

## Out

The diff, `change-log.md` (what changed and why, per AC), evidence files.
