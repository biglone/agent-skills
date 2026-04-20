#!/usr/bin/env bash
set -euo pipefail

controller_url="http://127.0.0.1:9090"
group_name="🔰 选择节点"
config_path=""
test_url="https://www.gstatic.com/generate_204"
timeout_ms="6000"
dry_run=0
show_current=0
include_direct=0
top_n="10"

usage() {
  cat <<'EOF'
Usage:
  switch_fastest_node.sh [options]

Options:
  --group <name>          Selector group name (default: 🔰 选择节点)
  --controller <url>      Clash controller URL (default: http://127.0.0.1:9090)
  --config <path>         Config path for reading secret (auto-detect if omitted)
  --url <url>             Delay test URL (default: https://www.gstatic.com/generate_204)
  --timeout <ms>          Delay timeout in ms (default: 6000)
  --top <n>               Show top N fastest nodes (default: 10)
  --dry-run               Benchmark only, do not switch
  --show-current          Print current selected node and exit
  --include-direct        Include DIRECT and REJECT in benchmark
  -h, --help              Show help
EOF
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: command not found: $1" >&2
    exit 1
  fi
}

detect_config_path() {
  local candidates=(
    "/etc/clash/config.yaml"
    "/etc/mihomo/config.yaml"
    "$PWD/config.yaml"
    "$HOME/clash/config.yaml"
    "$HOME/.config/clash/config.yaml"
    "$HOME/.config/mihomo/config.yaml"
  )
  local candidate
  for candidate in "${candidates[@]}"; do
    if [ -f "$candidate" ]; then
      printf '%s' "$candidate"
      return 0
    fi
  done
  return 1
}

read_secret_from_config() {
  local config_file="$1"
  local value=""
  if [ -f "$config_file" ]; then
    value="$(sed -n 's/^[[:space:]]*secret:[[:space:]]*//p' "$config_file" | head -n 1 || true)"
    value="$(printf '%s' "$value" | sed -E 's/[[:space:]]+$//')"
    value="$(printf '%s' "$value" | sed -E "s/^['\\\"]//; s/['\\\"]$//")"
  fi
  printf '%s' "$value"
}

urlencode() {
  jq -rn --arg v "$1" '$v|@uri'
}

auth_headers=()
api_get() {
  local path="$1"
  curl -sS --fail "${auth_headers[@]}" "${controller_url}${path}"
}

api_put() {
  local path="$1"
  local body="$2"
  curl -sS --fail -X PUT "${auth_headers[@]}" -H "Content-Type: application/json" -d "$body" "${controller_url}${path}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --group)
      group_name="${2:-}"
      shift 2
      ;;
    --controller)
      controller_url="${2:-}"
      shift 2
      ;;
    --config)
      config_path="${2:-}"
      shift 2
      ;;
    --url)
      test_url="${2:-}"
      shift 2
      ;;
    --timeout)
      timeout_ms="${2:-}"
      shift 2
      ;;
    --top)
      top_n="${2:-}"
      shift 2
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    --show-current)
      show_current=1
      shift
      ;;
    --include-direct)
      include_direct=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! "$timeout_ms" =~ ^[0-9]+$ ]] || [ "$timeout_ms" -le 0 ]; then
  echo "ERROR: --timeout must be a positive integer" >&2
  exit 1
fi

if [[ ! "$top_n" =~ ^[0-9]+$ ]] || [ "$top_n" -le 0 ]; then
  echo "ERROR: --top must be a positive integer" >&2
  exit 1
fi

require_command curl
require_command jq

if [ -z "$config_path" ]; then
  config_path="$(detect_config_path || true)"
fi

if [ -n "$config_path" ] && [ ! -f "$config_path" ]; then
  echo "ERROR: config not found: $config_path" >&2
  exit 1
fi

secret_value=""
if [ -n "$config_path" ]; then
  secret_value="$(read_secret_from_config "$config_path")"
fi

