#!/usr/bin/env bash
# Use only disposable config/credentials. --static also exercises mocked Linux
# preparation, but deliberately does not claim that kernel enforcement passed.
set -euo pipefail

STATIC_ONLY=0
case "${1:-}" in
  --static) STATIC_ONLY=1 ;;
  '') ;;
  *) printf 'usage: bash scripts/test-hindsight-sandbox.sh [--static]\n' >&2; exit 64 ;;
esac

SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
HOST_OS="$(uname -s)"
REAL_HOME="$HOME"
TEMP_ROOT="${TMPDIR:-/tmp}/opencode"
mkdir -p "$TEMP_ROOT"
TEST_ROOT="$(mktemp -d "$TEMP_ROOT/dotfiles-hindsight-sandbox.XXXXXX")"
export TMPDIR="$TEST_ROOT/"
FIXTURE=""
WRAPPER="$SOURCE_DIR/home/dot_local/bin/executable_safe-agent"

# Remove only paths owned by this invocation, including on assertion failure.
cleanup() {
  rm -rf -- "$TEST_ROOT"
  if [[ -n "$FIXTURE" ]]; then
    rm -rf -- "$FIXTURE"
  fi
}
trap cleanup EXIT

# Render with synthetic template data, not the caller's home/config or secrets.
render_profile() {
  local platform="$1" home="$2" source="$3" output="$4" escaped
  local profile="${5:-work}"
  escaped="${home//\\/\\\\}"
  escaped="${escaped//\"/\\\"}"
  chezmoi --source="$SOURCE_DIR" --config="$TEST_ROOT/chezmoi.toml" \
    --cache="$TEST_ROOT/cache" --persistent-state="$TEST_ROOT/chezmoi-state.boltdb" \
    --override-data="{\"profile\":\"$profile\",\"chezmoi\":{\"homeDir\":\"$escaped\",\"os\":\"$platform\",\"kernel\":{\"osrelease\":\"\"}}}" \
    execute-template < "$source" > "$output"
}

render_profile darwin "$TEST_ROOT/fake-home" \
  "$SOURCE_DIR/home/dot_config/sandbox/agent-base.sb.tmpl" "$TEST_ROOT/profile.sb"
render_profile linux "$TEST_ROOT/fake-home" \
  "$SOURCE_DIR/home/dot_config/landlock/agent-base.toml.tmpl" "$TEST_ROOT/profile.toml"

# Base must omit Hindsight permissions on both platforms.
render_profile darwin "$TEST_ROOT/fake-home" \
  "$SOURCE_DIR/home/dot_config/sandbox/agent-base.sb.tmpl" "$TEST_ROOT/base.sb" base
render_profile linux "$TEST_ROOT/fake-home" \
  "$SOURCE_DIR/home/dot_config/landlock/agent-base.toml.tmpl" "$TEST_ROOT/base.toml" base
if grep -Fq '.hindsight' "$TEST_ROOT/base.sb" "$TEST_ROOT/base.toml"; then
  printf 'FAIL: base sandbox profile grants Hindsight access\n' >&2
  exit 1
fi

# Compare entire Hindsight allow blocks, so broad parent or config-write grants
# cannot accidentally satisfy a mere substring check for the expected paths.
awk '
  /^\(allow / { block = ""; active = 1; depth = 0 }
  active {
    block = block $0
    line = $0
    gsub(/"([^"\\]|\\.)*"/, "", line)
    sub(/;;.*/, "", line)
    depth += gsub(/\(/, "(", line) - gsub(/\)/, ")", line)
    if (depth != 0) next
    if (block ~ /\.hindsight/) {
      gsub(/[[:space:]]/, "", block)
      if (block != "(allowfile-read-metadata(home-literal\"/.hindsight\"))" &&
          block != "(allowfile-read*(home-literal\"/.hindsight/coding-agent.json\"))" &&
          block != "(allowfile-read*file-write*(home-subpath\"/.hindsight/coding-agents-logs\"))") exit 1
      count++
    }
    active = 0
  }
  END { if (count != 3) exit 1 }
