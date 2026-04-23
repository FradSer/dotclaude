#!/usr/bin/env bash
#
# shadcn Skill 同步脚本
# 从 shadcn-ui/ui 仓库同步 skills/shadcn 目录到本地
#

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
UPSTREAM_REPO="https://github.com/shadcn-ui/ui.git"
UPSTREAM_BRANCH="main"
UPSTREAM_PATH="skills/shadcn"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TARGET_DIR="$SCRIPT_DIR/../skills/shadcn"
SYNC_FILE="$SCRIPT_DIR/../SYNC.md"
BACKUP_DIR="$TARGET_DIR/.backup"
TEMP_DIR="/tmp/shadcn-sync-$$"

# 排除的上游目录（OpenAI 特定，Claude Code 不需要）
EXCLUDE_DIRS=("agents" "assets")

# 帮助信息
show_help() {
    cat << EOF
${BLUE}shadcn Skill 同步脚本${NC}

${GREEN}用法:${NC}
    $0 [选项]

${GREEN}选项:${NC}
    -h, --help          显示此帮助信息
    -c, --check         仅检查是否有更新,不执行同步
    -f, --force         强制同步,跳过确认
    --no-backup         同步时不创建备份

${GREEN}示例:${NC}
    $0                  # 同步并备份现有文件
    $0 --check          # 仅检查更新
    $0 --force          # 强制同步,跳过确认

${GREEN}上游仓库:${NC}
    $UPSTREAM_REPO (branch: $UPSTREAM_BRANCH)

${GREEN}排除目录:${NC}
    ${EXCLUDE_DIRS[*]} (OpenAI 特定)

EOF
}

# 日志函数
log_info() {
    printf "${BLUE}[INFO]${NC} %s\n" "$1"
}

log_success() {
    printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"
}

log_warning() {
    printf "${YELLOW}[WARNING]${NC} %s\n" "$1"
}

log_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
}

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
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

# 检查是否为排除目录
is_excluded() {
    local name="$1"
    for excl in "${EXCLUDE_DIRS[@]}"; do
        if [ "$name" = "$excl" ]; then
            return 0
        fi
    done
    return 1
}

# 克隆上游 skills/shadcn 目录（sparse checkout）
clone_upstream() {
    log_info "正在从上游仓库获取 $UPSTREAM_PATH 目录..."

    mkdir -p "$TEMP_DIR"

    git clone --depth 1 --filter=blob:none --sparse \
        "$UPSTREAM_REPO" "$TEMP_DIR/repo" 2>/dev/null

    cd "$TEMP_DIR/repo" >/dev/null 2>&1
    git sparse-checkout set "$UPSTREAM_PATH" 2>/dev/null
    cd - >/dev/null 2>&1

    if [ ! -d "$TEMP_DIR/repo/$UPSTREAM_PATH" ]; then
        log_error "上游仓库中未找到 $UPSTREAM_PATH 目录"
        return 1
    fi

    # 删除排除的目录
    for excl in "${EXCLUDE_DIRS[@]}"; do
        if [ -d "$TEMP_DIR/repo/$UPSTREAM_PATH/$excl" ]; then
            rm -rf "$TEMP_DIR/repo/$UPSTREAM_PATH/$excl"
            log_info "已排除上游目录: $excl/"
        fi
    done

    log_success "上游文件获取完成"
    return 0
}

# 创建备份
create_backup() {
    if [ ! -d "$TARGET_DIR" ]; then
        log_info "目标目录不存在,跳过备份"
        return 0
    fi

    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$BACKUP_DIR/$timestamp"

    mkdir -p "$backup_path"

    # 备份所有子目录和文件（排除 .backup 和本地文件）
    local count=0
    while IFS= read -r -d '' item; do
        local basename
        basename=$(basename "$item")

        # 跳过备份目录
        local skip=false
        [ "$basename" = ".backup" ] && skip=true
        [ "$skip" = true ] && continue

        cp -R "$item" "$backup_path/"
        count=$((count + 1))
    done < <(find "$TARGET_DIR" -maxdepth 1 -mindepth 1 -print0)

    if [ $count -gt 0 ]; then
        log_success "已备份 $count 个项目到: $backup_path"
    else
        log_info "没有需要备份的内容"
        rmdir "$backup_path" 2>/dev/null || true
    fi
}

