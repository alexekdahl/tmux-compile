#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get configuration
height="${TMUX_COMPILE_HEIGHT:-30%}"
history_file="${TMUX_COMPILE_HISTORY:-$HOME/.tmux-compile-history}"

# Ensure history file exists
touch "$history_file"

# Create a temporary file for the command prompt
tmp_file=$(mktemp)

# Get the last command from history
last_cmd=$(tail -n 1 "$history_file" 2>/dev/null || echo "")

# Show command prompt with history
tmux command-prompt -I "$last_cmd" -p "Compile command:" \
    "run-shell \"$CURRENT_DIR/run-compile.sh '%1'\""
