#!/usr/bin/env bash
# Render OpenCode configuration into a disposable home; never apply to live state.
set -euo pipefail

SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_ROOT="${TMPDIR:-/tmp}/opencode"
mkdir -p "$TEMP_ROOT"
TEST_ROOT="$(mktemp -d "$TEMP_ROOT/dotfiles-opencode.XXXXXX")"
trap 'rm -rf -- "$TEST_ROOT"' EXIT
DEST="$TEST_ROOT/home"
CONFIG="$DEST/.config/opencode"
BASELINE="$SOURCE_DIR/scripts/fixtures/opencode-baseline.json"
mkdir -p "$CONFIG"
printf '[data]\nprofile = "base"\n' >"$TEST_ROOT/base.toml"
printf '[data]\nprofile = "work"\n' >"$TEST_ROOT/work.toml"

# Do not inherit the developer's chezmoi overrides or use their cache/state/home.
while IFS= read -r name; do
  case "$name" in CHEZMOI_*) unset "$name" ;; esac
done < <(compgen -e)
export HOME="$TEST_ROOT/isolated-home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME"

# Limit every apply to OpenCode files and isolate config, cache, and state. An
# absent default.toml deliberately tests apply without a saved profile.
apply_opencode() {
  chezmoi --source="$SOURCE_DIR" --destination="$DEST" \
    --config="${1:-$TEST_ROOT/work.toml}" --no-tty \
    --cache="$TEST_ROOT/cache" --persistent-state="$TEST_ROOT/state.boltdb" \
    apply --exclude=scripts,externals "$CONFIG"
}

# Compare the complete ordered policy and plugin set.
# Only work includes Hindsight and the managed work-service integrations.
assert_profile() {
  local profile="$1"
  jq -e --arg profile "$profile" --slurpfile baseline "$BASELINE" '
    def work_rule: .action | test("^(linear|notion|grafana)_");
    ($baseline[0].plugins | if $profile == "work" then . else
      map(select(startswith("@vectorize-io/hindsight-coding-agents@") | not)) end) as $plugins |
    .permissions == ($baseline[0].permissions |
      if $profile == "work" then . else map(select((work_rule | not) or .effect == "ask")) end) and
    .plugins == $plugins and
    (.mcp.servers | keys) ==
      (if $profile == "work" then ["context7", "linear", "notion"] else ["context7"] end) and
    .mcp.servers.context7 == {"type":"remote","url":"https://mcp.context7.com/mcp"} and
    (has("providers") | not) and
    .update == "auto" and .share == "disabled" and
    .experimental.todo == true and
    (has("model") | not) and
    ((.session // {}) | has("permissions") | not)
  ' "$CONFIG/opencode.jsonc" >/dev/null
  # Permission autoaccept and MLX activation remain machine-local defaults,
  # never profile-specific managed overrides, including in shared fragments.
  local managed
  for managed in "$CONFIG/config.d/sem.jsonc" \
    "$CONFIG/config.d/github.jsonc" "$CONFIG/config.d/explore.jsonc"; do
    jq -e '((.session // {}) | has("permissions") | not)' "$managed" >/dev/null
  done
  test ! -e "$CONFIG/config.d/mlx.jsonc"
  jq -e '. == {"mcp":{"servers":{"github":{
    "type":"remote", "url":"https://api.githubcopilot.com/mcp/",
    "headers":{"Authorization":"Bearer {env:GITHUB_TOKEN}"}
  }}}}' "$CONFIG/config.d/github.jsonc" >/dev/null
  if [[ "$profile" == work ]]; then
    jq -e '. == {"mcp":{"servers":{"grafana":{
      "type":"local", "command":["uvx","mcp-grafana"], "disabled":true,
      "environment":{"GRAFANA_URL":"{env:GRAFANA_URL}",
        "GRAFANA_SERVICE_ACCOUNT_TOKEN":"{env:GRAFANA_SERVICE_ACCOUNT_TOKEN}"}
    }}}}' "$CONFIG/config.d/grafana.jsonc" >/dev/null
  else
    # Empty template output must remove an existing target, not leave an empty
    # file or ignore stale Grafana configuration from the previous work apply.
    test ! -e "$CONFIG/config.d/grafana.jsonc"
    ! grep -Eq 'mcp-(linear|notion)-client-id' "$CONFIG/opencode.jsonc"
  fi
}

# Retired managed files must disappear on upgrades, without removing GPT rules.
mkdir -p "$CONFIG/provider-system-prompts"
printf 'retired Opus rule\n' >"$CONFIG/provider-system-prompts/80-opus.md"
printf 'retired plugin guide\n' >"$CONFIG/provider-system-prompts.md"

