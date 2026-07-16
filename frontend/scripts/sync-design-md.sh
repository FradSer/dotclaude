#!/usr/bin/env bash
#
# DESIGN.md spec 同步脚本
# 从 google-labs-code/design.md 仓库缓存 docs/spec.md 和 README.md 到 references/
# SKILL.md 是本地自定义集成,不会被同步/覆盖。
#

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
UPSTREAM_REPO="https://github.com/google-labs-code/design.md.git"
UPSTREAM_BRANCH="main"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TARGET_DIR="$SCRIPT_DIR/../skills/design-md/references"
SYNC_FILE="$SCRIPT_DIR/../SYNC.md"
TEMP_DIR="/tmp/design-md-sync-$$"

# 注:design-md 不接入 .sync-snapshots 快照——它是全量 clone(快照会被无关上游改动污染),
# 且本地仅缓存上游原文(无 modifications 重放),check_diff 比对本身已准确,无假阳性。

# 上游路径 <-> 本地缓存文件名(同索引对应)
UPSTREAM_FILES=("docs/spec.md" "README.md")
CACHE_NAMES=("upstream-spec.md" "upstream-README.md")

# 帮助信息
show_help() {
    cat << EOF
${BLUE}DESIGN.md spec 同步脚本${NC}

${GREEN}用法:${NC}
    $0 [选项]

${GREEN}选项:${NC}
    -h, --help          显示此帮助信息
    -c, --check         仅检查是否有更新,不执行同步
    -f, --force         强制同步,跳过确认
    --no-backup         同步时不创建备份

${GREEN}同步映射:${NC}
    docs/spec.md  →  skills/design-md/references/upstream-spec.md
    README.md     →  skills/design-md/references/upstream-README.md

${GREEN}上游仓库:${NC}
    $UPSTREAM_REPO (branch: $UPSTREAM_BRANCH)

${YELLOW}注意:${NC}
    - SKILL.md 是本地自定义集成,不会被同步/覆盖
    - spec.md 变更时,请让 Claude 比对 references/upstream-spec.md
      和 SKILL.md 内联的 schema / section / lint 规则是否仍一致
    - 上游版本为 alpha,期待破坏性变更

EOF
}

# 日志函数
log_info() { printf "${BLUE}[INFO]${NC} %s\n" "$1"; }
log_success() { printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"; }
log_warning() { printf "${YELLOW}[WARNING]${NC} %s\n" "$1"; }
log_error() { printf "${RED}[ERROR]${NC} %s\n" "$1"; }

# 检查必要工具
check_requirements() {
    local missing_tools=()
    for tool in git diff; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "缺少必要工具: ${missing_tools[*]}"
        exit 1
    fi
}

# 清理临时文件
cleanup() { [ -d "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"; }
trap cleanup EXIT

# 克隆上游(仓库较小,直接 depth-1 clone;不用 sparse checkout
# 是因为目标里同时包含文件和目录,非 cone 模式太复杂)
clone_upstream() {
    log_info "正在从上游仓库获取 DESIGN.md spec..."

    mkdir -p "$TEMP_DIR"

    if ! git clone --depth 1 --branch "$UPSTREAM_BRANCH" \
            "$UPSTREAM_REPO" "$TEMP_DIR/repo" 2>/dev/null; then
        log_error "克隆上游仓库失败"
        return 1
    fi

    # 验证上游文件存在
    for file in "${UPSTREAM_FILES[@]}"; do
        if [ ! -f "$TEMP_DIR/repo/$file" ]; then
            log_error "上游仓库中未找到 $file"
            return 1
        fi
    done

    log_success "上游文件获取完成"
    return 0
}

# 创建备份
create_backup() {
    if [ ! -d "$TARGET_DIR" ]; then
        return 0
    fi

    local backup_dir="$TARGET_DIR/.backup"
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$backup_dir/$timestamp"
    mkdir -p "$backup_path"

    local count=0
    while IFS= read -r -d '' item; do
        local basename
        basename=$(basename "$item")
        [ "$basename" = ".backup" ] && continue
        cp -R "$item" "$backup_path/"
        count=$((count + 1))
    done < <(find "$TARGET_DIR" -maxdepth 1 -mindepth 1 -print0)

    if [ $count -gt 0 ]; then
        log_success "  已备份: $count 个项目"
    else
        rmdir "$backup_path" 2>/dev/null || true
    fi
}

# 检查单个文件的差异,返回:
#   0 = 一致, 1 = 变更, 2 = 首次(本地缺失)
check_file_diff() {
    local upstream="$1"
    local cached="$2"

    if [ ! -f "$cached" ]; then
        return 2
    fi
    if ! diff -q "$cached" "$upstream" &> /dev/null; then
        return 1
    fi
    return 0
}

# 检查所有差异,任何变更/首次都视为 has_changes
check_diff() {
    local has_changes=false
    log_info "检查 spec 文件差异..."

    for i in "${!UPSTREAM_FILES[@]}"; do
        local upstream="$TEMP_DIR/repo/${UPSTREAM_FILES[$i]}"
        local cached="$TARGET_DIR/${CACHE_NAMES[$i]}"
        local rc=0
        check_file_diff "$upstream" "$cached" || rc=$?
        case $rc in
            1) log_info "  ${CACHE_NAMES[$i]}: 有变更"; has_changes=true ;;
            2) log_info "  ${CACHE_NAMES[$i]}: 首次同步"; has_changes=true ;;
        esac
    done

    if [ "$has_changes" = true ]; then
        return 1
    fi
    log_success "所有缓存文件已是最新版本"
    return 0
}