# 检查差异
check_diff() {
    local upstream_skills="$TEMP_DIR/repo/$UPSTREAM_PATH"
    local has_changes=false
    local new_count=0
    local changed_count=0
    local deleted_count=0

    if [ ! -d "$TARGET_DIR" ]; then
        log_warning "本地目录不存在,将创建新文件"
        return 1
    fi

    log_info "检查文件差异..."

    # 检查新增和变更的文件
    while IFS= read -r -d '' upstream_file; do
        local rel_path="${upstream_file#$upstream_skills/}"
        local local_file="$TARGET_DIR/$rel_path"

        if [ ! -f "$local_file" ]; then
            new_count=$((new_count + 1))
            has_changes=true
        elif ! diff -q "$local_file" "$upstream_file" &> /dev/null; then
            changed_count=$((changed_count + 1))
            has_changes=true
        fi
    done < <(find "$upstream_skills" -type f -print0)

    # 检查本地已删除的上游文件
    while IFS= read -r -d '' local_file; do
        local rel_path="${local_file#$TARGET_DIR/}"
        local basename
        basename=$(basename "$rel_path")
        local dirname
        dirname=$(dirname "$rel_path")

        # 跳过备份目录
        local skip=false
        [[ "$rel_path" == .backup* ]] && skip=true
        [ "$skip" = true ] && continue

        local upstream_file="$upstream_skills/$rel_path"
        if [ ! -f "$upstream_file" ]; then
            deleted_count=$((deleted_count + 1))
            has_changes=true
        fi
    done < <(find "$TARGET_DIR" -type f -print0)

    if [ "$has_changes" = true ]; then
        [ $new_count -gt 0 ] && log_info "  新增: $new_count 个文件"
        [ $changed_count -gt 0 ] && log_info "  变更: $changed_count 个文件"
        [ $deleted_count -gt 0 ] && log_info "  删除: $deleted_count 个文件(上游已移除)"
        return 1
    else
        log_success "所有文件已是最新版本"
        return 0
    fi
}

# 执行同步
sync_files() {
    local no_backup="$1"
    local upstream_skills="$TEMP_DIR/repo/$UPSTREAM_PATH"

    # 创建备份
    if [ "$no_backup" != "true" ]; then
        create_backup
    fi

    log_info "正在同步文件..."

    # 删除旧的上游内容（保留备份）
    while IFS= read -r -d '' item; do
        local basename
        basename=$(basename "$item")

        local skip=false
        [ "$basename" = ".backup" ] && skip=true
        [ "$skip" = true ] && continue

        rm -rf "$item"
    done < <(find "$TARGET_DIR" -maxdepth 1 -mindepth 1 -print0)

    # 复制上游内容
    local count=0
    while IFS= read -r -d '' item; do
        cp -R "$item" "$TARGET_DIR/"
        count=$((count + 1))
    done < <(find "$upstream_skills" -maxdepth 1 -mindepth 1 -print0)

    log_success "同步完成: 已同步 $count 个项目"

    # 更新 SYNC.md 中 shadcn section 的同步时间
    if [ -f "$SYNC_FILE" ]; then
        local today
        today=$(date +%Y-%m-%d)
        awk -v section="## shadcn" -v today="$today" '
            /^## / { in_section = ($0 == section) }
            in_section && /^- \*\*上次同步\*\*:/ { print "- **上次同步**: " today; next }
            { print }
        ' "$SYNC_FILE" > "$SYNC_FILE.tmp" && mv "$SYNC_FILE.tmp" "$SYNC_FILE"
        log_info "已更新 SYNC.md shadcn section 的同步时间"
    fi
}

# 主函数
main() {
    local check_only=false
    local force_sync=false
    local no_backup=false

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--check)
                check_only=true
                shift
                ;;
            -f|--force)
                force_sync=true
                shift
                ;;
            --no-backup)
                no_backup=true
                shift
                ;;
            *)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done

    log_info "开始同步 shadcn skill..."

    # 检查必要工具
    check_requirements

    # 克隆上游
    clone_upstream

    # 检查差异
    local has_diff=0
    check_diff || has_diff=$?

    # 如果只是检查模式
    if [ "$check_only" = true ]; then
        if [ $has_diff -eq 0 ]; then
            log_success "没有更新"
            exit 0
        else
            log_info "有更新可用,运行 $0 进行同步"
            exit 1
        fi
    fi

    # 如果没有差异且不是强制模式
    if [ $has_diff -eq 0 ] && [ "$force_sync" != true ]; then
        exit 0
    fi

    # 询问确认(除非强制模式)
    if [ "$force_sync" != true ] && [ -t 0 ]; then
        echo -n "是否继续同步? [y/N] "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "取消同步"
            exit 0
        fi
    fi

    # 执行同步
    sync_files "$no_backup"

    log_success "同步完成!"

    # 检查是否有本地 modifications 需要 replay
    local modifications_file="$SCRIPT_DIR/../modifications/shadcn.md"
    if [ -f "$modifications_file" ]; then
        local pending
        pending=$(grep -c "^## " "$modifications_file" 2>/dev/null || echo 0)
        if [ $pending -gt 0 ]; then
            echo ""
            log_warning "检测到 $pending 条本地 modification 需要 replay"
            log_warning "请让 Claude 读取 frontend/modifications/shadcn.md 并重新应用到对应目标文件"
            echo ""
        fi
    fi

    log_info "建议执行以下命令提交更改:"
    echo ""
    echo "    git add frontend/skills/shadcn/"
    echo "    git-agent commit --no-stage --intent \"sync shadcn skill from upstream shadcn-ui/ui\" --co-author \"Claude Opus 4.7 <noreply@anthropic.com>\""
    echo ""
}

main "$@"