# Both a missing profile and an explicit base select base.
apply_opencode "$TEST_ROOT/default.toml"
assert_profile base
test ! -e "$CONFIG/provider-system-prompts/80-opus.md"
test ! -e "$CONFIG/provider-system-prompts.md"
test -s "$CONFIG/provider-system-prompts/80-openai.md"
cp "$CONFIG/opencode.jsonc" "$TEST_ROOT/default.json"
apply_opencode "$TEST_ROOT/base.toml"
assert_profile base
cmp "$TEST_ROOT/default.json" "$CONFIG/opencode.jsonc"
cp "$CONFIG/opencode.jsonc" "$TEST_ROOT/base.json"

# Existing behavior remains covered using work, without machine-local clients.
apply_opencode
assert_profile work
cp "$CONFIG/opencode.jsonc" "$TEST_ROOT/work.json"
# Compare common rules and configuration, excluding work-only integrations.
jq -e -s '
  def common: [.permissions[] | select(.action | test("^(linear|notion|grafana)_") | not)];
  def common_config:
    del(.permissions, .mcp.servers.linear, .mcp.servers.notion) |
    .plugins |= map(select(startswith("@vectorize-io/hindsight-coding-agents@") | not));
  (.[0] | common) == (.[1] | common) and
  (.[0] | common_config) == (.[1] | common_config)
' "$TEST_ROOT/base.json" "$TEST_ROOT/work.json" >/dev/null
jq -e '
  .agents.build.permissions == null and
  .agents["plan-reviewer"].model == "openai/gpt-6.1-sol#high" and
  .agents["plan-reviewer"].permissions == [{"action":"edit","resource":"*","effect":"deny"},{"action":"shell","resource":"*","effect":"deny"}] and
  (.mcp.servers.linear | has("oauth") | not) and
  (.mcp.servers.notion | has("oauth") | not) and
  (has("plugin") or has("permission") or has("agent") or has("provider") or has("autoupdate") | not)
' "$CONFIG/opencode.jsonc" >/dev/null

# MCP resource discovery and reads use native agent defaults, without overrides.
jq -e '
  [.permissions[] | select(.action == "opencode_list_mcp_resources" or .action == "opencode_read_mcp_resource")] == []
' "$CONFIG/opencode.jsonc" >/dev/null

# Evaluate last-match-wins action rules for MCP tool calls (resource "*"). Check
# wildcard grants, diagnostic reads, and the approval boundary around mutations.
jq -e '
  def effect($action):
    [.permissions[] | select(.resource == "*") | . as $rule |
      select($action | test("^" + ($rule.action | gsub("\\*"; ".*")) + "$"))
    ][-1].effect // "allow";
  . as $config |
  (["sem_sem_check", "sem_future_tool", "context7_query_docs", "context7_future_tool"] |
    all(. as $action | $config | effect($action) == "allow")) and
  ([
    "grafana_get_dashboard_by_uid", "grafana_get_panel_image", "grafana_list_datasources",
    "grafana_search_dashboards", "grafana_query_prometheus", "grafana_query_prometheus_histogram",
    "grafana_query_loki_logs", "grafana_query_loki_patterns", "grafana_query_loki_stats",
    "grafana_query_cloudwatch", "grafana_query_cloud_logging", "grafana_query_graphite",
    "grafana_query_elasticsearch", "grafana_query_quickwit", "grafana_query_pyroscope",
    "grafana_run_panel_query", "grafana_alerting_manage_routing", "grafana_alerting_rules_read",
    "grafana_alerting_silences_read", "grafana_analyze_loki_labels", "grafana_check_datasources_health",
    "grafana_find_error_pattern_logs", "grafana_find_slow_requests",
    "grafana_suggest_loki_alloy_label_config", "grafana_validate_provisioning_file",
    "grafana_user_info", "grafana_generate_deeplink"
  ] | all(. as $action | $config | effect($action) == "allow")) and
  ([
    "grafana_add_activity_to_incident", "grafana_alerting_manage_rules",
    "grafana_alerting_rules_write", "grafana_alerting_routing_write", "grafana_alerting_silences_write",
    "grafana_create_annotation", "grafana_create_datasource", "grafana_create_folder",
    "grafana_create_incident", "grafana_create_snapshot", "grafana_delete_snapshot",
    "grafana_grafana_api_request", "grafana_install_plugin", "grafana_update_annotation",
    "grafana_update_dashboard", "grafana_update_datasource", "grafana_query_sql",
    "grafana_query_influxdb", "grafana_future_tool"
  ] | all(. as $action | $config | effect($action) == "ask"))
' "$CONFIG/opencode.jsonc" >/dev/null
test ! -e "$CONFIG/cli.json"
jq -e '.mcp.servers.sem.command == ["sem", "mcp"] and .mcp.servers.sem.disabled == false' \
  "$CONFIG/config.d/sem.jsonc" >/dev/null
test ! -e "$CONFIG/credentials/mcp-github-token"
jq -e '.agents.explore.model == "openai/gpt-6.1-terra#medium" and .agents.explore.permissions[0].action == "ast"' \
  "$CONFIG/config.d/explore.jsonc" >/dev/null
