#!/usr/bin/env bash
#
# Marketing Skills 同步脚本
# 从 coreyhaines31/marketingskills 仓库镜像全部功能内容到本地 marketing/
#
# 上游本身是一个 Claude Code 插件（"skills": "./skills" 自动发现，无路由 skill）。
# 为与上游功能完全一致，本脚本镜像：
#   - 两棵子树：skills/ tools/（整棵重建，删除生效）
#   - 根层功能文件：CLAUDE.md AGENTS.md VERSIONS.md validate-skills.sh
#     validate-skills-official.sh（单文件覆盖）
# 排除上游仓库元数据（README.md CONTRIBUTING.md .github/ .gitignore FUNDING.yml
# LICENSE），这些由本地市场元数据取代。
# 本地保留：scripts/ .backup/ .claude-plugin/ skills/SYNC.md（同步文档）。
# 刷新 marketing/skills/SYNC.md 的元数据。
#

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

UPSTREAM_REPO="https://github.com/coreyhaines31/marketingskills.git"
UPSTREAM_BRANCH="main"
# 镜像的子树（上游根下，整棵重建）
UPSTREAM_PATHS=("skills" "tools")
# 镜像的根层功能文件（单文件覆盖，逐个拷贝）
UPSTREAM_FILES=("CLAUDE.md" "AGENTS.md" "VERSIONS.md" "validate-skills.sh" "validate-skills-official.sh")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TARGET_DIR="$SCRIPT_DIR/.."
BACKUP_DIR="$TARGET_DIR/.backup"
TEMP_DIR="/tmp/marketing-sync-$$"

# 本地文件/目录（marketing/ 根层，不被覆盖）——脚本目录、备份、插件清单、同步文档
LOCAL_TOP=("scripts" ".backup" ".claude-plugin")

