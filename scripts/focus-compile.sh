#!/usr/bin/env bash

# Script to focus the compile pane and enter copy mode
current_window=$(tmux display-message -p '#{window_id}')

# Find compile pane
compile_pane=$(tmux list-panes -t "$current_window" -F '#{pane_id} #{@compile-pane}' | grep 'compile' | awk '{print $1}')

if [ -n "$compile_pane" ]; then
    tmux select-pane -t "$compile_pane"
    # Enter copy mode if not already in it
    tmux copy-mode -t "$compile_pane" 2>/dev/null || true
else
    tmux display-message "No compile pane found"
fi
