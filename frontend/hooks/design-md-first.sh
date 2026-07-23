#!/usr/bin/env bash
#
# UserPromptSubmit hook — design-md-first preamble injection (Option B 涌现)。
#
# 当用户工作目录存在 DESIGN.md 或 docs/DESIGN.md 时,向会话注入一段简短提示,
# 让 design-md-first ordering 成为 harness 行为而非 coordinator agent 的散文约定。
# 这样 design-md 作为「token 真相源」在 auto-load 路径(用户未显式
# 调用 /frontend-expert)下也能被优先加载,移除「真相源仅在 coordinator 可达」的
# 单点故障。
#
# v0.6.0 slim-down: ladder 从 4 步缩减为 design-md 真相源 + anti-patterns 手动检查。
# token-proposal / component-token-rebind / standards-citation 三步随对应镜像
# skill 删除移除(用户直装上游 repo)。详见 frontend/README.md migration note。
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
2. The \`frontend:frontend-anti-patterns\` agent supplies manual anti-pattern checks.

The ladder was slimmed down in v0.6.0: token-proposal, component-token rebind, and standards-citation skills were unbundled (they were upstream mirrors). Install the \`pbakaus/impeccable\`, \`shadcn-ui/ui\`, and \`vercel-labs/agent-skills\` repos directly for those capabilities. See the migration note in this plugin's README."

# JSON 转义 preamble(处理双引号/反斜杠/换行)。
escaped=$(printf '%s' "$preamble" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')

printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"%s"}}\n' "$escaped"
exit 0
