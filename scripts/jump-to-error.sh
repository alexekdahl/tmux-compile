#!/usr/bin/env bash

# Get the current line in copy mode
current_pane=$(tmux display-message -p '#{pane_id}')
current_window=$(tmux display-message -p '#{window_id}')

# Get the line under cursor in copy mode
# We'll capture the buffer and parse it
line=$(tmux capture-pane -t "$current_pane" -p -J | tail -n +$(tmux display-message -p '#{copy_cursor_line}') | head -n 1)

# Parse common compiler error formats:
# - file.c:123:45: error message
# - file.go:123: error message
# - file.rs:123:45 - error message
# - /absolute/path/file.py:123: error
# - ./relative/path/file.c:123: error
# - Error in file.c at line 123

# Try to extract file:line or file:line:column patterns
if [[ "$line" =~ ([^[:space:]]+\.(c|cpp|h|hpp|rs|go|py|js|ts|java|sh|bash|zig|nim|lua|rb|php|swift|kt|cs|m|mm|scala|clj|erl|ex|exs|hs|ml|fs|v|sv|vhd|vhdl|tcl|r|pl|pm))[[:space:]]*:[[:space:]]*([0-9]+)([[:space:]]*:[[:space:]]*([0-9]+))? ]]; then
    file="${BASH_REMATCH[1]}"
    line_num="${BASH_REMATCH[3]}"
    col_num="${BASH_REMATCH[5]}"
elif [[ "$line" =~ ([^[:space:]]+):([0-9]+):([0-9]+) ]]; then
    # Generic file:line:col
    file="${BASH_REMATCH[1]}"
    line_num="${BASH_REMATCH[2]}"
    col_num="${BASH_REMATCH[3]}"
elif [[ "$line" =~ ([^[:space:]]+):([0-9]+) ]]; then
    # Generic file:line
    file="${BASH_REMATCH[1]}"
    line_num="${BASH_REMATCH[2]}"
    col_num=""
elif [[ "$line" =~ [Ee]rror\ in\ ([^[:space:]]+)\ at\ line\ ([0-9]+) ]]; then
    # "Error in file.c at line 123" format
    file="${BASH_REMATCH[1]}"
    line_num="${BASH_REMATCH[2]}"
    col_num=""
else
    tmux display-message "No file:line pattern found on this line"
    exit 0
fi

# Find the neovim pane (the one we were in before compile)
neovim_pane=$(tmux list-panes -t "$current_window" -F '#{pane_id} #{@neovim-pane}' | grep 'neovim' | awk '{print $1}')

if [ -z "$neovim_pane" ]; then
    # Fallback: use the first non-compile pane
    neovim_pane=$(tmux list-panes -t "$current_window" -F '#{pane_id} #{@compile-pane}' | grep -v 'compile' | head -n 1 | awk '{print $1}')
fi

if [ -z "$neovim_pane" ]; then
    tmux display-message "No Neovim pane found"
    exit 0
fi

# Get the working directory of the compile pane to resolve relative paths
compile_dir=$(tmux display-message -p -t "$current_pane" '#{pane_current_path}')

# Resolve the file path
if [[ "$file" = /* ]]; then
    # Absolute path
    full_path="$file"
else
    # Relative path - resolve from compile directory
    full_path="$compile_dir/$file"
fi

# Check if file exists
if [ ! -f "$full_path" ]; then
    tmux display-message "File not found: $full_path"
    exit 0
fi

# Switch to neovim pane
tmux select-pane -t "$neovim_pane"

# Send command to neovim to open the file at the line
if [ -n "$col_num" ]; then
    # With column number
    tmux send-keys -t "$neovim_pane" Escape
    tmux send-keys -t "$neovim_pane" ":e +call\\ cursor($line_num,$col_num)\\ $full_path" Enter
else
    # Just line number
    tmux send-keys -t "$neovim_pane" Escape
    tmux send-keys -t "$neovim_pane" ":e +$line_num $full_path" Enter
fi

# Center the line in view
tmux send-keys -t "$neovim_pane" "zz"
