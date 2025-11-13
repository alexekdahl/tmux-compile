# tmux-compile
A tmux plugin inspired by Emacs' compile-mode, bringing seamless compilation workflows to your terminal. Designed to be simple and straightforward, yet packed with practical features for efficient development.

## Why compile-mode.tmux?
Like Emacs compile-mode, you don't have to leave your editor or tmux session. Trigger compilations, navigate errors directly to Neovim, and maintain your workflow without context switching. 
It strikes a balance between simplicity and functionality—no bloat, no unnecessary complexity.

## Features

- Run compilation commands in a separate tmux pane with a single keybinding
- Automatically save and recall previous compile commands
- Parse compiler errors and navigate directly to source files in Neovim
- Customizable pane height and keybindings
- Syntax-highlighted output with timestamps

## Installation

### Using tpm (Tmux Plugin Manager)

Add this line to your `tmux.conf`:

```tmux
set -g @plugin 'alexekdahl/tmux-compile'
```

Then press `prefix + I` to install the plugin.

### Manual Installation

Clone the repository into your tmux plugins directory:

```bash
git clone https://github.com/alexekdahl/tmux-compile ~/.tmux/plugins/tmux-compile
```

Add this line to your `tmux.conf`:

```tmux
run-shell ~/.tmux/plugins/tmux-comnpile/compile-mode.tmux
```

## Usage

### Basic Commands

- **Open compile pane**: `Ctrl-b` (default)
- **Recompile**: `Ctrl-r` (default)
- **Kill compile pane**: `Ctrl-k` (default)

When you trigger the compile command, you'll be prompted to enter a compilation command. Press Enter to execute it.

### Command History

By default, `tmux-compile` stores all compile commands in a single history file:
Enabling session-aware mode creates one history file per tmux session. Each file is named after the tmux session (for example, $COMPILE_HISTORY_DIR/my-session.history). Use @compile-mode-history-dir to change the directory.

### Error Navigation

When viewing compile output in copy-mode:

- **Open file at error**: `Enter` (default)

If the selected line matches a compiler error format (`file:line:col` or `file:line`), the file will open in Neovim at the specified location. This only works when Neovim is running in the adjacent pane.

## Configuration

Add these options to your `tmux.conf` to customize the plugin:

```tmux
# Change the compile command keybinding
set -g @compile-mode-key "C-c"

# Change the recompile keybinding
set -g @compile-mode-recompile-key "C-l"

# Change the kill pane keybinding
set -g @compile-mode-kill-key "C-x"

# Set compile pane height
set -g @compile-mode-height "25%"

# Set custom history file location
set -g @compile-mode-history-file "$HOME/.compile-history"

# Enable history file per session
set -g @compile-mode-session-history 'on'

# Set custom base directory for history files for history per session
set -g @compile-mode-history-dir "$HOME/.compile-history-dir"

# Change the file open keybinding (in copy-mode)
set -g @compile-mode-open-file-key "o"
```

## Requirements

- tmux 2.0 or later
- Neovim (for error navigation feature)
- bash

## License

MIT License - see LICENSE file for details
