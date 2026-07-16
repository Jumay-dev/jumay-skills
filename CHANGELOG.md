# Changelog

## 2026-07-16 — jumay-figma-implement

- Added `claude/jumay-figma-implement` (PR #2): five-phase Figma-to-PR
  pipeline (investigate → interview → execute → verify → close) with
  orchestrator-side exit gates at every phase. Distilled from a full
  production run (spec → interview → implementation → six verify/fix
  rounds → merge-ready PR).
- Hardening baked in from that run's failures: in-context usage walk +
  visual-claim provenance (packaging churn: content → popover → modal);
  container-semantics and interaction-story interview questions;
  protective-default recommendation bias for consent controls;
  computed-CSS and compensated-drift verification gates (matching outer
  dims hid a wrong-gap chain; malformed utility variants no-op silently);
  dispatch-landed / idle-vs-done / agent-alive pane mechanics.
- Rule: prefer appending commits over amend + force-push during review
  loops; squash at merge if the repo wants one commit.

## 2026-07-09 — jumay-parity efficiency optimizations

- Applied the three skill-side optimization candidates from the initial
  import (see PR #1 for the canary plan):
  - Blocking waits over polling: `gh pr checks --watch` for CI, >=60s
    field-scoped rechecks for review agents, new Efficiency Rules section.
  - Post-final-CI thread closeout, machine-verified via a GraphQL
    unresolved-thread count; `isOutdated` explicitly does not mean resolved.
  - Evidence reuse: one Figma node export per ticket, component-scoped
    screenshots from the first iteration, changed-stories-only re-captures.
- Not applied here: pre-warm worktree setup — that is an orchestrator-side
  concern (fleet-orchestrator), not a parity-skill rule.
- Baseline to beat (six-ticket run, pre-optimization): 82.8M tokens in,
  274.9K out, 0.33% ratio, 23-56 min per ticket, visual gates >=97.

## 2026-07-09 — fleet-orchestrator

- Added `claude/fleet-orchestrator`: the orchestrator-side playbook distilled
  from a real six-agent run — scope resolution, herdr grid spawn, dispatch,
  event-driven monitoring (bundled `watch-fleet.sh`), independent verification
  of agent claims (PR checks, unresolved review-thread counts), and warm-agent
  follow-up dispatch.

## 2026-07-09 — initial import

- Imported the working skill set as the version-control baseline, renamed
  the company-prefixed originals → `jumay-*`, and removed company-specific values (org/repo names,
  ticket prefixes, Slack channel and user IDs, reviewer names, machine-local
  paths) in favor of documented placeholders.
- `validate-pr-body.js`: the `owner/repo` argument is now required instead of
  defaulting to a hardcoded repository.
- Known optimization candidates (measured across six parallel runs, not yet
  applied):
  - Replace CI/review polling with blocking waits (`gh pr checks --watch`);
    polling dominated the 11–19M input tokens per run.
  - Move review-thread closeout to a post-final-CI gate verified by an
    unresolved-thread count query; agents treated "outdated" threads as closed
    and late review-bot threads were missed.
  - Capture component-cropped screenshots from the first visual iteration.
  - Pre-warm worktree setup (install/build caches) before fanning out a fleet.

## 2026-07-09 — fleet efficiency stats

- fleet-orchestrator: added `scripts/fleet-stats.sh` and a mandatory
  end-of-run efficiency report — per-agent duration, tokens in/out, out:in
  ratio, and context left, harvested from agent TUI status lines before any
  pane closes. Ratio is the polling-waste signal; tables double as canary
  baselines for judging skill changes.
