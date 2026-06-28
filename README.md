# Dotfiles and stuff [![End-to-End Tests](https://github.com/optix2000/dotfiles/actions/workflows/e2e.yml/badge.svg?branch=master)](https://github.com/optix2000/dotfiles/actions/workflows/e2e.yml)

Managed with [chezmoi](https://www.chezmoi.io/).

## Requirements

```text
chezmoi
git
zsh
vim or neovim
```

## Install

Install `chezmoi` with your OS package manager, then apply this repo:

```sh
chezmoi init --apply https://github.com/optix2000/dotfiles.git
```

The legacy installer remains as a thin wrapper around the same command:

```sh
./setup.sh
```

## Daily Use

```sh
chezmoi cd
chezmoi diff
chezmoi apply
chezmoi update --refresh-externals
```

Set `CHEZMOI_SKIP_VIM_PLUG=1` before applying if you want to skip the Vim plugin update script.
