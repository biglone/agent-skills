#!/bin/bash

# AI Coding Skills 安装脚本
# 支持 Claude Code 和 OpenAI Codex CLI
# 用法: curl -fsSL https://raw.githubusercontent.com/biglone/agent-skills/main/scripts/install.sh | bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || pwd)"

# 配置
REPO_URL="${SKILLS_REPO:-https://github.com/biglone/agent-skills.git}"
SKILLS_REF="${SKILLS_REF:-main}"
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
CODEX_SKILLS_DIR="$HOME/.codex/skills"
CLAUDE_WORKFLOWS_DIR="$HOME/.claude/workflows"
CODEX_WORKFLOWS_DIR="$HOME/.codex/workflows"
TEMP_DIR=$(mktemp -d)
CLAUDE_INSTALLED_REPORT="$TEMP_DIR/claude-installed-skills.txt"
CODEX_INSTALLED_REPORT="$TEMP_DIR/codex-installed-skills.txt"

# 安装目标 (claude, codex, both)
INSTALL_TARGET="${INSTALL_TARGET:-}"

# 更新模式 (ask, skip, force)
# ask: 询问用户是否更新已存在的 skill
# skip: 跳过已存在的 skill
# force: 强制更新所有 skill (默认)
UPDATE_MODE="${UPDATE_MODE:-force}"
DEBUG="${DEBUG:-0}"
NON_INTERACTIVE="${NON_INTERACTIVE:-0}"             # 1: 禁用交互输入
DRY_RUN="${DRY_RUN:-0}"                             # 1: 仅打印计划，不写入目标目录
SKILL_MARKET_DISCOVERY="${SKILL_MARKET_DISCOVERY:-off}"      # off/manifest/github/all
SKILL_MARKET_QUERIES="${SKILL_MARKET_QUERIES:-topic:agent-skills;topic:claude-code-skill;topic:codex-skill}"
SKILL_MARKET_PER_QUERY="${SKILL_MARKET_PER_QUERY:-10}"
SKILL_MARKET_MAX_REPOS="${SKILL_MARKET_MAX_REPOS:-5}"
SKILL_MARKET_MIN_STARS="${SKILL_MARKET_MIN_STARS:-10}"
SKILL_MARKET_EXTRA_REPOS="${SKILL_MARKET_EXTRA_REPOS:-}"     # 逗号分隔，支持 owner/repo 或 URL
SKILL_MARKET_ALLOWLIST="${SKILL_MARKET_ALLOWLIST:-}"         # 逗号/换行分隔，空表示不过滤
SKILL_MARKET_CONFLICT_MODE="${SKILL_MARKET_CONFLICT_MODE:-skip}"  # skip/replace/merge
SKILL_MARKET_SOURCE_MARK_FILE="${SKILL_MARKET_SOURCE_MARK_FILE:-.agent-skills-source}"
SKILL_MARKET_MERGED_FILE_NAME="${SKILL_MARKET_MERGED_FILE_NAME:-SKILL.merged.md}"
SKILL_MARKET_MERGE_REPORT_FILE_NAME="${SKILL_MARKET_MERGE_REPORT_FILE_NAME:-SKILL.merge-report.md}"
SKILL_MARKET_MERGE_SOURCE_DIR="${SKILL_MARKET_MERGE_SOURCE_DIR:-.agent-skills-merge-sources}"
SKILL_MARKET_MERGE_APPLY_MODE="${SKILL_MARKET_MERGE_APPLY_MODE:-preview}"  # preview/apply
SKILL_MARKET_MERGE_BACKUP_FILE_NAME="${SKILL_MARKET_MERGE_BACKUP_FILE_NAME:-SKILL.pre-merge.backup.md}"
SKILL_MARKET_MERGE_SOURCE_RETENTION_COUNT="${SKILL_MARKET_MERGE_SOURCE_RETENTION_COUNT:-5}"
SKILL_MARKET_MERGE_SOURCE_RETENTION_DAYS="${SKILL_MARKET_MERGE_SOURCE_RETENTION_DAYS:-30}"
CODEX_AUTO_UPDATE_SETUP="${CODEX_AUTO_UPDATE_SETUP:-on}"   # on/off: 是否自动配置 codex 启动前 skills 更新检查
CODEX_AUTO_UPDATE_REPO="${CODEX_AUTO_UPDATE_REPO:-}"       # owner/repo，默认根据 SKILLS_REPO 推断
CODEX_AUTO_UPDATE_BRANCH="${CODEX_AUTO_UPDATE_BRANCH:-$SKILLS_REF}"
CODEX_LOCAL_VERSION_FILE="${HOME}/.codex/.skills_version"
CODEX_AUTO_UPDATE_LOADER="${HOME}/.codex/codex-skills-auto-update.sh"
SKILLS_MANIFEST_FILE=""
WORKFLOWS_MANIFEST_FILE=""
MARKET_REPO_SEED_FILE=""
MARKET_CANDIDATES_FILE="$TEMP_DIR/market-repo-candidates.txt"
PRIMARY_REPO_SLUG=""
MERGE_SKILL_SCRIPT_PATH=""
SKILL_MARKET_ALLOWLIST_CSV=""
ASK_FALLBACK_WARNED=0

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    if [ "$DEBUG" = "1" ]; then
        echo -e "${CYAN}[DEBUG]${NC} $1"
    fi
}

usage() {
    cat <<'EOF'
Usage: install.sh [options]

Options:
  --non-interactive    Disable prompts and use defaults/env values.
  --dry-run            Print planned actions without writing target dirs.
  -h, --help           Show this help message.

Env:
  INSTALL_TARGET       claude | codex | both
  UPDATE_MODE          ask | skip | force
  SKILLS_REPO          Git repository URL
  SKILLS_REF           Branch/tag/commit-ish to install from (default: main)
  SKILL_MARKET_DISCOVERY    off | manifest | github | all
  SKILL_MARKET_EXTRA_REPOS  owner/repo,owner/repo
  SKILL_MARKET_ALLOWLIST    owner/repo,owner/repo
  SKILL_MARKET_CONFLICT_MODE skip | replace | merge
  SKILL_MARKET_MERGE_APPLY_MODE preview | apply
EOF
}

parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --non-interactive) NON_INTERACTIVE=1 ;;
            --dry-run) DRY_RUN=1 ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                usage
                exit 1
                ;;
        esac
        shift
    done
}

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

is_truthy() {
    case "${1:-}" in
        1|true|TRUE|yes|YES|on|ON) return 0 ;;
        *) return 1 ;;
    esac
}

resolve_github_repo_slug() {
    local input="$1"
    local slug=""

    if printf '%s' "$input" | grep -Eq '^https://github\.com/[^/]+/[^/]+(\.git)?/?$'; then
        slug="$(printf '%s' "$input" | sed -E 's#^https://github\.com/##; s#/$##; s/\.git$//')"
    elif printf '%s' "$input" | grep -Eq '^git@github\.com:[^/]+/[^/]+(\.git)?$'; then
        slug="$(printf '%s' "$input" | sed -E 's#^git@github\.com:##; s/\.git$//')"
    elif printf '%s' "$input" | grep -Eq '^ssh://git@github\.com/[^/]+/[^/]+(\.git)?/?$'; then
        slug="$(printf '%s' "$input" | sed -E 's#^ssh://git@github\.com/##; s/\.git$//')"
    elif printf '%s' "$input" | grep -Eq '^[^/]+/[^/]+$'; then
        slug="$input"
    fi

    printf '%s' "$slug"
}

trim_line() {
    printf '%s' "$1" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'
}

is_positive_integer() {
    printf '%s' "${1:-}" | grep -Eq '^[1-9][0-9]*$'
}

is_non_negative_integer() {
    printf '%s' "${1:-}" | grep -Eq '^[0-9]+$'
}

build_market_allowlist_csv() {
    local raw item slug lowered
    local seen_file="$TEMP_DIR/market-allowlist.tmp"
    : > "$seen_file"

    raw="$(printf '%s' "$SKILL_MARKET_ALLOWLIST" | tr ',;\t' '\n')"
    while IFS= read -r item; do
        item="$(trim_line "$item")"
        [ -z "$item" ] && continue

        slug="$(resolve_github_repo_slug "$item")"
        if [ -z "$slug" ]; then
            log_warn "[market] allowlist 项无效，已忽略: $item"
            continue
        fi

        lowered="$(printf '%s' "$slug" | tr '[:upper:]' '[:lower:]')"
        if ! grep -Fqx "$lowered" "$seen_file"; then
            printf '%s\n' "$lowered" >> "$seen_file"
        fi
    done <<< "$raw"

    if [ -s "$seen_file" ]; then
        SKILL_MARKET_ALLOWLIST_CSV="$(paste -sd',' "$seen_file")"
    else
        SKILL_MARKET_ALLOWLIST_CSV=""
    fi
}

validate_update_mode() {
    case "$UPDATE_MODE" in
        ask|skip|force) ;;
        *)
            log_error "UPDATE_MODE 无效: ${UPDATE_MODE}（可选 ask/skip/force）"
            exit 1
            ;;
    esac
}

validate_install_target() {
    case "$INSTALL_TARGET" in
        ""|claude|codex|both) ;;
        *)
            log_error "INSTALL_TARGET 无效: ${INSTALL_TARGET}（可选 claude/codex/both）"
            exit 1
            ;;
    esac
}

validate_market_config() {
    case "$SKILL_MARKET_DISCOVERY" in
        off|manifest|github|all) ;;
        *)
            log_error "SKILL_MARKET_DISCOVERY 无效: ${SKILL_MARKET_DISCOVERY}（可选 off/manifest/github/all）"
            exit 1
            ;;
    esac

    case "$SKILL_MARKET_CONFLICT_MODE" in
        skip|replace|merge) ;;
        *)
            log_error "SKILL_MARKET_CONFLICT_MODE 无效: ${SKILL_MARKET_CONFLICT_MODE}（可选 skip/replace/merge）"
            exit 1
            ;;
    esac

    case "$SKILL_MARKET_MERGE_APPLY_MODE" in
        preview|apply) ;;
        *)
            log_error "SKILL_MARKET_MERGE_APPLY_MODE 无效: ${SKILL_MARKET_MERGE_APPLY_MODE}（可选 preview/apply）"
            exit 1
            ;;
    esac

    if ! is_positive_integer "$SKILL_MARKET_PER_QUERY"; then
        log_error "SKILL_MARKET_PER_QUERY 必须是正整数（当前: $SKILL_MARKET_PER_QUERY）"
        exit 1
    fi
    if ! is_positive_integer "$SKILL_MARKET_MAX_REPOS"; then
        log_error "SKILL_MARKET_MAX_REPOS 必须是正整数（当前: $SKILL_MARKET_MAX_REPOS）"
        exit 1
    fi
    if ! is_non_negative_integer "$SKILL_MARKET_MIN_STARS"; then
        log_error "SKILL_MARKET_MIN_STARS 必须是非负整数（当前: $SKILL_MARKET_MIN_STARS）"
        exit 1
    fi
    if ! is_positive_integer "$SKILL_MARKET_MERGE_SOURCE_RETENTION_COUNT"; then
        log_error "SKILL_MARKET_MERGE_SOURCE_RETENTION_COUNT 必须是正整数（当前: $SKILL_MARKET_MERGE_SOURCE_RETENTION_COUNT）"
        exit 1
    fi
    if ! is_non_negative_integer "$SKILL_MARKET_MERGE_SOURCE_RETENTION_DAYS"; then
        log_error "SKILL_MARKET_MERGE_SOURCE_RETENTION_DAYS 必须是非负整数（当前: $SKILL_MARKET_MERGE_SOURCE_RETENTION_DAYS）"
        exit 1
    fi

    build_market_allowlist_csv
}

read_manifest_entries() {
    local manifest_file="$1"
    while IFS= read -r line; do
        local item
        item="$(printf '%s' "$line" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
        [ -z "$item" ] && continue
        case "$item" in \#*) continue ;; esac
        printf '%s\n' "$item"
    done < "$manifest_file"
}

