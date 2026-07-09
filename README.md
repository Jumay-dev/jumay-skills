# jumay-skills

Agent skills for running UI design-parity and ticket-to-PR workflows with
terminal AI agents (Codex CLI, Claude Code), plus a herdr-based multi-agent
orchestration skill.

These skills encode a complete, evidence-gated workflow: isolated git worktree
per ticket, Figma-vs-Storybook visual parity with a >97 gate, screenshot
evidence tables in PR bodies, review-bot feedback loops, and Slack handoffs.
Battle-tested by running six parallel agents on real design-parity tickets,
each landing a green PR in 25–55 minutes.

## Layout

| Path | Skill | Purpose |
| --- | --- | --- |
| `codex/jumay-parity` | `$jumay-parity` | Design-parity ticket end to end: Figma evidence, visual gate, PR, review loop |
| `codex/jumay-worktree` | `$jumay-worktree` | Fresh isolated git worktree per ticket (safe parallel agents) |
| `codex/jumay-oneshot` | `$jumay-oneshot` | Generic ticket-to-PR workflow with guardrails |
| `codex/jumay-implementation-guardrails` | `$jumay-implementation-guardrails` | Code-quality guardrails (React Query boundaries, narrow types, design-level review fixes) |
| `codex/jumay-review-message` | `$jumay-review-message` | Terse Slack review-request format |
| `claude/herdr-agents` | `/herdr-agents` | Spawn and orchestrate agent fleets in [herdr](https://herdr.dev) panes |
| `claude/fleet-orchestrator` | `/fleet-orchestrator` | Full orchestration loop: scope of tasks in, one agent per task, monitored and independently verified PRs out |

## Install

Codex CLI — copy or symlink each skill directory into `~/.codex/skills/`:

```sh
ln -s "$(pwd)/codex/jumay-parity" ~/.codex/skills/jumay-parity
```

Claude Code — same idea into `~/.claude/skills/`:

```sh
ln -s "$(pwd)/claude/herdr-agents" ~/.claude/skills/herdr-agents
```

## Configure

The skills are published with placeholders; set them for your org:

- `OWNER/REPO` — your GitHub repository (jumay-parity, validate-pr-body.js).
- `<@REVIEWER_1_ID>` / `<@REVIEWER_2_ID>` — Slack user IDs of your default
  reviewers (jumay-parity, jumay-review-message).
- Review channel name — your team's FE review channel.
- `TICKET-` examples assume a Linear-style ticket prefix; any tracker works.

## Changing a skill safely (canary workflow)

These skills steer long autonomous runs, so treat edits like code changes:

1. Branch, make one focused change, and note the motivation in `CHANGELOG.md`.
2. Canary: dispatch **one** agent on one real ticket with the modified skill
   while the rest of the fleet stays on the last known-good commit.
3. Compare against your baselines: wall-clock, input tokens, visual-gate score,
   and whether any success gate was skipped.
4. Merge on parity-or-better; revert on regression. Never big-bang the fleet.

Have runs record the skill commit hash (e.g. in the evidence manifest) so every
PR is traceable to the skill version that produced it.

## Why so prescriptive?

Most rules in `jumay-parity` exist because an agent once cut that corner:
optimistic visual scores without inspecting pixels, evidence links instead of
uploaded screenshots, review threads left unresolved because they looked
"outdated". Read `CHANGELOG.md` before deleting a rule that looks redundant —
it probably isn't.
