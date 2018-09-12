if [[ -z $EXTRASDIR ]]; then
  echo "Can't find env variables. Script not running from setup.sh"
  exit 1
fi

if [[ -e "~/.zshrc.pre.common" ]]; then
  if ! grep 'GOPATH' ~/.zshrc.pre.common; then
    cat $EXTRASDIR/go.zshrc >> ~/.zshrc.pre.common
  fi
else
  cat $EXTRASDIR/go.zshrc > ~/.zshrc.pre.common
fi
