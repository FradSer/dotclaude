#!/usr/bin/env bash
#
# Impeccable Skills 同步脚本
# 从 pbakaus/impeccable 仓库同步 .claude/skills/ 和 .claude/agents/anti-patterns.md
# 子 skill 自动添加 impeccable- 前缀（impeccable 本身不加）
#

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
UPSTREAM_REPO="https://github.com/pbakaus/impeccable.git"
UPSTREAM_BRANCH="main"
UPSTREAM_SKILLS_PATH=".claude/skills"
UPSTREAM_AGENTS_PATH=".claude/agents"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TARGET_SKILLS_DIR="$SCRIPT_DIR/../skills"
TARGET_AGENTS_DIR="$SCRIPT_DIR/../agents"
SYNC_FILE="$SCRIPT_DIR/../SYNC.md"
TEMP_DIR="/tmp/impeccable-sync-$$"

# impeccable skill 的 SKILL.md 保留本地版本，上游原文存为 reference
IMPECCABLE_LOCAL_SKILL=true

# 上游名 -> 本地目录名映射
# impeccable 保持原名，其余加 impeccable- 前缀
get_target_name() {
    local upstream_name="$1"
    if [ "$upstream_name" = "impeccable" ]; then
        echo "impeccable"
    else
        echo "impeccable-$upstream_name"
    fi
}

# 帮助信息
show_help() {
    cat << EOF
${BLUE}Impeccable Skills 同步脚本${NC}

${GREEN}用法:${NC}
    $0 [选项]

${GREEN}选项:${NC}
    -h, --help          显示此帮助信息
    -c, --check         仅检查是否有更新,不执行同步
    -f, --force         强制同步,跳过确认
    --no-backup         同步时不创建备份

${GREEN}同步内容:${NC}
    - .claude/skills/impeccable -> frontend/skills/impeccable
    - .claude/skills/<name>     -> frontend/skills/impeccable-<name>
    - .claude/agents/anti-patterns.md -> frontend/agents/references/

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
    log_info "正在从上游仓库获取 .claude 目录..."

    mkdir -p "$TEMP_DIR"

    git clone --depth 1 --filter=blob:none --sparse \
        "$UPSTREAM_REPO" "$TEMP_DIR/repo" 2>/dev/null

    cd "$TEMP_DIR/repo" >/dev/null 2>&1
    git sparse-checkout set "$UPSTREAM_SKILLS_PATH" "$UPSTREAM_AGENTS_PATH" 2>/dev/null
    cd - >/dev/null 2>&1

    if [ ! -d "$TEMP_DIR/repo/$UPSTREAM_SKILLS_PATH" ]; then
        log_error "上游仓库中未找到 $UPSTREAM_SKILLS_PATH 目录"
        return 1
    fi

    log_success "上游文件获取完成"
    return 0
}

# 发现上游 skill 目录
discover_skills() {
    local skills=()
    while IFS= read -r -d '' dir; do
        local name
        name=$(basename "$dir")
        skills+=("$name")
    done < <(find "$TEMP_DIR/repo/$UPSTREAM_SKILLS_PATH" -maxdepth 1 -mindepth 1 -type d -print0)
    echo "${skills[@]}"
}

# 创建备份
create_backup() {
    local target_name="$1"
    local skill_target="$TARGET_SKILLS_DIR/$target_name"
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
        [ "$basename" = ".backup" ] && skip=true
        [ "$skip" = true ] && continue
        cp -R "$item" "$backup_path/"
        count=$((count + 1))
    done < <(find "$skill_target" -maxdepth 1 -mindepth 1 -print0)

    if [ $count -gt 0 ]; then
        log_success "  已备份 $target_name: $count 个项目"
    else
        rmdir "$backup_path" 2>/dev/null || true
    fi
}

