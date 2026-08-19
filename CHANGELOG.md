# Changelog

## 2026-08-19 — jumay-review-reply: replies a human can scan

- New `claude/jumay-review-reply`: the *shape* of a PR review-thread reply.
  Six verdict lines (`Fixed in <sha>` / `Fixed in <sha>, differently` /
  `Not fixing` / `Deferred → <ticket>` / `Answered` / `Your call`), a hard
  3-line budget for everything but a disagreement, and an explicit cut list.
- Written from measured data, not taste: agent replies on open kmono PRs ran a
  median of 541–1138 chars and up to 1479, 11–15 lines each. PR #554 carried 49
  threads at that length — ~500 lines of prose between the reviewer and "did you
  fix it". The cut list is drawn item by item from those replies: gratitude
  openers, the reviewer's own diagnosis read back to them, investigation replay,
  self-justification, prose test enumerations, diff-restating code blocks,
  adjacent concerns buried in the last paragraph.
- Deliberately narrow, because two skills already cover the neighbours:
  `jumay-quality-gate` §Phase 7 enumerates threads and reconciles counts,
  `jumay-parity` §Review-Response owns comply/push-back/self-resolve policy.
  This one owns only the text, and cites both rather than restating them.
- Pipeline gains stage ⑦ Review response (`stages/7-review-response.md`) — the
  only stage that runs backwards: triage into verdicts, route code work back to
  ③ (fixes are not exempt from ④, per G4), reply only after the sha is on
  origin, never self-resolve.

## 2026-08-19 — jumay-pipeline: stage entrypoints for the development flow

- New `claude/jumay-pipeline`: an entrypoint per stage of the six-stage flow
  (investigation ⇄ specification → implementation → selfreview → commit → PR).
  Each `stages/<n>-<stage>.md` declares the skills that stage loads — `always`
  vs `if <condition>` — so a stage pulls in its own skills instead of the whole
  workflow's. You read one stage file at a time; that is the point.
- `SKILL.md` carries the stage/skill map as a table: the visual control surface
  for which skills fire where, plus a carry-forward table saying what context
  each stage inherits (spec.md is the only artifact that runs the whole way).
- No behavior change to existing skills — this composes what already exists.
  Quality-gate rules are cited by number, never restated: G19 anchors
  specification (never offer a safe/unsafe choice), G16/G17/G13/G18 anchor
  selfreview, G1/G8 anchor commit, G2 anchors PR evidence.
- Encodes the actor split G4 depends on: the executor's self-review and the
  different-actor review are both in stage ④ and explicitly not interchangeable.
- Stage ⑤ is marked host-only — a containerized commit cannot reach the signing
  key, and G1 forbids working around that.

## 2026-07-29 — jumay-quality-gate: the close-out gate

- New `claude/jumay-quality-gate`: takes work an executor claims is finished and
  proves or disproves each claim with the orchestrator's OWN commands, then
  returns PASS/BLOCKED plus a routed fix list. It verifies; it never fixes.
- Turns `docs/quality-gate.md` from review lenses into executable checks: G1
  signatures (`%G?` on every added commit, no local signing overrides), claimed
  shas actually pushed (`merge-base --is-ancestor`, not just existing locally),
  G2 evidence intact at the current head, G7 claims-vs-reality (fixes really in
  code, typecheck spot-run by exit code, unresolved review threads from the
  GraphQL API, CI on the exact head), G3 provenance on deletion claims, G13
  flagged coverage gaps closed.
- Deliberately NOT an implement skill: it composes with figma-implement,
  fleet-orchestrator, oneshot, or hand-written work. The G4 regression pass
  delegates to jumay-herdr-review (multi-target) or jumay-dual-review (single),
  so the fix diff is always reviewed by something that did not write it.
- All commands verified against live data before shipping: the reviewThreads
  query counted 63 threads on kmono #321 and correctly separated
  outdated-but-unresolved, which is the case agents habitually miss.
- A wrapper (`jumay-implement-with-review` = implement skill → this gate → fix
  loop until PASS) is planned as a thin layer on top; the gate holds the logic.

## 2026-07-29 — jumay-herdr-review: multi-target reviewer panels

- New `claude/jumay-herdr-review`: one Claude+Codex pane pair per target, all
  pairs reviewing at once (N targets never queue through one pair). Each pane
  then rules AGREE/DISAGREE on the findings the other caught but it missed, so
  cross-model disagreement gets a real second-model verdict instead of only the
  orchestrator's read.
- Review-skill split, documented on both sides: `jumay-dual-review` is the
  single-target, no-herdr path; `jumay-herdr-review` is multi-target panes you
  can dig into afterward. Both bind `docs/quality-gate.md` rather than
  restating rules.
