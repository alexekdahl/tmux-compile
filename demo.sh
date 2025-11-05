#!/usr/bin/env bash

# Demo script for tmux-compile-mode
# This shows what the output looks like

echo "=== tmux-compile-mode Demo ==="
echo ""
echo "This plugin recreates Emacs compile mode in tmux."
echo ""
echo "Try these commands:"
echo "  - make           (if you have a Makefile)"
echo "  - cargo build    (for Rust projects)"
echo "  - npm run build  (for Node projects)"
echo "  - go build       (for Go projects)"
echo "  - python setup.py build"
echo ""
echo "Example output format:"
echo ""
echo -e "\033[1;36m-*- mode: compilation; default-directory: \"$(pwd)\" -*-\033[0m"
echo -e "\033[1;36mCompilation started at $(date +'%a %b %d %H:%M:%S')\033[0m"
echo ""
echo "Building project..."
sleep 1
echo "Compiling src/main.c"
sleep 1
echo "Linking objects"
sleep 1
echo ""
echo "real    0m2.153s"
echo "user    0m1.890s"
echo "sys     0m0.234s"
echo ""
echo -e "\033[1;32mCompilation finished at $(date +'%a %b %d %H:%M:%S')\033[0m"
