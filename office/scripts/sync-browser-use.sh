#!/usr/bin/env bash
#
# Browser-Use Skill 同步脚本
# 从上游仓库同步 SKILL.md 到本地
#

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
UPSTREAM_URL="https://raw.githubusercontent.com/browser-use/browser-use/main/skills/browser-use/SKILL.md"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_FILE="$SCRIPT_DIR/../skills/browser-use/SKILL.md"
BACKUP_DIR="$SCRIPT_DIR/../skills/browser-use/.backup"

# 帮助信息
show_help() {
    cat << EOF
${BLUE}Browser-Use Skill 同步脚本${NC}

${GREEN}用法:${NC}
    $0 [选项]

${GREEN}选项:${NC}
    -h, --help          显示此帮助信息
    -c, --check         仅检查是否有更新,不执行同步
    -f, --force         强制同步,跳过备份
    --no-backup         同步时不创建备份

${GREEN}示例:${NC}
    $0                  # 同步并备份现有文件
    $0 --check          # 仅检查更新
    $0 --force          # 强制同步,跳过备份

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
    if [ ! -f "$TARGET_FILE" ]; then
        log_info "目标文件不存在,跳过备份"
        return 0
    fi

    mkdir -p "$BACKUP_DIR"
    local backup_file="$BACKUP_DIR/SKILL.md.$(date +%Y%m%d_%H%M%S)"
    cp "$TARGET_FILE" "$backup_file"
    log_success "已备份到: $backup_file"
}

# 下载上游文件
download_upstream() {
    local temp_file="/tmp/browser-use-skill-$$.md"

    log_info "正在下载上游文件..." >&2
    if curl -fsSL "$UPSTREAM_URL" -o "$temp_file"; then
        echo "$temp_file"
        return 0
    else
        log_error "下载失败" >&2
        rm -f "$temp_file"
        return 1
    fi
}

# 检查差异
check_diff() {
    local upstream_file="$1"

    if [ ! -f "$TARGET_FILE" ]; then
        log_warning "本地文件不存在,将创建新文件"
        return 1
    fi

    if diff -q "$TARGET_FILE" "$upstream_file" &> /dev/null; then
        log_success "本地文件已是最新版本"
        return 0
    else
        log_info "检测到差异,显示前 20 行变更:"
        echo ""
        diff -u "$TARGET_FILE" "$upstream_file" 2>&1 | head -20 || true
        echo ""
        log_info "(如需查看完整差异,运行: diff -u $TARGET_FILE $upstream_file)"
        return 1
    fi
}

# 执行同步
sync_file() {
    local upstream_file="$1"
    local no_backup="$2"

    # 创建备份
    if [ "$no_backup" != "true" ]; then
        create_backup
    fi

    # 复制文件
    cp "$upstream_file" "$TARGET_FILE"
    log_success "同步完成: $TARGET_FILE"

    # 更新 SYNC.md 中的同步时间
    local sync_md="$SCRIPT_DIR/../skills/browser-use/SYNC.md"
    if [ -f "$sync_md" ]; then
        # 使用 sed 更新最后同步时间
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s/\*\*上次同步\*\*: .*/\*\*上次同步\*\*: $(date +%Y-%m-%d)/" "$sync_md"
        else
            # Linux
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

    log_info "开始同步 browser-use skill..."

    # 检查必要工具
    check_requirements

    # 下载上游文件
    local upstream_file
    upstream_file=$(download_upstream)
    if [ $? -ne 0 ]; then
        exit 1
    fi

    # 检查差异
    check_diff "$upstream_file"
    local has_diff=$?

    # 清理临时文件
    cleanup() {
        rm -f "$upstream_file"
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
    sync_file "$upstream_file" "$no_backup"

    log_success "✨ 同步完成!"
    log_info "建议执行以下命令提交更改:"
    echo ""
    echo "    git add office/skills/browser-use/SKILL.md office/skills/browser-use/SYNC.md"
    echo "    git commit -m \"docs(office): sync browser-use skill from upstream\""
    echo ""
}

main "$@"
