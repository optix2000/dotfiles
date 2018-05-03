#!/bin/bash
# Quick installer for dotfiles
# USAGE: curl -L https://github.com/optix2000/dotfiles/raw/master/setup.sh | bash
GITURL='https://github.com/optix2000/dotfiles.git'
DOTDIR='dotfiles'
DOTSUBDIR='dotfiles'
TMPDIR=`mktemp -d`

function cleanup() {
  rc=$?
  if [ ! -z "$TMPDIR" ]; then
    echo 'Cleaning up tmpdir'
    rm -rf $TMPDIR
  fi
  exit $rc
}

trap cleanup EXIT ERR

if [ -z "$TMPDIR" ]; then
    exit 1
fi

cd $TMPDIR
git clone --depth 1 --recursive $GITURL $DOTDIR
cd $DOTDIR

# Patch zshrc on macOS 16 (Sierra)
if [[ "$OSTYPE" == "darwin16"* ]]; then
  patch $DOTDIR/.zshrc zshrc-macos-sierra-battery.patch
fi


# Glob dotfiles
shopt -s dotglob nullglob
rsync -rvvbcl $DOTSUBDIR/* ~/
# Make vim dirs
mkdir -p ~/.vim/autoload ~/.vim/undodir
# Install and init Plug
curl -Lo ~/.vim/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim +PlugUpdate +qall
reset
