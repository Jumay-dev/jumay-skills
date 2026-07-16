# Changelog

## 2026-07-16 — jumay-figma-implement review-round hardening

- Literal-grep gate now RE-RUNS on every fix round's diff, not just the
  first gate. Motivation: a hardcoded scrim color (`bg-[#0b172b]`, invisible
  overlay in dark mode) was added in a later fix round and shipped past a
  gate that had already run.
- New Phase-4 gate: public-API contract pass (callbacks fire on every
  triggering path; no casts erasing required callback params; unsurprising
  trigger/children semantics). Motivation: `onClose` fired only from the
  close button, and a type cast hid a missing required Base UI event-details
  argument — both caught by a human reviewer, not the pipeline.
- New Phase-4 gate + Phase-3 dispatch line: primitive-library APIs before
  hand-rolled interaction machinery (focus/dismissal/positioning).
  Motivation: hand-rolled focus-modality tracking with a rAF blur() hack
  duplicated Base UI's `initialFocus(openType)` and carried a stale-ref bug.
- Human-reviewer etiquette in the review sweep: reply with fix + commit sha
  on each human thread, never resolve them for the reviewer; sweep gate for
  human rounds = 0 unresolved bot threads + replies posted + green checks.

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
