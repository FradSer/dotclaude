# Retrospective Subsystem — Current Status

> 状态参考文档。描述 `docs/retros/` 当前真实状态与 retrospective skill 的运行机制。

## 当前 `docs/retros/` 内容

```
docs/retros/
├── checklists/                    # 7 个二元 PASS/FAIL checklist（运行时数据）
│   ├── code-v1.md
│   ├── code-v2.md
│   ├── code-v3.md                 # code 模式最新版
│   ├── design-v1.md
│   ├── design-v2.md
│   ├── design-v3.md               # design 模式最新版（2026-07-09, REQ-TRACE-01 双格式）
│   └── plan-v1.md                 # plan 模式最新版
├── evolution-log.jsonl            # 事件 log / watermark（运行时状态，勿删）
└── retro-2026-07-09-memory-layer-and-agentbook.md  # 最新 retro 报告
```

## 运行时状态（保留，勿删）

### `evolution-log.jsonl`
retrospective skill 的唯一 watermark 源。`item_added`/`item_modified` 行记录 checklist 演进，`retrospective_run` 行记录每次运行边界。
- **Phase 1 step 5**（re-proposal guard）读它避免重复加已移除 item
- **Phase 5 closure** 写 `retrospective_run` watermark
- `plans-completed.jsonl` 至今缺失（每个 retro 都记一笔），evolution-log 是唯一 watermark
- 被 superpowers 和 superdev 两个 retrospective skill 共同读写

### `checklists/*.md`
7 个版本化二元 checklist，被 superpowers + superdev retrospective skill 的 Phase 1 step 3 和 Phase 4 加载。item 加/改/删时版本号递增，prior 版本保留不删（`{mode}-v{N}.md`，取最高 N 为当前）。

| 模式 | 最新版 | 关键 item 例 |
|---|---|---|
| design | `design-v3.md` | JUST-01（justification）、REQ-TRACE-01（双格式 ID）、ARCH-01、RISK-01 |
| plan | `plan-v1.md` | PLAN-COV-01、TASK-COMP-03、DEP-01、TEST-01 |
| code | `code-v3.md` | CODE-VER-01（exit 0）、CODE-QUAL-01/02、CODE-ENV-ISO-01、CODE-TEST-LIVE-01 |

每个 item 标注 `computational`（grep/exit code/图遍历，确定性）或 `inferential`（附显式 check method 锚定，减少但不消除观察者变异）。

## retro 报告

`retro-2026-07-09-memory-layer-and-agentbook.md` 是当前唯一保留的 retro 报告——最新且其批准的提案（MODIFY design/REQ-TRACE-01 → `design-v3.md`，evaluator 须扫描 `REQ-NNN` 与编号列表两种格式）仍是当前最新 checklist 版本。覆盖 memory-layer 与 agentbook 设计。

其余 5 个 v2.8.x 时代 retro 报告已删（superpowers v2.8.x 工作流快照，产出已沉淀进 checklist + evolution-log）。墓碑见 `docs/orphaned-designs.md`。

## retrospective skill 运行机制

5-phase 流程（`superpowers/skills/retrospective/SKILL.md`）：
1. **Resolve inputs** — 解析 `$ARGUMENTS`；无参则读 `evolution-log.jsonl` 取最近 `retrospective_run` 后的 plan，`docs-index.sh list --kind plan --status implemented` 补全
2. **Pre-Check A/B** — A 检后计划 diff 充分性；B 扫 harness-injected `~/.claude/.../MEMORY.md`（Tier A，advisory prior）
3. **Analyze + propose** — ADD(2+ plan)/MODIFY(2+ false positive)/REMOVE(3+ report) 阈值；自反提案
4. **Emit** — 批准的 item 写进 checklist 新版本 + `evolution-log.jsonl` `item_added`/`item_modified`
5. **Closure** — `retrospective_run` watermark + retro 报告

## 关键产物

- `superpowers/skills/retrospective/SKILL.md` — 5-phase 流程定义
- `superpowers/lib/jsonl-emit.sh` — evolution-log 统一 writer（见 `docs/retro-events-status.md`）
- `superpowers/lib/docs-index.sh` — `list --kind memory` 补全 calibration 输入
- `superpowers/lib/seed-checklists.sh` — checklist 种子/校验
- `superpowers/agents/superpowers-evaluator.md` — 套用 checklist 的评估器（见 `docs/eval-harness-status.md`）

## 与 superdev 的关系

`superdev/`（mattpocock/skills fork）也有 retrospective skill，读写**同一** `docs/retros/checklists/` 与 `evolution-log.jsonl`。superdev 迁移计划把 `design→spec`、`plan→tickets`、`code` 不变——意味着 `design-v*.md`/`plan-v1.md` 在 superdev 的 `spec-v1.md`/`tickets-v1.md` 落地前仍是当前最新，落地后转为 stale。
