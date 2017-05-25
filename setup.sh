#!/bin/bash
# Quick installer for dotfiles
# USAGE: curl -L https://github.com/optix2000/dotfiles/raw/master/setup.sh | bash
GITURL='https://github.com/optix2000/dotfiles.git'
DOTDIR='dotfiles'
DOTSUBDIR='dotfiles'
TMPDIR=`mktemp -d`

function cleanup() {
  if [ ! -z "$TMPDIR" ]; then
    echo 'Cleaning up tmpdir'
    rm -rf $TMPDIR
  fi
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
# Init pathogen
mkdir -p ~/.vim/autoload ~/.vim/bundle ~/.vim/undodir
curl -LSso ~/.vim/autoload/pathogen.vim https://github.com/tpope/vim-pathogen/raw/master/autoload/pathogen.vim

rm -rf $TMPDIR
