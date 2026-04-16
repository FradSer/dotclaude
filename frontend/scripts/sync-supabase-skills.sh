#!/usr/bin/env bash
#
# Supabase Agent Skills 同步脚本
# 从 supabase/agent-skills 仓库同步 supabase 和 supabase-postgres-best-practices
#

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
UPSTREAM_REPO="https://github.com/supabase/agent-skills.git"
UPSTREAM_BRANCH="main"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TARGET_DIR="$SCRIPT_DIR/../skills"
TEMP_DIR="/tmp/supabase-skills-sync-$$"

# 要同步的 skill 目录
SKILL_DIRS=("supabase" "supabase-postgres-best-practices")

# 本地文件（不被覆盖）
LOCAL_FILES=("SYNC.md")

# 帮助信息
show_help() {
    cat << EOF
${BLUE}Supabase Agent Skills 同步脚本${NC}

${GREEN}用法:${NC}
    $0 [选项]

${GREEN}选项:${NC}
    -h, --help          显示此帮助信息
    -c, --check         仅检查是否有更新,不执行同步
    -f, --force         强制同步,跳过确认
    --no-backup         同步时不创建备份

${GREEN}同步的 Skills:${NC}
    ${SKILL_DIRS[*]}

${GREEN}上游仓库:${NC}
    $UPSTREAM_REPO (branch: $UPSTREAM_BRANCH)

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

# 克隆上游
clone_upstream() {
    log_info "正在从上游仓库获取 skills 目录..."

    mkdir -p "$TEMP_DIR"

    git clone --depth 1 --filter=blob:none --sparse \
        "$UPSTREAM_REPO" "$TEMP_DIR/repo" 2>/dev/null

    cd "$TEMP_DIR/repo" >/dev/null 2>&1
    local sparse_paths=()
    for skill in "${SKILL_DIRS[@]}"; do
        sparse_paths+=("skills/$skill")
    done
    git sparse-checkout set "${sparse_paths[@]}" 2>/dev/null
    cd - >/dev/null 2>&1

    for skill in "${SKILL_DIRS[@]}"; do
        if [ ! -d "$TEMP_DIR/repo/skills/$skill" ]; then
            log_error "上游仓库中未找到 skills/$skill 目录"
            return 1
        fi
    done

    log_success "上游文件获取完成"
    return 0
}

# 创建备份
create_backup() {
    local skill_name="$1"
    local skill_target="$TARGET_DIR/$skill_name"
    local backup_dir="$skill_target/.backup"

    [ ! -d "$skill_target" ] && return 0

    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$backup_dir/$timestamp"
    mkdir -p "$backup_path"

    local count=0
    while IFS= read -r -d '' item; do
        local basename
        basename=$(basename "$item")
        local skip=false
        for local_file in "${LOCAL_FILES[@]}"; do
            [ "$basename" = "$local_file" ] && skip=true && break
        done
        [ "$basename" = ".backup" ] && skip=true
        [ "$skip" = true ] && continue
        cp -R "$item" "$backup_path/"
        count=$((count + 1))
    done < <(find "$skill_target" -maxdepth 1 -mindepth 1 -print0)

    if [ $count -gt 0 ]; then
        log_success "  已备份 $skill_name: $count 个项目"
    else
        rmdir "$backup_path" 2>/dev/null || true
    fi
}

# 检查单个 skill 差异
check_skill_diff() {
    local skill_name="$1"
    local upstream_skill="$TEMP_DIR/repo/skills/$skill_name"
    local local_skill="$TARGET_DIR/$skill_name"
    local new_count=0
    local changed_count=0

    [ ! -d "$local_skill" ] && return 1

    while IFS= read -r -d '' upstream_file; do
        local rel_path="${upstream_file#$upstream_skill/}"
        local local_file="$local_skill/$rel_path"
        if [ ! -f "$local_file" ]; then
            new_count=$((new_count + 1))
        elif ! diff -q "$local_file" "$upstream_file" &> /dev/null; then
            changed_count=$((changed_count + 1))
        fi
    done < <(find "$upstream_skill" -type f -print0)

    if [ $new_count -gt 0 ] || [ $changed_count -gt 0 ]; then
        [ $new_count -gt 0 ] && log_info "  $skill_name: 新增 $new_count 个文件"
        [ $changed_count -gt 0 ] && log_info "  $skill_name: 变更 $changed_count 个文件"
        return 1
    fi
    return 0
}

# 检查所有差异
check_diff() {
    local has_changes=false
    log_info "检查文件差异..."
    for skill in "${SKILL_DIRS[@]}"; do
        if ! check_skill_diff "$skill"; then
            has_changes=true
        fi
    done
    if [ "$has_changes" = true ]; then
        return 1
    else
        log_success "所有文件已是最新版本"
        return 0
    fi
}

# 同步单个 skill
sync_skill() {
    local skill_name="$1"
    local no_backup="$2"
    local upstream_skill="$TEMP_DIR/repo/skills/$skill_name"
    local skill_target="$TARGET_DIR/$skill_name"

    [ "$no_backup" != "true" ] && create_backup "$skill_name"

    mkdir -p "$skill_target"

    if [ -d "$skill_target" ]; then
        while IFS= read -r -d '' item; do
            local basename
            basename=$(basename "$item")
            local skip=false
            for local_file in "${LOCAL_FILES[@]}"; do
                [ "$basename" = "$local_file" ] && skip=true && break
            done
            [ "$basename" = ".backup" ] && skip=true
            [ "$skip" = true ] && continue
            rm -rf "$item"
        done < <(find "$skill_target" -maxdepth 1 -mindepth 1 -print0)
    fi

    local count=0
    while IFS= read -r -d '' item; do
        cp -R "$item" "$skill_target/"
        count=$((count + 1))
    done < <(find "$upstream_skill" -maxdepth 1 -mindepth 1 -print0)

    log_success "  $skill_name: 已同步 $count 个项目"

    local sync_md="$skill_target/SYNC.md"
    if [ -f "$sync_md" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/\*\*上次同步\*\*: .*/\*\*上次同步\*\*: $(date +%Y-%m-%d)/" "$sync_md"
        else
            sed -i "s/\*\*上次同步\*\*: .*/\*\*上次同步\*\*: $(date +%Y-%m-%d)/" "$sync_md"
        fi
    fi
}

# 同步所有 skills
sync_files() {
    local no_backup="$1"
    log_info "正在同步文件..."
    for skill in "${SKILL_DIRS[@]}"; do
        sync_skill "$skill" "$no_backup"
    done
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

    log_info "开始同步 Supabase agent skills..."
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
    log_info "建议执行以下命令提交更改:"
    echo ""
    echo "    git add frontend/skills/supabase/ frontend/skills/supabase-postgres-best-practices/"
    echo "    git-agent commit --no-stage --intent \"sync supabase agent skills from upstream\" --co-author \"Claude Opus 4.6 <noreply@anthropic.com>\""
    echo ""
}

main "$@"
