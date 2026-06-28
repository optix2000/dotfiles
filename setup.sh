#!/bin/sh
set -eu

# Quick installer for dotfiles.
# USAGE: ./setup.sh

GITURL=${GITURL:-https://github.com/optix2000/dotfiles.git}

if ! command -v chezmoi >/dev/null 2>&1; then
  echo "chezmoi is required. Install it with your package manager, then rerun this script." >&2
  exit 1
fi

chezmoi init --apply "$GITURL"
