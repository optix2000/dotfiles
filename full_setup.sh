#!/bin/bash

# Install deps
if [[ "$OSTYPE" == "darwin"* ]]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew install curl rsync git zsh vim python
elif [[ -f "/etc/debian_version" ]]; then
  sudo apt-get update
  sudo apt-get install -y curl rsync git zsh neovim
fi

curl -sfL https://github.com/optix2000/dotfiles/raw/master/setup.sh | bash
