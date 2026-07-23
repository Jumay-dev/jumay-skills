---
name: jumay-dual-review
description: Dual-engine code review — runs a Claude review and a Codex review in PARALLEL over the same diff/PR, verifies findings against the quality gate, merges with cross-model confidence, and routes fixes per the stacked-PR conventions. Use when the user asks to "dual review", "review with both engines", or wants a pre-merge review of a branch/PR with independent cross-model coverage.
---

# Jumay Dual Review

One invocation → two independent reviews running concurrently (Claude subagent +
Codex CLI), then an orchestrator verification-and-merge pass. The orchestrator
never forwards raw findings: every surviving finding is verified per
`docs/quality-gate.md` (the repo this skill ships in) before it reaches the user.

## Inputs
- A target: PR number/URL, or a branch/worktree (default: current worktree's
  branch vs its PR base; fall back to origin/master).
- Optional focus areas ("security", "money paths", "tests").

## Phase 0 — Resolve target & context
1. Resolve the worktree that owns the branch (stacked-PR convention: fixes land
   where the file's owning PR lives — see quality-gate G8). Never review a dirty
   worktree without noting uncommitted state.
2. `git fetch origin <base>`; record `merge-base HEAD origin/<base>` — needed
   for quality-gate G3 (stale-base deletions).
3. Collect review context: repo rule docs (e.g. `docs/rules/*.md`, root
   `REVIEW.md`), the PR body/intent, and prior review threads (do not re-flag
   what's already tracked). Load `docs/quality-gate.md` from this skills repo.

## Phase 1 — Launch BOTH engines in parallel (one message)
Launch these concurrently; neither sees the other's output (independence is the
point). Cap each at the diff scope; name submodules as out of bounds.

**Claude engine** — Agent tool, fresh-context subagent:
- Prompt: full diff command, repo rules list, the quality-gate G-rules as review
  lenses (esp. G3 provenance and money-path units), adversarial framing ("find
  how this fails in production; no compliments"), JSON-line findings with
  `{severity, confidence 1-10, path, line, category, summary, fix, engine:"claude"}`.
- For large diffs (>3000 lines) split by area (features/api vs ui vs shared)
  into 2-3 parallel subagents instead of one.

**Codex engine** — Bash, `codex exec` (NOT `codex review` — its CLI contract
drifts across versions; exec with an explicit prompt is stable):
- `codex exec "<adversarial review prompt; ignore ~/.claude, ~/.agents,
  .claude/skills, agents/, submodules>" -s read-only -c 'model_reasoning_effort="medium"'`
  with the Bash tool timeout at 300000.
- Large-diff rule (learned: a 7.7k-line diff times out at 5 min): scope the
  prompt to the highest-risk areas first (money paths, new modules) or run two
  sequential scoped passes; on timeout, report the partial scope honestly —
  never present a timed-out pass as full coverage.
- If codex is unavailable or times out twice: proceed Claude-only and say so.

## Phase 2 — Orchestrator verification pass (never skip)
For each finding from either engine, before it may be reported:
- G3 check for any deletion/scope-creep claim (merge-base provenance).
- Read the cited code yourself for every CRITICAL; downgrade or kill findings
  that misread guards, reactivity, or units (a "nothing re-renders" claim may
  really be "re-renders within ~5s" — report the true window).
- Check overlap with: prior review threads, fixes already landed lower/higher
  in the stack (a finding can be true on this head and already fixed on a
  neighboring branch — resolution is a sync, not a code fix).
- Confidence calibration: verified-in-code 8-10; plausible-unverified ≤6;
  suppress <4 unless severity would be critical.

## Phase 3 — Merge & report
- Dedup by file:line/category. Cross-model agreement: keep the higher-confidence
  copy, +1 confidence, tag `[BOTH ENGINES]`.
- Report: criticals (each with my verification verdict), high-value P2s,
  batched informational, then a **routing plan** per quality-gate G8 — which
  worktree/executor owns each fix, what's answer-only, what needs a user
  decision. Do NOT auto-fix product code from this skill; fixes go to the
  owning executor with the standing constraints (signing G1, evidence G2,
  marker G5).
- Persist: if the gstack review log exists, append a summary entry so /ship
  sees a review ran.

## Phase 4 — Post-fix regression loop (quality-gate G4)
When fixes come back, re-run a SCOPED dual pass over only the changed lines of
the fix commits (cheap: both engines get the fix diff, the original findings,
and "find what the fixes broke"). A fix round without a regression pass is not
closed — this skill exists because a reactive-settings 'fix' shipped a
click-time staleness regression that only a second reviewer caught.

## Constraints
- Submodules are never staged, modified, or reviewed as in-scope.
- This skill reviews and routes; it does not commit, push, or resolve human
  review threads.
- All quality-gate rules (G1-G8) bind every downstream dispatch this skill
  produces.
