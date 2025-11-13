#!/usr/bin/env bash

# compile-mode.tmux
#
# Minimal tmux plugin for running compile commands in a dedicated pane.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

get_tmux_option() {
    local option=$1
    local default_value=$2
    local option_value
    option_value=$(tmux show-option -gqv "$option")
    if [ -z "$option_value" ]; then
        echo "$default_value"
    else
        echo "$option_value"
    fi
}

# Read configuration
compile_key=$(get_tmux_option "@compile-mode-key" "C-b")
recompile_key=$(get_tmux_option "@compile-mode-recompile-key" "C-r")
kill_key=$(get_tmux_option "@compile-mode-kill-key" "C-k")
height=$(get_tmux_option "@compile-mode-height" "30%")

# default (single file history)
history_file=$(get_tmux_option "@compile-mode-history-file" "$HOME/.tmux-compile-history")

# opt-in session mode
session_history_enabled=$(get_tmux_option "@compile-mode-session-history" "off")
base_history_dir=$(get_tmux_option "@compile-mode-history-dir" "$HOME/.tmux-compile-session-history-dir")

# Export configuration
tmux set-environment -g TMUX_COMPILE_HEIGHT "$height"
tmux set-environment -g TMUX_COMPILE_HISTORY "$history_file"
tmux set-environment -g TMUX_COMPILE_HISTORY_DIR "$base_history_dir"
tmux set-environment -g TMUX_COMPILE_SESSION_HISTORY_ENABLED "$session_history_enabled"

# Bind keys
tmux bind-key "$compile_key" run-shell "$CURRENT_DIR/scripts/compile.sh"
tmux bind-key "$recompile_key" run-shell "$CURRENT_DIR/scripts/recompile.sh"
tmux bind-key "$kill_key" run-shell "$CURRENT_DIR/scripts/kill-compile.sh"

# When in copy-mode inside the compile pane, pressing <Enter> will copy the
# current selection and, if it looks like a compiler error referencing a
# source file, open that file in the neighbouring pane running Neovim.  The
# default key can be overridden via `@compile-mode-open-file-key`.
open_file_key=$(get_tmux_option "@compile-mode-open-file-key" "Enter")
# Bind to both vi and emacs copy-mode tables.  The helper script will
# gracefully fall back to the default copy behaviour when run outside the
# compile pane.
tmux bind-key -T copy-mode-vi "$open_file_key" run-shell "$CURRENT_DIR/scripts/open-compile-file.sh"
tmux bind-key -T copy-mode "$open_file_key" run-shell "$CURRENT_DIR/scripts/open-compile-file.sh"