' "$TEST_ROOT/profile.sb"

# Landlock needs only read_file on the exact config, not read_dir on its parent.
awk '
  function check() {
    if (block !~ /\.hindsight/) return
    gsub(/[[:space:]]/, "", block)
    if (block != "[[path_beneath]]allowed_access=[\"read_file\"]parent=[\"${home}/.hindsight/coding-agent.json\"]" &&
        block != "[[path_beneath]]allowed_access=[\"abi.read_write\"]parent=[\"${home}/.hindsight/coding-agents-logs\"]") bad = 1
    count++
  }
  /^\[\[/ { check(); block = ""; active = ($0 == "[[path_beneath]]") }
  active && $0 !~ /^#/ { block = block $0 }
  END { check(); if (bad || count != 2) exit 1 }
' "$TEST_ROOT/profile.toml"
grep -Fq "(define HOME_DIR \"$TEST_ROOT/fake-home\")" "$TEST_ROOT/profile.sb"
grep -Fq "literal = [\"$TEST_ROOT/fake-home\"]" "$TEST_ROOT/profile.toml"
grep -Fq '(home-subpath "/.docker")' "$TEST_ROOT/profile.sb"
grep -Fq '(home-subpath "/.config/gcloud")' "$TEST_ROOT/profile.sb"
grep -Fq '(remote unix-socket (path-literal "/var/run/docker.sock"))' "$TEST_ROOT/profile.sb"
if grep -Eq '\.docker|\.config/gcloud|docker\.sock' "$TEST_ROOT/profile.toml"; then
  printf 'FAIL: default Landlock profile grants Docker/cloud credentials\n' >&2
  exit 1
fi
printf 'PASS: Hindsight grants are work-only and narrow; default Docker/cloud boundaries retained\n'

# Mock only the Linux launcher, not filesystem enforcement. This runs on either
# OS and proves preparation happens before llconfig, including standalone argv.
MOCK_HOME="$TEST_ROOT/mock-home"
mkdir -p "$TEST_ROOT/bin" "$TEST_ROOT/work" "$MOCK_HOME/.local/bin"
printf '#!/bin/sh\nprintf "Linux\\n"\n' > "$TEST_ROOT/bin/uname"
cat > "$MOCK_HOME/.local/bin/llconfig" <<'SH'
#!/bin/sh
set -eu
case "$EXPECT_LOGS" in
  present) test -d "$HOME/.hindsight/coding-agents-logs" ;;
  absent) test ! -e "$HOME/.hindsight" ;;
esac
SH
chmod +x "$TEST_ROOT/bin/uname" "$MOCK_HOME/.local/bin/llconfig"

# Route through the real wrapper without using the real HOME or managed binary.
mock_run() {
  local expected="$1"
  shift
  HOME="$MOCK_HOME" PATH="$TEST_ROOT/bin:$PATH" EXPECT_LOGS="$expected" \
    SAFE_AGENT_PROFILE="${MOCK_PROFILE:-$TEST_ROOT/profile.toml}" SAFE_AGENT_WORKDIR="$TEST_ROOT/work" \
    SAFE_OPENCODE_ALLOW_ALL=0 SAFE_AGENT_ENABLE_DOCKER=0 bash "$WRAPPER" "$@"
}

# Unsafe rule roots must fail for both OpenCode and other sandboxed commands,
# before the mock launcher can resolve a symlink into a broader writable grant.
expect_unsafe_hindsight_paths() {
  local command status
  for command in opencode /bin/sh; do
    status=0
    mock_run present "$command" > "$TEST_ROOT/error" 2>&1 || status=$?
    if [[ "$status" != 77 ]]; then
      printf 'FAIL: unsafe Hindsight directory accepted by %s (status %s)\n' "$command" "$status" >&2
      exit 1
    fi
  done
}

