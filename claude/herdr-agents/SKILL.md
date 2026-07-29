---
name: herdr-agents
description: Spawn and orchestrate AI coding agents (codex, claude, etc.) in herdr panes instead of tmux panes. Use when asked to spawn agents in panes, build a pane grid of agents, dispatch tasks to pane agents, or monitor/orchestrate multiple terminal agents. Requires the herdr CLI (>= 0.7.0) and a running herdr session — never fall back to tmux.
---

# Herdr Agents

Orchestrate multiple terminal AI agents (`claude`, `codex`, …) as panes in the
current herdr session. herdr is a terminal workspace manager with a socket API —
all control goes through the `herdr` CLI, **never tmux**.

**Requires herdr >= 0.7.0** (protocol 17). `agent start`, `agent prompt`, and
`pane wait-output` do not exist before it, and the top-level `herdr wait` command
was REMOVED in 0.7 — see [Migration](#migration-from-06x) if you hit a transcript
or skill that still uses it.

## Preconditions

1. `herdr status` — server must be `running`; check `version` is >= 0.7.0.
2. You are inside a herdr pane when `HERDR_ENV=1`; your own pane id is
   `$HERDR_PANE_ID`.
3. If not inside herdr, ask the user to launch `herdr` first. Never fall back
   to tmux.

```sh
[ "$HERDR_ENV" = 1 ] || { echo "not in a herdr session"; exit 1; }
herdr status | awk '/^client:/{c=1} c&&/version:/{print $2; exit}'
```

## Pane ids

**The pane id format changes between herdr versions** — `w<ws>-<N>` in 0.6.x,
`w<ws>:p<N>` in 0.7.5 (e.g. `w655af1c9425d91:p4`). Never hardcode or grep for a
shape: always parse ids out of JSON. `$HERDR_PANE_ID` may hold a legacy `p_NN`
form; it still resolves, so pass it through untouched rather than "fixing" it.

**`herdr pane …` takes a pane id, never an agent name** (that's `pane_not_found`).
Only `herdr agent …` resolves names, labels, and terminal ids. Keep a
name→pane map whenever you use both families.

**Pane ids renumber when any pane closes.** Relocate by label via `pane list`
immediately before any send if panes may have closed since you captured ids.

## Command reference (0.7.5)

```sh
# Panes
herdr pane list [--workspace <ws>]                  # JSON: .result.panes[]
herdr pane current                                  # your own pane
herdr pane split <pane_id> --direction right|down [--ratio <FLOAT>] \
                 [--cwd PATH] [--env K=V] [--no-focus]
                                                    # JSON: .result.pane.pane_id
herdr pane rename <pane_id> <label>
herdr pane read <pane_id> [--lines N] [--source visible|recent|recent-unwrapped]
herdr pane wait-output <pane_id> --match <TEXT>|--regex <PAT> [--timeout MS]
herdr pane send-text <pane_id> <text>               # literal text, NO Enter
herdr pane send-keys <pane_id> <key>...             # `esc` is canonical
herdr pane run <pane_id> <command>...               # command + Enter (shells only)
herdr pane close <pane_id>

# Agents (herdr auto-detects agent TUIs running in panes)
herdr agent list                                    # detected agents + state
herdr agent start <name> --kind <kind> --pane <id> [--timeout MS] [-- <argv>...]
herdr agent prompt <target> <text> [--wait] [--until <status>] [--timeout MS]
herdr agent read <target> [--lines N] [--source visible|recent|detection]
herdr agent wait <target> [--until idle|working|blocked|done|unknown] [--timeout MS]
herdr agent explain <target>                        # why detection is in this state
herdr agent rename <target> <name>
```

`--kind` accepts: `pi, claude, codex, gemini, cursor, devin, agy, cline, omp,
mastracode, opencode, copilot, kimi, kiro, droid, amp, grok, hermes, kilo,
qodercli, maki`.

## Spawning a grid of agents

`pane split` prints **JSON** — parse `.result.pane.pane_id` with `jq`. Never
grep for a fixed id pattern; formats vary by version and a wrong grep silently
returns empty.

`--ratio` is the fraction **kept by the pane you split**, so cutting N equal
columns off your own pane means ratios `1/(N+1), 1/N, … 1/2`.

```sh
sp(){ herdr pane split "$1" --direction "$2" --ratio "$3" --cwd "$4" --no-focus \
        | jq -r '.result.pane.pane_id'; }
inv(){ awk "BEGIN{printf \"%.4f\", 1/$1}"; }

ME=$HERDR_PANE_ID; CWD=/path/to/repo; N=3          # N columns beside you
COLS=("$(sp "$ME" right "$(inv $((N+1)))" "$CWD")")
for ((c=N; c>1; c--)); do COLS+=("$(sp "${COLS[-1]}" right "$(inv $c)" "$CWD")"); done
```

Split from **your own** pane so the grid stays visible to the user. Pass `--cwd`
on every split so the shell starts where the agent should run, and `--no-focus`
to keep your pane focused. Verify the layout with `herdr pane list`.

## Starting the agent CLI in each pane

`agent start` **blocks until the agent is detected and ready for input**, and
names the agent in one call — no polling, no `agent rename`, and no
"is it actually alive?" dance. It fails loudly if the pane is not at an
interactive shell prompt or the expected agent never appears.

**A freshly split pane is not yet a shell.** `agent start` fired immediately
after `pane split` returns `agent_pane_busy` ("not an available shell") — the
shell has not reached its prompt. Retry that one error; anything else is real.

```sh
# start_agent <name> <kind> <pane_id> [-- <argv>...]
start_agent() {
  local name=$1 kind=$2 pane=$3; shift 3
  local attempt out
  for attempt in 1 2 3 4 5; do
    out=$(herdr agent start "$name" --kind "$kind" --pane "$pane" "$@" 2>&1) && {
      printf 'started %s\n' "$name"; return 0; }
    case "$out" in
      *agent_pane_busy*) sleep 3; continue ;;
      *) printf 'START-FAIL %s %s\n' "$name" "$out" >&2; return 1 ;;
    esac
  done
  printf 'START-BUSY %s: pane never reached a shell prompt\n' "$name" >&2; return 2
}

start_agent review-852 codex "$P" -- -m gpt-5.6-sol -c model_reasoning_effort=xhigh
herdr pane rename "$P" review-852
```

Name it and label the pane identically. Agent names must match
`[a-z][a-z0-9_-]{0,31}` and be unique among live agents — check `agent list`
for collisions from a concurrent run.

Permission bypass is environmental, not a flag you pass: Claude's comes from the
user's `claude` shell alias, Codex's from `~/.codex/config.toml`.

## Dispatching tasks

Use `agent prompt` — it submits text **and** Enter through the agent facade,
honors bracketed paste (so multi-line briefs are safe), and with `--wait` fails
loudly instead of dropping a paste silently.

```sh
herdr agent prompt review-852 "$BRIEF" --wait --until working --timeout 30000
```

`--wait` first requires an observed state change within 5000ms, else it returns
**`agent_prompt_stalled`**. Keep `--timeout` well above 5000 — a shorter one
returns `timeout` instead and you lose the distinction.

### `agent prompt` success does NOT prove delivery

**An agent that reports ready can still be booting** (loading MCP servers,
auth), and a prompt sent into that window is **silently swallowed** — while
`--wait --until working` still returns rc=0. Observed directly: `agent start`
returned `interactive_ready: true, agent_status: idle`, the dispatch returned
success, and the composer sat empty at `0 in · 0 out` with the brief nowhere.

The only proof of intake is the **input-token counter moving** in the TUI status
line (`… · 90.2K in · 389 out · …`). Verify it, and re-send when it hasn't moved.

### The canonical `dispatch`

Retries the stalled case and the swallowed case; any other error needs eyes.

```sh
# Input-token counter from the TUI status line.
tokens_in() {
  herdr agent read "$1" --source visible --lines 4 2>/dev/null \
    | grep -oE '[0-9.]+[KM]? in' | tail -1
}

# dispatch <agent-name> <brief> [timeout_ms]
# SAFE TO RETRY ONLY when the brief's deliverable is an idempotent tmp+mv
# overwrite — a retry can deliver the brief twice. Never use with appends.
dispatch() {
  local target=$1 brief=$2 timeout=${3:-30000} attempt before after out rc
  for attempt in 1 2 3; do
    before=$(tokens_in "$target")
    out=$(herdr agent prompt "$target" "$brief" \
            --wait --until working --timeout "$timeout" 2>&1); rc=$?
    if [ $rc -ne 0 ]; then
      case "$out" in
        *agent_prompt_stalled*) sleep 2; continue ;;
        *) printf 'DISPATCH-FAIL %s rc=%s %s\n' "$target" "$rc" "$out" >&2; return 1 ;;
      esac
    fi
    sleep 8                                    # let the counter render
    after=$(tokens_in "$target")
    [ -n "$after" ] && [ "$after" != "$before" ] && {
      printf 'dispatched %s (%s -> %s)\n' "$target" "${before:-none}" "$after"; return 0; }
    printf 'no intake on %s (attempt %s, counter %s) — resending\n' \
      "$target" "$attempt" "${after:-none}" >&2
    sleep 5
  done
  printf 'DISPATCH-NO-INTAKE %s after 3 attempts\n' "$target" >&2; return 2
}
```

### Fan out in parallel, then reap failures

`dispatch` blocks per pane. A sequential foreground loop leaves later agents
unbriefed for minutes, and an interrupt silently drops every send after the
cursor. Background all of them, then reap:

```sh
FAIL=$REV/dispatch.fail; : > "$FAIL"
for i in "${!NAMES[@]}"; do
  ( dispatch "${NAMES[$i]}" "${BRIEFS[$i]}" || echo "${NAMES[$i]}" >> "$FAIL" ) &
done
wait
[ -s "$FAIL" ] && { echo "UNBRIEFED — do not gate on these:"; cat "$FAIL"; }
```

Rules:
- One task per agent pane; the pane label must name the task.
- Keep briefs self-contained: task link, skill to use, done criteria. Multi-step
  orders go to a **scratchpad file** ("Read <file> and execute it") — files
  survive the agent compacting its context, pasted instructions don't.
- Multi-agent work in one repo must be isolated per agent (separate worktrees
  or cwds) unless the worker skill creates worktrees itself.

## Monitoring — the deliverable is the only completion signal

**Gate on the artifact, never on pane idleness.**

- **Idle ≠ done.** Agents die mid-turn on API errors (ECONNRESET) and sit idle
  with no output. On idle, check for the marker; if absent, read the pane tail
  and resume with "continue" (session context survives).
- **Marker ≠ work.** A compacted agent can print a completion marker without
  doing the task. Markers and mtimes are hints; CONTENT is the only unfakeable
  evidence.
- **`pane wait-output --match` matches the echoed prompt.** The sentinel string
  is in the brief you just dispatched, so it is already on screen — the match
  fires instantly and false-positives. Make markers embed a variable artifact
  (`TASK COMPLETE <sha>`) and match with `--regex 'TASK COMPLETE [0-9a-f]{7,40}'`,
  or skip output-matching entirely and poll the file.
- `agent prompt --wait` **does not track turns**: if the agent was already
  working, that older turn's completion can satisfy the wait. It is delivery
  confirmation, not completion.

```sh
# await_file <path> [timeout_s] — run in BACKGROUND, never a foreground poll
await_file() {
  local f=$1 deadline=$(( SECONDS + ${2:-1800} ))
  until [ -f "$f" ]; do
    [ $SECONDS -ge $deadline ] && { echo "TIMEOUT $f" >&2; return 1; }
    sleep 10
  done
}
```

Other monitoring:
- `herdr agent list` — one-glance state of the fleet.
- `herdr agent wait <target> --until idle --timeout <ms>` — blocks until the
  agent settles. Between-turn blips can fire it; debounce (require idle to hold
  across two checks) when you use it as a completion proxy.
- `herdr agent explain <target>` — why detection is stuck, when a pane looks
  wrong.
- Blocked agent? `herdr agent read <target> --lines 40`, then answer via
  `agent prompt`, or escalate to the user for decisions that are genuinely
  theirs.

### Interrupting a working agent

A running agent will **not** self-interrupt — queued messages are only consumed
when the current turn ends, so an edit queued behind a CI wait starves. Interrupt
with `herdr pane send-keys <pane_id> esc` (canonical name is lowercase `esc`;
`escape` is also accepted), then re-dispatch a consolidated batch. Re-state
standing constraints in the new brief — the interrupted turn's context may be
stale and long-running agents compact.

- Close panes with `herdr pane close` only when the user confirms the task is
  done. Warm agents retain context, so follow-ups cost minutes, not a session.

## Migration from 0.6.x

| 0.6.x | 0.7+ |
|---|---|
| `herdr wait output <id> --match` | `herdr pane wait-output <id> --match` |
| `herdr wait agent-status <id> --status <s>` | `herdr agent wait <id> --until <s>` |
| `herdr agent send <t> <text>` | `herdr agent prompt <t> <text>` (submits, incl. Enter) |
| `herdr pane run <id> 'codex --yolo'` + wait for idle | `herdr agent start <name> --kind codex --pane <id>` |
| `send-text` + `send-keys Enter` to dispatch | `herdr agent prompt … --wait` |
| `--status` flag | `--until` flag |

One 0.6-era gotcha is now **obsolete**: *"codex needs a second Enter"* —
`agent prompt` submits atomically.

Two are **NOT** obsolete, despite the friendlier API:
- *"Verify the agent is alive"* — `agent start` proves the agent was detected,
  but the pane can still drop to a shell later (an agent CLI auto-updating and
  exiting). A start failure means no agent; never dispatch into that pane.
- *"Confirm the dispatch actually landed"* — still mandatory, and now the
  trap is worse: `agent prompt --wait` reports success on a swallowed prompt.
  Gate on the token counter, then on the deliverable.
