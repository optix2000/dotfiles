# Dotfiles and stuff [![End-to-End Tests](https://github.com/optix2000/dotfiles/actions/workflows/e2e.yml/badge.svg?branch=master)](https://github.com/optix2000/dotfiles/actions/workflows/e2e.yml)

## Requirements

Install before applying:

- [chezmoi](https://www.chezmoi.io/)
- Git
- Zsh
- Vim or Neovim
- curl and CA certificates (`ca-certificates` on Debian/Ubuntu)

## Setup

```sh
chezmoi init https://github.com/optix2000/dotfiles.git
chezmoi edit-config
```

Choose the machine's profile in the chezmoi config:

```toml
[data]
profile = "base" # or "work"
```

- **`base`** (default): shared dotfiles, with GitHub, Context7, and SEM integrations.
- **`work`**: base plus Hindsight, Linear, Notion, and Grafana configuration.
  Grafana stays disabled by default. Hindsight sandbox access is work-only.

```sh
chezmoi diff
chezmoi apply
```

After changing profiles, run a full `chezmoi apply` so the OpenCode configuration
and sandbox policies stay in sync. To pull updates, including external files:

```sh
chezmoi update --refresh-externals
```

## Setup notes

- OpenCode requires version 2.0.32 or newer and `sem` on `PATH`. GitHub MCP
  requires `GITHUB_TOKEN` in OpenCode's environment. Authenticate Linear and
  Notion through `/mcps` on work machines.
- Put machine-local OpenCode providers in `~/.config/opencode/config.d/local.jsonc`.
- Set `CHEZMOI_SKIP_VIM_PLUG=1` before applying to skip the Vim plugin update.

## llconfig

Linux installs a pinned, statically linked `llconfig` sandbox launcher for
`amd64` and `arm64` directly from this repository. Target machines do not need
Rust or Cargo.

Rebuild both binaries using Docker, the pinned upstream source, and digest-pinned
musl toolchains:

```sh
./scripts/build-llconfig-binaries.sh
```