# 同步文件
sync_files() {
    local no_backup="$1"
    log_info "正在同步缓存文件..."

    mkdir -p "$TARGET_DIR"

    if [ "$no_backup" != "true" ]; then
        create_backup
    fi

    local spec_changed=false
    for i in "${!UPSTREAM_FILES[@]}"; do
        local upstream="$TEMP_DIR/repo/${UPSTREAM_FILES[$i]}"
        local cached="$TARGET_DIR/${CACHE_NAMES[$i]}"

        # 仅当 spec.md 实际变更(不是首次)时才警告人工 review
        if [ "${UPSTREAM_FILES[$i]}" = "docs/spec.md" ] && [ -f "$cached" ]; then
            if ! diff -q "$cached" "$upstream" &> /dev/null; then
                spec_changed=true
            fi
        fi

        cp "$upstream" "$cached"
        log_success "  ${CACHE_NAMES[$i]}: 已更新"
    done

    # 更新 SYNC.md design-md section 的同步日期
    if [ -f "$SYNC_FILE" ]; then
        local today
        today=$(date +%Y-%m-%d)
        awk -v section="## design-md" -v today="$today" '
            /^## / { in_section = ($0 == section) }
            in_section && /^- \*\*上次同步\*\*:/ { print "- **上次同步**: " today; next }
            { print }
        ' "$SYNC_FILE" > "$SYNC_FILE.tmp" && mv "$SYNC_FILE.tmp" "$SYNC_FILE"
    fi

    if [ "$spec_changed" = true ]; then
        echo ""
        log_warning "docs/spec.md 发生变更"
        log_warning "请让 Claude 比对 frontend/skills/design-md/references/upstream-spec.md"
        log_warning "和 SKILL.md 的内联 schema / section 顺序 / lint 规则表,"
        log_warning "判断是否需要同步更新 SKILL.md。"
    fi
}

# 主函数
main() {
    local check_only=false
    local force_sync=false
    local no_backup=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help) show_help; exit 0 ;;
            -c|--check) check_only=true; shift ;;
            -f|--force) force_sync=true; shift ;;
            --no-backup) no_backup=true; shift ;;
            *) log_error "未知选项: $1"; show_help; exit 1 ;;
        esac
    done

    log_info "开始同步 DESIGN.md spec..."
    check_requirements
    clone_upstream

    local has_diff=0
    check_diff || has_diff=$?

    if [ "$check_only" = true ]; then
        [ $has_diff -eq 0 ] && log_success "没有更新" && exit 0
        log_info "有更新可用,运行 $0 进行同步"
        exit 1
    fi

    if [ $has_diff -eq 0 ] && [ "$force_sync" != true ]; then
        exit 0
    fi

    if [ "$force_sync" != true ] && [ -t 0 ]; then
        echo -n "是否继续同步? [y/N] "
        read -r response
        [[ ! "$response" =~ ^[Yy]$ ]] && log_info "取消同步" && exit 0
    fi

    sync_files "$no_backup"

    log_success "同步完成!"

    # 引用完整性校验(死链不阻断同步,仅提示据实更新 SKILL.md 链接)
    echo ""
    "$SCRIPT_DIR/check-references.sh" || log_warning "请据实修复上面的 SKILL.md 死链"

    # 检查是否有本地 modifications 需要 replay
    local modifications_file="$SCRIPT_DIR/../modifications/design-md.md"
    if [ -f "$modifications_file" ]; then
        local pending
        pending=$(grep -c "^## " "$modifications_file" 2>/dev/null || true)
        if [ "${pending:-0}" -gt 0 ]; then
            echo ""
            log_warning "检测到 $pending 条本地 modification 需要 replay"
            log_warning "请让 Claude 读取 frontend/modifications/design-md.md 并重新应用到对应目标文件"
            echo ""
        fi
    fi

    log_info "建议执行以下命令提交更改:"
    echo ""
    echo "    git add frontend/skills/design-md/references/ frontend/SYNC.md"
    echo "    git-agent commit --no-stage --intent \"sync DESIGN.md spec from upstream\" --co-author \"Claude Opus 4.7 <noreply@anthropic.com>\""
    echo ""
}

main "$@"
