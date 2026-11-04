---
name: feedback_skill_invocation_bypass
description: superpowers 改为用户手动调用、模型无法调用；SessionStart hook + using-superpowers dispatcher
  已删除
type: feedback
---

superpowers 插件改为「用户手动调用、模型无法调用」模式。SessionStart hook（注入路由表）和 `using-superpowers` dispatcher skill 已删除。

**Why:** 用户决策：superpowers 全部改为用户手动触发，模型不应自动派发任何 superpowers skill。

**How to apply:**
- superpowers 只剩 1 个 hook：`stop-state-sync.sh`（Stop，状态回填）
- 5 个用户命令（用户手动调）与 3 个内部 helper（只在用户发起的流程内被加载）都放在 `skills/`，由 SKILL.md frontmatter 控制可见性；不要再写进 `plugin.json` 的 `commands`
- 若将来要恢复自动派发，需同时重建 SessionStart hook + using-superpowers skill
- 若重新引入 UserPromptSubmit hook，保留"slash command 不注入通用 system message"的原则