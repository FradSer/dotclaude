#!/usr/bin/env bash
#
# cross-skill 一致性校验。
#
# validate-plugin.py 校验 per-skill 形状，check-references.sh 校验 SKILL.md 的
# reference 链接解析。二者都不校验 cross-skill 一致性——本脚本填补这一层：
#
#   断言 4  agents/frontend-expert.md pipeline 引用的每个 `frontend:<skill>` ID
#            都在 plugin.json 注册（commands ∪ skills）。
#
# v0.6.0 slim-down: 断言 1（phantom `frontend:impeccable-<cmd>` ID）、断言 2
# （`node *.mjs` 死路径）、断言 3（modifications replay Target 存在）随对应镜像
# skill（impeccable / shadcn / react-best-practices）删除而退役——它们校验的是
# 已不存在的 skill 的不变量。仅断言 4 保留。
#
# 用法: ./check-coherence.sh
# 退出码: 0 = 全部通过; 1 = 存在违反
#
# 故意与 check-references.sh 分离：那个校验「链接是否解析」，本校验校验「skill 之间
# 是否互相一致」。两个关注点不同，分开维护。

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
FRONTEND_DIR="$SCRIPT_DIR/.."
AGENTS_DIR="$FRONTEND_DIR/agents"
PLUGIN_JSON="$FRONTEND_DIR/.claude-plugin/plugin.json"

violations=0
add_violation() {
    # $1 = assertion label, $2 = detail
    printf "${RED}[FAIL]${NC} %s: %s\n" "$1" "$2"
    violations=$((violations + 1))
}

# ── 断言 4: frontend-expert pipeline 引用的 skill ID 已注册 ───────────────
if [ -f "$PLUGIN_JSON" ] && [ -f "$AGENTS_DIR/frontend-expert.md" ]; then
    # 注册的 skill id：从 plugin.json commands ∪ skills 提取目录名
    registered=()
    while IFS= read -r name; do
        [ -n "$name" ] && registered+=("$name")
    done < <(
        python3 -c "
import json
d = json.load(open('$PLUGIN_JSON'))
paths = d.get('commands', []) + d.get('skills', [])
for p in paths:
    name = p.strip('./').strip('/').split('/')[-1]
    if name:
        print(name)
" 2>/dev/null
    )
    while IFS= read -r sid; do
        [ -z "$sid" ] && continue
        if [[ ! " ${registered[*]} " =~ " ${sid} " ]]; then
            add_violation "断言4 未注册 ID" "frontend-expert.md: frontend:$sid 未在 plugin.json 注册"
        fi
    done < <(
        grep -oE 'frontend:[a-z][a-z0-9-]*' "$AGENTS_DIR/frontend-expert.md" 2>/dev/null \
            | sed 's/^frontend://' | sort -u
    )
fi

# ── 汇总 ──────────────────────────────────────────────────────────────────
if [ "$violations" -gt 0 ]; then
    printf "${YELLOW}共 %d 条违反。修复后重跑。${NC}\n" "$violations"
    exit 1
fi

printf "${GREEN}[OK]${NC} cross-skill 一致性校验通过（注册 ID）\n"
exit 0