mock_run absent /bin/sh -c true
MOCK_PROFILE="$TEST_ROOT/base.toml" mock_run absent opencode --standalone
mock_run present opencode --standalone api get /api/info
test ! -e "$MOCK_HOME/.hindsight/coding-agent.json"
test "$(ls -ld "$MOCK_HOME/.hindsight" | cut -c1-10)" = drwx------
test "$(ls -ld "$MOCK_HOME/.hindsight/coding-agents-logs" | cut -c1-10)" = drwx------
rmdir "$MOCK_HOME/.hindsight/coding-agents-logs"
printf 'fake-config-preserved\n' > "$MOCK_HOME/.hindsight/coding-agent.json"
mock_run present "$TEST_ROOT/work/opencode" --standalone
grep -qx fake-config-preserved "$MOCK_HOME/.hindsight/coding-agent.json"
chmod 750 "$MOCK_HOME/.hindsight/coding-agents-logs"
mock_run present opencode --standalone
test "$(ls -ld "$MOCK_HOME/.hindsight/coding-agents-logs" | cut -c1-10)" = drwxr-x---
rmdir "$MOCK_HOME/.hindsight/coding-agents-logs"
printf 'not-a-directory\n' > "$MOCK_HOME/.hindsight/coding-agents-logs"
expect_unsafe_hindsight_paths
rm "$MOCK_HOME/.hindsight/coding-agents-logs"
mkdir "$TEST_ROOT/symlink-target"
ln -s "$TEST_ROOT/symlink-target" "$MOCK_HOME/.hindsight/coding-agents-logs"
expect_unsafe_hindsight_paths
rm "$MOCK_HOME/.hindsight/coding-agents-logs"
mkdir "$MOCK_HOME/.ssh"
printf 'fake-key-preserved\n' > "$MOCK_HOME/.ssh/id_ed25519"
for target in "$MOCK_HOME/.ssh" "$MOCK_HOME/.hindsight"; do
  ln -s "$target" "$MOCK_HOME/.hindsight/coding-agents-logs"
  expect_unsafe_hindsight_paths
  grep -qx fake-key-preserved "$MOCK_HOME/.ssh/id_ed25519"
  grep -qx fake-config-preserved "$MOCK_HOME/.hindsight/coding-agent.json"
  rm "$MOCK_HOME/.hindsight/coding-agents-logs"
done
# read_file applies recursively if its rule root is a directory. Reject both
# directory and file symlinks (and plain directories) masquerading as config.
mv "$MOCK_HOME/.hindsight/coding-agent.json" "$TEST_ROOT/saved-config"
for target in "$MOCK_HOME/.ssh" "$MOCK_HOME/.ssh/id_ed25519"; do
  ln -s "$target" "$MOCK_HOME/.hindsight/coding-agent.json"
  expect_unsafe_hindsight_paths
  grep -qx fake-key-preserved "$MOCK_HOME/.ssh/id_ed25519"
  rm "$MOCK_HOME/.hindsight/coding-agent.json"
done
mkdir "$MOCK_HOME/.hindsight/coding-agent.json"
expect_unsafe_hindsight_paths
rmdir "$MOCK_HOME/.hindsight/coding-agent.json"
mv "$TEST_ROOT/saved-config" "$MOCK_HOME/.hindsight/coding-agent.json"
mv "$MOCK_HOME/.hindsight" "$TEST_ROOT/saved-hindsight"
ln -s "$MOCK_HOME/.ssh" "$MOCK_HOME/.hindsight"
expect_unsafe_hindsight_paths
test ! -e "$MOCK_HOME/.ssh/coding-agents-logs"
grep -qx fake-key-preserved "$MOCK_HOME/.ssh/id_ed25519"
rm "$MOCK_HOME/.hindsight"
ln -s "$TEST_ROOT/symlink-target" "$MOCK_HOME/.hindsight"
expect_unsafe_hindsight_paths
test ! -e "$TEST_ROOT/symlink-target/coding-agents-logs"
rm "$MOCK_HOME/.hindsight"
printf 'not-a-directory\n' > "$MOCK_HOME/.hindsight"
expect_unsafe_hindsight_paths
printf 'PASS: work-only Linux log preparation, absent config, preserved modes and all-command symlink rejection (mock launcher)\n'