grep -qx '/home/dot_config/opencode/credentials/' "$SOURCE_DIR/.gitignore"

# Machine-local config, terminal preferences, native plugin files, service state,
# and credentials remain unmanaged through profile transitions.
printf '{"providers":{"local":{},"mlx":{"url":"http://127.0.0.1:8080/v1"}}}\n' >"$CONFIG/config.d/local.jsonc"
printf '{"mcp":{"servers":{"machine-local":{"type":"local","command":["local-service"]}}}}\n' >"$CONFIG/config.d/local-service.jsonc"
printf 'machine-local service state\n' >"$CONFIG/service.json"
# Upstream no longer manages CLI preferences, including local approval mode.
printf '{"theme":{"name":"local-theme"},"session":{"permissions":"autoaccept"}}\n' >"$CONFIG/cli.json"
mkdir -p "$CONFIG/credentials" "$CONFIG/plugins"
printf '// machine-local plugin, not managed\n' >"$CONFIG/plugins/local-test.js"
printf 'private-linear-client\n' >"$CONFIG/credentials/mcp-linear-client-id"
printf 'private-notion-client\n' >"$CONFIG/credentials/mcp-notion-client-id"
# Preserve legacy local credentials even though GitHub now uses the environment.
printf 'private-github-token\n' >"$CONFIG/credentials/mcp-github-token"
printf 'private-grafana-token\n' >"$CONFIG/credentials/local-grafana-token"
# Paths, rather than parsed JSON, protect formatting and opaque service state.
unmanaged_files=(cli.json config.d/local.jsonc config.d/local-service.jsonc
  plugins/local-test.js service.json credentials/mcp-linear-client-id
  credentials/mcp-notion-client-id credentials/mcp-github-token credentials/local-grafana-token)
for relative in "${unmanaged_files[@]}"; do
  mkdir -p "$TEST_ROOT/unmanaged/$(dirname "$relative")"
  cp "$CONFIG/$relative" "$TEST_ROOT/unmanaged/$relative"
done

# Every successful transition must preserve the complete local-state inventory.
assert_local_files() {
  local relative
  for relative in "${unmanaged_files[@]}"; do
    cmp "$TEST_ROOT/unmanaged/$relative" "$CONFIG/$relative"
  done
}

# Existing credentials must never opt an uninitialized machine into work. Then
# exercise base -> work -> base -> work, including actual Grafana deletion.
for profile in default work base work; do
  GITHUB_TOKEN=private-github-env-token apply_opencode "$TEST_ROOT/$profile.toml"
  expected_profile="$profile"
  [[ "$profile" == default ]] && expected_profile=base
  assert_profile "$expected_profile"
  assert_local_files
done
jq -e '
  .mcp.servers.linear.oauth.client_id == "{file:./credentials/mcp-linear-client-id}" and
  .mcp.servers.notion.oauth.client_id == "{file:./credentials/mcp-notion-client-id}"
' "$CONFIG/opencode.jsonc" >/dev/null
! grep -q 'private-.*-client' "$CONFIG/opencode.jsonc"
! grep -q 'private-github-token' "$CONFIG/config.d/github.jsonc"
! grep -q 'private-github-env-token' "$CONFIG/config.d/github.jsonc"

# Each OAuth file is optional independently and uses a reference, never its
# contents. Missing one must not suppress the other service's client reference.
rm "$CONFIG/credentials/mcp-notion-client-id"
apply_opencode
jq -e '
  .mcp.servers.linear.oauth.client_id == "{file:./credentials/mcp-linear-client-id}" and
  (.mcp.servers.notion | has("oauth") | not)
' "$CONFIG/opencode.jsonc" >/dev/null
cp "$TEST_ROOT/unmanaged/credentials/mcp-notion-client-id" "$CONFIG/credentials/mcp-notion-client-id"
apply_opencode
assert_local_files

# Reject invalid persisted data rather than silently selecting base or work.
cp "$CONFIG/opencode.jsonc" "$TEST_ROOT/before-profile-main.json"
cp "$CONFIG/config.d/grafana.jsonc" "$TEST_ROOT/before-profile-grafana.json"
for invalid in '"unknown"' '""' '42' 'true' '[]' '{}'; do
  printf '[data]\nprofile = %s\n' "$invalid" >"$TEST_ROOT/invalid-profile.toml"
  if apply_opencode "$TEST_ROOT/invalid-profile.toml" >"$TEST_ROOT/invalid-profile.log" 2>&1; then
    printf 'Invalid profile was accepted: %s\n' "$invalid" >&2
    exit 1
  fi
  grep -qi profile "$TEST_ROOT/invalid-profile.log"
  cmp "$TEST_ROOT/before-profile-main.json" "$CONFIG/opencode.jsonc"
  cmp "$TEST_ROOT/before-profile-grafana.json" "$CONFIG/config.d/grafana.jsonc"
done

printf 'OpenCode V2 base/work configuration checks passed\n'
