#!/usr/bin/env bash

compile_cmd="$1"

if [ -z "$compile_cmd" ]; then
    exit 0
fi

# Get configuration
height="${TMUX_COMPILE_HEIGHT:-30%}"
history_file="${TMUX_COMPILE_HISTORY:-$HOME/.tmux-compile-history}"

# Save command to history
echo "$compile_cmd" >> "$history_file"

# Get current pane and window
current_pane=$(tmux display-message -p '#{pane_id}')
current_window=$(tmux display-message -p '#{window_id}')

# Mark current pane as the neovim pane for later reference
tmux set-option -p -t "$current_pane" @neovim-pane "neovim"

# Look for existing compile pane (marked with @compile-pane)
compile_pane=$(tmux list-panes -t "$current_window" -F '#{pane_id} #{@compile-pane}' | grep 'compile' | awk '{print $1}')

# Get current working directory
current_path=$(tmux display-message -p '#{pane_current_path}')

if [ -n "$compile_pane" ]; then
    # Reuse existing compile pane - kill it and recreate to avoid state issues
    tmux kill-pane -t "$compile_pane"
    compile_pane=""
fi

if [ -z "$compile_pane" ]; then
    # Create new pane at bottom
    tmux split-window -v -l "$height" -c "$current_path" -P -F '#{pane_id}' \
        "printf '\\033[1;36m-*- mode: compilation; default-directory: \"$current_path\" -*-\\033[0m\n'; \
         printf '\\033[1;36mCompilation started at %s\\033[0m\n\n' \"\$(date +'%a %b %d %H:%M:%S')\"; \
         time $compile_cmd; \
         exit_code=\$?; \
         echo; \
         if [ \$exit_code -eq 0 ]; then \
             printf '\\033[1;32mCompilation finished at %s\\033[0m\n' \"\$(date +'%a %b %d %H:%M:%S')\"; \
         else \
             printf '\\033[1;31mCompilation exited abnormally with code %s at %s\\033[0m\n' \$exit_code \"\$(date +'%a %b %d %H:%M:%S')\"; \
         fi; \
         pane_id=\$(tmux display-message -p '#{pane_id}'); \
         tmux set-option -p -t \$pane_id @compile-pane 'compile'; \
         cat > /dev/null" > /tmp/compile-pane-id
    
    # Get the pane ID
    new_pane=$(cat /tmp/compile-pane-id)
    
    # Focus back on original pane
    tmux select-pane -t "$current_pane"
else
    # Create new pane at bottom
    tmux split-window -v -l "$height" -c "$current_path" -P -F '#{pane_id}' \
        "printf '\\033[1;36m-*- mode: compilation; default-directory: \"$current_path\" -*-\\033[0m\n'; \
         printf '\\033[1;36mCompilation started at %s\\033[0m\n\n' \"\$(date +'%a %b %d %H:%M:%S')\"; \
         time $compile_cmd; \
         exit_code=\$?; \
         echo; \
         if [ \$exit_code -eq 0 ]; then \
             printf '\\033[1;32mCompilation finished at %s\\033[0m\n' \"\$(date +'%a %b %d %H:%M:%S')\"; \
         else \
             printf '\\033[1;31mCompilation exited abnormally with code %s at %s\\033[0m\n' \$exit_code \"\$(date +'%a %b %d %H:%M:%S')\"; \
         fi; \
         pane_id=\$(tmux display-message -p '#{pane_id}'); \
         tmux set-option -p -t \$pane_id @compile-pane 'compile'; \
         cat > /dev/null" > /tmp/compile-pane-id
    
    # Get the pane ID and mark it
    new_pane=$(cat /tmp/compile-pane-id)
    
    # Focus back on original pane
    tmux select-pane -t "$current_pane"
fi
