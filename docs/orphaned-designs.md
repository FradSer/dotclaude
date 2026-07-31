# Orphaned / Superseded / Active-Unimplemented Designs — Index

> 设计索引。记录已废弃、从未实现、或已设计但未开始实现的设计，避免未来重复提案或丢失设计要点。
> 对应设计文件夹已删（plans/ 整体清空），要点在此。

## harness-evidence channel（ORPHANED — 从未实现）

**来源**：原 `docs/plans/2026-05-09-harness-evidence-channel-design/`，前身是已删的
`docs/retros/2026-05-09-v3-considered-deferred.md` §4 condition 2。

**设计意图**：单一 append-only NDJSON channel，写 3 种 event type，每个 Stop hook 触发，
retrospective Phase 1 step 8 用一次 `run_haiku_merge` 聚合窗口内未蒸馏行。捕获现有 pipeline
丢弃的内容——跨 session scratch note、用户想 flag 的文件改动、刚发生的事的 prose 回顾。

**为何 orphaned**：设计依赖 `lib/loop.sh`、`lib/bail-log.sh`、`lib/vet.sh`——这三个 lib
在 v3.0.0（commit `18aedda`）全部删除且未恢复。`harness-evidence.sh` 从未创建，
`harness-evidence.jsonl` 从未存在。2026-07-31 superpowers 恢复（commit `f5eca53`）只恢复了
`docs-index.sh`/`jsonl-emit.sh`/`post-plan-diff.sh`/`review-package.sh`/`seed-checklists.sh`/
`task-brief.sh`/`task-ledger.sh`/`utils.sh`，原依赖的三个 lib 仍未恢复。

**关键约束（若未来重启）**：Stop-hook critical path 上不放任何 LLM call——writer 只捕获原始输入
（`task`、last-assistant tail 截 500 byte、`modified_files` 路径）即退出，蒸馏全延后到
retrospective Phase 1。保持 v2.x ~20ms p95 Stop hook 延迟预算，匹配 `vet.sh=Haiku, evaluator=Sonnet` 不对称原则。

## v3.x knowledge platform（从未激活）

**来源**：已删的 `docs/retros/2026-05-09-v3-considered-deferred.md`（reject-form retro）。

**状态**：v3.x retro 设了 4 condition activation gate（≥3 project 证据 / harness-evidence
channel / read-rate 证据 / meta-retrospective skill），4 condition 全未达成。v3.x 从未激活。

**词表被取代**：v3.x 的 privacy-tier 词表（`local-only`/`cross-session`/`cross-project`/`external`）
被 memory 插件的 Tier A（私有 `~/.claude/.../MEMORY.md`）/ Tier B（`docs/memory/`）双层模型取代。

**教训已沉淀**：anti-add-bias（不捆绑无关发现进单 PR）、simplify-don't-add 已在
`reference_anthropic_harness_blog` / `project_superpowers_upstream_lessons` 记忆中。

## superpowers v2.8.x 架构（STALE — 已删）

5 个 v2.8.x 时代 retro 报告（`meta-retro-2026-05-08-superpowers-v2.8.x.md`、
`retro-2026-06-02-unified-retro-events.md`、`retro-2026-06-08-calibration-no-new-data.md`、
`retro-2026-07-04-docs-index-plan.md`、`2026-05-09-v3-considered-deferred.md`）已删。
这些是 superpowers v2.8.x 工作流（bail-log、post-plan-diff、SessionStart dispatcher、
using-superpowers 路由）的快照——v3.8.0 删 SessionStart hook + using-superpowers dispatcher，
superdev 从头重实现自改进（只 `jsonl-emit` + `seed-checklists` 存活）。

产出未丢：所有 ADD/MODIFY 已沉淀进 `docs/retros/checklists/{design,plan,code}-v{N}.md`，
`evolution-log.jsonl` 保留 `item_added`/`item_modified` 行。可迁移教训（`repo_root()` fallback
bug）已提取到 `docs/memory/pitfall_repo-root-claude-project-dir.md`。

## Active 但未实现的设计

以下两个设计已 PASS 评估、写完 plan，但零代码实现。设计文件夹随 `plans/` 整体清空已删，要点在此，重启时据此重写。

### agentbook commons-bridge（设计 PASS，无 plan 无代码）

**来源**：原 `docs/plans/2026-07-06-agentbook-memory-design/`。

**设计意图**：独立 `commons-bridge/` 插件，桥接 agentbook（`/Users/FradSer/Developer/FradSer/agentbook`，"public debug-knowledge commons for AI coding agents"）的 live MCP 服务，作为跨插件可复用能力——不是 superpowers-only 机制。agentbook 提供 `recall`/`trace`（匿名免费读）和 `remember`/`report`/`verify`（Bearer 认证写），Bayesian confidence score（作者自报不计分，独立 agent 确认才升分）。

