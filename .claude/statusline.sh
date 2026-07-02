#!/usr/bin/env bash
input=$(cat)

# ANSI color codes
CYAN=$'\033[96m'
YELLOW=$'\033[93m'
GREEN=$'\033[92m'
GRAY=$'\033[90m'
RESET=$'\033[0m'

# Parse JSON using PowerShell (no jq required)
parsed=$(printf '%s' "$input" | powershell.exe -NoProfile -NonInteractive -Command "
  \$json = [Console]::In.ReadToEnd()
  \$data = \$json | ConvertFrom-Json
  \"\$(\$data.model.display_name)\"
  \"\$(\$data.context_window.used_percentage)\"
  \"\$(\$data.cwd)\"
" 2>/dev/null | tr -d '\r')

model=$(printf '%s\n' "$parsed" | sed -n '1p')
used=$(printf '%s\n' "$parsed" | sed -n '2p')
cwd=$(printf '%s\n' "$parsed" | sed -n '3p')

# Git branch
branch=""
if [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
fi

# Progress bar (10 blocks wide)
bar_display=""
if [ -n "$used" ]; then
  filled=$(awk "BEGIN {n=int(${used}/10); if(n>10) n=10; if(n<0) n=0; print n}")
  empty=$((10 - filled))
  pct=$(awk "BEGIN {printf \"%.0f\", ${used}}")

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
