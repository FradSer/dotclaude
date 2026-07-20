#!/usr/bin/env bash
#
# Lark CLI Skills 同步脚本
# 从 larksuite/cli 仓库同步 skills/ 目录到本地
#

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
UPSTREAM_REPO="https://github.com/larksuite/cli.git"
UPSTREAM_BRANCH="main"
UPSTREAM_PATH="skills"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TARGET_DIR="$SCRIPT_DIR/../skills/lark"
BACKUP_DIR="$TARGET_DIR/.backup"
TEMP_DIR="/tmp/lark-cli-sync-$$"

# 本地文件（不被覆盖）
LOCAL_FILES=("SKILL.md" "SYNC.md")

# 上游子 skill 以 SKILL.md 交付；同步后改名为 <dirname>.md，避免被
# Claude/Cursor 当成独立 skill 误发现。见 denest-lark-skills.py。
DENEST_SCRIPT="$SCRIPT_DIR/denest-lark-skills.py"

# 帮助信息
show_help() {
    cat << EOF
${BLUE}Lark CLI Skills 同步脚本${NC}

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

${GREEN}本地变换:${NC}
    同步后将 lark-*/SKILL.md 重命名为 lark-*/<dirname>.md
    （仅根目录 SKILL.md 路由器可被 skill 发现）

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

# 克隆上游 skills 目录（sparse checkout）
clone_upstream() {
    log_info "正在从上游仓库获取 skills 目录..."

    mkdir -p "$TEMP_DIR"

    git clone --depth 1 --filter=blob:none --sparse \
        "$UPSTREAM_REPO" "$TEMP_DIR/repo" 2>/dev/null

    cd "$TEMP_DIR/repo"
    git sparse-checkout set "$UPSTREAM_PATH" 2>/dev/null
    cd - > /dev/null

    if [ ! -d "$TEMP_DIR/repo/$UPSTREAM_PATH" ]; then
        log_error "上游仓库中未找到 $UPSTREAM_PATH 目录"
        return 1
    fi

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

    # 备份所有子目录（排除 .backup 和本地文件）
    local count=0
    while IFS= read -r -d '' item; do
        local basename
        basename=$(basename "$item")

        # 跳过本地文件和备份目录
        local skip=false
        for local_file in "${LOCAL_FILES[@]}"; do
            if [ "$basename" = "$local_file" ]; then
                skip=true
                break
            fi
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

# 仅保留最近 KEEP_BACKUPS 份备份,清理更旧的(避免镜像备份无限累积)
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

# 在给定目录上执行与生产相同的 denest（rename SKILL.md + 重写链接）
apply_denest() {
    local tree="$1"
    if [ ! -f "$DENEST_SCRIPT" ]; then
        log_error "缺少 denest 脚本: $DENEST_SCRIPT"
        return 1
    fi
    LARK_DIR_OVERRIDE="$tree" DENEST_SCRIPT="$DENEST_SCRIPT" python3 - <<'PY'
from pathlib import Path
import importlib.util
import os
import sys

script = os.environ["DENEST_SCRIPT"]
spec = importlib.util.spec_from_file_location("denest", script)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
mod.LARK_DIR = Path(os.environ["LARK_DIR_OVERRIDE"]).resolve()
renamed = mod.rename_nested()
links = mod.rewrite_links()
print(f"denest: renamed={len(renamed)} link_files={links}", file=sys.stderr)
PY
}

# 检查差异（先对上游临时副本做 denest，再与本地比较）
check_diff() {
    local upstream_skills="$TEMP_DIR/repo/$UPSTREAM_PATH"
    local compare_dir="$TEMP_DIR/denested"
    local has_changes=false
    local new_count=0
    local changed_count=0
    local deleted_count=0

    if [ ! -d "$TARGET_DIR" ]; then
        log_warning "本地目录不存在,将创建新文件"
        return 1
    fi

    log_info "检查文件差异..."

    rm -rf "$compare_dir"
    mkdir -p "$compare_dir"
    # 只镜像上游 skill 子树，再应用与本地相同的 denest
    while IFS= read -r -d '' item; do
        cp -R "$item" "$compare_dir/"
    done < <(find "$upstream_skills" -maxdepth 1 -mindepth 1 -print0)
    apply_denest "$compare_dir" || return 1

    # 检查新增和变更的文件
    while IFS= read -r -d '' upstream_file; do
        local rel_path="${upstream_file#$compare_dir/}"
        local local_file="$TARGET_DIR/$rel_path"

        if [ ! -f "$local_file" ]; then
            new_count=$((new_count + 1))
            has_changes=true
        elif ! diff -q "$local_file" "$upstream_file" &> /dev/null; then
            changed_count=$((changed_count + 1))
            has_changes=true
        fi
    done < <(find "$compare_dir" -type f -print0)

    # 检查本地已删除的上游文件
    while IFS= read -r -d '' local_file; do
        local rel_path="${local_file#$TARGET_DIR/}"
        local basename
        basename=$(basename "$rel_path")
        local dirname
        dirname=$(dirname "$rel_path")

        # 跳过本地文件和备份目录
        local skip=false
        for lf in "${LOCAL_FILES[@]}"; do
            [ "$basename" = "$lf" ] && [ "$dirname" = "." ] && skip=true && break
        done
        [[ "$rel_path" == .backup* ]] && skip=true
        [ "$skip" = true ] && continue

        local upstream_file="$compare_dir/$rel_path"
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

    # 删除旧的上游内容（保留本地文件和备份）
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

    # 复制上游内容
    local count=0
    while IFS= read -r -d '' item; do
        cp -R "$item" "$TARGET_DIR/"
        count=$((count + 1))
    done < <(find "$upstream_skills" -maxdepth 1 -mindepth 1 -print0)

    log_success "同步完成: 已同步 $count 个 skill 目录"

    # 重命名嵌套 SKILL.md，避免被当成独立 skill 发现
    log_info "正在 denest 子 skill（SKILL.md → <dirname>.md）..."
    apply_denest "$TARGET_DIR" || return 1

    # 按子 skill frontmatter 刷新路由器索引表
    if [ -f "$SCRIPT_DIR/gen-lark-index.py" ]; then
        python3 "$SCRIPT_DIR/gen-lark-index.py" || log_warning "gen-lark-index.py 失败，请手动重跑"
    fi

    # 更新 SYNC.md 元数据：同步日期 / 已装 lark-cli 版本 / 同步到的 commit
    local sync_md="$TARGET_DIR/SYNC.md"
    if [ -f "$sync_md" ]; then
        local lark_ver synced_commit today
        today=$(date +%Y-%m-%d)
        lark_ver=$(lark-cli --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        [ -z "$lark_ver" ] && lark_ver="unknown"
        synced_commit=$(git -C "$TEMP_DIR/repo" rev-parse --short HEAD 2>/dev/null || echo "unknown")
        update_sync_md_field "$sync_md" "Last sync" "$today"
        update_sync_md_field "$sync_md" "lark-cli version" "$lark_ver"
        update_sync_md_field "$sync_md" "Synced commit" "$synced_commit"
        log_info "已更新 SYNC.md (date=$today, lark-cli=$lark_ver, commit=$synced_commit)"
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

    log_info "开始同步 Lark CLI skills..."

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
    log_info "建议执行以下命令提交更改:"
    echo ""
    echo "    git add office/skills/lark/"
    echo "    git-agent commit --no-stage --intent \"sync lark skills from upstream larksuite/cli\" --co-author \"Claude Opus 4.6 <noreply@anthropic.com>\""
    echo ""
}

main "$@"