if [[ "$STATIC_ONLY" == 1 ]]; then
  printf 'SKIP: kernel sandbox checks (--static); rerun without --static outside an existing sandbox\n'
  exit 0
fi
case "$HOST_OS" in
  Darwin) PLATFORM=darwin; PROFILE_SOURCE="$SOURCE_DIR/home/dot_config/sandbox/agent-base.sb.tmpl" ;;
  Linux)
    PLATFORM=linux; PROFILE_SOURCE="$SOURCE_DIR/home/dot_config/landlock/agent-base.toml.tmpl"
    if [[ ! -x "$REAL_HOME/.local/bin/llconfig" ]]; then
      printf 'SKIP: kernel sandbox checks require managed ~/.local/bin/llconfig\n'
      exit 0
    fi
    ;;
  *) printf 'SKIP: kernel sandbox checks require macOS or Linux\n'; exit 0 ;;
esac

# Do not place the fake HOME under /tmp, TMPDIR or ~/repos: those already have
# recursive grants and would hide a regression. No real user files are read.
if [[ ! -d "$REAL_HOME/.local" ]] ||
   ! FIXTURE="$(mktemp -d "$REAL_HOME/.local/hindsight-sandbox-test.XXXXXX")"; then
  printf 'SKIP: kernel sandbox checks cannot create isolated ~/.local fixture; rerun outside the current sandbox\n'
  exit 0
