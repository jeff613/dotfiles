#!/bin/sh
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
rl5h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl7d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# Shorten home directory to ~
home="$HOME"
short_cwd="${cwd/#$home/~}"

# Git branch (skip optional locks to avoid contention)
branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)

# ANSI colors
esc=$(printf '\033')
reset="${esc}[0m"
dim="${esc}[2m"

# color_pct VALUE GREEN_MAX RED_MIN: green < GREEN_MAX, red >= RED_MIN, else yellow
color_pct() {
  v=${1%.*}
  if [ "$v" -ge "$3" ]; then printf '%s' "${esc}[31m"
  elif [ "$v" -lt "$2" ]; then printf '%s' "${esc}[32m"
  else printf '%s' "${esc}[33m"; fi
}

# Build output
out="${esc}[34m${short_cwd}${reset}"
[ -n "$branch" ] && out="$out  ${esc}[35m${branch}${reset}"
[ -n "$model" ] && out="$out  ${esc}[36m${model}${reset}"
[ -n "$used" ] && out="$out  $(color_pct "$used" 40 80)ctx:$(printf '%.0f' "$used")%${reset}"
[ -n "$rl5h" ] && out="$out  $(color_pct "$rl5h" 50 80)5h:$(printf '%.0f' "$rl5h")%${reset}"
[ -n "$rl7d" ] && out="$out  $(color_pct "$rl7d" 50 80)7d:$(printf '%.0f' "$rl7d")%${reset}"
[ -n "$cost" ] && out="$out  ${dim}$(printf '$%.2f' "$cost")${reset}"

printf '%s' "$out"
