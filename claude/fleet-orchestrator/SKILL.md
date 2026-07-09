---
name: fleet-orchestrator
description: Orchestrate a fleet of terminal AI agents over a scope of tasks. Use when the user shares a set of tickets/tasks (a Linear project or filter, an issue list, or explicit task descriptions) and wants them executed in parallel by spawned agents — "orchestrate these", "run these tickets in parallel", "spawn agents for this scope", "one agent per task". Builds on the herdr-agents skill; runs the full loop: resolve scope, spawn, dispatch, monitor, independently verify, handle follow-ups, report.
---

# Fleet Orchestrator

Turn a scope of tasks into verified, reviewed pull requests by fanning the
tasks out to one terminal agent each (e.g. `codex --yolo` panes via herdr),
then monitoring, unblocking, and independently verifying the results.

You are the orchestrator: you never implement the tickets yourself, and you
never take an agent's word for the outcome.

## 1. Resolve the scope

- Accept scope in any form: a Linear/GitHub project or filter ("In Progress in
  project X"), a list of issue links, or plain task descriptions.
- Enumerate the concrete task list up front (fetch via the tracker's tools) and
  confirm the count. One task per agent; the mapping must be explicit.
- Pick the worker skill the agents will run (e.g. `$jumay-parity` for design
  parity tickets, `$jumay-oneshot` for generic tickets). Verify it exists in
  `~/.codex/skills/` before dispatching; tell the user if it does not.
- Parallel safety: agents sharing one repo must not collide. Verify the worker
  skill creates an isolated worktree per ticket (e.g. via `$jumay-worktree`);
  otherwise create one worktree per agent yourself and use it as the pane cwd.

## 2. Spawn the fleet

- Use the `herdr-agents` skill for all pane mechanics (split grid, label,
  start agents, send prompts). Never tmux.
- Grid size = task count; prefer roughly square layouts (6 → 2x3, 8 → 2x4).
- Label every pane with its ticket id before dispatch.
- Wait for each agent TUI to report `idle` before sending its prompt.

## 3. Dispatch

One self-contained prompt per agent, containing:

- the exact task link,
- the worker skill to use (`$<skill>` syntax for Codex),
- isolation instruction (fresh worktree from the refreshed base),
- done criteria (e.g. "one PR, visual gate >97", "checks green"),
- org context the worker skill leaves as placeholders: the GitHub `owner/repo`
  and, when a handoff is expected, the review channel/reviewers. Published
  skills are sanitized; the dispatch prompt is where real values enter.

Send with `pane send-text` + `send-keys Enter`, then confirm every agent
transitions to `working` before reporting dispatch complete.

## 4. Monitor event-driven, not chatty

- Run `scripts/watch-fleet.sh <pane_id>...` (from this skill's directory) as a
  background task. It polls `herdr agent list` and exits the moment any
  watched pane leaves `working` — the exit re-invokes you. Do not busy-poll in
  the foreground and do not sleep blindly.
- On wake: read the finished/blocked pane (`herdr pane read <id> --lines 40
  --source recent`), act, then re-arm the watcher on the panes still working.
- Blocked agent: read what it needs; answer via `send-text` + Enter if you can,
  escalate to the user only for decisions that are genuinely theirs.
- Idle agent claiming completion: verify (next section), then either accept or
  dispatch a follow-up to the same pane — warm agents retain context, so
  follow-ups cost minutes, not a fresh session.

## 5. Verify independently — never trust self-reports

Agents report optimistically. After each agent finishes, check its claims with
your own tool calls:

- PR exists and is green: `gh pr view/checks`.
- Review threads: query unresolved counts via the GraphQL `reviewThreads` API.
  Watch for the classic gap: agents treat "outdated" threads as closed, and
  review-bot threads that land after the agent's last sweep get missed.
- Whatever the worker skill's success gate demands (evidence files, scores,
  audits): spot-check at least the machine-checkable parts.

Any gap becomes a follow-up dispatch to the owning agent, not a silent fix by
you — the agent has the context and must own its PR.

## 6. Report and keep the fleet warm

- Report a task → pane → PR → status mapping; state what you verified vs what
  the agent claimed.
- Always include an efficiency table: run `scripts/fleet-stats.sh
  <pane_id>...` (from this skill's directory) BEFORE closing any pane. It
  parses each agent's TUI status line into per-agent duration, tokens in/out,
  out:in ratio, and context left, plus a fleet total. Present it to the user
  and read it yourself:
  - Out:in ratio is the efficiency signal — a low ratio (well under ~1%) means
    the agent spent most tokens re-reading (polling loops, repeated file
    reads, screenshot iterations) rather than producing work. Flag the worst
    pane and, when the pane log shows an obvious cause, name it.
  - Note outliers in duration and context-left as canary baselines for future
    skill changes; comparing these tables across runs is how a skill edit is
    judged (see the repo's canary workflow).
  - Stats live in the pane scrollback, so harvest them while panes are open —
    closing a pane destroys its numbers.
- Keep panes open after completion: review feedback usually arrives later, and
  follow-ups to warm agents are cheap. Close panes only when the user confirms
  the work is fully done.
- If asked to hand off for review (Slack etc.), confirm the message with the
  user before sending unless they already approved the format.

## Failure notes (learned the hard way)

- `chmod +x` the watcher before backgrounding it; launch via the harness's
  background mechanism, not shell `&` (the shell dies with the tool call).
- A pane id is not an agent until its TUI boots — wait for `idle` first.
- Do not dispatch follow-up work as `pane run`; running TUIs take
  `send-text` + `send-keys Enter`.