**关键约束**：
- **独立插件 + `plugin.json "dependencies"` 声明**——跨插件 Skill-tool 解析无文档保证，唯一有强制行为的是 `dependencies` 数组（Claude Code 自动解析/安装）。嵌套为 superpowers 内部 skill 靠 undocumented 行为。
- **agentbook 是 pre-pilot/alpha**：同任务 recall 有验证（weak-model pass@1 lift），跨任务转移现零 fix-lift，外部流量近零。必须当脆弱可选增强，绝不作任何核心自动 workflow（如 executing-plans）可 block/fail 的依赖。
- **credential 复用现有 pattern**：`code-context/.mcp.json` 的 env-var 插值（`"x-api-key": "${EXA_API_KEY}"`）做 bundled MCP server config；`office/lib/progressive_env.py` 的 CLI flag → env → .env → default 链做脚本级用。never print/log raw key（`git-agent-cli/cmd/config.go` `maskAPIKey` 先例）。
- **不强制塞进 docs-index**：`docs-index.sh` 的 `validate_path()`/`scan_folders()`/`rebuild` 全是 local-file-only，agentbook record 无本地文件、`candidate→promoted/demoted`+confidence 生命周期零语义重叠。强塞第五 `kind=agentbook` 是 `rebuild` 唯一无法 reconcile 的 kind，且会撑破 60 行 row 预算。

**3 个具体消费触点**（非假设）：
1. `autoresearch/scripts/setup-autoresearch.sh` — plateau-escalation 时刻（3 连续非改进行触发 GAN tournament `TOURNAMENT_BLOCK`）先试便宜 `recall`；`results.tsv` outcome log 是 `report` 的并行写点。
2. `superpowers/skills/systematic-debugging/SKILL.md` — Phase 1 step 0 "Consult Memory"（commit `57d3738` 已加 Tier B 触点）在此加 parallel cross-project `recall`；Phase 4 step 3（Verify Fix，"did it work" 即知）是 `report` 点，独立于 Tier B 的 3-strikes write gate。
3. `github/skills/review-pr/` — review-loop 复杂 PR 评审时 `recall` 类似问题。

**MCP 工具契约**：5 工具——`recall`(匿名 30/min)、`trace`(匿名)、`remember`(Bearer 120/hr)、`report`(Bearer 10/hr)、`verify`(Bearer 5/min+20/hr sandbox, Python 单文件)。两种错误信封（protocol-layer JSON-RPC error vs tool-layer `result.isError`）；401 是配置坏了需 surfacing，`unauthorized` 是预期的 silent-skip。

### designing loops（设计 + plan 完成，零实现）

**来源**：原 `docs/plans/2026-07-08-designing-loops-design/` + `-plan/`。

**设计意图**：把 Anthropic "designing loops" 指南集成进 superpowers——4 loop 类型（turn-based/goal-based/time-based/proactive），按 trigger/stop criteria/primitive 区分。superpowers 已实现大部分（`verification-before-completion`、`/goal` via `goal-wrapper.md`、`receiving-code-review`+evaluator、retrospective checklist 演进、`workflow-orchestration.md`），真正缺的是：无人命名 time-based 类型（`/loop`、`/schedule`），无"哪种 loop→哪个 primitive"决策辅助，`goal-wrapper.md` 无 turn-cap 指导。

**关键约束**：
- **reference file 形态（非 skill）**：`superpowers/skills/references/loop-types.md`，无 frontmatter/registration/README entry，匹配 `goal-wrapper.md`/`workflow-orchestration.md` 先例。round-1 设计过 auto-loading skill，对抗式比例审查 RECONSIDER（~5 段新内容不值一个常驻 description 的 skill，且 trigger 精度本 repo 无法验）。用户 2026-07-08 确认 pivot。
- **pointer 在 routing 表外**：`hooks/session-start.sh:28` grep `^\| .*superpowers:` 表行进每 session bootstrap，表内 pointer 会被刮进每 session。
- **token 预算**：`retrospective/SKILL.md`(4671/5000)、`writing-plans/SKILL.md`(4778/5000) 编辑限单句，`validate-plugin.py superpowers` 每次编辑后保持 exit 0。
- **禁词**："autonomous loop" 不得出现在 `loop-types.md` 或任何触及文件（collide "auto mode" + brainstorming 的 "autonomous"）。词表：小写 `turn-based loop` 等；backtick `/goal`/`/loop`/`/schedule`/`Workflow`。
- **禁裸行号引用**：cite by file path + section/rule name（REQ-009），rename/renumber drift 可检测。
- **禁重复**：goal-based/Workflow/verification/review 机制在 `loop-types.md` 内只 cite 到 owner file（REQ-006/004/007/008），原创内容限于 time-based 段 + 两个 token 项（interval matching；`/usage`/`/goal`/`/workflows` review）。
- **尺寸**：`loop-types.md` 目标 60-90 行（REQ-017）。

**plan 概要**（5 task，零实现）：t001 `loop-types.md`+goal-wrapper Rule 3 → t002 5 command-skill pointer + systematic-debugging 2nd anchor → t003 using-superpowers pointer(表外) → t004 workflow-orchestration See also → t005 grep+validator 验证。t002/003/004 可并行。

**依赖外部文件**：`hooks/session-start.sh`（已在 v3.8.0 删 SessionStart hook——重启时需确认 `using-superpowers` routing 表是否仍存在，pivot 前提可能已变）。
