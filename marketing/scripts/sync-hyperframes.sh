#!/usr/bin/env bash
#
# HyperFrames Skills 同步脚本
# 从 heygen-com/hyperframes 仓库同步 skills/ 目录到本地 marketing/skills/hyperframes/
#
# 本子树寄居在 marketing 插件下，由本脚本独立同步；marketing 上游(coreyhaines31/
# marketingskills)的 sync-marketing.sh 会备份并恢复此子树，互不破坏。
# 仿 office/scripts/sync-lark.sh 模式：sparse-checkout 上游 skills/，镜像全部内容，
# 排除本地 SKILL.md / SYNC.md（顶层路由与同步文档），按需创建备份并刷新 SYNC.md 元数据。
#

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
UPSTREAM_REPO="https://github.com/heygen-com/hyperframes.git"
UPSTREAM_BRANCH="main"
UPSTREAM_PATH="skills"
# 上游根层功能文件（agent 指南），镜像到 TARGET_DIR 下并加 UPSTREAM- 前缀，
# 避免与 marketing 插件根的 CLAUDE.md（marketingskills 上游指南）混淆。
# 格式: "上游路径:本地文件名"
UPSTREAM_FILES=("CLAUDE.md:UPSTREAM-CLAUDE.md" "AGENTS.md:UPSTREAM-AGENTS.md")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TARGET_DIR="$SCRIPT_DIR/../skills/hyperframes"
BACKUP_DIR="$TARGET_DIR/.backup"
TEMP_DIR="/tmp/hyperframes-sync-$$"

# 本地文件（不被覆盖）——位于 TARGET_DIR 根层，不含子目录
LOCAL_FILES=("SKILL.md" "SYNC.md" "LICENSE" "UPSTREAM-CLAUDE.md" "UPSTREAM-AGENTS.md")

# 帮助信息
show_help() {
    cat << EOF
${BLUE}HyperFrames Skills 同步脚本${NC}

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
    $UPSTREAM_REPO (branch: $UPSTREAM_BRANCH, path: $UPSTREAM_PATH)

EOF
}