set_manifests() {
    SKILLS_MANIFEST_FILE="$TEMP_DIR/skills-repo/scripts/manifest/skills.txt"
    WORKFLOWS_MANIFEST_FILE="$TEMP_DIR/skills-repo/scripts/manifest/workflows.txt"

    if [ ! -f "$SKILLS_MANIFEST_FILE" ]; then
        log_error "skills manifest 不存在: $SKILLS_MANIFEST_FILE"
        exit 1
    fi
    if [ ! -f "$WORKFLOWS_MANIFEST_FILE" ]; then
        log_warn "workflows manifest 不存在: $WORKFLOWS_MANIFEST_FILE"
    fi

    MARKET_REPO_SEED_FILE="$TEMP_DIR/skills-repo/scripts/manifest/market-seed-repos.txt"

    MERGE_SKILL_SCRIPT_PATH="$TEMP_DIR/skills-repo/scripts/merge-skill.py"
    if [ ! -f "$MERGE_SKILL_SCRIPT_PATH" ] && [ -f "$SCRIPT_DIR/merge-skill.py" ]; then
        MERGE_SKILL_SCRIPT_PATH="$SCRIPT_DIR/merge-skill.py"
    fi
}

resolve_repo_spec() {
    local raw_spec
    local spec
    local slug=""
    local clone_url=""
    local ref="main"
    raw_spec="${1:-}"
    spec="$(trim_line "$raw_spec")"
    [ -z "$spec" ] && return 1

    if printf '%s' "$spec" | grep -Eq '^[^/@]+/[^/@]+@[^[:space:]]+$'; then
        ref="${spec##*@}"
        spec="${spec%@*}"
    fi

    slug="$(resolve_github_repo_slug "$spec")"
    [ -n "$slug" ] || return 1

    if printf '%s' "$spec" | grep -Eq '^https://github\.com/'; then
        clone_url="$(printf '%s' "$spec" | sed -E 's#/$##')"
        if ! printf '%s' "$clone_url" | grep -Eq '\.git$'; then
            clone_url="${clone_url}.git"
        fi
    elif printf '%s' "$spec" | grep -Eq '^git@github\.com:|^ssh://git@github\.com/'; then
        clone_url="$spec"
    else
        clone_url="https://github.com/${slug}.git"
    fi

    printf '%s|%s|%s\n' "$slug" "$clone_url" "$ref"
}

append_market_candidate() {
    local output_file="$1"
    local slug="$2"
    local clone_url="$3"
    local ref="$4"
    local stars="${5:-0}"
    local source="$6"
    printf '%s|%s|%s|%s|%s\n' "$slug" "$clone_url" "$ref" "$stars" "$source" >> "$output_file"
}

collect_manifest_market_candidates() {
    local output_file="$1"
    local entry

    [ -f "$MARKET_REPO_SEED_FILE" ] || return 0

    while IFS= read -r entry; do
        entry="$(trim_line "$entry")"
        [ -z "$entry" ] && continue
        case "$entry" in \#*) continue ;; esac

        local resolved=""
        resolved="$(resolve_repo_spec "$entry" || true)"
        if [ -z "$resolved" ]; then
            log_warn "[market] 无法识别 seed 仓库: $entry"
            continue
        fi

        local slug clone_url ref
        IFS='|' read -r slug clone_url ref <<< "$resolved"
        append_market_candidate "$output_file" "$slug" "$clone_url" "$ref" "0" "manifest"
    done < "$MARKET_REPO_SEED_FILE"
    return 0
}

collect_extra_market_candidates() {
    local output_file="$1"
    local spec
    local resolved=""
    local normalized_list

    normalized_list="$(printf '%s' "$SKILL_MARKET_EXTRA_REPOS" | tr ',' '\n')"
    while IFS= read -r spec; do
        spec="$(trim_line "$spec")"
        [ -z "$spec" ] && continue

        resolved="$(resolve_repo_spec "$spec" || true)"
        if [ -z "$resolved" ]; then
            log_warn "[market] 无法识别额外仓库: $spec"
            continue
        fi

        local slug clone_url ref
        IFS='|' read -r slug clone_url ref <<< "$resolved"
        append_market_candidate "$output_file" "$slug" "$clone_url" "$ref" "0" "extra"
    done <<< "$normalized_list"
    return 0
}

discover_github_market_candidates() {
    local output_file="$1"
    local query
    local encoded_query
    local api_url
    local response
    local parsed_count=0
    local auth_header=""

    if ! command -v curl &> /dev/null; then
        log_warn "[market] 未检测到 curl，跳过 GitHub 热门仓库发现"
        return
    fi
    if ! command -v python3 &> /dev/null; then
        log_warn "[market] 未检测到 python3，跳过 GitHub 热门仓库发现"
        return
    fi

    if [ -n "${GITHUB_TOKEN:-}" ]; then
        auth_header="Authorization: Bearer ${GITHUB_TOKEN}"
    fi

    IFS=';' read -r -a queries <<< "$SKILL_MARKET_QUERIES"
    for query in "${queries[@]}"; do
        query="$(trim_line "$query")"
        [ -z "$query" ] && continue

        encoded_query="$(python3 - "$query" <<'PY'
import sys
import urllib.parse
print(urllib.parse.quote(sys.argv[1], safe=""))
PY
)"
        api_url="https://api.github.com/search/repositories?q=${encoded_query}&sort=stars&order=desc&per_page=${SKILL_MARKET_PER_QUERY}"
        log_debug "[market] GitHub 搜索: $query"

        if [ -n "$auth_header" ]; then
            response="$(curl -fsSL --max-time 20 -H "$auth_header" "$api_url" 2>/dev/null || true)"
        else
            response="$(curl -fsSL --max-time 20 "$api_url" 2>/dev/null || true)"
        fi
        if [ -z "$response" ]; then
            log_warn "[market] GitHub 查询失败: $query"
            continue
        fi

        while IFS='|' read -r slug clone_url ref stars; do
            [ -z "$slug" ] && continue
            append_market_candidate "$output_file" "$slug" "$clone_url" "$ref" "$stars" "github"
            parsed_count=$((parsed_count + 1))
        done < <(printf '%s' "$response" | python3 - <<'PY'
import json
import sys

try:
    payload = json.load(sys.stdin)
except Exception:
    sys.exit(0)

for item in payload.get("items", []):
    slug = item.get("full_name") or ""
    clone_url = item.get("clone_url") or ""
    default_branch = item.get("default_branch") or "main"
    stars = item.get("stargazers_count") or 0
    if slug and clone_url:
        print(f"{slug}|{clone_url}|{default_branch}|{stars}")
PY
)
    done

    if [ "$parsed_count" -eq 0 ]; then
        log_warn "[market] GitHub 查询无可用结果（可能受 API 频率限制，可设置 GITHUB_TOKEN）"
    fi
}