if [ -n "$secret_value" ]; then
  auth_headers=(-H "Authorization: Bearer $secret_value")
fi

tmp_file="$(mktemp)"
err_file="$(mktemp)"
trap 'rm -f "$tmp_file" "$err_file"' EXIT

encoded_group="$(urlencode "$group_name")"
if ! group_json="$(api_get "/proxies/${encoded_group}" 2>"$err_file")"; then
  echo "无法访问分组: $group_name" >&2
  echo "可用分组如下:" >&2
  api_get "/proxies" \
    | jq -r '.proxies | to_entries[] | select(.value.type=="Selector" or .value.type=="URLTest" or .value.type=="Fallback" or .value.type=="LoadBalance") | .key' \
    | sed 's/^/- /' >&2
  echo "错误信息:" >&2
  cat "$err_file" >&2
  exit 2
fi

current_node="$(printf '%s' "$group_json" | jq -r '.now // empty')"
if [ "$show_current" -eq 1 ]; then
  echo "当前分组: $group_name"
  echo "当前节点: ${current_node:-<none>}"
  exit 0
fi

mapfile -t all_candidates < <(printf '%s' "$group_json" | jq -r '.all[]? // empty')
candidates=()
for node_name in "${all_candidates[@]}"; do
  if [ "$include_direct" -eq 0 ] && { [ "$node_name" = "DIRECT" ] || [ "$node_name" = "REJECT" ]; }; then
    continue
  fi
  candidates+=("$node_name")
done

if [ "${#candidates[@]}" -eq 0 ]; then
  echo "分组 '$group_name' 没有可测速候选节点。"
  exit 3
fi

encoded_test_url="$(urlencode "$test_url")"
best_node=""
best_delay=9999999

echo "当前分组: $group_name"
echo "当前节点: ${current_node:-<none>}"
echo "候选数量: ${#candidates[@]}"
echo
printf '%-4s %-10s %s\n' "NO" "DELAY" "NODE"

index=0
for node_name in "${candidates[@]}"; do
  index=$((index + 1))
  encoded_node="$(urlencode "$node_name")"
  delay=0
  if delay_json="$(api_get "/proxies/${encoded_node}/delay?timeout=${timeout_ms}&url=${encoded_test_url}" 2>/dev/null)"; then
    delay="$(printf '%s' "$delay_json" | jq -r '.delay // 0' 2>/dev/null || echo 0)"
  fi

  if [[ "$delay" =~ ^[0-9]+$ ]] && [ "$delay" -gt 0 ]; then
    printf '%-4s %-10sms %s\n' "$index" "$delay" "$node_name"
    printf '%s\t%s\n' "$delay" "$node_name" >>"$tmp_file"
    if [ "$delay" -lt "$best_delay" ]; then
      best_delay="$delay"
      best_node="$node_name"
    fi
  else
    printf '%-4s %-10s %s\n' "$index" "timeout" "$node_name"
  fi
done

if [ -z "$best_node" ]; then
  echo
  echo "没有测速成功的节点，未切换。"
  exit 4
fi

echo
echo "Top ${top_n} fastest:"
sort -n "$tmp_file" | head -n "$top_n" | awk -F'\t' '{printf "%-10sms %s\n",$1,$2}'

if [ "$dry_run" -eq 1 ]; then
  echo
  echo "Dry run completed,未执行切换。"
  exit 0
fi

if [ "$best_node" = "$current_node" ]; then
  echo
  echo "最快节点已是当前节点：$best_node (${best_delay}ms)"
  exit 0
fi

switch_body="$(jq -nc --arg name "$best_node" '{name:$name}')"
api_put "/proxies/${encoded_group}" "$switch_body" >/dev/null
new_now="$(api_get "/proxies/${encoded_group}" | jq -r '.now // empty')"

echo
echo "已切换: ${current_node:-<none>} -> ${new_now:-<none>}"
echo "最快延迟: ${best_delay}ms"
