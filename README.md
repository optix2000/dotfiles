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

Requires OpenCode 2.0.32 or newer and `sem` on `PATH`. Export `GITHUB_TOKEN`
before starting OpenCode to use GitHub MCP. Sign into Linear and Notion through
`/mcps`.

Profiles default to `base` (GitHub, Context7, SEM). For Hindsight, Linear, Notion,
and Grafana, set `profile = "work"` under `[data]` in `chezmoi edit-config` before
applying. Grafana stays disabled by default. Profile switches must reapply
`~/.config/opencode/opencode.jsonc`, `~/.config/opencode/config.d/grafana.jsonc`,
and the platform's `~/.config/sandbox/agent-base.sb` or
`~/.config/landlock/agent-base.toml`.

Keep machine-local providers in `~/.config/opencode/config.d/local.jsonc`.

Sandbox wrappers preserve approval prompts by default. Set
`SAFE_OPENCODE_ALLOW_ALL=1` to opt into automatic approval.

Run configuration and wrapper checks without changing the live setup:

```sh
./scripts/test-opencode-config.sh
bash scripts/test-safe-opencode.sh
bash scripts/test-hindsight-sandbox.sh
```