# 日志函数
log_info()    { printf "${BLUE}[INFO]${NC} %s\n" "$1"; }
log_success() { printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"; }
log_warning() { printf "${YELLOW}[WARNING]${NC} %s\n" "$1"; }
log_error()   { printf "${RED}[ERROR]${NC} %s\n" "$1"; }

# 原地更新 SYNC.md 中 **Key**: value 形式的字段
update_sync_md_field() {
    local file="$1" key="$2" value="$3"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|^\*\*$key\*\*: .*|**$key**: $value|" "$file"
    else
        sed -i "s|^\*\*$key\*\*: .*|**$key**: $value|" "$file"
    fi
}

# 检查必要工具
check_requirements() {
    local missing_tools=()
    for tool in git diff; do
        command -v "$tool" >/dev/null 2>&1 || missing_tools+=("$tool")
    done
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "缺少必要工具: ${missing_tools[*]}"
        exit 1
    fi
}

# 清理临时文件
cleanup() {
    [ -d "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# 克隆上游 skills 目录 + 根层功能文件（sparse checkout）
clone_upstream() {
    log_info "正在从上游仓库获取 skills 目录与根层功能文件..."

    mkdir -p "$TEMP_DIR"

    git clone --depth 1 --filter=blob:none --sparse \
        "$UPSTREAM_REPO" "$TEMP_DIR/repo" 2>/dev/null

    cd "$TEMP_DIR/repo"
    # cone 模式默认把参数当目录，文件路径需 --skip-checks
    local sparse_args=("$UPSTREAM_PATH")
    for entry in "${UPSTREAM_FILES[@]}"; do
        sparse_args+=("${entry%%:*}")
    done
    git sparse-checkout set --skip-checks "${sparse_args[@]}" 2>/dev/null
    cd - > /dev/null

    if [ ! -d "$TEMP_DIR/repo/$UPSTREAM_PATH" ]; then
        log_error "上游仓库中未找到 $UPSTREAM_PATH 目录"
        return 1
    fi

    log_success "上游文件获取完成"
    return 0
}

# 仅保留最近 KEEP_BACKUPS 份备份,清理更旧的
KEEP_BACKUPS=2
prune_backups() {
    [ -d "$BACKUP_DIR" ] || return 0
    local old
    while IFS= read -r old; do
        [ -n "$old" ] || continue
        rm -rf "$BACKUP_DIR/$old"
        log_info "已清理旧备份: $old"
    done < <(ls -1 "$BACKUP_DIR" 2>/dev/null | sort -r | tail -n +$((KEEP_BACKUPS + 1)))
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

    # 备份所有子目录与文件（排除 .backup 与根层本地文件）
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
    done < <(find "$TARGET_DIR" -maxdepth 1 -mindepth 1 -print0)

    if [ $count -gt 0 ]; then
        log_success "已备份 $count 个项目到: $backup_path"
        prune_backups
    else
        log_info "没有需要备份的内容"
        rmdir "$backup_path" 2>/dev/null || true
    fi
}

# 检查差异
check_diff() {
    local upstream_skills="$TEMP_DIR/repo/$UPSTREAM_PATH"
    local has_changes=false
    local new_count=0 changed_count=0 deleted_count=0

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
        elif ! diff -q "$local_file" "$upstream_file" >/dev/null 2>&1; then
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

        local skip=false
        for lf in "${LOCAL_FILES[@]}"; do
            [ "$basename" = "$lf" ] && [ "$dirname" = "." ] && skip=true && break
        done
        [[ "$rel_path" == .backup* ]] && skip=true
        [ "$skip" = true ] && continue

        local upstream_file="$upstream_skills/$rel_path"
        if [ ! -f "$upstream_file" ]; then
            deleted_count=$((deleted_count + 1))
            has_changes=true
        fi
    done < <(find "$TARGET_DIR" -type f -print0)

    # 根层功能文件（CLAUDE.md/AGENTS.md → UPSTREAM-*.md）
    for entry in "${UPSTREAM_FILES[@]}"; do
        local upstream_src="${entry%%:*}"
        local local_name="${entry##*:}"
        local upstream_file="$TEMP_DIR/repo/$upstream_src"
        [ -f "$upstream_file" ] || continue
        local local_file="$TARGET_DIR/$local_name"
        if [ ! -f "$local_file" ]; then
            new_count=$((new_count + 1)); has_changes=true
        elif ! diff -q "$local_file" "$upstream_file" >/dev/null 2>&1; then
            changed_count=$((changed_count + 1)); has_changes=true
        fi
    done

    if [ "$has_changes" = true ]; then
        [ $new_count -gt 0 ]      && log_info "  新增: $new_count 个文件"
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

    if [ "$no_backup" != "true" ]; then
        create_backup
    fi

    log_info "正在同步文件..."

    # 删除旧的上游内容（保留根层本地文件和备份）
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
    done < <(find "$TARGET_DIR" -maxdepth 1 -mindepth 1 -print0)

    # 复制上游内容（整棵 skills/ 子树镜像到 TARGET_DIR）
    local count=0
    while IFS= read -r -d '' item; do
        cp -R "$item" "$TARGET_DIR/"
        count=$((count + 1))
    done < <(find "$upstream_skills" -maxdepth 1 -mindepth 1 -print0)

    log_success "同步完成: 已同步 $count 个顶层条目"

    # 根层功能文件（CLAUDE.md/AGENTS.md → UPSTREAM-*.md，加前缀避免与 marketing 根的 CLAUDE.md 冲突）
    for entry in "${UPSTREAM_FILES[@]}"; do
        local upstream_src="${entry%%:*}"
        local local_name="${entry##*:}"
        local upstream_file="$TEMP_DIR/repo/$upstream_src"
        [ -f "$upstream_file" ] || continue
        cp "$upstream_file" "$TARGET_DIR/$local_name"
    done
    log_info "  已同步根层功能文件 (UPSTREAM-CLAUDE.md, UPSTREAM-AGENTS.md)"

    # 更新 SYNC.md 元数据：同步日期 / 上游分支 / 同步到的 commit
    local sync_md="$TARGET_DIR/SYNC.md"
    if [ -f "$sync_md" ]; then
        local synced_commit today
        today=$(date +%Y-%m-%d)
        synced_commit=$(git -C "$TEMP_DIR/repo" rev-parse --short HEAD 2>/dev/null || echo "unknown")
        update_sync_md_field "$sync_md" "Last sync" "$today"
        update_sync_md_field "$sync_md" "Synced commit" "$synced_commit"
        log_info "已更新 SYNC.md (date=$today, commit=$synced_commit)"
    fi
}

# 主函数
main() {
    local check_only=false
    local force_sync=false
    local no_backup=false

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

    log_info "开始同步 HyperFrames skills..."

    check_requirements
    clone_upstream

    local has_diff=0
    check_diff || has_diff=$?

    if [ "$check_only" = true ]; then
        if [ $has_diff -eq 0 ]; then
            log_success "没有更新"
            exit 0
        else
            log_info "有更新可用,运行 $0 进行同步"
            exit 1
        fi
    fi

    if [ $has_diff -eq 0 ] && [ "$force_sync" != true ]; then
        exit 0
    fi

    if [ "$force_sync" != true ] && [ -t 0 ]; then
        echo -n "是否继续同步? [y/N] "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "取消同步"
            exit 0
        fi
    fi

    sync_files "$no_backup"

    log_success "同步完成!"
    log_info "建议执行以下命令提交更改:"
    echo ""
    echo "    git add hyperframes/skills/hyperframes/"
    echo "    git-agent commit --no-stage --intent \"sync hyperframes skills from upstream heygen-com/hyperframes\""
    echo ""
}

main "$@"
