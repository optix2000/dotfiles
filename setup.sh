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

cd $TMPDIR
git clone --depth 1 --recursive $GITURL $DOTDIR
cd $DOTDIR

# Patch zshrc on macOS 16 (Sierra)
if [[ "$OSTYPE" == "darwin16"* ]] || [[ "$OSTYPE" == "darwin17"* ]] ; then
  patch $DOTSUBDIR/.zshrc zshrc-macos-sierra-battery.patch
fi


# Glob dotfiles
shopt -s dotglob nullglob
rsync -rvvbcl $DOTSUBDIR/* ~/
# Make zsh cache dir
mkdir -p ~/.zsh/cache
# Detect golang
if go version; then
  bash extras/go_setup.sh
fi

# Make vim dirs
mkdir -p ~/.vim/autoload ~/.vim/undodir
chmod 750 ~/.vim/autoload
# undodir can contain sensitive info
chmod 700 ~/.vim/undodir
# spring cleaning
find ~/.vim/undodir -maxdepth 1 -mindepth 1 -type f -mtime +365 -delete
# Install and init Plug
curl -Lo ~/.vim/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim +PlugClean +PlugUpdate +qall
reset