# 检查差异
check_diff() {
    local has_changes=false
    log_info "检查文件差异..."

    local skills
    skills=$(discover_skills)
    for skill in $skills; do
        local target_name
        target_name=$(get_target_name "$skill")
        local upstream_skill="$TEMP_DIR/repo/$UPSTREAM_SKILLS_PATH/$skill"
        local local_skill="$TARGET_SKILLS_DIR/$target_name"

        if [ ! -d "$local_skill" ]; then
            log_info "  $target_name: 新 skill 目录"
            has_changes=true
            continue
        fi

        local new_count=0
        local changed_count=0
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
            [ $new_count -gt 0 ] && log_info "  $target_name: 新增 $new_count 个文件"
            [ $changed_count -gt 0 ] && log_info "  $target_name: 变更 $changed_count 个文件"
            has_changes=true
        fi
    done

    # 检查 anti-patterns agent
    local upstream_agent="$TEMP_DIR/repo/$UPSTREAM_AGENTS_PATH/anti-patterns.md"
    local local_agent="$TARGET_AGENTS_DIR/references/anti-patterns.md"
    if [ -f "$upstream_agent" ]; then
        if [ ! -f "$local_agent" ]; then
            log_info "  anti-patterns agent: 新文件"
            has_changes=true
        elif ! diff -q "$local_agent" "$upstream_agent" &> /dev/null; then
            log_info "  anti-patterns agent: 有变更"
            has_changes=true
        fi
    fi

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
    local target_name
    target_name=$(get_target_name "$skill_name")
    local upstream_skill="$TEMP_DIR/repo/$UPSTREAM_SKILLS_PATH/$skill_name"
    local skill_target="$TARGET_SKILLS_DIR/$target_name"

    [ "$no_backup" != "true" ] && create_backup "$target_name"

    mkdir -p "$skill_target"

    # 构建跳过列表
    local skip_files=()
    local is_impeccable=false

    if [ "$skill_name" = "impeccable" ] && [ "$IMPECCABLE_LOCAL_SKILL" = true ]; then
        skip_files+=("SKILL.md")
        is_impeccable=true
    fi

    # 删除旧内容（保留本地文件和备份）
    while IFS= read -r -d '' item; do
        local basename
        basename=$(basename "$item")
        local skip=false
        for sf in "${skip_files[@]}"; do
            [ "$basename" = "$sf" ] && skip=true && break
        done
        [ "$basename" = ".backup" ] && skip=true
        [ "$skip" = true ] && continue
        rm -rf "$item"
    done < <(find "$skill_target" -maxdepth 1 -mindepth 1 -print0)

    # 复制上游内容（impeccable 跳过 SKILL.md）
    local count=0
    while IFS= read -r -d '' item; do
        local item_basename
        item_basename=$(basename "$item")
        if [ "$is_impeccable" = true ] && [ "$item_basename" = "SKILL.md" ]; then
            continue
        fi
        cp -R "$item" "$skill_target/"
        count=$((count + 1))
    done < <(find "$upstream_skill" -maxdepth 1 -mindepth 1 -print0)

    # impeccable: 保存上游 SKILL.md 到 reference/
    if [ "$is_impeccable" = true ] && [ -f "$upstream_skill/SKILL.md" ]; then
        mkdir -p "$skill_target/reference"
        cp "$upstream_skill/SKILL.md" "$skill_target/reference/SKILL.md"
        log_info "  $target_name: 上游 SKILL.md 已保存为 reference/SKILL.md"
    fi

    # 子 skill: 将 user-invocable 改为 false（仅 impeccable 保持 true）
    if [ "$is_impeccable" = false ] && [ -f "$skill_target/SKILL.md" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' 's/^user-invocable: true$/user-invocable: false/' "$skill_target/SKILL.md"
        else
            sed -i 's/^user-invocable: true$/user-invocable: false/' "$skill_target/SKILL.md"
        fi
    fi

    log_success "  $target_name: 已同步 $count 个项目"

    # 更新 SYNC.md 时间
    local sync_md="$SYNC_FILE"
    if [ -f "$sync_md" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/\*\*上次同步\*\*: .*/\*\*上次同步\*\*: $(date +%Y-%m-%d)/" "$sync_md"
        else
            sed -i "s/\*\*上次同步\*\*: .*/\*\*上次同步\*\*: $(date +%Y-%m-%d)/" "$sync_md"
        fi
    fi
}

# 同步 anti-patterns agent 原始文本
sync_agent() {
    local upstream_agent="$TEMP_DIR/repo/$UPSTREAM_AGENTS_PATH/anti-patterns.md"
    local target_ref_dir="$TARGET_AGENTS_DIR/references"

    if [ ! -f "$upstream_agent" ]; then
        log_warning "上游未找到 anti-patterns.md"
        return 0
    fi

    mkdir -p "$target_ref_dir"
    cp "$upstream_agent" "$target_ref_dir/anti-patterns.md"
    log_success "  anti-patterns agent: 已保存原始文本到 agents/references/"
}

# 执行同步
sync_files() {
    local no_backup="$1"
    log_info "正在同步 skills..."

    local skills
    skills=$(discover_skills)
    local skill_count=0
    for skill in $skills; do
        sync_skill "$skill" "$no_backup"
        skill_count=$((skill_count + 1))
    done

    log_info "正在同步 anti-patterns agent..."
    sync_agent

    # 设置脚本执行权限
    find "$TARGET_SKILLS_DIR" -name "*.mjs" -exec chmod +x {} \; 2>/dev/null || true
    find "$TARGET_SKILLS_DIR" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

    log_success "共同步 $skill_count 个 skills + 1 个 agent 参考文件"
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

    log_info "开始同步 Impeccable design skills..."
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
    echo "    git add frontend/skills/ frontend/agents/references/"
    echo "    git-agent commit --no-stage --intent \"sync impeccable design skills from upstream\" --co-author \"Claude Opus 4.6 <noreply@anthropic.com>\""
    echo ""
}

main "$@"
