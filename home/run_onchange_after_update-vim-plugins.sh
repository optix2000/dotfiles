#!/bin/sh
set -eu

if [ "${CHEZMOI_SKIP_VIM_PLUG:-}" = "1" ]; then
  exit 0
fi

editor=""
if command -v nvim >/dev/null 2>&1; then
  editor="nvim"
elif command -v vim >/dev/null 2>&1; then
  editor="vim"
fi

if [ -z "$editor" ] || [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
  exit 0
fi

"$editor" +PlugClean! +PlugUpdate +qall
