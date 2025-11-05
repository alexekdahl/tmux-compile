#!/usr/bin/env bash

current_window=$(tmux display-message -p '#{window_id}')

# Find compile pane
compile_pane=$(tmux list-panes -t "$current_window" -F '#{pane_id} #{@compile-pane}' | grep 'compile' | awk '{print $1}')

if [ -n "$compile_pane" ]; then
    tmux kill-pane -t "$compile_pane"
else
    tmux display-message "No compile pane found"
fi