- The gate is wired into the panel, not bolted on: G3 merge-base preflight runs
  BEFORE dispatch and ships in the brief (otherwise every pane re-reports
  stale-base deletions), G9–G15 ride as explicit review lenses, and the report
  ends in a G8 routing plan plus a G4 regression pass. Orchestrator
  verification (G7) sits between the panes' findings and the user — pane
  self-reports are never forwarded raw.
- Deliverables are idempotent tmp+mv overwrites, never appends: that is what
  makes the `dispatch` retry safe, and an append is readable half-finished the
  moment its first line lands.

## 2026-07-29 — herdr 0.7 migration: pane skills rewritten, dispatch hardened

- herdr 0.6.8 → 0.7.5 removed the top-level `herdr wait` command and dropped
  `agent send`, breaking `herdr-agents` and `jumay-figma-implement`. All pane
  skills now target 0.7.x: `pane wait-output`, `agent wait --until`,
  `agent prompt`, `agent start --kind --pane`, and `pane split --ratio`.
- `herdr-agents` rewritten with a version gate (>= 0.7.0), a corrected command
  reference, and the canonical `start_agent` / `dispatch` / `await_file`
  helpers the other skills were already citing but which never existed.
- **Dispatch success ≠ delivery** (new G6 rule, found by live smoke test): an
  agent still booting (MCP servers, auth) silently swallows a prompt while
  `agent prompt --wait --until working` returns rc=0 — observed with the
  composer empty at `0 in · 0 out`. Intake must be confirmed via the
  input-token counter, then completion gated on the deliverable file. The 0.7
  API moved this silent-drop failure from Enter-handling to readiness; it did
  not remove it.
- `agent start` immediately after `pane split` returns `agent_pane_busy` — the
  new pane has no shell prompt yet. `start_agent` retries only that error.
- Pane id FORMAT changed (`w<ws>-N` → `w<ws>:p<N>`): parse ids from JSON, never
  grep a shape. Legacy `p_NN` in `$HERDR_PANE_ID` still resolves.
- Obsolete: the codex second-Enter dance. NOT obsolete: verifying the agent is
  alive, and confirming every dispatch landed.

## 2026-07-17 — jumay-figma-implement: trust-but-verify session lessons

- Marker ≠ work: completion markers need orchestrator-verifiable
  proof-of-work; mtimes are gameable, content is the only unfakeable
  evidence; gate monitors on deliverables existing, not pane idleness.
  Motivation: a compacted agent printed "COMPLETE 99/100" over hour-old
  artifacts, then "normalized" mtimes to satisfy the freshness check.
- Every multi-step order goes to a file ("Read <file> and execute it") —
  pasted instructions die in compaction; a dropped pasted order caused the
  fake-marker incident.
- Publish steps never chain behind gating commands: pipes eat exit codes
  (`git commit | tail` let a failed commit post a wrong-sha reply twice);
  pipefail + verify-then-publish + no HEAD interpolation before the commit
  is confirmed. GPG warms must themselves be verified.
- Reviewer suggestions get the same verification as any change — a wrong
  "redundant class" nit regressed segment layout two rounds later.
- New Phase 4.5: optional fresh-eyes review by a zero-context agent with
  a11y-name and next-consumer lenses (found a HIGH and an API blocker that
  every context-loaded participant missed). Phase-4 gate adds
  getByRole("dialog", { name }) assertion.
- Port identity check before captures/QA (another worktree's Storybook
  silently took over the port); portal-hosted parity targets playbook entry
  (element-scoped capture, blur the programmatic defaultOpen focus).

## 2026-07-16 — jumay-figma-implement: lockfile, gate, and capture lessons

- Worktree submodule rule: initialize submodules in fresh worktrees before
  any dependency change — empty submodule dirs make the package manager
  silently prune their lockfile importers (observed: 29k-line rewrite).
- Exit-code gates: verify command outcomes by exit code, never by grepping
  (possibly colored) output — two real false-green gates came from ANSI
  codes breaking the grep pattern and from empty-grep-reads-as-green.
- Failure playbook: mid-animation capture signature (edge-heavy doubling,
  clean center) — await subtree animations + document.fonts.ready before
  capture, or gate reduced-motion on navigator.webdriver.

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

## 2026-07-16 — jumay-parity PR-body quality gate

- PR body gate now requires: a compact list of intentional design
  deviations (decision/reason each), `## Summary` as plain-English prose,
  and `## Validation` as 4-6 short bullets naming what was validated —
  never command dumps.
- Machine-generated process proof (token/CSS-variable audit tables,
  focus-ring evidence, capture diagnostics, command output) moves to the
  ledger artifacts under `.omx/artifacts/`, not the PR body. Motivation:
  reviewers were skipping bloated auto-generated bodies; the human-readable
  format came out of a six-fix-round session where the deviations list was
  what reviewers actually asked about.


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
