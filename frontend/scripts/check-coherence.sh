#!/usr/bin/env bash
#
# cross-skill 一致性校验。
#
# validate-plugin.py 校验 per-skill 形状，check-references.sh 校验 SKILL.md 的
# reference 链接解析。二者都不校验 cross-skill 一致性——本脚本填补这一层：
#
#   断言 1  无 phantom `frontend:impeccable-<cmd>` ID（已被 upstream 合并为 sub-command，
#            应写作 `frontend:impeccable (argument: <cmd>)`）。任何匹配都意味着
#            照着加载的 agent 会 not-found 后静默回退到启发式，丢失 DESIGN.md grounding。
#   断言 2  SKILL.md / agent .md body 里每个 `node <path>/*.mjs` 调用要么解析到
#            plugin root 下真实文件，要么在 modifications/*.md 的 known-caveat
#            列表里显式标注。捕获 impeccable 的 `node .claude/skills/...` 死路径类。
#   断言 3  每个 modifications/*.md 的 ## Edit / ## Add 块声明的 Target 文件仍存在
#            （## Add 创建的文件被 sync 洗掉会缺失；## Edit 的目标文件被删会缺失）。
#            捕获 sync 覆盖静默洗掉本地 replay 类，在 ship 之前。
#   断言 4  agents/frontend-expert.md pipeline 引用的每个 `frontend:<skill>` ID
#            都在 plugin.json 注册（commands ∪ skills）。
#
# 用法: ./check-coherence.sh
# 退出码: 0 = 全部通过; 1 = 存在违反
#
# 故意与 check-references.sh 分离：那个校验「链接是否解析」，本校验校验「skill 之间
# 是否互相一致」。两个关注点不同，分开维护。

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
FRONTEND_DIR="$SCRIPT_DIR/.."
SKILLS_DIR="$FRONTEND_DIR/skills"
AGENTS_DIR="$FRONTEND_DIR/agents"
MODIFICATIONS_DIR="$FRONTEND_DIR/modifications"
PLUGIN_JSON="$FRONTEND_DIR/.claude-plugin/plugin.json"

violations=0
add_violation() {
    # $1 = assertion label, $2 = detail
    printf "${RED}[FAIL]${NC} %s: %s\n" "$1" "$2"
    violations=$((violations + 1))
}

# 已知 caveat:`.claude/skills/impeccable/scripts/**` 整树在插件布局下不解析，
# 但已在 modifications/impeccable.md 记录取舍选项（默认 A：verbatim，上游脚本
# 优雅降级 / P0-e preamble 注入）。本校验不阻断它们——只阻断「未文档化」的死路径。
is_known_caveat() {
    local p="$1"
    [[ "$p" == *".claude/skills/impeccable/scripts/"* ]] && return 0
    return 1
}

# 收集要扫描的文件（排除 .backup / upstream- 缓存）。
# macOS bash 3.2 无 mapfile，用普通数组 + while read。
scan_files=()
while IFS= read -r f; do
    scan_files+=("$f")
done < <(
    find "$SKILLS_DIR" "$AGENTS_DIR" -type f -name "*.md" \
        ! -path "*/.backup/*" \
        ! -name "upstream-*.md" \
        ! -path "*/node_modules/*"
)

# ── 断言 1: 无 phantom impeccable-<cmd> ID ──────────────────────────────
# 捕获两种形式：(a) `frontend:impeccable-<cmd>`（带前缀）；(b) bare `impeccable-<cmd>`
# （无前缀，如 `impeccable-audit`）。后者也是 phantom —— 子命令应写作
# `frontend:impeccable (argument: <cmd>)` 或 prose 形式 `impeccable audit`（空格）。
# 排除上游合法 token：`data-impeccable-*`、`live-*` 脚本名、`.impeccable` 等。
phantom_hits=""
for f in "${scan_files[@]}"; do
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        phantom_hits+="${f#$FRONTEND_DIR/}: $line"$'\n'
    done < <(grep -nE '(frontend:)?impeccable-(audit|critique|colorize|typeset|polish|clarify|bolder|quieter|distill|harden|onboard|animate|layout|delight|overdrive|optimize|adapt|live|craft|shape|init|document|extract)' "$f" 2>/dev/null \
        | grep -vE 'impeccable-(browser|server|poll|target|status|resume|complete|insert|wrap)|data-impeccable|\.impeccable/')
done
while IFS= read -r l; do
    [ -n "$l" ] && add_violation "断言1 phantom ID" "$l"
done < <(printf '%s' "$phantom_hits")

# ── 断言 2: node *.mjs 调用解析或属已知 caveat ──────────────────────────
# 注意：add_violation 必须在父 shell 调用（不能在 `printf | while` 管道子 shell 里，
# 否则 violations 计数器修改丢失，脚本永远 exit 0 假绿灯）。用进程替换 < <(...) 避免子 shell。
node_hits=""
for f in "${scan_files[@]}"; do
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        # 提取 `node <path>.mjs` 里的路径
        path=$(printf '%s' "$line" | grep -oE 'node [^` ]+\.mjs' | sed 's/^node //')
        [ -z "$path" ] && continue
        # 跳过示例/占位路径：含 shell 变量 $ / 占位符 <>。
        # 注意：模式里不能有裸 `*|*` 分支（那是 "*" OR "*"，匹配任意字符串，会让断言全 no-op）。
        case "$path" in
            *\$*|*\<*|*\${*) continue ;;
        esac
        if is_known_caveat "$path"; then
            continue
        fi
        # 尝试解析：相对 plugin root
        resolved="$FRONTEND_DIR/$path"
        if [ ! -f "$resolved" ]; then
            node_hits+="${f#$FRONTEND_DIR/}: $line (未解析: $path)"$'\n'
        fi
    done < <(grep -nE 'node [^` ]+\.mjs' "$f" 2>/dev/null)
done
while IFS= read -r l; do
    [ -n "$l" ] && add_violation "断言2 死路径" "$l"
done < <(printf '%s' "$node_hits")

# ── 断言 3: modifications Edit/Add 的 Target 文件存在 ─────────────────────
if [ -d "$MODIFICATIONS_DIR" ]; then
    for mod in "$MODIFICATIONS_DIR"/*.md; do
        [ -f "$mod" ] || continue
        case "$(basename "$mod")" in
            README.md) continue ;;
        esac
        while IFS= read -r target; do
            # 提取 backtick 里的路径
            target=$(printf '%s' "$target" | grep -oE '`[^`]+`' | tr -d '`')
            [ -z "$target" ] && continue
            resolved="$FRONTEND_DIR/$target"
            if [ ! -e "$resolved" ]; then
                add_violation "断言3 replay 缺失" "$(basename "$mod"): Target $target 不存在（sync 可能已洗掉本地 replay）"
            fi
        done < <(grep -E '^\*\*Target\*\*:' "$mod" 2>/dev/null)
    done
fi

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
        # 跳过 trailing-hyphen 占位（`frontend:impeccable-` 作为禁止模板，源自
        # 「no such skill」「never frontend:impeccable-<cmd>」等禁述语境）
        [[ "$sid" == "impeccable-" ]] && continue
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

printf "${GREEN}[OK]${NC} cross-skill 一致性校验通过（phantom ID / 死路径 / replay anchor / 注册 ID）\n"
exit 0
