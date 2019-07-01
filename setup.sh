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

# Patch broken zshrc battery meter on macOS 16+ (Sierra)
if [[ "$OSTYPE" == "darwin16"* ]] || [[ "$OSTYPE" == "darwin17"* ]] || [[ "$OSTYPE" == "darwin18"* ]]; then
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
# Init and update antigen plugins
zsh -c 'source ~/.zshrc; antigen update'
# Detect golang and do some go setup
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
curl -Lso ~/.vim/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim +PlugClean +PlugUpdate +qall
reset
echo "Done!"
