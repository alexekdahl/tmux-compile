#!/usr/bin/env bash

# scripts/recompile.sh
#
# Re-run the most recent compile command stored in history.
# Useful for quickly iterating on builds without re-typing the command.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

history_file="$("$CURRENT_DIR/get-history-file.sh")"

# Retrieve the most recent command from history
last_cmd=$(tail -n 1 "$history_file" 2>/dev/null)

if [ -z "$last_cmd" ]; then
    tmux display-message "No previous compile command"
    exit 0
fi

# Execute the command using the main compile runner
"$CURRENT_DIR/run-compile.sh" "$last_cmd"

exit 0
