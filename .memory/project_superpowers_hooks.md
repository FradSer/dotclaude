---
name: project_superpowers_hooks
description: superpowers 架构：Stop hook(stop-state-sync.sh) 做状态回填；用户手动调用、模型无法调用；与 mattpocock
  并存
type: project
---

superpowers 插件当前架构（与 mattpocock 并存于 marketplace.json）：

**唯一 hook：`stop-state-sync.sh`（Stop）** — 两个职责：
- R1：每次 Stop 检测 plan 是否刚完成（C1-C4 条件），满足则追加一行到 `docs/retros/plans-completed.jsonl`
- R2：回填 evolution-log 缺失的 watermark（retrospective_run 行）和 checklist 变更行（item_added/item_removed）
- 两个回填都 dedup，正常路径下是 no-op

**lib/ 层（8 文件）：** utils.sh / jsonl-emit.sh / post-plan-diff.sh / seed-checklists.sh / task-brief.sh / task-ledger.sh / review-package.sh / docs-index.sh

**Skills（8 个）：** 5 个用户命令（brainstorming、writing-plans、executing-plans、retrospective、systematic-debugging）+ 3 个内部 helper（behavior-driven-development、verification-before-completion、receiving-code-review）

**SessionStart hook + using-superpowers dispatcher 已删除。** superpowers 改为「用户手动调用、模型无法调用」。5 个用户命令与 3 个内部 helper 都在 `skills/` 下自动发现，可见性由 SKILL.md frontmatter（`user-invocable` / `disable-model-invocation`）控制；不要把 skill 目录写进 `plugin.json` 的 `commands`（会重复注册）。

**关键设计约束：**
- 整个插件只允许 1 个 hook（用户硬约束），且必须兼容各种情况
- `/goal` 集成已落地（推荐默认包 /goal 续跑）
- 4 个 agent 并发上限（用 Workflow tool 需用户显式 opt-in 或 ultracode 开）
- evaluator 是独立 agent，二元裁决（PASS/REWORK），refute-before-PASS 协议
- 子 agent 产物放工作树内目录（`<plan-dir>/_briefs/`、`_reviews/`），不写 `.git/`
- 每次 dispatch subagent 必须显式声明 model
- task-ledger 防止重派已完成任务

关联：[[project_mattpocock_fork]]、[[feedback_skill_invocation_bypass]]、[[project_active_design_work]]