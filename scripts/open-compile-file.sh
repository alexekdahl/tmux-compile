#!/usr/bin/env bash
set -euo pipefail

# This helper is invoked from copy-mode (see compile-mode.tmux) when the user
# presses Enter.  It attempts to emulate the default behaviour of copying the
# current selection while also parsing compiler error lines.  If the current
# pane is a compile pane (marked with the `@compile-pane` tmux option) and
# the selection looks like a file:line[:col] location, the script will open
# that file at the specified line in the nearest pane that is not the
# compile pane.  Neovim must be running in that target pane.  Outside of
# compile panes, this script falls back to the default copy behaviour.

current_pane=$(tmux display-message -p '#{pane_id}')
current_window=$(tmux display-message -p '#{window_id}')
is_compile=$(tmux display-message -p -t "$current_pane" '#{@compile-pane}')

# Outside compile pane → keep Enter behaving like "copy + exit"
if [ "$is_compile" != "compile" ]; then
  tmux send -X copy-selection-and-cancel 2>/dev/null || true
  exit 0
fi

# Must be in copy-mode and have a valid copy-mode cursor
cursor_y=$(tmux display-message -p -t "$current_pane" '#{?pane_in_mode,#{copy_cursor_y},}')
if [ -z "$cursor_y" ]; then
  tmux send -X cancel 2>/dev/null || true
  exit 0
fi
scroll_pos=$(tmux display-message -p -t "$current_pane" '#{scroll_position}')
cursor_y=$((cursor_y - scroll_pos))

# Capture the single line under the copy-mode cursor
line_text=$(tmux capture-pane -p -J -t "$current_pane" -S "$cursor_y" -E "$cursor_y" 2>/dev/null || echo "")
line_text=$(echo "$line_text" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

# Match various compiler formats:
#   --> path:line:col   (Rust)
#   path:line:col       (Go/TypeScript)
#   path:line           (Go/TypeScript)
#   path(line, col)     (Nim)
#   path(line)          (Nim)
if [[ "$line_text" =~ ^[[:space:]]*--\>[[:space:]]*([[:alnum:]_./-]+):([0-9]+):([0-9]+) ]]; then
  # Rust: --> src/main.rs:514:3
  file="${BASH_REMATCH[1]}"
  line="${BASH_REMATCH[2]}"
  col="${BASH_REMATCH[3]}"
elif [[ "$line_text" =~ ^([[:alnum:]_./-]+):([0-9]+):([0-9]+) ]]; then
  # Common: src/file.ts:12:3
  file="${BASH_REMATCH[1]}"
  line="${BASH_REMATCH[2]}"
  col="${BASH_REMATCH[3]}"
elif [[ "$line_text" =~ ^([[:alnum:]_./-]+):([0-9]+)$ ]]; then
  # Common: src/file.ts:12
  file="${BASH_REMATCH[1]}"
  line="${BASH_REMATCH[2]}"
elif [[ "$line_text" =~ ^([[:alnum:]_./-]+)\(([0-9]+),[[:space:]]*([0-9]+)\) ]]; then
  # Nim: /path/to/file.nim(47, 1)
  file="${BASH_REMATCH[1]}"
  line="${BASH_REMATCH[2]}"
  col="${BASH_REMATCH[3]}"
elif [[ "$line_text" =~ ^([[:alnum:]_./-]+)\(([0-9]+)\) ]]; then
  # Nim: /path/to/file.nim(47)
  file="${BASH_REMATCH[1]}"
  line="${BASH_REMATCH[2]}"
fi

# Leave copy-mode; if nothing parsed, do nothing further
tmux send -X cancel 2>/dev/null || true
[ -z "$file" ] && exit 0

# Resolve to absolute path
compile_path=$(tmux display-message -p -t "$current_pane" '#{pane_current_path}')
[[ "$file" != /* ]] && full_path="$compile_path/$file" || full_path="$file"
full_path=$(readlink -f "$full_path" 2>/dev/null || echo "$full_path")
[ ! -f "$full_path" ] && exit 0

# First non-compile pane in this window
target_pane=$(tmux list-panes -t "$current_window" -F '#{pane_id} #{@compile-pane}' \
               | awk '$2!="compile"{print $1; exit}')
[ -z "$target_pane" ] && exit 0

# **Only act if Neovim is running in the target pane**
target_cmd=$(tmux display-message -p -t "$target_pane" '#{pane_current_command}')
if [ "$target_cmd" != "nvim" ]; then
  exit 0
fi

# Drive Neovim
tmux send-keys -t "$target_pane" Escape
if [ -n "$line" ]; then
  tmux send-keys -t "$target_pane" ":e +${line} ${full_path}" Enter
else
  tmux send-keys -t "$target_pane" ":e ${full_path}" Enter
fi

# Switch focus to the Neovim pane
tmux select-pane -t "$target_pane" 2>/dev/null || true

exit 0
