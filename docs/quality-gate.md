# Quality Gate — orchestrator verification invariants

Canonical checklist for any orchestrated fix/review cycle. Referenced by
`claude/jumay-dual-review`, `claude/jumay-figma-implement` (exit gates), and
executor/verifier briefs. Every rule below exists because the failure actually
happened; the origin incident is noted so the rule doesn't decay into cargo cult.

## G1 — Signing invariant
All commits GPG-signed per the author's global git config (`gpg.format openpgp`,
`commit.gpgsign true`, global `user.signingkey`).
- Agents must NEVER set local git signing config, switch signature formats, or
  commit unsigned when the signer is unavailable. On signing failure: STOP,
  leave work uncommitted, report `BLOCKED-SIGNING`.
- Orchestrator verifies `git log --format='%G?'` shows `G` on every new commit
  BEFORE accepting a task as complete or syncing branches upward. `N`/`E` plus
  ssh-verification errors means an agent bypassed the signer.
- Origin: an executor silently SSH-signed two commits via a local
  `user.signingkey` override when the hardware key was locked (kmono PR #321).

## G2 — Evidence invariant
PR evidence (screenshots/overlays) is never removed without same-task
regeneration at the current head.
- Any body edit that touches evidence must leave: the full evidence set, a
  capture-commit note equal to the pushed head, and a passing body validator.
- "Stale screenshot cleanup" is only valid as remove-AND-regenerate, never
  remove-only. Removal must be reported explicitly, not buried in one line.
- Origin: an executor stripped all 10 evidence images from a PR body during a
  review-response task and reported it as one clause (kmono PR #321).

## G3 — Diff-provenance rule
Before flagging deletions, scope creep, or "removed infrastructure" in a review:
check `git merge-base HEAD origin/<base>` and whether the flagged paths were
ADDED to the base after the merge-base. Upstream additions appear as deletions
in a stale-base diff.
- Origin: a review pass reported "this PR deletes REVIEW.md/greptile.json" when
  master had gained those files after the branch's last sync (kmono PR #322 review).

## G4 — Regression re-review
Every fix round gets a focused re-review of the exact lines it changed before
the cycle closes — fixes introduce regressions at the same rate as features.
The re-review may be a second engine (see jumay-dual-review) or a human pass,
but it must be someone/something that did not write the fix.
- Origin: a "make settings reactive" fix moved the read to hook render and
  introduced a stale-priority-fee-at-click regression, caught only by the human
  reviewer's follow-up pass (kmono PR #321, useLoanActions.ts).

## G5 — Marker protocol (agent completion)
- Completion markers MUST embed a variable artifact (commit sha, PR URL), e.g.
  `TASK COMPLETE <sha>` — never a bare constant string.
- Watchers grep with the variable resolved (`TASK COMPLETE [0-9a-f]{7,40}`),
  never the bare prefix: the dispatch prompt echo contains the bare string and
  false-positives the watcher.
- Sentinel words for failure states (e.g. `BLOCKED-SIGNING`) appear once in the
  dispatch prompt; watchers must require count > prompt-occurrences or match a
  line-anchored report form.
- Idle ≠ done: on watcher fire, verify the marker exists AND the claimed
  artifact exists on origin before treating the task as complete.
- Origin: two watcher false-positives in one day from prompt echoes (kmono
  FE-879 cycle).

## G6 — Pane protocol (herdr)
- Relocate panes BY LABEL immediately before every send; pane IDs renumber when
  any pane closes.
- After launching an agent CLI, verify the agent is detected and idle before
  dispatching (auto-update exits drop the pane to a shell; text then goes to
  the shell).
- Codex TUIs may need a second Enter when idle; confirm status flips to
  `working` (or token counters move) after every dispatch.
- Origin: watcher attached to a renumbered pane id reported a healthy agent as
  gone; codex auto-update swallowed a dispatch (same cycle).

## G7 — Verify-before-report
Agent self-reports are never accepted bare. Before closing any task the
orchestrator must independently confirm, with its own commands:
- claimed commits exist on origin (and satisfy G1),
- claimed fixes exist in code (grep/read at least the critical ones),
- claimed validation matches reality (spot-run at least typecheck),
- claimed PR-state changes are live (threads replied/resolved counts via API),
- claimed CI state matches `gh pr checks` on the exact head.
GitHub mergeability flags may be stale after squash-merges/retargets: a locally
clean `git merge-tree` + ancestor check overrides a CONFLICTING flag; poll or
nudge, don't churn the branch.

## G8 — Fix routing (stacked PRs)
Fixes land in the worktree/branch that OWNS the file per the PR-split
convention; cross-branch duplicate fixes require a reconciliation plan naming
which side is canonical BEFORE both sides land. Never sync upward while a lower
branch has unverified signatures (G1) or stripped evidence (G2).
- Origin: the same two bugs fixed independently on two stack levels forced a
  conflict-heavy reconciliation merge (kmono #321/#322).
