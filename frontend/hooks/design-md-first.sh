#!/usr/bin/env bash
#
# UserPromptSubmit hook — design-md-first preamble injection (Option B 涌现)。
#
# 当用户工作目录存在 DESIGN.md 或 docs/DESIGN.md 时,向会话注入一段简短提示,
# 让 design-md-first ordering 成为 harness 行为而非 coordinator agent 的散文约定。
# 这样 design-md 作为「所有设计 skill 的上游真相源」在 auto-load 路径(用户未显式
# 调用 /frontend-expert)下也能被优先加载,移除「真相源仅在 coordinator 可达」的
# 单点故障。
#
# 输入(stdin JSON):{ "session_id", "cwd", "prompt", ... }
# 输出:exit 0 + JSON { hookSpecificOutput: { hookEventName, additionalContext } }
#   additionalContext 作为 system reminder 注入 Claude 上下文(纯文本)。
# 无 DESIGN.md 时静默 exit 0(无输出),不污染上下文。
#
# 参考文档:https://code.claude.com/docs/en/hooks (UserPromptSubmit)

set -uo pipefail

# 读取 stdin JSON;容错(无 jq 时静默退出)。不用 set -e:grep 无匹配返回 1
# 会被当成致命错误,而这里「无 cwd 字段」是正常情况,应静默 fallback。
input=$(cat)
cwd=$(printf '%s' "$input" | grep -oE '"cwd"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"cwd"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/' || true)
[ -z "$cwd" ] && cwd="$PWD"

# 定位 DESIGN.md(root 或 docs/)
design_md=""
for candidate in "DESIGN.md" "docs/DESIGN.md"; do
    if [ -f "$cwd/$candidate" ]; then
        design_md="$candidate"
        break
    fi
done

# 无 DESIGN.md:静默退出,不注入。
[ -z "$design_md" ] && exit 0

# 有 DESIGN.md:注入 design-md-first preamble + Token authority 阶梯。
# 注意(Claude Code hooks 文档建议):措辞用陈述句而非命令式,避免被当成 prompt-injection
# (命令式会触发 Claude 把文本 surface 给用户而非当上下文)。所以用「...是真相源」而非
# 「你必须先加载...」。
preamble="This project has a DESIGN.md at ${design_md}. Frontend token authority ladder (Option B, no coordinator needed):

1. \`frontend:design-md\` is the source of truth for tokens; it is directly callable as \`/design-md\` for narrow lint/diff/export work.
2. \`frontend:impeccable\` (colorize/typeset) proposes tokens; in this project those proposals are written back to DESIGN.md / the @theme stylesheet rather than inlined as raw hex, so proposed tokens stay aligned with DESIGN.md.
3. \`frontend:shadcn\` rebinds component styles to semantic tokens (--primary, --background); DESIGN.md exports map onto shadcn's CSS variable contract rather than raw \`bg-blue-500\`.
4. The four quality authorities measure different axes: design-md lint is computed facts, impeccable audit is heuristic, web-design-guidelines is standard citations, the anti-patterns agent is pattern-match. Reconciliation is by evidence type — computed supersedes heuristic on the same node; pattern-match findings are additive; standard citations are advisory."

# JSON 转义 preamble(处理双引号/反斜杠/换行)。
escaped=$(printf '%s' "$preamble" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')

printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"%s"}}\n' "$escaped"
exit 0
