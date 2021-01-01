#!/bin/bash

# Install deps
if [[ "$OSTYPE" == "darwin"* ]]; then
  brew install rsync git zsh vim
  brew install getantibody/tap/antibody
elif [[ -f "/etc/debian_version" ]]; then
  sudo apt-get update
  sudo apt-get install -y curl rsync git zsh vim-nox
  # TODO: Make this generic across arch and autoupdate
  #wget 'https://github.com/getantibody/antibody/releases/download/v6.0.1/antibody_6.0.1_linux_amd64.deb' && sudo dpkg -i antibody_6.0.1_linux_amd64.deb
fi

curl -sfL https://github.com/optix2000/dotfiles/raw/master/setup.sh | bash
