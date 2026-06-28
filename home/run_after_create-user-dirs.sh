#!/bin/sh
set -eu

mkdir -p "$HOME/.zsh/cache"
mkdir -p "$HOME/.vim/autoload" "$HOME/.vim/undodir"
chmod 750 "$HOME/.vim/autoload"
chmod 700 "$HOME/.vim/undodir"

if command -v go >/dev/null 2>&1; then
  mkdir -p "$HOME/go"
fi

# Vim undo files can contain sensitive content from edited files.
find "$HOME/.vim/undodir" -maxdepth 1 -mindepth 1 -type f -mtime +365 -delete
