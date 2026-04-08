#!/bin/bash

# AI Skills 卸载脚本
# 支持 Claude Code、OpenAI Codex CLI 和 Gemini CLI

set -euo pipefail

CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
CODEX_SKILLS_DIR="$HOME/.codex/skills"
GEMINI_DEFAULT_SKILLS_DIR="$HOME/.gemini/skills"
GEMINI_ALIAS_SKILLS_DIR="$HOME/.agents/skills"
if [ -z "${GEMINI_SKILLS_DIR:-}" ]; then
    if [ -d "$GEMINI_ALIAS_SKILLS_DIR" ]; then
        GEMINI_SKILLS_DIR="$GEMINI_ALIAS_SKILLS_DIR"
    else
        GEMINI_SKILLS_DIR="$GEMINI_DEFAULT_SKILLS_DIR"
    fi
fi
CLAUDE_WORKFLOWS_DIR="$HOME/.claude/workflows"
CODEX_WORKFLOWS_DIR="$HOME/.codex/workflows"

UNINSTALL_TARGET="${UNINSTALL_TARGET:-}"
SKILLS_REF="${SKILLS_REF:-main}"
MANIFEST_BASE_URL="${MANIFEST_BASE_URL:-https://raw.githubusercontent.com/biglone/agent-skills/${SKILLS_REF}/scripts/manifest}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_MANIFEST_DIR="$SCRIPT_DIR/manifest"
SKILLS_TO_REMOVE=()
WORKFLOWS_TO_REMOVE=()

read_manifest_stream() {
    local filename="$1"
    local local_path="$LOCAL_MANIFEST_DIR/$filename"

    if [ -f "$local_path" ]; then
        cat "$local_path"
        return
    fi

    if command -v curl > /dev/null 2>&1; then
        curl -fsSL "$MANIFEST_BASE_URL/$filename"
        return
    fi

    if command -v wget > /dev/null 2>&1; then
        wget -qO- "$MANIFEST_BASE_URL/$filename"
        return
    fi

    log_error "无法读取 manifest: $filename（本地缺失且未找到 curl/wget）"
    exit 1
}

load_manifests() {
    while IFS= read -r line; do
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [ -z "$line" ] && continue
        case "$line" in \#*) continue ;; esac
        SKILLS_TO_REMOVE+=("$line")
    done < <(read_manifest_stream "skills.txt")

    while IFS= read -r line; do
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [ -z "$line" ] && continue
        case "$line" in \#*) continue ;; esac
        WORKFLOWS_TO_REMOVE+=("$line")
    done < <(read_manifest_stream "workflows.txt")

    if [ "${#SKILLS_TO_REMOVE[@]}" -eq 0 ]; then
        log_error "skills manifest 为空"
        exit 1
    fi
}

validate_uninstall_target() {
    case "$UNINSTALL_TARGET" in
        ""|claude|codex|gemini|both|all) ;;
        *)
            log_error "UNINSTALL_TARGET 无效: ${UNINSTALL_TARGET}（可选 claude/codex/gemini/both/all）"
            exit 1
            ;;
    esac
}

uninstall_target_includes() {
    local platform="$1"

    case "$UNINSTALL_TARGET" in
        all) return 0 ;;
        both)
            [ "$platform" = "claude" ] || [ "$platform" = "codex" ]
            return
            ;;
        "$platform") return 0 ;;
        *) return 1 ;;
    esac
}

select_target() {
    if [ -n "$UNINSTALL_TARGET" ]; then
        UNINSTALL_TARGET="$(printf '%s' "$UNINSTALL_TARGET" | tr '[:upper:]' '[:lower:]')"
        validate_uninstall_target
        return
    fi

    # 检查是否有可用的终端输入
    if [ ! -t 0 ] && [ ! -r /dev/tty ]; then
        log_warn "无法获取用户输入，默认卸载两者"
        UNINSTALL_TARGET="both"
        return
    fi

    echo -e "${CYAN}请选择卸载目标:${NC}"
    echo "  1) Claude Code"
    echo "  2) OpenAI Codex CLI"
    echo "  3) Gemini CLI"
    echo "  4) Claude Code + Codex CLI"
    echo "  5) 全部卸载"
    echo ""
    read -p "请输入选项 [1-5] (默认: 4): " choice </dev/tty

    case "$choice" in
        1) UNINSTALL_TARGET="claude" ;;
        2) UNINSTALL_TARGET="codex" ;;
        3) UNINSTALL_TARGET="gemini" ;;
        4|"") UNINSTALL_TARGET="both" ;;
        5) UNINSTALL_TARGET="all" ;;
        *) UNINSTALL_TARGET="both" ;;
    esac

    validate_uninstall_target
}

uninstall_from_dir() {
    local target_dir="$1"
    local target_name="$2"

    for skill in "${SKILLS_TO_REMOVE[@]}"; do
        skill_path="$target_dir/$skill"
        if [ -d "$skill_path" ]; then
            rm -rf "$skill_path"
            log_info "[$target_name] 已卸载: $skill"
        else
            log_warn "[$target_name] Skill '$skill' 不存在，跳过"
        fi
    done
}

uninstall_workflows_from_dir() {
    local target_dir="$1"
    local target_name="$2"

    for workflow in "${WORKFLOWS_TO_REMOVE[@]}"; do
        workflow_path="$target_dir/$workflow"
        if [ -d "$workflow_path" ]; then
            rm -rf "$workflow_path"
            log_info "[$target_name] 已卸载 workflow: $workflow"
        else
            log_warn "[$target_name] Workflow '$workflow' 不存在，跳过"
        fi
    done
}

main() {
    echo ""
    echo "╔═══════════════════════════════════════════╗"
    echo "║       AI Skills 卸载程序                  ║"
    echo "║ 支持 Claude Code / Codex / Gemini CLI     ║"
    echo "╚═══════════════════════════════════════════╝"
    echo ""

    select_target
    load_manifests

    if uninstall_target_includes "claude"; then
        uninstall_from_dir "$CLAUDE_SKILLS_DIR" "Claude Code"
        uninstall_workflows_from_dir "$CLAUDE_WORKFLOWS_DIR" "Claude Code"
    fi

    if uninstall_target_includes "codex"; then
        uninstall_from_dir "$CODEX_SKILLS_DIR" "Codex CLI"
        uninstall_workflows_from_dir "$CODEX_WORKFLOWS_DIR" "Codex CLI"
    fi

    if uninstall_target_includes "gemini"; then
        uninstall_from_dir "$GEMINI_SKILLS_DIR" "Gemini CLI"
    fi

    echo ""
    log_info "卸载完成! 请重启对应的 AI 编程工具"
}

main "$@"
