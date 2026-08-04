#!/usr/bin/env bash
#
# Interfaces Skills 同步脚本
# 从 jakubkrehel/skills 仓库镜像 skills/ 目录到本地 interfaces/skills/
#
# 与 hyperframes 的 <dirname>.md denest 不同，interfaces 使用 ref-pack 变换：
# 本地只注册一个路由器 skill（better-interface），其余 better-* 域在同步后
# 被降级为 better-interface/references/<domain>/ 参考包（SKILL.md → overview.md，
# 去除 frontmatter 与独立 Review Output Format 段，重写 better-* 交叉引用）。
# 路由器 SKILL.md 是本地自有文件（同步时保留），references/ 是从上游派生的
# 内容（每次同步整树重建，删除上游已移除的域）。
# 仿 hyperframes/scripts/sync-hyperframes.sh 模式：sparse-checkout 上游 skills/，
# 排除 agents/ 目录（上游 OpenAI agent 配置，非 Claude 技能）与上游
# better-interface/（本地路由器取代之），同步后执行 ref-pack denest。
#

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
UPSTREAM_REPO="https://github.com/jakubkrehel/skills.git"
UPSTREAM_BRANCH="main"
UPSTREAM_PATH="skills"
# 本地路由器 skill（本地自有 SKILL.md，同步时保留；references/ 派生内容整树重建）
ROUTER="better-interface"
# 参考包目录名去掉的域前缀（better-accessibility → accessibility）
STRIP_PREFIX="better-"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TARGET_DIR="$SCRIPT_DIR/../skills"
BACKUP_DIR="$TARGET_DIR/.backup"
TEMP_DIR="/tmp/interfaces-sync-$$"

# 本地保留的顶层条目（不被覆盖）
LOCAL_FILES=("$ROUTER" "SYNC.md")

# 共享 ref-pack 工具（repo 根 tools/skill-sync/）：子 skill → references/ 包
REF_PACK_SCRIPT="$SCRIPT_DIR/../../tools/skill-sync/denest.py"

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

cleanup() {
    [ -d "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# 克隆上游 skills 目录（sparse checkout）
clone_upstream() {
    log_info "正在从上游仓库获取 skills 目录..."

    mkdir -p "$TEMP_DIR"
    git clone --depth 1 --filter=blob:none --sparse \
        "$UPSTREAM_REPO" "$TEMP_DIR/repo" 2>/dev/null
    cd "$TEMP_DIR/repo"
    git sparse-checkout set --skip-checks "$UPSTREAM_PATH" 2>/dev/null
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

# 对指定目录执行与生产相同的 ref-pack denest（子 skill → references/ 包）
apply_ref_pack() {
    local tree="$1"
    if [ ! -f "$REF_PACK_SCRIPT" ]; then
        log_error "缺少共享 ref-pack 工具: $REF_PACK_SCRIPT（需要完整 repo 克隆）"
        return 1
    fi
    python3 "$REF_PACK_SCRIPT" --tree "$tree" \
        --ref-pack "$ROUTER" --strip-prefix "$STRIP_PREFIX" || return 1
}

# 检查差异（先对上游临时副本做 ref-pack 变换，再与本地比较）
check_diff() {
    local upstream_skills="$TEMP_DIR/repo/$UPSTREAM_PATH"
    local has_changes=false
    local new_count=0 changed_count=0 deleted_count=0

    if [ ! -d "$TARGET_DIR" ]; then
        log_warning "本地目录不存在,将创建新文件"
        return 1
    fi

    log_info "检查文件差异..."

    # 先把上游副本变换成 ref-pack 形态（空路由器占位），再与本地比较，
    # 避免 denest 被误报为变更/删除。路由器 SKILL.md 与 agents/ 两侧均排除。
    local compare_dir="$TEMP_DIR/refpacked"
    rm -rf "$compare_dir"
    mkdir -p "$compare_dir/$ROUTER"
    while IFS= read -r -d '' item; do
        local basename
        basename=$(basename "$item")
        [ "$basename" = "$ROUTER" ] && continue
        cp -R "$item" "$compare_dir/"
    done < <(find "$upstream_skills" -maxdepth 1 -mindepth 1 -print0)
    apply_ref_pack "$compare_dir" || return 1
    upstream_skills="$compare_dir"

    # 检查新增和变更的文件
    while IFS= read -r -d '' upstream_file; do
        local rel_path="${upstream_file#$upstream_skills/}"
        [[ "$rel_path" == "$ROUTER"/* || "$rel_path" == *"/agents/"* ]] && continue
        local local_file="$TARGET_DIR/$rel_path"

        if [ ! -f "$local_file" ]; then
            new_count=$((new_count + 1))
            has_changes=true
        elif ! diff -q "$local_file" "$upstream_file" >/dev/null 2>&1; then
            changed_count=$((changed_count + 1))
            has_changes=true
        fi
    done < <(find "$upstream_skills" -type f -print0)

    # 检查本地已删除的上游文件（本地自有文件与派生的 references/ 旧包除外）
    while IFS= read -r -d '' local_file; do
        local rel_path="${local_file#$TARGET_DIR/}"
        local basename
        basename=$(basename "$rel_path")

        local skip=false
        [[ "$rel_path" == .backup* ]] && skip=true
        for lf in "${LOCAL_FILES[@]}"; do
            [ "$basename" = "$lf" ] && [ "$(dirname "$rel_path")" = "." ] && skip=true && break
        done
        # 路由器 SKILL.md 是本地自有文件（上游 better-interface/ 不同步）
        [ "$rel_path" = "$ROUTER/SKILL.md" ] && skip=true
        [ "$skip" = true ] && continue

        local upstream_file="$upstream_skills/$rel_path"
        if [ ! -f "$upstream_file" ]; then
            deleted_count=$((deleted_count + 1))
            has_changes=true
        fi
    done < <(find "$TARGET_DIR" -type f -print0)

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

    # 删除旧的上游内容（保留本地路由器、同步文档与备份）
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

    # references/ 是派生内容：整树重建，确保上游移除的域同步删除
    rm -rf "$TARGET_DIR/$ROUTER/references"

    # 复制上游内容（排除 agents/ 与上游 better-interface/）
    local count=0
    while IFS= read -r -d '' item; do
        local basename
        basename=$(basename "$item")
        [ "$basename" = "$ROUTER" ] && continue
        cp -R "$item" "$TARGET_DIR/"
        count=$((count + 1))
    done < <(find "$upstream_skills" -maxdepth 1 -mindepth 1 -print0)
    find "$TARGET_DIR" -type d -name agents -prune -exec rm -rf {} + 2>/dev/null || true

    log_success "同步完成: 已同步 $count 个顶层条目"

    # ref-pack 降级子 skill（→ references/<domain>/ 包，仅路由器可被发现）
    log_info "正在应用 ref-pack 变换（子 skill → references/ 包）..."
    apply_ref_pack "$TARGET_DIR" || return 1

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

show_help() {
    cat << EOF
${BLUE}Interfaces Skills 同步脚本${NC}

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

${GREEN}本地变换:${NC}
    同步后将 better-* 子 skill 降级为 $ROUTER/references/<domain>/ 参考包
    （SKILL.md → overview.md；仅路由器 SKILL.md 可被 skill 发现）

EOF
}

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

    log_info "开始同步 Interfaces skills..."

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
    echo "    git add interfaces/skills/"
    echo "    git-agent commit --no-stage --intent \"sync interfaces skills from upstream jakubkrehel/skills\""
    echo ""
}

main "$@"
