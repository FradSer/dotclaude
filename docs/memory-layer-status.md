# Memory Layer (kind=memory) — Current Status

> 状态参考文档。压缩自已删的 `plans/2026-07-04-superpowers-memory-layer-design/`、
> `2026-07-04-superpowers-memory-layer-plan/`。

## 当前架构

扩展 docs-index 的 `kind` 词表加第四值 `memory`，把 `docs/README.md` 同时作为
memory 层。一文件一事实，存 `docs/memory/<category>_<slug>.md`，被五个 skill
（brainstorming、writing-plans、executing-plans、systematic-debugging、retrospective）
开工前读、条件性写后。回答"我们学到了什么"——docs-index 只答"什么 artifact 存在"。

## 文件格式

`docs/memory/<category>_<slug>.md`，frontmatter：

| 字段 | 值 |
|---|---|
| `name` | kebab-case slug |
| `category` | `convention \| pitfall \| decision \| preference` |
| `summary` | ≤72 字符 |
| `source` | repo-relative path / `commit:<sha>` / 省略 |
| `created` / `updated` | 日期 |

`category` 不复用保留词 `kind`/`type`。`status` 只在索引行（不在文件 frontmatter），单一真相源。

## kind=memory 行 status 限制

脚本级强制仅 `active | expired:<reason>`——memory 事实永不在 pipeline 中途（无 `wip`）、
永不"发布"（`implemented:<sha>` 不适用）、永不是正向替代指针（无 `superseded-by`，合并直接丢被吸收行）、
永不常青（无 `reference`，memory 设计上会过期）。其他 kind 的 6 状态不受此限。

## 5-skill 触点

- **read-before**：所有五个 skill 入口跑 `docs-index.sh list --kind memory --status active`，读 topically 相关文件再开工。
- **write-after（条件）**：每个 skill 用**自己已有**的 escalation 阈值触发写，不新发明阈值：
  - brainstorming — 2+ evaluator REWORK round
  - writing-plans — Phase 4 reflection FAIL 需返工
  - executing-plans — intra-plan-learning "variety gap"（2+ rework round 但最终 PASS）
  - systematic-debugging — 现有 3+ failed-fixes 触发，或显式 cross-cutting gotcha；单步折进完成 turn，不新增 phase/commit 义务
  - retrospective — 现有 ADD/MODIFY 阈值 + plateau/variety 非缺口根因（2+ 轮）

## 与 Tier A 互补，不重复

| 维度 | Tier A `~/.claude/.../MEMORY.md` | Tier B `docs/memory/` |
|---|---|---|
| 可见性 | 私有（本 assistant 实例） | 项目本地、git-tracked、团队共享 |
| 范围 | 跨项目全局 | 本 repo |
| 注入 | harness 自动注入，session start | 显式 Read/Bash 访问 |
| 角色 | retrospective Pre-Check B advisory | authoritative within scope |
| 可查 | 仅 retrospective 读 | 五 skill 任意时读 |

retrospective 是唯一桥接两者者：Phase 3 可把 recalled global-memory prior 提升为 `docs/memory/` 文件，引用 originating hook。Pre-Check B 本身不变。

## anti-bloat

一文件一事实是**机制性** anti-bloat——单 `docs/memory.md` 无塌缩点（每次 append 在一个文件内，对 60 行 row 上限不可见）。一事实一文件使索引（非文件）成为唯一增长面，每事实恰好一行，共享 docs-index 的 60 行上限与塌缩规则，零新逻辑。consolidation 由 retrospective 用现有 2+ instance MODIFY 阈值形状处理。

## 关键产物

- `docs/memory/` — 事实文件
- `superpowers/lib/docs-index.sh` — 调度脚本（`kind=memory` 校验 + kind-aware status 限制）
- 触点：`superpowers/skills/{brainstorming,writing-plans,executing-plans,systematic-debugging,retrospective}/SKILL.md`
