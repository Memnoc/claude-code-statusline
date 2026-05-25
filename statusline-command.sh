#!/bin/bash
# Claude Code statusLine — multi-theme, user-configurable

input=$(cat)

# --- Config ---
CONF="$HOME/.claude/statusline.conf"
THEME="dawn"
SIZE="full"
[ -f "$CONF" ] && . "$CONF"

# --- Themes ---
case "$THEME" in
  moon)
    C_FOAM='\033[38;5;116m'
    C_PINE='\033[38;5;31m'
    C_IRIS='\033[38;5;183m'
    C_MUTED='\033[38;5;60m'
    C_ROSE='\033[38;5;217m'
    C_LOVE='\033[38;5;168m'
    C_GOLD='\033[38;5;221m'
    ;;
  main)
    C_FOAM='\033[38;5;116m'
    C_PINE='\033[38;5;32m'
    C_IRIS='\033[38;5;147m'
    C_MUTED='\033[38;5;60m'
    C_ROSE='\033[38;5;217m'
    C_LOVE='\033[38;5;168m'
    C_GOLD='\033[38;5;221m'
    ;;
  dawn|*)
    C_FOAM='\033[38;5;66m'
    C_PINE='\033[38;5;24m'
    C_IRIS='\033[38;5;103m'
    C_MUTED='\033[38;5;102m'
    C_ROSE='\033[38;5;174m'
    C_LOVE='\033[38;5;132m'
    C_GOLD='\033[38;5;214m'
    ;;
esac
C_RESET='\033[0m'
C_BOLD='\033[1m'

case "$SIZE" in
  small) BAR_LEN=5 ;;
  *)     BAR_LEN=10 ;;
esac

COLS=$(tput cols 2>/dev/null || echo 120)
SEP=$(printf "${C_MUTED}|${C_RESET}")

join_segments() {
  local first=1 result=""
  for seg in "$@"; do
    [ -z "$seg" ] && continue
    if [ "$first" -eq 1 ]; then
      result="$seg"; first=0
    else
      result="${result} ${SEP} ${seg}"
    fi
  done
  printf '%s' "$result"
}

# --- Directory ---
seg_dir=""
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
if [ -n "$cwd" ]; then
  short_dir=$(echo "$cwd" | sed "s|$HOME|~|")
  count=$(echo "$short_dir" | tr -cd '/' | wc -c | tr -d ' ')
  if [ "$count" -gt 3 ]; then
    short_dir="…/$(echo "$short_dir" | rev | cut -d'/' -f1-3 | rev)"
  fi
  seg_dir=$(printf "${C_FOAM}${C_BOLD} %s${C_RESET}" "$short_dir")
fi

