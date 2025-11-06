#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default options
default_key="C-c C-c"
default_height="30%"
default_history_file="$HOME/.tmux-compile-history"

get_tmux_option() {
    local option=$1
    local default_value=$2
    local option_value=$(tmux show-option -gqv "$option")
    if [ -z "$option_value" ]; then
        echo "$default_value"
    else
        echo "$option_value"
    fi
}

# Get user configuration
key=$(get_tmux_option "@compile-mode-key" "$default_key")
height=$(get_tmux_option "@compile-mode-height" "$default_height")
history_file=$(get_tmux_option "@compile-mode-history-file" "$default_history_file")

# Export variables for scripts to use
tmux set-environment -g TMUX_COMPILE_HEIGHT "$height"
tmux set-environment -g TMUX_COMPILE_HISTORY "$history_file"

# Bind the compile command
tmux bind-key "$key" run-shell "$CURRENT_DIR/scripts/compile.sh"

# Bind recompile (C-c C-r) to run last command
tmux bind-key "C-b C-r" run-shell "$CURRENT_DIR/scripts/recompile.sh"

# Bind to close compile pane (C-c C-k)
tmux bind-key "C-b C-k" run-shell "$CURRENT_DIR/scripts/kill-compile.sh"

# Bind to focus compile pane and enter copy mode (C-c C-o)
tmux bind-key "C-b C-o" run-shell "$CURRENT_DIR/scripts/focus-compile.sh"

# Bind to jump to next error (C-c C-n)
tmux bind-key "C-b C-n" run-shell "$CURRENT_DIR/scripts/next-error.sh"

# In copy-mode in compile pane, bind Enter to jump to error in Neovim
tmux bind-key -T copy-mode-vi "Enter" run-shell "$CURRENT_DIR/scripts/jump-to-error.sh"
tmux bind-key -T copy-mode "Enter" run-shell "$CURRENT_DIR/scripts/jump-to-error.sh"
