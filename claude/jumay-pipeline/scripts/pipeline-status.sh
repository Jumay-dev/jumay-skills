#!/bin/zsh
# Live pipeline dashboard: one row per ticket, seven stages, what each agent is doing.
#
# Usage:  pipeline-status.sh [ticket ...]      # default: every ticket in PIPELINE_DIR
#         pipeline-status.sh --once            # render one frame and exit (for CI/logs)
#
# Env:    PIPELINE_DIR (default ~/.pipeline)   INTERVAL_S (default 1)
#
# Reads three sources, none of which it has to ask an agent for:
#   1. PIPELINE_DIR/<ticket>/progress.log  — "PROGRESS <stage> <message>" lines (authoritative)
#   2. PIPELINE_DIR/<ticket>/*.md          — stage artifacts (fallback when no log yet)
#   3. herdr agent list                    — pane liveness, matched by pane label

emulate -L zsh
setopt no_nomatch

PIPELINE_DIR="${PIPELINE_DIR:-$HOME/.pipeline}"
INTERVAL_S="${INTERVAL_S:-1}"
ONCE=0
TICKETS=()
for a in "$@"; do
  case "$a" in
    --once) ONCE=1 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) TICKETS+=("$a") ;;
  esac
done

STAGES=(investigation specification implementation selfreview commit pr review-response)
GLYPHS=(1 2 3 4 5 6 7)
ARTIFACTS=(findings.md spec.md change-log.md selfreview.md '' '' '')   # proof a stage finished
FRAMES=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
QUIET_S=300

C_DIM=$'\e[2m'; C_OK=$'\e[32m'; C_ACT=$'\e[36m'; C_WARN=$'\e[33m'; C_OFF=$'\e[0m'; C_B=$'\e[1m'

stage_index() {           # stage name or number -> 1..7, else 0
  local s="${1:l}" i
  if [[ "$s" == <-> ]] && (( s >= 1 && s <= 7 )); then print -- "$s"; return; fi
  for i in {1..7}; do [[ "${STAGES[$i]}" == "$s"* ]] && { print -- "$i"; return }; done
  print -- 0
}

herdr_snapshot() {
  command -v herdr >/dev/null 2>&1 || return
  command -v jq >/dev/null 2>&1 || return
  herdr agent list 2>/dev/null | jq -r '
    .result.agents[]? | [.pane_id, (.label // "-"), .agent_status] | @tsv' 2>/dev/null
}

render() {                # $1 spinner frame, $2 herdr snapshot -> body on stdout, no trailing newline
  local frame="$1" snap="$2" out="" t dir line i cur curmsg age strip color pane lbl st
  local -a found lines
  local width=$(( ${COLUMNS:-100} - 6 ))

  if (( ${#TICKETS} )); then
    found=("${TICKETS[@]}")
  else
    found=(); for dir in "$PIPELINE_DIR"/*(N/); do found+=("${dir:t}"); done
  fi

  out="${C_B}pipeline${C_OFF} ${C_DIM}${PIPELINE_DIR}${C_OFF}"
  if (( ${#found} == 0 )); then
    print -rn -- "${out}"$'\n'"  ${C_DIM}no runs — create ${PIPELINE_DIR}/<ticket>/ to start one${C_OFF}"
    return
  fi

  for t in "${found[@]}"; do
    dir="$PIPELINE_DIR/$t"
    cur=0; curmsg=""; age=-1
    if [[ -s "$dir/progress.log" ]]; then
      line=$(tail -n 1 "$dir/progress.log")
      if [[ "$line" == PROGRESS\ * ]]; then
        cur=$(stage_index "${${(z)line}[2]}")
        curmsg="${line#PROGRESS * }"
      fi
      age=$(( $(date +%s) - $(stat -f %m "$dir/progress.log" 2>/dev/null || print 0) ))
    fi
    if (( cur == 0 )); then                       # no usable log — infer from artifacts
      for i in {1..7}; do
        [[ -n "${ARTIFACTS[$i]}" && -f "$dir/${ARTIFACTS[$i]}" ]] && cur=$(( i + 1 ))
      done
      (( cur < 1 )) && cur=1
      (( cur > 7 )) && cur=7
    fi

    strip=""
    for i in {1..7}; do
      if   (( i <  cur )); then strip+="${C_OK}${GLYPHS[$i]}${C_OFF}"
      elif (( i == cur )); then strip+="${C_ACT}${C_B}${frame}${GLYPHS[$i]}${C_OFF}"
      else                      strip+="${C_DIM}${GLYPHS[$i]}${C_OFF}"; fi
      (( i < 7 )) && strip+=" "
    done

    out+=$'\n'$'\n'"  ${C_B}${t}${C_OFF}  ${strip}  ${C_DIM}${STAGES[$cur]}${C_OFF}"
    if [[ -n "$curmsg" ]]; then
      (( ${#curmsg} > width )) && curmsg="${curmsg[1,$width]}…"
      out+=$'\n'"    ${curmsg}"
      (( age > QUIET_S )) && out+=" ${C_WARN}(quiet ${age}s)${C_OFF}"
    fi

    if [[ -n "$snap" ]]; then                      # here-string, NOT a pipe: a pipe subshells the appends away
      while IFS=$'\t' read -r pane lbl st; do
        [[ -n "$pane" && "$lbl" == *"$t"* ]] || continue
        color="$C_DIM"; [[ "$st" == working ]] && color="$C_ACT"
        out+=$'\n'"    ${C_DIM}${pane}${C_OFF} ${lbl} ${color}${st}${C_OFF}"
      done <<< "$snap"
    fi
  done
  print -rn -- "$out"
}

if (( ONCE )); then
  render "•" "$(herdr_snapshot)"
  print
  exit 0
fi

typeset -i DONE=0
cleanup() { (( DONE )) && return; DONE=1; trap - INT TERM EXIT; printf '\e[?25h\n'; exit 0 }
printf '\e[?25l'
trap cleanup INT TERM EXIT

typeset -i i=0 tick=0 prev_lines=0 k n
snap="$(herdr_snapshot)"
while :; do
  (( tick % 20 == 0 )) && snap="$(herdr_snapshot)"      # herdr is the costly call — poll it slower
  body="$(render "${FRAMES[$(( i % 10 + 1 ))]}" "$snap")"
  lines=("${(@f)body}")                                  # (@f) keeps empty lines; (f) silently drops them
  n=${#lines}

  (( prev_lines > 0 )) && printf '\e[%dA' "$prev_lines"
  # erase each line BEFORE writing it; erasing after would leave a shorter frame's tail behind
  for k in {1..$n}; do printf '\e[2K%s\n' "${lines[$k]}"; done
  if (( prev_lines > n )); then                          # previous frame was taller — wipe the remainder
    for k in {1..$(( prev_lines - n ))}; do printf '\e[2K\n'; done
    printf '\e[%dA' $(( prev_lines - n ))
  fi
  prev_lines=$n

  i+=1; tick+=1
  sleep "$INTERVAL_S"
done
