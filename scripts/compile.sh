#!/usr/bin/env bash

# scripts/compile.sh
#
# Prompt for a compile command and execute it.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

height="${TMUX_COMPILE_HEIGHT:-30%}"
history_file="${TMUX_COMPILE_HISTORY:-$HOME/.tmux-compile-history}"

# Ensure history exists
touch "$history_file"

# Get last command
last_cmd=$(tail -n 1 "$history_file" 2>/dev/null || echo "")

# Prompt user
tmux command-prompt -I "$last_cmd" -p "Compile command:" \
    "run-shell \"$CURRENT_DIR/run-compile.sh '%%'\""

exit 0