finalize_market_candidates() {
    local raw_file="$1"
    local output_file="$2"

    if [ ! -s "$raw_file" ]; then
        : > "$output_file"
        return
    fi

    awk -F'|' -v min_stars="$SKILL_MARKET_MIN_STARS" -v primary="$PRIMARY_REPO_SLUG" -v allowlist_csv="$SKILL_MARKET_ALLOWLIST_CSV" '
        BEGIN {
            allowlist_enabled = (allowlist_csv != "")
            if (allowlist_enabled) {
                split(allowlist_csv, allowlist_arr, ",")
                for (i in allowlist_arr) {
                    allow_map[allowlist_arr[i]] = 1
                }
            }
        }
        {
            slug_lc = tolower($1)
            slug=$1
            clone_url=$2
            ref=$3
            stars=$4 + 0
            source=$5

            if (allowlist_enabled && !(slug_lc in allow_map)) next

            if (slug == "" || clone_url == "") next
            if (slug == primary) next
            if (source == "github" && stars < min_stars) next

            if (!(slug in best_line) || stars > best_stars[slug]) {
                best_line[slug]=$0
                best_stars[slug]=stars
            }
        }
        END {
            for (slug in best_line) {
                print best_line[slug]
            }
        }
    ' "$raw_file" | sort -t'|' -k4,4nr | head -n "$SKILL_MARKET_MAX_REPOS" > "$output_file"
}

collect_market_repo_candidates() {
    local raw_file="$TEMP_DIR/market-repo-candidates.raw"
    : > "$raw_file"
    : > "$MARKET_CANDIDATES_FILE"

    if [ "$SKILL_MARKET_DISCOVERY" = "off" ]; then
        return
    fi

    if [ "$SKILL_MARKET_DISCOVERY" = "manifest" ] || [ "$SKILL_MARKET_DISCOVERY" = "all" ]; then
        collect_manifest_market_candidates "$raw_file"
    fi

    if [ "$SKILL_MARKET_DISCOVERY" = "github" ] || [ "$SKILL_MARKET_DISCOVERY" = "all" ]; then
        discover_github_market_candidates "$raw_file"
    fi

    collect_extra_market_candidates "$raw_file"
    finalize_market_candidates "$raw_file" "$MARKET_CANDIDATES_FILE"
}

collect_repo_skill_entries() {
    local repo_dir="$1"
    local manifest_file="$repo_dir/scripts/manifest/skills.txt"
    local skills_dir="$repo_dir/skills"

    if [ -f "$manifest_file" ]; then
        read_manifest_entries "$manifest_file"
        return
    fi

    [ -d "$skills_dir" ] || return

    find "$skills_dir" -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null | while IFS= read -r skill_path; do
        [ -f "$skill_path/SKILL.md" ] || continue
        basename "$skill_path"
    done | sort
}

read_skill_source_slug() {
    local skill_dir="$1"
    local source_file="$skill_dir/$SKILL_MARKET_SOURCE_MARK_FILE"
    if [ ! -f "$source_file" ]; then
        return
    fi
    grep '^repo_slug=' "$source_file" 2>/dev/null | head -1 | cut -d'=' -f2-
}

write_skill_source_metadata() {
    local skill_dir="$1"
    local repo_slug="$2"
    local repo_url="$3"
    local repo_ref="$4"
    local source_file="$skill_dir/$SKILL_MARKET_SOURCE_MARK_FILE"

    cat > "$source_file" <<EOF
repo_slug=$repo_slug
repo_url=$repo_url
repo_ref=$repo_ref
synced_at=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
EOF
}

sanitize_path_token() {
    printf '%s' "$1" | sed -E 's#[^A-Za-z0-9._-]+#_#g'
}

