#!/usr/bin/env bash
input=$(cat)

# ANSI color codes
CYAN=$'\033[96m'
YELLOW=$'\033[93m'
GREEN=$'\033[92m'
GRAY=$'\033[90m'
RESET=$'\033[0m'

model=$(echo "$input" | jq -r '.model.display_name // ""')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
cwd=$(echo "$input" | jq -r '.cwd // ""')

# Git branch
branch=""
if [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
fi

# Progress bar (10 blocks wide)
bar_display=""
if [ -n "$used" ]; then
  filled=$(echo "$input" | jq -r '(.context_window.used_percentage / 10) | floor | if . > 10 then 10 elif . < 0 then 0 else . end')
  empty=$((10 - filled))
  pct=$(echo "$input" | jq -r '.context_window.used_percentage | round')

  filled_chars=""
  i=0
  while [ "$i" -lt "$filled" ]; do filled_chars="${filled_chars}█"; i=$((i+1)); done

  empty_chars=""
  i=0
  while [ "$i" -lt "$empty" ]; do empty_chars="${empty_chars}░"; i=$((i+1)); done

  bar_display="[${GREEN}${filled_chars}${GRAY}${empty_chars}${RESET}] ${pct}%"
fi

# Assemble status line
out=""
[ -n "$branch" ] && out="${CYAN} ${branch}${RESET}"
[ -n "$model" ]  && out="${out}  ${YELLOW}${model}${RESET}"
[ -n "$bar_display" ] && out="${out}  ctx:${bar_display}"

printf '%s\n' "$out"
