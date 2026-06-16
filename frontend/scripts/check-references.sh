#!/usr/bin/env bash
#
# 引用完整性校验:扫描 frontend/skills/ 下所有 SKILL.md，
# 检查其引用的 reference 文件是否真实存在。
# 上游重构（删除/重命名 reference 文件）后，本地 SKILL.md 的链接会静默失效；
# 每个 sync 脚本收尾时调用本脚本，第一时间抓出死链。
#
# 用法: ./check-references.sh [skills_dir]
# 退出码: 0 = 全部解析正常; 1 = 存在死链
#

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
SKILLS_DIR="${1:-$SCRIPT_DIR/../skills}"

checked=0
dead_list=""

# 抓裸路径 `reference/x.md`、markdown 链接 `](reference/x.md)`、跨技能 `../<skill>/reference/x.md`，
# 相对 SKILL.md 所在目录解析。跳过备份与上游原文缓存（非我方维护）。
while IFS= read -r -d '' skill; do
    case "$skill" in
        */.backup/*|*/upstream-*.md) continue ;;
    esac
    dir=$(dirname "$skill")
    checked=$((checked + 1))
    while read -r ref; do
        [ -z "$ref" ] && continue
        if [ ! -f "$dir/$ref" ]; then
            dead_list+="  ${skill#$SKILLS_DIR/} -> $ref"$'\n'
        fi
    done < <(grep -oE '(\.\./[a-z0-9-]+/)?reference/[a-z0-9_-]+\.md' "$skill" 2>/dev/null | sort -u)
done < <(find "$SKILLS_DIR" -name "SKILL.md" -print0)

if [ -n "$dead_list" ]; then
    dead_count=$(printf '%s' "$dead_list" | grep -c '\->')
    printf "${RED}[FAIL]${NC} 引用校验:%d 处死链(共扫描 %d 个 SKILL.md)\n" "$dead_count" "$checked"
    printf '%s' "$dead_list"
    printf "${YELLOW}请据实更新对应 SKILL.md 的 reference 链接(对照实际文件 / upstream-SKILL.md)。${NC}\n"
    exit 1
fi

printf "${GREEN}[OK]${NC} 引用校验:%d 个 SKILL.md 链接全部解析正常\n" "$checked"
exit 0
