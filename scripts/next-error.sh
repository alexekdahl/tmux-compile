#!/usr/bin/env bash

# Script to find and jump to the next error in the compile buffer
current_window=$(tmux display-message -p '#{window_id}')

# Find compile pane
compile_pane=$(tmux list-panes -t "$current_window" -F '#{pane_id} #{@compile-pane}' | grep 'compile' | awk '{print $1}')

if [ -z "$compile_pane" ]; then
    tmux display-message "No compile pane found"
    exit 0
fi

# Switch to compile pane and enter copy mode
tmux select-pane -t "$compile_pane"
tmux copy-mode -t "$compile_pane" 2>/dev/null || true

# Search for common error patterns
# This will highlight and move to the next occurrence
tmux send-keys -t "$compile_pane" "/" ":[0-9]\\+:" "Enter"
