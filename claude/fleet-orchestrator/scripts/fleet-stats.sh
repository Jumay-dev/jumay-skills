#!/bin/zsh
# Harvest per-agent efficiency stats from herdr agent panes (codex TUI status line).
# Usage: fleet-stats.sh <pane_id> [pane_id ...]
# Output: TSV — pane, label, last_turn_duration, tokens_in, tokens_out, out_in_pct, context_left
PANES=("$@")
[ ${#PANES[@]} -eq 0 ] && { echo "usage: fleet-stats.sh <pane_id>..." >&2; exit 2; }

to_num() {
  awk -v v="$1" 'BEGIN{ m=1
    if (v ~ /M$/){m=1000000; sub(/M$/,"",v)}
    else if (v ~ /K$/){m=1000; sub(/K$/,"",v)}
    printf "%.0f", v*m }'
}

printf "pane\tlabel\tlast_turn\ttokens_in\ttokens_out\tout_in_pct\tcontext_left\n"
TOTAL_IN=0; TOTAL_OUT=0
for p in "${PANES[@]}"; do
  label=$(herdr pane get "$p" 2>/dev/null | jq -r '.result.pane.label // "-"')
  out=$(herdr pane read "$p" --lines 150 --source recent 2>/dev/null)
  stats=$(echo "$out" | grep -Eo '[0-9.]+[KM]? in · [0-9.]+[KM]? out' | tail -1)
  ctx=$(echo "$out" | grep -Eo 'Context [0-9]+% left' | tail -1 | grep -Eo '[0-9]+%')
  dur=$(echo "$out" | grep -Eo 'Worked for [0-9]+[hms][0-9ms ]*' | tail -1 | sed 's/Worked for //')
  if [ -z "$stats" ]; then
    printf "%s\t%s\t%s\tn/a\tn/a\tn/a\t%s\n" "$p" "$label" "${dur:-n/a}" "${ctx:-n/a}"
    continue
  fi
  in_raw=$(echo "$stats" | awk '{print $1}')
  out_raw=$(echo "$stats" | awk '{print $4}')
  in_n=$(to_num "$in_raw"); out_n=$(to_num "$out_raw")
  pct=$(awk -v i="$in_n" -v o="$out_n" 'BEGIN{ if (i>0) printf "%.2f%%", o/i*100; else print "n/a" }')
  TOTAL_IN=$((TOTAL_IN + in_n)); TOTAL_OUT=$((TOTAL_OUT + out_n))
  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "$p" "$label" "${dur:-n/a}" "$in_raw" "$out_raw" "$pct" "${ctx:-n/a}"
done
TOTAL_PCT=$(awk -v i="$TOTAL_IN" -v o="$TOTAL_OUT" 'BEGIN{ if (i>0) printf "%.2f%%", o/i*100; else print "n/a" }')
printf "TOTAL\t-\t-\t%s\t%s\t%s\t-\n" "$TOTAL_IN" "$TOTAL_OUT" "$TOTAL_PCT"