fi
FIXTURE="$(cd "$FIXTURE" && pwd -P)"
case "$FIXTURE/" in
  /tmp/*|/private/tmp/*|/var/tmp/*|/var/folders/*|/private/var/folders/*|"$REAL_HOME/repos/"*)
    printf 'FAIL: fixture resolves inside a broad sandbox grant: %s\n' "$FIXTURE" >&2
    exit 1
    ;;
esac
FAKE_HOME="$FIXTURE/home"
WORKDIR="$FIXTURE/workdir"
mkdir -p "$FAKE_HOME/.hindsight/coding-agents-logs-other" "$FAKE_HOME/.docker/run" \
  "$FAKE_HOME/.config/gcloud" "$FAKE_HOME/.terraform.d" "$FAKE_HOME/.ssh" \
  "$FAKE_HOME/.gsutil" "$FAKE_HOME/repos" "$WORKDIR"
printf '{"apiUrl":"http://127.0.0.1:8888"}\n' > "$FAKE_HOME/.hindsight/coding-agent.json"
for path in .hindsight/private.txt .hindsight/coding-agents \
  .hindsight/coding-agents-logs-other/private.txt .docker/config.json \
  .docker/run/docker.sock .config/gcloud/credentials.db \
  .terraform.d/credentials.tfrc.json .ssh/id_ed25519 .ssh/config .gsutil/cred; do
  printf 'disposable-not-a-secret\n' > "$FAKE_HOME/$path"
done
PROBE="$WORKDIR/opencode"
if [[ "$HOST_OS" == Linux ]]; then
  mkdir -p "$FAKE_HOME/.local/bin" "$FAKE_HOME/.local/libexec"
  ln -s "$REAL_HOME/.local/bin/llconfig" "$FAKE_HOME/.local/bin/llconfig"
  # The managed launcher resolves its architecture-specific executable via HOME.
  # Mirror that binary directory too, and verify the fake-home launcher works
  # before claiming that a later failure exercised kernel policy enforcement.
  ln -s "$REAL_HOME/.local/libexec/llconfig" "$FAKE_HOME/.local/libexec/llconfig"
  HOME="$FAKE_HOME" "$FAKE_HOME/.local/bin/llconfig" --version >/dev/null
  # Landlock read_write intentionally excludes execute; use the existing
  # executable-directory grant instead of adding a test-only permission.
  PROBE="$FAKE_HOME/.local/bin/opencode"
fi
render_profile "$PLATFORM" "$FAKE_HOME" "$PROFILE_SOURCE" "$TEST_ROOT/runtime-profile"

# Give the probe the OpenCode basename so Linux must prepare the absent log dir.
# It performs only filesystem operations; it never starts OpenCode or a server.
cat > "$PROBE" <<'SH'
#!/bin/sh
set -eu
grep -qx '{"apiUrl":"http://127.0.0.1:8888"}' "$HOME/.hindsight/coding-agent.json"
for path in .hindsight/private.txt .hindsight/coding-agents \
  .hindsight/coding-agents-logs-other/private.txt .docker/config.json \
  .docker/run/docker.sock .config/gcloud/credentials.db \
  .terraform.d/credentials.tfrc.json .ssh/id_ed25519 .ssh/config .gsutil/cred; do
  if cat "$HOME/$path" >/dev/null 2>&1; then
    printf 'FAIL: protected fixture readable: %s\n' "$path" >&2
    exit 1
  fi
done
for path in .hindsight/coding-agent.json .hindsight/private.txt \
  .hindsight/new-file .hindsight/coding-agents \
  .hindsight/coding-agents-logs-other/private.txt .docker/config.json \
  .docker/run/docker.sock .config/gcloud/credentials.db \
  .terraform.d/credentials.tfrc.json .ssh/id_ed25519 .ssh/config .gsutil/cred; do
  if (printf 'forbidden\n' > "$HOME/$path") 2>/dev/null; then
    printf 'FAIL: protected fixture writable: %s\n' "$path" >&2
    exit 1
  fi
done
if mkdir "$HOME/.hindsight/new-directory" 2>/dev/null; then
  printf 'FAIL: Hindsight parent writable\n' >&2
  exit 1
fi
logs="$HOME/.hindsight/coding-agents-logs"
mkdir -p "$logs"
printf 'old\n' >> "$logs/plugin.log"
mv "$logs/plugin.log" "$logs/plugin.log.1"
printf 'current\n' >> "$logs/plugin.log"
mv "$logs/plugin.log" "$logs/plugin.log.1"
printf 'new\n' >> "$logs/plugin.log"
grep -qx current "$logs/plugin.log.1"
grep -qx new "$logs/plugin.log"
# Existing baseline project and runtime workdir grants must remain functional.
printf 'baseline\n' > "$HOME/repos/baseline-file"
grep -qx baseline "$HOME/repos/baseline-file"
printf 'workspace\n' > workspace-file
grep -qx workspace workspace-file
SH
chmod +x "$PROBE"
test ! -e "$FAKE_HOME/.hindsight/coding-agents-logs"
(
  cd "$WORKDIR"
  HOME="$FAKE_HOME" PATH=/usr/bin:/bin:/usr/sbin:/sbin SAFE_AGENT_PROFILE="$TEST_ROOT/runtime-profile" \
    SAFE_AGENT_WORKDIR="$WORKDIR" SAFE_AGENT_ENABLE_DOCKER=0 SAFE_OPENCODE_ALLOW_ALL=0 \
    bash "$WRAPPER" "$PROBE" --standalone
)
grep -qx '{"apiUrl":"http://127.0.0.1:8888"}' "$FAKE_HOME/.hindsight/coding-agent.json"
printf 'PASS: kernel sandbox config-read/config-write, sibling, log creation/rotation, Docker/cloud path and base/workdir boundaries\n'
