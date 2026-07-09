#!/bin/zsh
# Watch a fleet of herdr agent panes; exit when any pane needs attention.
# Usage: watch-fleet.sh <pane_id> [pane_id ...]
# Env: WATCH_TIMEOUT_S (default 7200), WATCH_INTERVAL_S (default 20)
PANES=("$@")
[ ${#PANES[@]} -eq 0 ] && { echo "no panes to watch"; exit 2; }

DEADLINE=$(( $(date +%s) + ${WATCH_TIMEOUT_S:-7200} ))
while [ "$(date +%s)" -lt "$DEADLINE" ]; do
  LIST=$(herdr agent list 2>/dev/null) || { echo "herdr unreachable"; exit 3; }
  ATTN=""
  for p in "${PANES[@]}"; do
    st=$(echo "$LIST" | jq -r --arg p "$p" '.result.agents[] | select(.pane_id==$p) | .agent_status')
    [ -z "$st" ] && st="gone"
    if [ "$st" != "working" ]; then
      ATTN="$ATTN$p=$st\n"
    fi
  done
  if [ -n "$ATTN" ]; then
    echo "ATTENTION NEEDED:"
    printf "$ATTN"
    exit 0
  fi
  sleep "${WATCH_INTERVAL_S:-20}"
done
echo "watch timeout with all agents still working"
exit 1