# --- Git ---
seg_git=""
if [ -n "$cwd" ] && git -C "$cwd" --no-optional-locks rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
           || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    seg_git=$(printf "${C_IRIS}  %s${C_RESET}" "$branch")
    modified=$(git -C "$cwd" --no-optional-locks diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    staged=$(git -C "$cwd" --no-optional-locks diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    untracked=$(git -C "$cwd" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    status_flags=""
    [ "$modified" -gt 0 ]  && status_flags="${status_flags}!"
    [ "$staged" -gt 0 ]    && status_flags="${status_flags}+"
    [ "$untracked" -gt 0 ] && status_flags="${status_flags}?"
    [ -n "$status_flags" ] && seg_git="${seg_git}$(printf " ${C_ROSE}%s${C_RESET}" "$status_flags")"
  fi
fi

# --- Model ---
seg_model=""
model=$(echo "$input" | jq -r '.model.display_name // empty')
[ -n "$model" ] && seg_model=$(printf "${C_PINE}%s${C_RESET}" "$model")

# --- Context window ---
seg_ctx=""
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used" ]; then
  used_int=$(printf '%.0f' "$used")
  if [ "$used_int" -lt 30 ]; then
    ctx_color="$C_FOAM"; ctx_emoji="🧠"
  elif [ "$used_int" -lt 60 ]; then
    ctx_color="$C_GOLD"; ctx_emoji="💭"
  elif [ "$used_int" -lt 80 ]; then
    ctx_color="$C_ROSE"; ctx_emoji="🔥"
  else
    ctx_color="$C_LOVE"; ctx_emoji="💀"
  fi
  filled=$(( used_int * BAR_LEN / 100 )); empty=$(( BAR_LEN - filled ))
  bar=""
  for ((i=0; i<filled; i++)); do bar="${bar}█"; done
  for ((i=0; i<empty;  i++)); do bar="${bar}░"; done
  seg_ctx=$(printf "%s ${ctx_color}%s %d%%${C_RESET}" "$ctx_emoji" "$bar" "$used_int")
fi

# --- Rate limit ---
seg_rate=""
rate=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
if [ -n "$rate" ]; then
  rate_int=$(printf '%.0f' "$rate")
  if [ "$rate_int" -lt 40 ]; then
    rate_color="$C_FOAM"; rate_emoji="⚡"
  elif [ "$rate_int" -lt 70 ]; then
    rate_color="$C_GOLD"; rate_emoji="🌡️"
  elif [ "$rate_int" -lt 90 ]; then
    rate_color="$C_ROSE"; rate_emoji="⚠️"
  else
    rate_color="$C_LOVE"; rate_emoji="🚫"
  fi
  filled=$(( rate_int * BAR_LEN / 100 )); empty=$(( BAR_LEN - filled ))
  bar=""
  for ((i=0; i<filled; i++)); do bar="${bar}█"; done
  for ((i=0; i<empty;  i++)); do bar="${bar}░"; done
  reset_str=""
  resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
  if [ -n "$resets_at" ] && [ "$resets_at" -gt 0 ] 2>/dev/null; then
    now_s=$(date +%s)
    remain_s=$((resets_at - now_s))
    if [ "$remain_s" -gt 0 ]; then
      rh=$((remain_s / 3600))
      rm=$(( (remain_s % 3600) / 60 ))
      if [ "$rh" -gt 0 ]; then
        reset_str=" ~${rh}h${rm}m"
      else
        reset_str=" ~${rm}m"
      fi
    fi
  fi
  seg_rate=$(printf "%s ${rate_color}%s %d%%%s${C_RESET}" "$rate_emoji" "$bar" "$rate_int" "$reset_str")
fi

# --- Caveman badge ---
seg_caveman=""
caveman_out=$(bash "/Users/matteostara/.claude/hooks/caveman-statusline.sh" 2>/dev/null)
[ -n "$caveman_out" ] && seg_caveman="$caveman_out"

# --- Session duration ---
seg_duration=""
SESSION_FILE=$(ls -t "$HOME/.claude/sessions/"*.json 2>/dev/null | head -1)
if [ -n "$SESSION_FILE" ]; then
  STARTED_AT=$(jq -r '.startedAt // empty' "$SESSION_FILE" 2>/dev/null)
  if [ -n "$STARTED_AT" ] && [ "$STARTED_AT" != "null" ] && [ "$STARTED_AT" -gt 0 ] 2>/dev/null; then
    NOW_S=$(date +%s)
    STARTED_S=$((STARTED_AT / 1000))
    ELAPSED_S=$((NOW_S - STARTED_S))
    if [ "$ELAPSED_S" -gt 0 ]; then
      HOURS=$((ELAPSED_S / 3600))
      MINS=$(( (ELAPSED_S % 3600) / 60 ))
      if [ "$HOURS" -gt 0 ]; then
        seg_duration=$(printf "${C_MUTED}⏱ %dh%02dm${C_RESET}" "$HOURS" "$MINS")
      else
        seg_duration=$(printf "${C_MUTED}⏱ %dm${C_RESET}" "$MINS")
      fi
    fi
  fi
fi

# --- Cache efficiency bar (lifetime, iris-colored) ---
seg_cache=""
STATS="$HOME/.claude/stats-cache.json"
if [ -f "$STATS" ]; then
  CACHE_READ=$(jq '[.modelUsage | to_entries[] | .value.cacheReadInputTokens // 0] | add // 0' "$STATS" 2>/dev/null)
  CACHE_CREATE=$(jq '[.modelUsage | to_entries[] | .value.cacheCreationInputTokens // 0] | add // 0' "$STATS" 2>/dev/null)
  INPUT_TOK=$(jq '[.modelUsage | to_entries[] | .value.inputTokens // 0] | add // 0' "$STATS" 2>/dev/null)
  CR=${CACHE_READ%.*}; CC=${CACHE_CREATE%.*}; IT=${INPUT_TOK%.*}
  TOTAL=$(( CR + CC + IT ))
  if [ "$TOTAL" -gt 0 ] && [ "$CR" -gt 0 ]; then
    CACHE_PCT=$(( CR * 100 / TOTAL ))
    filled=$(( CACHE_PCT * BAR_LEN / 100 )); empty=$(( BAR_LEN - filled ))
    bar=""
    for ((i=0; i<filled; i++)); do bar="${bar}█"; done
    for ((i=0; i<empty;  i++)); do bar="${bar}░"; done
    seg_cache=$(printf "💾 ${C_IRIS}%s %d%%${C_RESET}" "$bar" "$CACHE_PCT")
  fi
fi

# --- Session lines added/removed ---
seg_diff=""
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // empty')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // empty')
if [ -n "$lines_added" ] || [ -n "$lines_removed" ]; then
  [ -z "$lines_added" ] && lines_added=0
  [ -z "$lines_removed" ] && lines_removed=0
  la=$(printf '%.0f' "$lines_added")
  lr=$(printf '%.0f' "$lines_removed")
  if [ "$la" -gt 0 ] || [ "$lr" -gt 0 ]; then
    seg_diff=$(printf "${C_FOAM}+%d${C_RESET} ${C_ROSE}-%d${C_RESET}" "$la" "$lr")
  fi
fi

# --- Session cost ---
seg_cost=""
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
if [ -n "$cost" ]; then
  cost_cents=$(echo "$cost" | awk '{printf "%d", $1 * 100 + 0.5}')
  if [ "$cost_cents" -gt 0 ] 2>/dev/null; then
    seg_cost=$(printf "${C_GOLD}\$%.2f${C_RESET}" "$cost")
  fi
fi

# --- Segment layout by SIZE ---
case "$SIZE" in
  small)
    wide_segs=("$seg_dir" "$seg_git" "$seg_model" "$seg_ctx" "$seg_rate" "$seg_cache" "$seg_duration" "$seg_cost" "$seg_diff" "$seg_caveman")
    line1_segs=("$seg_dir" "$seg_git" "$seg_model")
    line2_segs=("$seg_ctx" "$seg_rate" "$seg_cache" "$seg_duration" "$seg_cost" "$seg_diff" "$seg_caveman")
    ;;
  minimal)
    wide_segs=("$seg_dir" "$seg_model" "$seg_ctx")
    line1_segs=("$seg_dir" "$seg_model" "$seg_ctx")
    line2_segs=()
    ;;
  full|*)
    wide_segs=("$seg_dir" "$seg_git" "$seg_model" "$seg_ctx" "$seg_rate" "$seg_cache" "$seg_duration" "$seg_cost" "$seg_diff" "$seg_caveman")
    line1_segs=("$seg_dir" "$seg_git" "$seg_model")
    line2_segs=("$seg_ctx" "$seg_rate" "$seg_cache" "$seg_duration" "$seg_cost" "$seg_diff" "$seg_caveman")
    ;;
esac

# --- Render ---
if [ "$COLS" -ge 100 ]; then
  join_segments "${wide_segs[@]}"
elif [ "$COLS" -ge 50 ]; then
  line1=$(join_segments "${line1_segs[@]}")
  line2=$(join_segments "${line2_segs[@]}")
  if [ -n "$line2" ]; then
    printf '%s\n%s' "$line1" "$line2"
  else
    printf '%s' "$line1"
  fi
else
  line1=$(join_segments "${line1_segs[@]}")
  line2=$(join_segments "${line2_segs[@]}")
  out="$line1"
  [ -n "$line2" ] && out="${out}
${line2}"
  printf '%s' "$out"
fi