log_info()    { printf "${BLUE}[INFO]${NC} %s\n" "$1"; }
log_success() { printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"; }
log_warning() { printf "${YELLOW}[WARNING]${NC} %s\n" "$1"; }
log_error()   { printf "${RED}[ERROR]${NC} %s\n" "$1"; }

update_sync_md_field() {
    local file="$1" key="$2" value="$3"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|^\*\*$key\*\*: .*|**$key**: $value|" "$file"
    else
        sed -i "s|^\*\*$key\*\*: .*|**$key**: $value|" "$file"
    fi
}

check_requirements() {
    local missing=()
    for tool in git diff; do
        command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
    done
    if [ ${#missing[@]} -ne 0 ]; then
        log_error "缺少必要工具: ${missing[*]}"
        exit 1
    fi
}

cleanup() { [ -d "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"; }
trap cleanup EXIT

clone_upstream() {
    log_info "正在从上游仓库获取 skills/ tools/ 与根层功能文件 ..."
    mkdir -p "$TEMP_DIR"
    git clone --depth 1 --filter=blob:none --sparse \
        "$UPSTREAM_REPO" "$TEMP_DIR/repo" 2>/dev/null
    cd "$TEMP_DIR/repo"
    git sparse-checkout set --skip-checks "${UPSTREAM_PATHS[@]}" "${UPSTREAM_FILES[@]}" 2>/dev/null
    cd - > /dev/null
    for p in "${UPSTREAM_PATHS[@]}"; do
        if [ ! -d "$TEMP_DIR/repo/$p" ]; then
            log_error "上游仓库中未找到 $p 目录"
            return 1
        fi
    done
    log_success "上游文件获取完成"
}

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

create_backup() {
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$BACKUP_DIR/$timestamp"
    mkdir -p "$backup_path"
    local count=0
    while IFS= read -r -d '' item; do
        local basename
        basename=$(basename "$item")
        local skip=false
        for lf in "${LOCAL_TOP[@]}"; do
            [ "$basename" = "$lf" ] && skip=true && break
        done
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

check_diff() {
    local has_changes=false new_c=0 changed_c=0 deleted_c=0
    # 本地保留条目（skills/ 根层，不被视为上游删除）：
    #   SYNC.md = 本同步文档；hyperframes/ = 镜像自 heygen-com/hyperframes 的子树
    #   （由 sync-hyperframes.sh 独立同步，本脚本不触碰）
    local local_skill_keep=("SYNC.md" "hyperframes")
    for p in "${UPSTREAM_PATHS[@]}"; do
        local upstream_root="$TEMP_DIR/repo/$p"
        local local_root="$TARGET_DIR/$p"
        if [ ! -d "$local_root" ]; then
            log_warning "本地 $p/ 不存在,将创建"
            has_changes=true
            continue
        fi
        while IFS= read -r -d '' uf; do
            local rel="${uf#$upstream_root/}"
            local lf="$local_root/$rel"
            if [ ! -f "$lf" ]; then
                new_c=$((new_c + 1)); has_changes=true
            elif ! diff -q "$lf" "$uf" >/dev/null 2>&1; then
                changed_c=$((changed_c + 1)); has_changes=true
            fi
        done < <(find "$upstream_root" -type f -print0)
        while IFS= read -r -d '' lf; do
            local rel="${lf#$local_root/}"
            # 跳过本地保留条目（文件或目录的顶层名）
            local top="${rel%%/*}"
            local skip=false
            for lsf in "${local_skill_keep[@]}"; do
                [ "$top" = "$lsf" ] && skip=true && break
            done
            [ "$skip" = true ] && continue
            local uf="$upstream_root/$rel"
            if [ ! -f "$uf" ]; then
                deleted_c=$((deleted_c + 1)); has_changes=true
            fi
        done < <(find "$local_root" -type f -print0)
    done
    # 根层功能文件（单文件）
    for uf in "${UPSTREAM_FILES[@]}"; do
        local upstream_file="$TEMP_DIR/repo/$uf"
        [ -f "$upstream_file" ] || continue
        local local_file="$TARGET_DIR/$uf"
        if [ ! -f "$local_file" ]; then
            new_c=$((new_c + 1)); has_changes=true
        elif ! diff -q "$local_file" "$upstream_file" >/dev/null 2>&1; then
            changed_c=$((changed_c + 1)); has_changes=true
        fi
    done
    if [ "$has_changes" = true ]; then
        log_info "检查文件差异..."
        [ $new_c -gt 0 ]     && log_info "  新增: $new_c 个文件"
        [ $changed_c -gt 0 ] && log_info "  变更: $changed_c 个文件"
        [ $deleted_c -gt 0 ] && log_info "  删除: $deleted_c 个文件(上游已移除)"
        return 1
    fi
    log_success "所有文件已是最新版本"
    return 0
}

sync_files() {
    local no_backup="$1"
    if [ "$no_backup" != "true" ]; then create_backup; fi
    log_info "正在同步文件..."

    # 备份本地 skills/SYNC.md 与 skills/hyperframes/ 子树
    # （整棵重建 skills/ 会把它们删掉；hyperframes/ 由 sync-hyperframes.sh 独立同步）
    local local_sync_md="$TARGET_DIR/skills/SYNC.md"
    local sync_md_backup=""
    if [ -f "$local_sync_md" ]; then
        sync_md_backup="$TEMP_DIR/local-SYNC.md"
        cp "$local_sync_md" "$sync_md_backup"
    fi
    local local_hf="$TARGET_DIR/skills/hyperframes"
    local hf_backup=""
    if [ -d "$local_hf" ]; then
        hf_backup="$TEMP_DIR/local-hyperframes"
        cp -R "$local_hf" "$hf_backup"
    fi

    for p in "${UPSTREAM_PATHS[@]}"; do
        local upstream_root="$TEMP_DIR/repo/$p"
        local local_root="$TARGET_DIR/$p"
        # 删除旧的本地镜像子树（整棵重建，保证删除生效）
        rm -rf "$local_root"
        mkdir -p "$local_root"
        while IFS= read -r -d '' item; do
            cp -R "$item" "$local_root/"
        done < <(find "$upstream_root" -maxdepth 1 -mindepth 1 -print0)
        log_info "  已同步 $p/"
    done
    # 根层功能文件（单文件覆盖）
    for uf in "${UPSTREAM_FILES[@]}"; do
        local upstream_file="$TEMP_DIR/repo/$uf"
        [ -f "$upstream_file" ] || continue
        cp "$upstream_file" "$TARGET_DIR/$uf"
    done
    log_info "  已同步根层功能文件: ${UPSTREAM_FILES[*]}"
    log_success "同步完成"

    # 恢复本地 hyperframes/ 子树（由 sync-hyperframes.sh 独立同步，本脚本不动）
    if [ -n "$hf_backup" ]; then
        cp -R "$hf_backup" "$TARGET_DIR/skills/hyperframes"
        log_info "  已恢复 skills/hyperframes/ 子树"
    fi

    # 恢复本地 SYNC.md 并刷新元数据
    local sync_md="$TARGET_DIR/skills/SYNC.md"
    if [ -n "$sync_md_backup" ]; then
        cp "$sync_md_backup" "$sync_md"
    elif [ ! -f "$sync_md" ]; then
        log_warning "本地 skills/SYNC.md 不存在，跳过元数据刷新"
        return 0
    fi
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
${BLUE}Marketing Skills 同步脚本${NC}

${GREEN}用法:${NC}
    $0 [选项]

${GREEN}选项:${NC}
    -h, --help          显示此帮助信息
    -c, --check         仅检查是否有更新,不执行同步
    -f, --force         强制同步,跳过确认
    --no-backup         同步时不创建备份

${GREEN}上游:${NC}
    $UPSTREAM_REPO (branch: $UPSTREAM_BRANCH, paths: ${UPSTREAM_PATHS[*]})
EOF
}

main() {
    local check_only=false force_sync=false no_backup=false
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help) show_help; exit 0 ;;
            -c|--check) check_only=true; shift ;;
            -f|--force) force_sync=true; shift ;;
            --no-backup) no_backup=true; shift ;;
            *) log_error "未知选项: $1"; show_help; exit 1 ;;
        esac
    done
    log_info "开始同步 Marketing skills..."
    check_requirements
    clone_upstream
    local has_diff=0
    check_diff || has_diff=$?
    if [ "$check_only" = true ]; then
        if [ $has_diff -eq 0 ]; then log_success "没有更新"; exit 0; fi
        log_info "有更新可用,运行 $0 进行同步"; exit 1
    fi
    if [ $has_diff -eq 0 ] && [ "$force_sync" != true ]; then exit 0; fi
    if [ "$force_sync" != true ] && [ -t 0 ]; then
        echo -n "是否继续同步? [y/N] "
        read -r response
        [[ "$response" =~ ^[Yy]$ ]] || { log_info "取消同步"; exit 0; }
    fi
    sync_files "$no_backup"
    log_success "同步完成!"
    log_info "建议提交: git-agent commit --no-stage --intent \"sync marketing skills from upstream coreyhaines31/marketingskills\""
}

main "$@"