cleanup_merge_source_snapshots() {
    local merge_root="$1"
    local max_count="$2"
    local max_days="$3"
    local idx=0
    local old_ifs="$IFS"

    [ -d "$merge_root" ] || return 0

    if is_non_negative_integer "$max_days" && [ "$max_days" -gt 0 ]; then
        find "$merge_root" -mindepth 1 -maxdepth 1 -type d -mtime +"$max_days" -exec rm -rf {} + 2>/dev/null || true
    fi

    if ! is_positive_integer "$max_count"; then
        return 0
    fi

    IFS=$'\n'
    for dir in $(ls -1dt "$merge_root"/* 2>/dev/null || true); do
        idx=$((idx + 1))
        if [ "$idx" -le "$max_count" ]; then
            continue
        fi
        rm -rf "$dir"
    done
    IFS="$old_ifs"
    return 0
}

merge_market_skill_in_place() {
    local skill_target="$1"
    local incoming_skill="$2"
    local repo_slug="$3"
    local repo_url="$4"
    local repo_ref="$5"
    local target_name="$6"
    local skill_name="$7"
    local base_skill_md="$skill_target/SKILL.md"
    local incoming_skill_md="$incoming_skill/SKILL.md"
    local merged_skill_md="$skill_target/$SKILL_MARKET_MERGED_FILE_NAME"
    local merge_report_md="$skill_target/$SKILL_MARKET_MERGE_REPORT_FILE_NAME"
    local source_tag
    local merge_source_dir
    local merge_source_root
    local merge_backup_md
    local merge_action_label="已融合"

    source_tag="$(sanitize_path_token "$repo_slug")"
    merge_source_root="$skill_target/$SKILL_MARKET_MERGE_SOURCE_DIR"
    merge_source_dir="$merge_source_root/$source_tag"
    merge_backup_md="$skill_target/$SKILL_MARKET_MERGE_BACKUP_FILE_NAME"

    if [ ! -f "$base_skill_md" ]; then
        log_warn "[${target_name}][market:${repo_slug}] 无法融合 ${skill_name}：本地缺少 SKILL.md"
        return 1
    fi
    if [ ! -f "$incoming_skill_md" ]; then
        log_warn "[${target_name}][market:${repo_slug}] 无法融合 ${skill_name}：外部缺少 SKILL.md"
        return 1
    fi
    if ! command -v python3 &> /dev/null; then
        log_warn "[${target_name}][market:${repo_slug}] 无法融合 ${skill_name}：未检测到 python3"
        return 1
    fi
    if [ ! -f "$MERGE_SKILL_SCRIPT_PATH" ]; then
        log_warn "[${target_name}][market:${repo_slug}] 无法融合 ${skill_name}：merge 脚本缺失"
        return 1
    fi

    rm -rf "$merge_source_dir"
    mkdir -p "$merge_source_root"
    cp -r "$incoming_skill" "$merge_source_dir"
    cleanup_merge_source_snapshots "$merge_source_root" "$SKILL_MARKET_MERGE_SOURCE_RETENTION_COUNT" "$SKILL_MARKET_MERGE_SOURCE_RETENTION_DAYS"

    if ! python3 "$MERGE_SKILL_SCRIPT_PATH" \
        --base "$base_skill_md" \
        --incoming "$incoming_skill_md" \
        --output "$merged_skill_md" \
        --report "$merge_report_md" \
        --source "$repo_slug"; then
        log_warn "[$target_name][market:$repo_slug] 融合失败: $skill_name"
        return 1
    fi

    cat > "$skill_target/.agent-skills-merge-source" <<EOF
repo_slug=$repo_slug
repo_url=$repo_url
repo_ref=$repo_ref
merged_at=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
merged_file=$SKILL_MARKET_MERGED_FILE_NAME
report_file=$SKILL_MARKET_MERGE_REPORT_FILE_NAME
source_snapshot_dir=$SKILL_MARKET_MERGE_SOURCE_DIR/$source_tag
apply_mode=$SKILL_MARKET_MERGE_APPLY_MODE
EOF

    if [ "$SKILL_MARKET_MERGE_APPLY_MODE" = "apply" ]; then
        cp "$base_skill_md" "$merge_backup_md"
        cp "$merged_skill_md" "$base_skill_md"
        merge_action_label="已融合并应用"
    fi

    log_info "[$target_name][market:$repo_slug] ${merge_action_label}: $skill_name -> $SKILL_MARKET_MERGED_FILE_NAME"
    return 0
}

install_market_skills_from_repo_to_dir() {
    local repo_dir="$1"
    local repo_slug="$2"
    local repo_url="$3"
    local repo_ref="$4"
    local target_dir="$5"
    local target_name="$6"
    local report_file="$7"

    local source_dir="$repo_dir/skills"
    [ -d "$source_dir" ] || {
        log_warn "[$target_name][market:$repo_slug] 未找到 skills 目录，跳过"
        return
    }

    while IFS= read -r skill_name; do
        [ -z "$skill_name" ] && continue
        local skill="$source_dir/$skill_name"
        local skill_target="$target_dir/$skill_name"
        local should_apply=0
        local should_merge=0
        local action_label="安装"
        local changed=0

        [ -d "$skill" ] || continue

        if [ -d "$skill_target" ]; then
            local existing_slug=""
            existing_slug="$(read_skill_source_slug "$skill_target" || true)"

            if [ "$existing_slug" = "$repo_slug" ]; then
                if ask_update_skill "$skill_name" "$target_name"; then
                    should_apply=1
                    action_label="更新"
                else
                    log_warn "[$target_name][market:$repo_slug] 跳过: $skill_name"
                fi
            else
                case "$SKILL_MARKET_CONFLICT_MODE" in
                    replace)
                        if ask_update_skill "$skill_name" "$target_name"; then
                            should_apply=1
                            action_label="覆盖"
                        else
                            log_warn "[$target_name][market:$repo_slug] 跳过冲突 skill: $skill_name"
                        fi
                        ;;
                    merge)
                        if ask_update_skill "$skill_name" "$target_name"; then
                            should_merge=1
                            action_label="融合"
                        else
                            log_warn "[$target_name][market:$repo_slug] 跳过融合 skill: $skill_name"
                        fi
                        ;;
                    *)
                        log_warn "[${target_name}][market:${repo_slug}] 跳过冲突 skill: ${skill_name}（已存在且来源不同）"
                        ;;
                esac
            fi
        else
            should_apply=1
        fi

        if [ "$should_apply" -eq 0 ] && [ "$should_merge" -eq 0 ]; then
            continue
        fi

        if [ "$DRY_RUN" = "1" ]; then
            log_info "[DRY-RUN][$target_name][market:$repo_slug] 将${action_label}: $skill_name"
            changed=1
        else
            if [ "$should_merge" -eq 1 ]; then
                if merge_market_skill_in_place "$skill_target" "$skill" "$repo_slug" "$repo_url" "$repo_ref" "$target_name" "$skill_name"; then
                    changed=1
                fi
            else
                rm -rf "$skill_target"
                cp -r "$skill" "$target_dir/"
                write_skill_source_metadata "$skill_target" "$repo_slug" "$repo_url" "$repo_ref"
                log_info "[$target_name][market:$repo_slug] 已${action_label}: $skill_name"
                changed=1
            fi
        fi

        if [ "$changed" -eq 1 ]; then
            echo "$skill_name" >> "$report_file"
        fi
    done < <(collect_repo_skill_entries "$repo_dir")
    return 0
}

sync_market_skills() {
    local mode="$SKILL_MARKET_DISCOVERY"
    local repo_line
    local repo_index=0

    if [ "$mode" = "off" ]; then
        return
    fi

    collect_market_repo_candidates
    if [ ! -s "$MARKET_CANDIDATES_FILE" ]; then
        log_warn "[market] 未发现可同步的外部 skill 仓库"
        return
    fi

    log_info "[market] 已启用外部 skill 市场同步（mode=${mode}）"

    while IFS='|' read -r repo_slug repo_url repo_ref repo_stars repo_source; do
        [ -z "$repo_slug" ] && continue
        repo_index=$((repo_index + 1))
        local repo_dir="$TEMP_DIR/market-repo-${repo_index}"

        log_info "[market] 同步仓库: $repo_slug (source=$repo_source stars=$repo_stars ref=$repo_ref)"
        if ! git clone --depth 1 --branch "$repo_ref" "$repo_url" "$repo_dir" >/dev/null 2>&1; then
            rm -rf "$repo_dir"
            if ! git clone --depth 1 "$repo_url" "$repo_dir" >/dev/null 2>&1; then
                log_warn "[market] 克隆失败，跳过: $repo_slug"
                continue
            fi
        fi

        if [ "$INSTALL_TARGET" = "claude" ] || [ "$INSTALL_TARGET" = "both" ]; then
            install_market_skills_from_repo_to_dir "$repo_dir" "$repo_slug" "$repo_url" "$repo_ref" "$CLAUDE_SKILLS_DIR" "Claude Code" "$CLAUDE_INSTALLED_REPORT"
        fi

        if [ "$INSTALL_TARGET" = "codex" ] || [ "$INSTALL_TARGET" = "both" ]; then
            install_market_skills_from_repo_to_dir "$repo_dir" "$repo_slug" "$repo_url" "$repo_ref" "$CODEX_SKILLS_DIR" "Codex CLI" "$CODEX_INSTALLED_REPORT"
        fi
    done < "$MARKET_CANDIDATES_FILE"
    return 0
}

upsert_shell_source_block() {
    local profile="$1"
    local start_marker="# >>> agent-skills codex auto-update >>>"
    local end_marker="# <<< agent-skills codex auto-update <<<"
    local source_line='[ -f "$HOME/.codex/codex-skills-auto-update.sh" ] && source "$HOME/.codex/codex-skills-auto-update.sh"'
    local tmp_file="${profile}.tmp.$$"

    mkdir -p "$(dirname "$profile")"
    [ -f "$profile" ] || touch "$profile"

    if grep -Fq "$start_marker" "$profile"; then
        awk -v start="$start_marker" -v end="$end_marker" -v line="$source_line" '
            $0 == start {
                print
                print line
                in_block = 1
                next
            }
            $0 == end {
                in_block = 0
                print
                next
            }
            !in_block { print }
        ' "$profile" > "$tmp_file"
        mv "$tmp_file" "$profile"
    else
        {
            echo ""
            echo "$start_marker"
            echo "$source_line"
            echo "$end_marker"
        } >> "$profile"
    fi
}

sync_codex_local_version() {
    local version_file="$TEMP_DIR/skills-repo/scripts/manifest/version.txt"
    local version=""

    if [ -f "$version_file" ]; then
        version="$(tr -d '[:space:]' < "$version_file")"
    fi

    # 回退到 commit hash，避免缺失 version 文件时失效
    if [ -z "$version" ]; then
        version="$(git -C "$TEMP_DIR/skills-repo" rev-parse --short=12 HEAD 2>/dev/null || true)"
    fi

    if [ -z "$version" ]; then
        log_warn "[Codex CLI] 无法写入本地 skills 版本（version/commit 均不可用）"
        return
    fi

    mkdir -p "$(dirname "$CODEX_LOCAL_VERSION_FILE")"
    printf '%s\n' "$version" > "$CODEX_LOCAL_VERSION_FILE"
    log_info "[Codex CLI] 已写入本地 skills 版本: $version"
}

configure_codex_auto_update_launcher() {
    local repo_slug="${CODEX_AUTO_UPDATE_REPO}"

    if ! is_truthy "$CODEX_AUTO_UPDATE_SETUP"; then
        log_info "[Codex CLI] 跳过自动更新启动器配置（CODEX_AUTO_UPDATE_SETUP=${CODEX_AUTO_UPDATE_SETUP}）"
        return
    fi

    if ! command -v curl &> /dev/null; then
        log_warn "[Codex CLI] 未检测到 curl，无法配置自动更新启动器"
        return
    fi

    if [ -z "$repo_slug" ]; then
        repo_slug="$(resolve_github_repo_slug "$REPO_URL")"
    fi
    if [ -z "$repo_slug" ]; then
        repo_slug="biglone/agent-skills"
        log_warn "[Codex CLI] 无法从 SKILLS_REPO 推断 GitHub 仓库，已回退为: $repo_slug"
    fi

    mkdir -p "$(dirname "$CODEX_AUTO_UPDATE_LOADER")"
    cat > "$CODEX_AUTO_UPDATE_LOADER" <<EOF
# Auto-generated by agent-skills/scripts/install.sh
# Set CODEX_SKILLS_AUTO_UPDATE=0 to disable auto update checks.
codex() {
  local repo="${repo_slug}"
  local branch="${CODEX_AUTO_UPDATE_BRANCH}"
  local version_url="https://raw.githubusercontent.com/\${repo}/\${branch}/scripts/manifest/version.txt"
  local install_url="https://raw.githubusercontent.com/\${repo}/\${branch}/scripts/install.sh"
  local local_ver_file="\$HOME/.codex/.skills_version"
  local remote_ver local_ver

  if [ "\${CODEX_SKILLS_AUTO_UPDATE:-1}" = "0" ]; then
    command codex "\$@"
    return
  fi

  remote_ver="\$(curl -fsSL --max-time 5 "\$version_url" 2>/dev/null | tr -d '[:space:]' || true)"
  local_ver="\$(cat "\$local_ver_file" 2>/dev/null | tr -d '[:space:]' || true)"

  if [ -n "\$remote_ver" ] && [ "\$remote_ver" != "\$local_ver" ]; then
    echo "[skills] update \$local_ver -> \$remote_ver"
    if curl -fsSL --max-time 20 "\$install_url" | UPDATE_MODE=force INSTALL_TARGET=codex CODEX_AUTO_UPDATE_SETUP=off SKILLS_REF="\$branch" bash; then
      printf '%s\n' "\$remote_ver" > "\$local_ver_file"
    else
      echo "[skills] auto-update failed, continue launching codex" >&2
    fi
  fi

  command codex "\$@"
}
EOF

    upsert_shell_source_block "$HOME/.bashrc"
    upsert_shell_source_block "$HOME/.zshrc"

    log_info "[Codex CLI] 已配置 codex 启动前自动检查 skills 更新"
    log_info "[Codex CLI] 配置文件: $CODEX_AUTO_UPDATE_LOADER"
}

check_git() {
    if ! command -v git &> /dev/null; then
        log_error "Git 未安装，请先安装 Git"
        exit 1
    fi
}

select_target() {
    if [ -n "$INSTALL_TARGET" ]; then
        INSTALL_TARGET="$(printf '%s' "$INSTALL_TARGET" | tr '[:upper:]' '[:lower:]')"
        validate_install_target
        return
    fi

    if [ "$NON_INTERACTIVE" = "1" ]; then
        INSTALL_TARGET="both"
        log_info "非交互模式：默认安装到两者（INSTALL_TARGET=both）"
        return
    fi

    # 检查是否有可用的终端输入
    if [ ! -t 0 ] && [ ! -r /dev/tty ]; then
        log_warn "无法获取用户输入，默认安装到两者"
        INSTALL_TARGET="both"
        return
    fi

    echo -e "${CYAN}请选择安装目标:${NC}"
    echo "  1) Claude Code"
    echo "  2) OpenAI Codex CLI"
    echo "  3) 两者都安装"
    echo ""
    # 从 /dev/tty 读取，支持 curl | bash 方式
    read -p "请输入选项 [1-3] (默认: 3): " choice </dev/tty

    case "$choice" in
        1) INSTALL_TARGET="claude" ;;
        2) INSTALL_TARGET="codex" ;;
        3|"") INSTALL_TARGET="both" ;;
        *)
            log_warn "无效选项，默认安装到两者"
            INSTALL_TARGET="both"
            ;;
    esac

    validate_install_target
}

create_skills_dirs() {
    : > "$CLAUDE_INSTALLED_REPORT"
    : > "$CODEX_INSTALLED_REPORT"

    if [ "$INSTALL_TARGET" = "claude" ] || [ "$INSTALL_TARGET" = "both" ]; then
        if [ ! -d "$CLAUDE_SKILLS_DIR" ]; then
            log_info "创建 Claude Code skills 目录: $CLAUDE_SKILLS_DIR"
            if [ "$DRY_RUN" != "1" ]; then
                mkdir -p "$CLAUDE_SKILLS_DIR"
            fi
        fi
        if [ ! -d "$CLAUDE_WORKFLOWS_DIR" ]; then
            log_info "创建 Claude Code workflows 目录: $CLAUDE_WORKFLOWS_DIR"
            if [ "$DRY_RUN" != "1" ]; then
                mkdir -p "$CLAUDE_WORKFLOWS_DIR"
            fi
        fi
    fi

    if [ "$INSTALL_TARGET" = "codex" ] || [ "$INSTALL_TARGET" = "both" ]; then
        if [ ! -d "$CODEX_SKILLS_DIR" ]; then
            log_info "创建 Codex CLI skills 目录: $CODEX_SKILLS_DIR"
            if [ "$DRY_RUN" != "1" ]; then
                mkdir -p "$CODEX_SKILLS_DIR"
            fi
        fi
        if [ ! -d "$CODEX_WORKFLOWS_DIR" ]; then
            log_info "创建 Codex CLI workflows 目录: $CODEX_WORKFLOWS_DIR"
            if [ "$DRY_RUN" != "1" ]; then
                mkdir -p "$CODEX_WORKFLOWS_DIR"
            fi
        fi
    fi
}

clone_repo() {
    log_info "克隆 skills 仓库..."
    log_debug "clone source: $REPO_URL"
    log_debug "clone ref: $SKILLS_REF"
    log_debug "clone target: $TEMP_DIR/skills-repo"
    git clone --depth 1 --branch "$SKILLS_REF" "$REPO_URL" "$TEMP_DIR/skills-repo" || {
        log_error "克隆仓库失败，请检查仓库地址/引用: $REPO_URL @ $SKILLS_REF"
        exit 1
    }

    PRIMARY_REPO_SLUG="$(resolve_github_repo_slug "$REPO_URL")"
    set_manifests
}

# 询问用户是否更新单个 skill
ask_update_skill() {
    local skill_name="$1"
    local target_name="$2"

    if [ "$UPDATE_MODE" = "skip" ]; then
        return 1  # 不更新
    elif [ "$UPDATE_MODE" = "force" ]; then
        return 0  # 更新
    fi

    # ask 模式：询问用户（从 /dev/tty 读取，支持 curl | bash）
    if [ "$NON_INTERACTIVE" = "1" ]; then
        if [ "$ASK_FALLBACK_WARNED" -eq 0 ]; then
            log_warn "非交互模式下 UPDATE_MODE=ask，将按 force 处理"
            ASK_FALLBACK_WARNED=1
        fi
        return 0
    fi

    if [ ! -t 0 ] && [ ! -r /dev/tty ]; then
        if [ "$ASK_FALLBACK_WARNED" -eq 0 ]; then
            log_warn "无法交互且 UPDATE_MODE=ask，将按 force 处理"
            ASK_FALLBACK_WARNED=1
        fi
        return 0
    fi

    echo ""
    read -p "[$target_name] Skill '$skill_name' 已存在，是否更新? [y/N]: " answer </dev/tty
    case "$answer" in
        [Yy]|[Yy][Ee][Ss]) return 0 ;;
        *) return 1 ;;
    esac
}

install_skills_to_dir() {
    local target_dir="$1"
    local target_name="$2"
    local report_file="$3"
    local source_dir="$TEMP_DIR/skills-repo/skills"

    log_info "安装 skills 到 $target_name..."

    while IFS= read -r skill_name; do
        [ -z "$skill_name" ] && continue
        local skill="$source_dir/$skill_name"
        local skill_target="$target_dir/$skill_name"

        if [ ! -d "$skill" ]; then
            log_warn "[$target_name] manifest 中的 skill 不存在，跳过: $skill_name"
            continue
        fi

        if [ -d "$skill_target" ]; then
            if ask_update_skill "$skill_name" "$target_name"; then
                if [ "$DRY_RUN" = "1" ]; then
                    log_info "[DRY-RUN][$target_name] 将更新: $skill_name"
                else
                    rm -rf "$skill_target"
                    cp -r "$skill" "$target_dir/"
                    log_info "[$target_name] 已更新: $skill_name"
                fi
                echo "$skill_name" >> "$report_file"
            else
                log_warn "[$target_name] 跳过: $skill_name"
            fi
        else
            if [ "$DRY_RUN" = "1" ]; then
                log_info "[DRY-RUN][$target_name] 将安装: $skill_name"
            else
                cp -r "$skill" "$target_dir/"
                log_info "[$target_name] 已安装: $skill_name"
            fi
            echo "$skill_name" >> "$report_file"
        fi
    done < <(read_manifest_entries "$SKILLS_MANIFEST_FILE")
}

install_skills() {
    local source_dir="$TEMP_DIR/skills-repo/skills"

    if [ ! -d "$source_dir" ]; then
        log_error "skills 目录不存在"
        exit 1
    fi

    if [ "$INSTALL_TARGET" = "claude" ] || [ "$INSTALL_TARGET" = "both" ]; then
        install_skills_to_dir "$CLAUDE_SKILLS_DIR" "Claude Code" "$CLAUDE_INSTALLED_REPORT"
    fi

    if [ "$INSTALL_TARGET" = "codex" ] || [ "$INSTALL_TARGET" = "both" ]; then
        install_skills_to_dir "$CODEX_SKILLS_DIR" "Codex CLI" "$CODEX_INSTALLED_REPORT"
    fi
}

install_workflows_to_dir() {
    local target_dir="$1"
    local target_name="$2"
    local source_dir="$TEMP_DIR/skills-repo/workflows"

    log_info "安装 workflows 到 $target_name..."

    if [ ! -f "$WORKFLOWS_MANIFEST_FILE" ]; then
        log_warn "workflows manifest 缺失，跳过 workflows 安装"
        return
    fi

    while IFS= read -r workflow_name; do
        [ -z "$workflow_name" ] && continue
        local workflow="$source_dir/$workflow_name"
        local workflow_target="$target_dir/$workflow_name"

        if [ ! -d "$workflow" ]; then
            log_warn "[$target_name] manifest 中的 workflow 不存在，跳过: $workflow_name"
            continue
        fi

        if [ -d "$workflow_target" ]; then
            if ask_update_skill "$workflow_name" "$target_name"; then
                if [ "$DRY_RUN" = "1" ]; then
                    log_info "[DRY-RUN][$target_name] 将更新 workflow: $workflow_name"
                else
                    rm -rf "$workflow_target"
                    cp -r "$workflow" "$target_dir/"
                    log_info "[$target_name] 已更新 workflow: $workflow_name"
                fi
            else
                log_warn "[$target_name] 跳过 workflow: $workflow_name"
            fi
        else
            if [ "$DRY_RUN" = "1" ]; then
                log_info "[DRY-RUN][$target_name] 将安装 workflow: $workflow_name"
            else
                cp -r "$workflow" "$target_dir/"
                log_info "[$target_name] 已安装 workflow: $workflow_name"
            fi
        fi
    done < <(read_manifest_entries "$WORKFLOWS_MANIFEST_FILE")
}

install_workflows() {
    local source_dir="$TEMP_DIR/skills-repo/workflows"

    if [ ! -d "$source_dir" ]; then
        log_warn "workflows 目录不存在，跳过"
        return
    fi

    if [ "$INSTALL_TARGET" = "claude" ] || [ "$INSTALL_TARGET" = "both" ]; then
        install_workflows_to_dir "$CLAUDE_WORKFLOWS_DIR" "Claude Code"
    fi

    if [ "$INSTALL_TARGET" = "codex" ] || [ "$INSTALL_TARGET" = "both" ]; then
        install_workflows_to_dir "$CODEX_WORKFLOWS_DIR" "Codex CLI"
    fi
}

show_installed() {
    local skills_dir="$1"
    local name="$2"
    local report_file="$3"

    if [ ! -d "$skills_dir" ] && [ "$DRY_RUN" != "1" ]; then
        return
    fi

    echo ""
    log_info "$name 本次安装/更新的 Skills:"
    echo "─────────────────────────────────────────"
    if [ ! -s "$report_file" ]; then
        echo "  (无变更)"
        echo "─────────────────────────────────────────"
        return
    fi

    while IFS= read -r skill_name; do
        [ -z "$skill_name" ] && continue
        if [ "$DRY_RUN" = "1" ]; then
            echo "  • $skill_name (planned)"
            continue
        fi

        skill="$skills_dir/$skill_name"
        if [ -d "$skill" ] && [ -f "$skill/SKILL.md" ]; then
            desc=$(grep "^description:" "$skill/SKILL.md" 2>/dev/null | head -1 | sed 's/description: //')
            echo "  • $skill_name"
            if [ -n "$desc" ]; then
                echo "    $desc"
            fi
        fi
    done < <(sort -u "$report_file")
    echo "─────────────────────────────────────────"
}

main() {
    parse_args "$@"

    echo ""
    echo "╔═══════════════════════════════════════════╗"
    echo "║     AI Coding Skills 安装程序             ║"
    echo "║     支持 Claude Code / Codex CLI          ║"
    echo "╚═══════════════════════════════════════════╝"
    echo ""
    if [ "$DRY_RUN" = "1" ]; then
        log_info "已启用 dry-run：不会写入目标目录"
    fi

    check_git
    validate_update_mode
    validate_install_target
    validate_market_config
    select_target
    create_skills_dirs
    clone_repo
    install_skills
    install_workflows
    sync_market_skills

    if [ "$INSTALL_TARGET" = "codex" ] || [ "$INSTALL_TARGET" = "both" ]; then
        if [ "$DRY_RUN" = "1" ]; then
            log_info "[DRY-RUN] 跳过写入 Codex 本地版本与自动更新配置"
        else
            sync_codex_local_version
            configure_codex_auto_update_launcher
        fi
    fi

    if [ "$INSTALL_TARGET" = "claude" ] || [ "$INSTALL_TARGET" = "both" ]; then
        show_installed "$CLAUDE_SKILLS_DIR" "Claude Code" "$CLAUDE_INSTALLED_REPORT"
    fi

    if [ "$INSTALL_TARGET" = "codex" ] || [ "$INSTALL_TARGET" = "both" ]; then
        show_installed "$CODEX_SKILLS_DIR" "Codex CLI" "$CODEX_INSTALLED_REPORT"
    fi

    echo ""
    log_info "安装完成! 请重启对应的 AI 编程工具以加载 Skills"
    if [ "$DRY_RUN" != "1" ] && { [ "$INSTALL_TARGET" = "codex" ] || [ "$INSTALL_TARGET" = "both" ]; }; then
        log_info "Codex 自动更新配置已写入 ~/.bashrc 和 ~/.zshrc，新终端会生效"
    fi
}

main "$@"
