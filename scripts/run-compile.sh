#!/usr/bin/env bash

# scripts/run-compile.sh
#
# Core execution script: creates a dedicated compile pane, runs the command,
# saves to history, and provides syntax-highlighted output with timestamps.
# Handles all pane management and error context preservation.

compile_cmd="$1"

if [ -z "$compile_cmd" ]; then
    exit 0
fi

# Read configuration from tmux environment
height="${TMUX_COMPILE_HEIGHT:-30%}"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
history_file="$("$CURRENT_DIR/get-history-file.sh")"

# Persist command to history for reuse via recompile script
mkdir -p "$(dirname "$history_file")" 2>/dev/null
echo "$compile_cmd" >> "$history_file" 2>/dev/null || true

# Capture current tmux context to restore focus after pane creation
current_pane=$(tmux display-message -p '#{pane_id}')
current_window=$(tmux display-message -p '#{window_id}')
current_path=$(tmux display-message -p '#{pane_current_path}')

# Verify we're in a valid tmux session
if [ -z "$current_pane" ] || [ -z "$current_window" ]; then
    tmux display-message "Error: Cannot determine current pane"
    exit 1
fi

# Search only in the current window for an existing compile pane
compile_pane=$(tmux list-panes -t "$current_window" -F '#{pane_id} #{@compile-pane}' 2>/dev/null | \
    awk '$2=="compile" {print $1; exit}')

# Create a temporary wrapper script to avoid shell escaping complications
# and to provide consistent formatting across different compile commands
wrapper=$(mktemp)
cat > "$wrapper" << 'WRAPPER_EOF'
#!/usr/bin/env bash
compile_cmd="$1"
current_path="$2"

# Print header with emacs-style compilation mode marker and working directory
printf '\033[1;36m-*- mode: compilation; default-directory: "%s" -*-\033[0m\n' "$current_path"
printf '\033[1;36mCompilation started at %s\033[0m\n\n' "$(date +'%a %b %d %H:%M:%S')"

# Execute the compilation command and capture exit code
time eval "$compile_cmd"
exit_code=$?

# Print footer with appropriate color based on success/failure
echo
if [ $exit_code -eq 0 ]; then
    printf '\033[1;32mCompilation finished at %s\033[0m\n' "$(date +'%a %b %d %H:%M:%S')"
else
    printf '\033[1;31mCompilation exited abnormally with code %d at %s\033[0m\n' $exit_code "$(date +'%a %b %d %H:%M:%S')"
fi

# Keep the pane open so output remains visible for inspection
# User must press Enter to close, giving time to navigate errors
tmux copy-mode -t "$TMUX_PANE" 2>/dev/null || true
read -r -p "Press Enter to close..."
WRAPPER_EOF
chmod +x "$wrapper"

new_pane=""
pane_cmd="$wrapper '$compile_cmd' '$current_path'; rm -f '$wrapper'"

# If compile pane exists, re-run in place
if [ -n "$compile_pane" ]; then
    tmux clear-history -t "$compile_pane"
    tmux respawn-pane -k -t "$compile_pane" "$pane_cmd" 2>/dev/null
    new_pane="$compile_pane"
# Otherwise create a new split
else
    new_pane=$(tmux split-window -t "$current_window" -h -l "$height" -c "$current_path" -P -F '#{pane_id}' \
        "$pane_cmd" 2>/dev/null)
fi

# Verify the pane was created successfully
if [ -z "$new_pane" ]; then
    rm -f "$wrapper"
    tmux display-message "Error: Failed to create compile pane"
    exit 1
fi

# Mark the pane as a compile pane using a custom tmux option
# This marking is set from outside the pane shell to avoid race conditions
# where the pane might exit before the option is applied
tmux set-option -p -t "$new_pane" @compile-pane "compile" 2>/dev/null

# Return focus to the original pane so the user isn't interrupted
tmux select-pane -t "$current_pane" 2>/dev/null

exit 0
