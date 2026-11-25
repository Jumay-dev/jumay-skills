---
name: jumay-investigate-implement
description: Investigate and specify a coding task with Astra medium, delegate implementation to Sol medium in a Herdr pane, then independently review and self-test the result. Use for requests to investigate and implement a task with this model split and pane handoff.
---

# Investigate and Implement

## Run the orchestrator on Astra

The orchestrator uses `gpt-6.2-astra` with `medium` reasoning for investigation, specification, review, and self-testing. In Codex CLI, launch the orchestrator with `codex --model gpt-6.2-astra -c model_reasoning_effort=medium`. In Codex App, verify the model and effort in the session controls. If the current session is on different settings and cannot switch, continue from an Astra-medium session before investigating. Naming a model in a prompt does not change the active session.

Load `$herdr-agents` from the installed skills or the [sibling skill](../herdr-agents/SKILL.md). Verify the Herdr server and anchor pane early. Use `$jumay-worktree` for a new ticket and `$jumay-implementation-guardrails` before editing. For follow-ups to existing work, verify the intended worktree, branch, base, and pre-existing changes before dispatch.

## Investigate and specify

1. Read the request or ticket and repo instructions, including applicable `AGENTS.md` and `CLAUDE.md`. Trace the current behavior through the actual entry point and its runtime dependencies. Inspect nearby implementations and tests for repository conventions.
2. Write `spec.md` to a per-task scratch directory outside the source diff. Include the observed behavior and supporting paths, the expected behavior, scope and non-goals, implementation pointers, and acceptance criteria. Give each user-facing criterion a reproducible running-app path, setup and data requirements, expected visible results, and planned evidence. Include relevant asynchronous and alternate states when the change affects them. Record repo commands for applicable automated checks.
3. Confirm the spec resolves the requested outcome, including which existing behavior must still work. Carry routine assumptions forward in the spec and resolve material ambiguity before dispatch.

## Delegate to Sol and wait

Use `$herdr-agents` to open a new pane in the task worktree. Start its Codex session with `gpt-6.2-sol` and `medium` reasoning. Brief it with the absolute spec and worktree paths, the baseline, the repo instructions, any edits to preserve, and a fresh round result path in the scratch directory. Ask it to verify repo conventions, implement the spec, run targeted checks, and record changed paths, commands and outcomes, evidence paths, and blockers. Keep commits, pushes, PR creation, and other external actions within the user's explicit authorization.

Confirm intake and wait for the implementation report. The orchestrator owns review and verification. Keep implementation changes with the Sol worker so its work and the independent review stay identifiable.

## Review, self-test, and request changes

1. Inspect the actual change against the baseline and `spec.md`. Check the complete path behind each changed behavior and independently run relevant repository checks. Verify the worker's evidence against the current worktree.
2. Exercise every affected user-facing criterion yourself in the running app, even when the worker already captured evidence. Record the revision and working-tree state, environment, steps, expected and observed results, and artifact paths when useful. For behavior without a user-facing flow, verify the affected entry point using the repo's applicable checks.
3. Send confirmed findings back to the same Sol pane with reproduction steps, expected behavior, and a new round result path. Wait, inspect the revised diff, and rerun affected checks and app flows. If a required check is blocked, record the exact blocker and leave the result pending until it can be verified.
4. Finish when the review findings are resolved and the acceptance checks pass. Report the worktree, changes, and evidence. If the user also requested a PR, open it only after this gate passes.
