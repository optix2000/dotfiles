# Dotfiles and stuff [![End-to-End Tests](https://github.com/optix2000/dotfiles/actions/workflows/e2e.yml/badge.svg?branch=master)](https://github.com/optix2000/dotfiles/actions/workflows/e2e.yml)

Managed with [chezmoi](https://www.chezmoi.io/).

## Requirements

```text
chezmoi
git
zsh
vim or neovim
```

Linux installs a pinned, statically linked `llconfig` sandbox launcher for
`amd64` and `arm64` directly from this repository. Target machines do not need
Rust or Cargo.

Maintainers can rebuild both binaries from the pinned upstream source and
digest-pinned musl toolchains with:

```sh
./scripts/build-llconfig-binaries.sh
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

## OpenCode

The managed MCP fragments require `sem` on `PATH` and `GITHUB_TOKEN` in
OpenCode's environment. Grafana remains disabled; when enabled, it also uses
`GRAFANA_URL` and `GRAFANA_SERVICE_ACCOUNT_TOKEN`. Set these variables before
applying the fragments over existing credential-bearing configuration.

Machine-local provider settings, such as MLX, can remain in the unmanaged
`~/.config/opencode/config.d/local.jsonc` file.

For machine-local plugins, create `~/.config/opencode/plugins.local.json`
with a `plugins` array. For example:

```json
{
  "plugins": [
    {
      "source": "local",
      "path": "~/repos/opencode-e2b",
      "entry": "./src/index.ts"
    }
  ]
}
```

Chezmoi appends these entries to the portable defaults when rendering
`plugins.jsonc`. The local manifest must be valid JSON and remains outside
the repository. Apply changes to it with:

```sh
chezmoi apply ~/.config/opencode/plugins.jsonc
```

Restart OpenCode after applying configuration changes.
