#!/usr/bin/env bash
#
# Agent-Browser Skill 同步脚本
# 从 vercel-labs/agent-browser 仓库同步整个 skill 文件夹到本地
#

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
UPSTREAM_BASE="https://raw.githubusercontent.com/vercel-labs/agent-browser/main/skills/agent-browser"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$SCRIPT_DIR/../skills/agent-browser"
BACKUP_DIR="$SCRIPT_DIR/../skills/agent-browser/.backup"

# 需要同步的文件列表
declare -a FILES=(
    "SKILL.md"
    "references/authentication.md"
    "references/proxy-support.md"
    "references/session-management.md"
    "references/snapshot-refs.md"
    "references/video-recording.md"
    "templates/authenticated-session.sh"
    "templates/capture-workflow.sh"
    "templates/form-automation.sh"
)

# 帮助信息
show_help() {
    cat << EOF
${BLUE}Agent-Browser Skill 同步脚本${NC}

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

    for tool in curl diff; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "缺少必要工具: ${missing_tools[*]}"
        exit 1
    fi
}

# 创建备份
create_backup() {
    if [ ! -d "$TARGET_DIR" ]; then
        log_info "目标目录不存在,跳过备份"
        return 0
    fi

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$BACKUP_DIR/$timestamp"

    mkdir -p "$backup_path"

    # 备份所有现有文件
    for file in "${FILES[@]}"; do
        local target_file="$TARGET_DIR/$file"
        if [ -f "$target_file" ]; then
            local backup_file="$backup_path/$file"
            mkdir -p "$(dirname "$backup_file")"
            cp "$target_file" "$backup_file"
        fi
    done

    log_success "已备份到: $backup_path"
}

# 下载单个文件
download_file() {
    local file="$1"
    local temp_dir="$2"
    local url="$UPSTREAM_BASE/$file"
    local temp_file="$temp_dir/$file"

    mkdir -p "$(dirname "$temp_file")"

    if curl -fsSL "$url" -o "$temp_file"; then
        return 0
    else
        log_error "下载失败: $file" >&2
        return 1
    fi
}

# 下载所有上游文件
download_upstream() {
    local temp_dir="/tmp/agent-browser-skill-$$"
    mkdir -p "$temp_dir"

    log_info "正在下载上游文件..."

    local failed_files=()
    for file in "${FILES[@]}"; do
        if ! download_file "$file" "$temp_dir"; then
            failed_files+=("$file")
        fi
    done

    if [ ${#failed_files[@]} -ne 0 ]; then
        log_error "以下文件下载失败: ${failed_files[*]}"
        rm -rf "$temp_dir"
        return 1
    fi

    echo "$temp_dir"
    return 0
}

# 检查差异
check_diff() {
    local temp_dir="$1"
    local has_changes=false

    if [ ! -d "$TARGET_DIR" ]; then
        log_warning "本地目录不存在,将创建新文件"
        return 1
    fi

    log_info "检查文件差异..."

    for file in "${FILES[@]}"; do
        local target_file="$TARGET_DIR/$file"
        local temp_file="$temp_dir/$file"

        if [ ! -f "$target_file" ]; then
            log_info "  新增: $file"
            has_changes=true
        elif ! diff -q "$target_file" "$temp_file" &> /dev/null; then
            log_info "  变更: $file"
            has_changes=true
        fi
    done

    if [ "$has_changes" = false ]; then
        log_success "所有文件已是最新版本"
        return 0
    else
        return 1
    fi
}

# 执行同步
sync_files() {
    local temp_dir="$1"
    local no_backup="$2"

    # 创建备份
    if [ "$no_backup" != "true" ]; then
        create_backup
    fi

    # 同步所有文件
    log_info "正在同步文件..."

    for file in "${FILES[@]}"; do
        local target_file="$TARGET_DIR/$file"
        local temp_file="$temp_dir/$file"

        mkdir -p "$(dirname "$target_file")"
        cp "$temp_file" "$target_file"

        # 如果是 .sh 文件，设置执行权限
        if [[ "$file" == *.sh ]]; then
            chmod +x "$target_file"
        fi
    done

    log_success "同步完成: $TARGET_DIR"

    # 更新 SYNC.md 中的同步时间（如果存在）
    local sync_md="$TARGET_DIR/SYNC.md"
    if [ -f "$sync_md" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/\*\*上次同步\*\*: .*/\*\*上次同步\*\*: $(date +%Y-%m-%d)/" "$sync_md"
        else
            sed -i "s/\*\*上次同步\*\*: .*/\*\*上次同步\*\*: $(date +%Y-%m-%d)/" "$sync_md"
        fi
        log_info "已更新 SYNC.md 中的同步时间"
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

    log_info "开始同步 agent-browser skill..."

    # 检查必要工具
    check_requirements

    # 下载上游文件
    local temp_dir
    temp_dir=$(download_upstream)
    if [ $? -ne 0 ]; then
        exit 1
    fi

    # 检查差异
    check_diff "$temp_dir"
    local has_diff=$?

    # 清理临时文件
    cleanup() {
        rm -rf "$temp_dir"
    }
    trap cleanup EXIT

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
    sync_files "$temp_dir" "$no_backup"

    log_success "✨ 同步完成!"
    log_info "建议执行以下命令提交更改:"
    echo ""
    echo "    git add office/skills/agent-browser/"
    echo "    git commit -m \"docs(office): sync agent-browser skill from upstream\""
    echo ""
}

main "$@"
