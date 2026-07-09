---
name: herdr-agents
description: Spawn and orchestrate AI coding agents (codex, claude, etc.) in herdr panes instead of tmux panes. Use when asked to spawn agents in panes, build a pane grid of agents, dispatch tasks to pane agents, or monitor/orchestrate multiple terminal agents. Requires the herdr CLI and a running herdr session — never fall back to tmux.
---

# Herdr Agents

Orchestrate multiple terminal AI agents (e.g. `codex --yolo`, `claude`) as panes
in the current herdr session. herdr is a terminal workspace manager with a
socket API — all control goes through the `herdr` CLI, **never tmux**.

## Preconditions

1. `herdr status` — server must be `running`.
2. You are inside a herdr pane when `HERDR_ENV=1`; your own pane id is
   `$HERDR_PANE_ID`. All splits are made relative to pane ids.
3. If not inside herdr, ask the user to launch `herdr` first.

## Core commands

```sh
# Panes
herdr pane list [--workspace <ws>]            # all panes with ids/labels
herdr pane split <pane_id> --direction right|down [--cwd PATH] [--no-focus]
                                              # prints the new pane id — capture it
herdr pane rename <pane_id> <label>           # label pane (use task id, e.g. TICKET-852)
herdr pane run <pane_id> '<command>'          # types command + Enter (start the agent)
herdr pane send-text <pane_id> '<text>'       # literal text, NO Enter (TUI prompts)
herdr pane send-keys <pane_id> Enter          # submit a TUI prompt
herdr pane read <pane_id> [--lines N] [--source visible|recent]   # inspect output
herdr pane close <pane_id>

# Agents (herdr auto-detects agent TUIs running in panes)
herdr agent list                              # detected agents + state
herdr agent send <target> '<text>'            # literal text to an agent pane
herdr agent wait <target> --status idle|working|blocked [--timeout MS]

# Blocking waits (polling loops are a smell — prefer these)
herdr wait output <pane_id> --match '<text>' [--regex] [--timeout MS]
herdr wait agent-status <pane_id> --status idle|working|blocked|done [--timeout MS]
```

## Spawning a grid of agents

To build an `C columns x R rows` grid to the right of your own pane:

1. Split your pane (`$HERDR_PANE_ID`) `--direction right` once per extra
   column, always splitting the most recently created column pane — this
   stacks columns to the right.
2. For each column pane, split it `--direction down` `R-1` times to create the
   rows (split the newest pane each time for even stacking).
3. Capture every printed pane id; `--no-focus` keeps your pane focused.
4. Pass `--cwd` on each split so the shell starts where the agent should run.
5. `herdr pane rename <id> <task-label>` each pane immediately — labels are how
   you and the user track which agent owns which task.

Example — 2x3 grid (2 columns, 3 rows = 6 panes) to the right:

```sh
ME=$HERDR_PANE_ID; CWD=/path/to/repo
C1=$(herdr pane split $ME --direction right --cwd $CWD --no-focus)
C2=$(herdr pane split $C1 --direction right --cwd $CWD --no-focus)
C1R2=$(herdr pane split $C1  --direction down --cwd $CWD --no-focus)
C1R3=$(herdr pane split $C1R2 --direction down --cwd $CWD --no-focus)
C2R2=$(herdr pane split $C2  --direction down --cwd $CWD --no-focus)
C2R3=$(herdr pane split $C2R2 --direction down --cwd $CWD --no-focus)
```

If `pane split` prints more than a bare id, extract the id (`p_NN`) from the
output. Verify the final layout with `herdr pane list`.

## Starting the agent CLI in each pane

```sh
herdr pane run <pane_id> 'codex --yolo'    # or: claude, codex, aider ...
```

Then wait for the TUI to be ready before dispatching (don't sleep blindly):

```sh
herdr wait agent-status <pane_id> --status idle --timeout 60000
```

## Dispatching tasks

Agent CLIs are TUIs — a prompt is typed text plus Enter, so use
`send-text` + `send-keys Enter`, **not** `pane run`:

```sh
herdr pane send-text <pane_id> 'Use the $jumay-parity skill to complete https://linear.app/... end to end.'
herdr pane send-keys <pane_id> Enter
```

Rules:
- One task per agent pane; the pane label must name the task.
- Keep dispatch prompts self-contained: task link, skill to use, done criteria.
- Multi-agent work in one repo must be isolated per agent (separate git
  worktrees / cwds) unless the agent's own workflow creates worktrees itself.

## Orchestrating / monitoring

- `herdr agent list` — one-glance state of the fleet (idle/working/blocked).
- `herdr wait agent-status <id> --status idle --timeout <ms>` — block until an
  agent finishes its turn, then `herdr pane read <id> --lines 40` to review.
- Agent blocked (waiting on approval/input)? Read the pane, answer via
  `send-text` + `send-keys Enter`, or escalate to the user.
- Re-dispatch follow-ups the same way; close panes with `herdr pane close`
  only when the user confirms the task is done.
