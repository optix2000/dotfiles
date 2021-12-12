#!/bin/bash
# Quick installer for dotfiles
# USAGE: curl -L https://github.com/optix2000/dotfiles/raw/master/setup.sh | bash
GITURL='https://github.com/optix2000/dotfiles.git'
DOTDIR='dotfiles'
DOTSUBDIR='dotfiles'
export EXTRASDIR='extras'
TMPDIR=`mktemp -d` || exit 1

function cleanup() {
  rc=$?
  if [ ! -z "$TMPDIR" ]; then
    echo 'Cleaning up tmpdir'
    rm -rf $TMPDIR
  fi
  exit $rc
}

trap cleanup EXIT ERR

# Install zsh-snap
if ! command -v znap && ! [ -d ~/.zsh/zsh-snap]; then
    git clone --depth 1 -- https://github.com/marlonrichert/zsh-snap.git ~/.zsh/zsh-snap
else


cd $TMPDIR
git clone --depth 1 --recursive $GITURL $DOTDIR
cd $DOTDIR

# Patch broken zshrc battery meter on macOS 16+ (Sierra)
if [[ "$OSTYPE" == "darwin16"* ]] || [[ "$OSTYPE" == "darwin17"* ]] || [[ "$OSTYPE" == "darwin18"* ]] || [[ "$OSTYPE" == "darwin19"* ]]; then
  patch $DOTSUBDIR/.zshrc zshrc-macos-sierra-battery.patch
fi

# Glob dotfiles
shopt -s dotglob nullglob
# Use rsync to copy files and symlinks and make backups. cp is not the same on linux vs Macos
rsync -rbcl $DOTSUBDIR/* ~/
# Touch local files
touch ~/.zshrc.pre.local
touch ~/.zshrc.local.local
# Make zsh cache dir
mkdir -p ~/.zsh/cache
# Init zsh
zsh -c 'source ~/.zshrc'

# Detect golang and do some go setup
if go version; then
  bash extras/go_setup.sh
fi

# Setup (n)vim
bash extras/vim_setup.sh

reset
echo "Done!"
