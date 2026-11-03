#!/usr/bin/env bash
# Check private-server argument routing and macOS ancestor-discovery boundaries.
set -euo pipefail

SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_ROOT="${TMPDIR:-/tmp}/opencode"
mkdir -p "$TEMP_ROOT"
TEST_ROOT="$(mktemp -d "$TEMP_ROOT/dotfiles-safe-opencode.XXXXXX")"
# Keep generated sandbox profiles inside the test's disposable directory too.
export TMPDIR="$TEST_ROOT/"
FIXTURE=""

# Remove only disposable paths created by this test, including on assertion failure.
cleanup() {
  rm -rf -- "$TEST_ROOT"
  if [[ -n "$FIXTURE" ]]; then
    rm -rf -- "$FIXTURE"
  fi
}
trap cleanup EXIT

# Load the actual wrapper definitions without shell plugins or interactive startup.
zsh -f -s -- "$SOURCE_DIR/home/dot_zshrc" <<'ZSH'
set -eu
# Shell startup adds local commands once and leaves profile selection to safe-agent.
export SAFE_AGENT_PROFILE=/custom/profile
shell_setup="$(sed -n '/^case "$OSTYPE" in/,/^esac/p' "$1")"
eval "$shell_setup"
[[ "$SAFE_AGENT_PROFILE" == /custom/profile ]]
[[ ":$PATH:" == *":$HOME/.local/bin:"* ]]
saved_path="$PATH"
eval "$shell_setup"
[[ "$PATH" == "$saved_path" ]]

eval "$(sed -n '/^safe-opencode() {/,/^}/p; /^safe-opencode-docker() {/,/^}/p' "$1")"
unset SAFE_OPENCODE_ALLOW_ALL SAFE_AGENT_ENABLE_DOCKER

# Capture the sandbox boundary invocation without starting any OpenCode services.
safe-agent() {
  print -r -- "allow=${SAFE_OPENCODE_ALLOW_ALL:-0} docker=${SAFE_AGENT_ENABLE_DOCKER:-0}"
  printf '<%s>\n' "$@"
}

# Compare complete argv, preserving spaces and argument ordering.
expect_args() {
  local expected="$1"
  shift
  local actual="$("$@")"
  if [[ "$actual" != "$expected" ]]; then
    print -u2 -r -- "Unexpected invocation: $actual"
    return 1
  fi
}

expect_args $'allow=0 docker=0\n<opencode>\n<--standalone>\n<--prompt>\n<hello world>' safe-opencode --prompt 'hello world'
expect_args $'allow=0 docker=0\n<opencode>\n<run>\n<--standalone>\n<hello world>' safe-opencode run 'hello world'
expect_args $'allow=0 docker=0\n<opencode>\n<api>\n<--standalone>\n<get>\n</api/info>' safe-opencode api get /api/info
for mode in mini acp; do
  expect_args "allow=0 docker=0"$'\n<opencode>\n<'"$mode"$'>\n<--standalone>' safe-opencode "$mode"
done
SAFE_OPENCODE_ALLOW_ALL=0 expect_args $'allow=0 docker=0\n<opencode>\n<--standalone>\n<--continue>' safe-opencode --continue
expect_args $'allow=0 docker=1\n<opencode>\n<run>\n<--standalone>\n<hello world>' safe-opencode-docker run 'hello world'

# Explicit opt-in restores automatic approval without changing routing.
SAFE_OPENCODE_ALLOW_ALL=1 expect_args $'allow=1 docker=0\n<opencode>\n<--standalone>\n<--auto>\n<--prompt>\n<hello world>' safe-opencode --prompt 'hello world'
SAFE_OPENCODE_ALLOW_ALL=1 expect_args $'allow=1 docker=1\n<opencode>\n<run>\n<--standalone>\n<--auto>\n<hello world>' safe-opencode-docker run 'hello world'
for mode in mini api acp; do
  SAFE_OPENCODE_ALLOW_ALL=1 expect_args "allow=1 docker=0"$'\n<opencode>\n<'"$mode"$'>\n<--standalone>' safe-opencode "$mode"
done
for arg in --server --server=http://localhost:1 --standalone=false --no-standalone service serve pair; do
  if safe-opencode "$arg" >/dev/null 2>&1; then
    print -u2 -r -- "Unsafe server selection accepted: $arg"
    exit 1
  else
    [[ $? == 64 ]]
  fi
done
print 'PASS: private-server routing, approval by default, autoapproval opt-in, Docker opt-in and unsafe-command rejection'
ZSH

if [[ "$(uname -s)" != Darwin ]]; then
  printf 'SKIP: macOS sandbox discovery checks require sandbox-exec\n'
  exit 0
fi

# Unlike /tmp and ~/repos, this path is not recursively readable in the profile.
# A nested workdir must not expose the parent repo's files or Git object contents.
FIXTURE="$(mktemp -d "$HOME/.local/safe-opencode-test.XXXXXX")"
mkdir -p "$FIXTURE/workdir" "$FIXTURE/.git" "$FIXTURE/.hg"
printf 'parent-private\n' > "$FIXTURE/sibling.txt"
printf 'git-private\n' > "$FIXTURE/.git/config"
printf 'hg-private\n' > "$FIXTURE/.hg/hgrc"
printf 'workspace-readable\n' > "$FIXTURE/workdir/file.txt"

chezmoi --source="$SOURCE_DIR" --destination="$HOME" --config="$TEST_ROOT/chezmoi.toml" \
  --cache="$TEST_ROOT/cache" --persistent-state="$TEST_ROOT/chezmoi-state.boltdb" \
  execute-template < "$SOURCE_DIR/home/dot_config/sandbox/agent-base.sb.tmpl" > "$TEST_ROOT/profile.sb"

cd "$FIXTURE/workdir"
SAFE_AGENT_PROFILE="$TEST_ROOT/profile.sb" SAFE_AGENT_WORKDIR="$FIXTURE/workdir" \
  bash "$SOURCE_DIR/home/dot_local/bin/executable_safe-agent" /bin/sh -c '
    set -eu
    parent="$1"
    /usr/bin/stat -f "%N" "$parent/.git" "$parent/.hg" >/dev/null
    grep -qx workspace-readable "$parent/workdir/file.txt"
    for path in "$parent/sibling.txt" "$parent/.git/config" "$parent/.hg/hgrc"; do
      if cat "$path" >/dev/null 2>&1; then
        printf "FAIL: ancestor content readable: %s\n" "$path" >&2
        exit 1
      fi
    done
    if ( : > "$parent/.git/config" ) 2>/dev/null; then
      printf "FAIL: ancestor Git state writable\n" >&2
      exit 1
    fi
  ' sh "$FIXTURE"

# Worktrees use a .git file instead of a directory; stat must work for both.
rm -- "$FIXTURE/.git/config"
rmdir -- "$FIXTURE/.git"
printf 'gitdir: /outside/worktree\n' > "$FIXTURE/.git"
SAFE_AGENT_PROFILE="$TEST_ROOT/profile.sb" SAFE_AGENT_WORKDIR="$FIXTURE/workdir" \
  bash "$SOURCE_DIR/home/dot_local/bin/executable_safe-agent" /usr/bin/stat -f '%N' "$FIXTURE/.git" >/dev/null

printf 'PASS: ancestor VCS metadata allowed; parent content and Git writes remain denied\n'
