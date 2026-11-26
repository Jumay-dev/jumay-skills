---
name: herdr-agents
description: Launch, brief, and monitor Codex agents in Herdr panes. Use when the user requests pane-based delegation, a pane grid, or a follow-up in an existing Herdr agent session. Requires Herdr 0.7 or newer.
---

# Herdr Agents for Codex

## Locate the session

- Run `herdr status` to confirm the server is running and the client and server are compatible. Herdr 0.7 introduced `agent start`, `agent prompt`, and `agent wait`.
- Use `$HERDR_PANE_ID` or `herdr pane current` from inside Herdr. If the caller is outside Herdr, use an explicitly designated anchor pane and confirm it with `herdr pane list`. If no anchor can be identified, report the blocker. Keep the work in Herdr.
- `pane` commands take pane IDs. `agent` commands take agent names. Parse pane IDs from JSON without assuming their format. Give the agent and pane the same unique task label and resolve the label again before pane commands if panes may have closed.

## Launch one agent per task

Resolve the task worktree before splitting. For parallel tasks, launch each in its own worktree. Use a short, unique label matching `[a-z][a-z0-9_-]{0,31}` and check `herdr agent list` for collisions. Start additional panes from an identified anchor. Use `--no-focus` to keep the user's focus and set `--cwd` on each split.

```sh
# Set anchor, worktree, worker, model, and effort for this run.
pane_reply=$(herdr pane split "$anchor" --direction right --cwd "$worktree" --no-focus) &&
  worker_pane=$(printf '%s\n' "$pane_reply" | jq -er '.result.pane.pane_id') &&
  herdr pane rename "$worker_pane" "$worker" &&
  herdr agent start "$worker" --kind codex --pane "$worker_pane" --timeout 30000 -- \
    --cd "$worktree" --sandbox workspace-write --ask-for-approval on-request \
    --model "$model" -c "model_reasoning_effort=$effort"
```

Run the start only after the split and label succeed. A freshly split shell can return `agent_pane_busy` before its prompt is ready. Retry that error briefly on the same pane. For other errors, inspect the pane. If the agent appears blocked on approval, read the prompt and use the normal approval path for the action. Keep the worker within the caller's authorized scope.

## Dispatch and monitor

1. Write multi-step briefs to an absolute path the agent can read. Include the task, worktree, scope, expected deliverables, and a unique result path per round. Keep artifacts outside the source diff. For a result path outside the worktree and standard writable scratch space, grant only the scoped directory if authorized.
2. Send the brief with `herdr agent prompt "$worker" "$brief" --wait --until working --timeout 30000`. This submits the multiline text. Verify intake with `herdr agent read "$worker" --source recent --lines 40`. Look for an acknowledgment of this round or visible task-specific work. A state change or token counter alone is ambiguous. If startup swallowed the prompt, resend only after confirming the worker is ready and the round never started. When delivery is unclear, check the result path and worktree before retrying.
3. Wait in bounded intervals. Use `herdr agent list`, `herdr agent wait "$worker" --until idle --timeout 30000`, and `herdr agent explain "$worker"` to diagnose state. Verify the round's result artifact against the actual diff and checks. An idle pane, an echoed sentinel, or a result file by itself cannot prove completion.
4. For follow-ups, use the same agent once its current turn has settled and assign a fresh result path. Use `herdr pane send-keys <pane-id> esc` only when interrupting that worker is necessary. Re-resolve the pane by label first. Leave the pane available for follow-up unless closure was requested.
