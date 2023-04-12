if [[ -z $EXTRASDIR ]]; then
  echo "Can't find env variables. Script not running from setup.sh"
  exit 1
fi

if command -v nvim > /dev/null; then
  if [[ -e "~/.zshrc.pre.common" ]]; then
    if ! grep 'alias vim' ~/.zshrc.pre.common; then
      cat $EXTRASDIR/nvim.zshrc >> ~/.zshrc.pre.common
    fi
  fi
  alias vim=nvim
fi

# Make vim dirs
mkdir -p ~/.vim/autoload ~/.vim/undodir
chmod 750 ~/.vim/autoload
# undodir can contain sensitive info
chmod 700 ~/.vim/undodir
# spring cleaning
find ~/.vim/undodir -maxdepth 1 -mindepth 1 -type f -mtime +365 -delete
# Install and init Plug
curl -Lsfo ~/.vim/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
nvim +PlugClean! "+PlugUpdate --sync" +qall
