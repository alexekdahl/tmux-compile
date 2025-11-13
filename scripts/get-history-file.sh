#!/usr/bin/env bash

# scripts/get-history-file.sh
#
# Returns the shared history file or session-aware history file path if enabled

set -euo pipefail

session_history_enabled="${TMUX_COMPILE_SESSION_HISTORY_ENABLED}"
base_history_file="${TMUX_COMPILE_HISTORY_FILE}"

if [ "$session_history_enabled" != "on" ]; then
    touch "$base_history_file"
    if [ -d "$base_history_file" ]; then
        tmux display-message "Path to history file is a dir"
        exit 0
    fi

    echo "$base_history_file"
    exit 0
fi

# Session aware history
base_history_dir="${TMUX_COMPILE_HISTORY_DIR}"
raw_session_name="$(tmux display-message -p '#S' 2>/dev/null || echo default)"
session_name="${raw_session_name//[^A-Za-z0-9._-]/}"
: "${session_name:=default}"

mkdir -p "$base_history_dir"

touch "$base_history_dir/$session_name"
if [ -f "$base_history_dir" ]; then
    tmux display-message "Path to base directory is a file"
    exit 0
fi
 
echo "$base_history_dir/$session_name"
