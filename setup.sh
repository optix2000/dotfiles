#!/bin/bash
set -e
# USAGE: curl -L https://github.com/optix2000/dotfiles/raw/master/setup.sh | bash
GITURL='https://github.com/optix2000/dotfiles.git'
DOTDIR='dotfiles'
DOTSUBDIR='dotfiles'
TMPDIR=`mktemp -d`
if [ -z "$TMPDIR" ]; then
    exit 1
fi
cd $TMPDIR
git clone --depth 1 --recursive $GITURL $DOTDIR
cd $DOTDIR
# Glob dotfiles
shopt -s dotglob nullglob
rsync -rvvbcl $DOTSUBDIR/* ~/
# Init pathogen
mkdir -p ~/.vim/autoload ~/.vim/bundle
curl -LSso ~/.vim/autoload/pathogen.vim https://github.com/tpope/vim-pathogen/raw/master/autoload/pathogen.vim

rm -rf $TMPDIR
