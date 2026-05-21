# 01 — Context Management

## Blog Principle（引用 + 概括）

Anthropic 工程博文 *Harness Design for Long-Running Apps* 的核心论点（WebFetch 摘录）：

> "context resets—clearing the context window entirely and starting a fresh agent, combined with a structured handoff that carries the previous agent's state and the next steps—addresses both these issues."
>
> "While compaction preserves continuity, it doesn't give the agent a clean slate, which means context anxiety can still persist. A reset provides a clean slate, at the cost of the handoff artifact having enough state for the next agent to pick up the work cleanly."

博文还描述了具体实现："one agent would write a file, another agent would read it and respond either within that file or with a new file"，以及 evaluator/generator 之间用 "sprint contracts" 锁死成功标准的做法。

**我的概括**：博文主张以 reset（彻底清空 + 结构化 handoff 文件）替代 in-place compaction，把长任务切成"每段都开一个新 agent，靠落盘文件传递必要状态"的形态。Token budget 不通过显式裁剪管理，而是通过 reset 的频次 + handoff 文件的最小化来隐式控制。

## superpowers 现状（带 file:line 证据）

### 1. 主结构：context reset 已经是显式架构原则

`skills/executing-plans/SKILL.md:105-119` 写明 Phase 3 标题就是 "Batch Execution Loop (Context-Reset Architecture)"，并直接引用博文原则 1：

> "**CRITICAL — Context Reset Principle (Anthropic harness-design blog, principle 1)**: The main executing-plans agent does NOT execute batch tasks itself. Each batch runs inside a **fresh, isolated sub-agent context** spawned via the Agent tool (`subagent_type: "general-purpose"`). The main agent orchestrates only..." (`SKILL.md:107`)

主 agent 与子 agent 的职责切分在同一段被明确列出（`SKILL.md:110-119`）：主 agent 持有 `_index.md` / TaskList / `handoff-state.md` / git commit；子 batch coordinator 持有任务文件读取、verification、BDD/Red-Green 执行、evaluator 调用、rework loop、per-task transcripts，**在 batch 返回时全部丢弃**。

brainstorming 在 `skills/brainstorming/SKILL.md:81` 也把 "Context Reset by Design" 列为 Core Principle #5；`SKILL.md:130-135` 强制并行 3+ 个 sub-agent 做架构 / best-practices / requirements 研究，主 agent 只做 synthesize；writing-plans 在 `skills/writing-plans/SKILL.md:181-197` 同样用并行 sub-agent 做 BDD coverage / dependency / completeness 三路 review。

**判断**：reset 是 superpowers 的默认机制，三个 user-invocable skill 都用。

### 2. 结构化交接文件已落盘，分工清晰

executing-plans 落盘了两类 handoff 文件：

- `handoff-state.md` — 滚动 mutable 快照。`skills/executing-plans/SKILL.md:131-138`："This file is the ONLY cross-batch memory the spawned batch coordinator can rely on. If it is not written, the coordinator starts blind — do not skip."
- `handoff-summary-{N}.md` — 每个 batch 都产生的不可变记录。`SKILL.md:197` 强调 "every batch boundary, no task-count gate"。

`references/handoff-template.md:5-11` 把两者职责说清："`handoff-state.md` — rolling, rewritten each batch... `handoff-summary-{N}.md` — immutable per-batch record"，并要求 5 个 section（Completed Tasks / Remaining Tasks / Key Decisions / File Ownership / Blockers）全部填充，空 section 写 "None."（`handoff-template.md:131-135`）。

sprint contract 是另一层 handoff：`references/sprint-contract-template.md:1-9` 说明这是 "before execution begins" 的合同，由 executing-plans 写、evaluator + batch executors 读，acceptance criteria **机械地从 BDD Then-clause 派生**（`sprint-contract-template.md:62-65, 180-213`），消除主 agent / 任务文件 / 合同三处重复 spec。

batch coordinator 输入是 "self-contained prompt — the coordinator has no memory of prior conversation, only the handoff files named in its prompt"（`references/batch-execution-playbook.md:5`），输出是结构化 verdict（`batch-execution-playbook.md:14-17`），主 agent 只接收 `Verdict / Completed task IDs / Evidence blocks / Modified files / Evaluation report path / Recurring patterns / Pivot recommendation`（`SKILL.md:162-169`）。

**判断**：交接摘要充分。`handoff-state.md` + sprint contract + 任务文件三件套，从零接手的 agent 拿到这三个路径就能完整复原 batch 任务，符合博文的 "handoff artifact having enough state for the next agent to pick up the work cleanly"。

### 3. Token budget 的显式控制只出现在两处弱信号

直接搜 `token / budget / context.window / compact` 几乎没有命中（见对话中 grep 结果）：

- `references/evaluation-file-formats.md:132-137`：evaluation report 模板里有 "Evaluator input tokens / Evaluator output tokens" 字段，但同段标注 "best-effort"、"informational only — it does not affect the verdict"。**不是预算控制，是观察指标。**
- `lib/loop.sh:431` 注释提到 "burn the entire max_iterations budget"，但这是迭代次数预算（`--max-iterations 100 / 50 / 30`，分别见 `executing-plans/SKILL.md:31`、`writing-plans/SKILL.md:75`、`brainstorming/SKILL.md:72`），不是 token 预算。

主 agent 唯一的"防膨胀"措施是 `lib/loop.sh:297-320`：modified-files 快照只在 `next_iteration <= 2` 注入一次，cap 20 条带 overflow 指针。Phase 4 step 1（`executing-plans/SKILL.md:181-189`）也明确："Evidence is drawn from the coordinator's return payload — do NOT re-run verification in the main context"。

但**没有任何代码路径会因 token 上限触发裁剪 / dump / restart**。stuck 检测（`lib/loop.sh:486-499`）基于 edits/reads 计数，stall 检测（`lib/loop.sh:438-461`）基于 output hash，都和上下文体量无关。

**判断**：token budget 没有显式上限或裁剪机制；隐含假设是"context-reset 频次足够高 → 主 agent 上下文不会膨胀到危险区"。这个假设大体成立（主 agent 只读 `_index.md` 一次、持有 TaskList、每 batch rewrite `handoff-state.md`），但**没有保险**——一旦异常导致主 agent 误读大量任务文件或重跑 verification，没有任何机制会通知或回收。

### 4. 现状里的隐式假设

- `lib/loop.sh:297-320` 的"只在前两次迭代注入 modified-files 快照"假设 SKILL.md 还在 working context；`lib/loop.sh:215-224` 的 generic header 注释承认 "post-compact" 是真实风险，但留给 Claude 自己重读 SKILL.md，没有量化阈值。
- `lib/loop.sh:240-294` 提供 executing-plans 的 batch progress hint，从文件系统数 `sprint-contract-batch-*.md` 和 `handoff-summary-*.md`，再用 TaskList 决断。这是把上下文丢失后的"重定位"成本转嫁到文件系统枚举上，**显著降低了主 agent 上下文恢复成本**——但仅 executing-plans 有，writing-plans / brainstorming 没有等价 hint（`loop.sh:240` 的 if-guard 写死了 `skill_name == "executing-plans"`）。
- `skills/retrospective/references/analysis-patterns.md:94` 已经把"Context reset (per-batch coordinator)"列为需要"Confirm load-bearing; no action unless it demonstrably costs more than it saves"的 pattern——说明 retrospective 流程预期会对 reset 体制做证伪，但没有量化指标。

## 差距分析（按 gap-level 排序）

### Gap A — Token budget 完全没有显式上限或观测 [gap-level: moderate]

**证据**：grep 无 `token budget / context.window / compaction` 触发；`evaluation-file-formats.md:132` 的 token 字段只用于 evaluator 报告，主 agent 自己的上下文使用量从不记录、从不告警。

**与博文差距**：博文虽然也不做硬裁剪，但成本对比是论点核心（"$9 / $200 / $125"），靠 reset 频次替代 compaction 是建立在"我们知道 reset 是更便宜的"这个量化前提上。superpowers 没有等价的 telemetry——一旦真实 plan 跑出 50+ batch、主 agent 上下文异常膨胀，**没有观测信号能在出问题之前抓到**。

### Gap B — handoff-state.md 是 mutable rolling snapshot，没有 versioning [gap-level: minor]

**证据**：`references/handoff-template.md:6-9` 明说 `handoff-state.md` "rolling, rewritten each batch"；`SKILL.md:131-138` 让主 agent 每 batch 重写。`handoff-summary-{N}.md` 是 immutable 的，但**它不是 coordinator 读的那份**（`SKILL.md:137` 明确 `handoff-state.md` 是 the ONLY cross-batch memory）。

**与博文差距**：博文里 "one agent would write a file, another agent would read it and respond either within that file or with a new file that the previous agent would read in turn" 的模式更接近"append-only / new file per round"。superpowers 把 audit trail（`handoff-summary-{N}.md`）和 live memory（`handoff-state.md`）拆开是合理的，但 mutable 那份在异常 batch 失败后，**可能写入了不一致状态**（比如某 batch coordinator 没有返回但主 agent 已经 rewrite 了 state）——目前没有原子写或回滚机制。

### Gap C — writing-plans / brainstorming 的 reset 边界比 executing-plans 弱 [gap-level: minor]

**证据**：executing-plans 有 Phase 3 step 0-2 ATOMIC 契约（`SKILL.md:123`、`batch-execution-playbook.md:39-42`）+ stuck-detection（`loop.sh:486-499`）+ filesystem-derived progress hint（`loop.sh:240-294`）。

writing-plans Phase 4 reflection（`writing-plans/SKILL.md:181-207`）启动 3 个并行 sub-agent，但**主 agent 仍然要"Collect findings → Prioritize → Update plan files → Re-verify"**（step 1-5），更新 plan 文件这步在主 agent 上下文里完成；brainstorming Phase 2 step 1（`brainstorming/SKILL.md:130-148`）也是 sub-agent 返回后主 agent 整合 + 写 4 个文件 + 做 vocabulary 调和。

**与博文差距**：博文的"separating work from evaluation"原则在 executing-plans 已经做到（生成 = coordinator，评估 = evaluator，主 agent 只编排），但 writing-plans / brainstorming 还混着——sub-agent 做 research，主 agent 既做 synthesis 又做落盘。当 design 复杂、sub-agent 返回内容多时，主 agent 上下文会被研究产物撑满，**没有进一步的 reset 边界**。

### Gap D — 没有"force restart from handoff"的恢复路径 [gap-level: minor]

**证据**：`lib/loop.sh:451-461` 在 stall_count >= 3 时 force-clear 状态并退出循环；`writing-plans/SKILL.md:212-222` 描述 loop stall recovery 是"读 `_index.md` + Glob 任务文件来重建状态"。但这是**完全清状态**，不是"从最近的 handoff 开 fresh agent 继续"。

**与博文差距**：博文的 reset 是带 handoff artifact 的，superpowers 的强制 reset（stall force-clear）是**裸 reset**——清完状态用户必须自己重新调用 slash command。executing-plans 因为有 `handoff-state.md` + sprint contract 在磁盘上，重新调用相对廉价；但 writing-plans / brainstorming 没有等价中间产物时，force-clear 会丢更多上下文。

### Gap E — Sprint contract 的 "Evaluation Criteria Preview" 是单向 feedforward，不是博文里的"negotiated contract" [gap-level: minor]

**证据**：`references/sprint-contract-template.md:99-115` 说 Evaluation Criteria Preview 是"feedforward lets the generator know upfront what will be assessed"。`SKILL.md:125-129` 写 contract 由主 agent 单方面 derive，"Acceptance criteria **auto-derived** from each task file's BDD Then-clauses... do NOT author new criteria"。

**与博文差距**：博文描述 "the evaluator and generator negotiated 'sprint contracts' defining success criteria upfront"——是 negotiate（双向）。superpowers 这版是单向：主 agent 写 → coordinator 读 → evaluator 用同一份打分。设计上更简单，但失去了 evaluator 在合同生成时挑战 spec 的机会。**风险**：BDD Then-clause 本身模糊时（`sprint-contract-template.md:242-281` 的 "Ambiguity Detection" 是 auto-resolve，不让 evaluator 介入），坏 spec 会一路走到 grading 阶段。

## 行动建议（按 impact / effort 排序）

### 建议 1：给主 agent 加 conversation-turn / read-write 计数 telemetry [effort: S, impact: high]

**做什么**：复用现有 `state.edits_since_last_spawn / reads_since_last_spawn`，把 batch 边界的累计值写进 `harness-observations.jsonl` 或 `plans-completed.jsonl`。每个 plan 完成时记 `main_agent_total_reads / total_edits / total_agent_spawns`。

**为什么**：直接闭合 Gap A。不需要拿到真实 token 数（API 不暴露），用 tool-call 计数做代理指标，retrospective 就能跨 plan 看主 agent 是不是越来越胖。**已经有 hook 在数了**，只是没汇总落盘。

### 建议 2：writing-plans Phase 4 把"integration"也拆给子 agent [effort: M, impact: med]

**做什么**：3 个 review sub-agent 返回后，主 agent 不自己 update plan 文件，而是 spawn 第 4 个 "fixer" sub-agent，把 3 份 review report 路径 + plan 路径作为 self-contained prompt 喂进去，让 fixer 在 fresh context 里改 plan 文件。主 agent 只校验 fixer 的 verdict。

**为什么**：闭合 Gap C 的一半。brainstorming 同理可办，但 vocabulary reconciliation 那步天然需要主 agent 看到所有 sub-agent 输出，先不动 brainstorming。

### 建议 3：handoff-state.md 写入加 swap-then-rename 原子化 [effort: S, impact: med]

**做什么**：`executing-plans` Phase 3 step 1 改成"写 `handoff-state.md.tmp` → 整体 rename"，避免 batch coordinator 异常返回时主 agent 已经局部更新 state 的窗口。

**为什么**：闭合 Gap B。`lib/utils.sh:204-223` 的 `state_update` 已经有 tmp+mv 的成例可参考。低风险、low effort、防一类不可见数据损坏。

### 建议 4：retrospective 检查 sub-agent 数量 vs 主 agent reads/edits 比例 [effort: M, impact: med]

**做什么**：retrospective Phase 5 增加一个固定 check：本期分析的 plan 里，主 agent 的 read+edit 计数 / Agent spawn 计数比例，超过阈值（比如 10:1）就告警 "main agent likely accumulating context — investigate which phase is leaking work"。

**为什么**：把"reset 体制是否还 load-bearing"（`retrospective/references/analysis-patterns.md:94` 已经埋了的问题）变成可量化的 retrospective 项目，需要建议 1 的数据。

### 建议 5：sprint contract 加 evaluator pre-flight 校验 [effort: L, impact: low]

**做什么**：主 agent 写完 sprint contract 后，spawn evaluator 做一次 "criteria are binary-verifiable, not ambiguous" 的预审，evaluator 返回 PASS / NEEDS_REVISION。NEEDS_REVISION 时主 agent 重写一次合同。最多两轮，否则按现状走 auto-resolve。

**为什么**：闭合 Gap E。但这是边际改进，且会增加每个 batch 的 evaluator 开销。**只在 retrospective 数据显示 BDD Then-clause 模糊度真的造成下游 rework 时才做**——不是优先要做的事。

## 一句话结论

superpowers 已经把 Anthropic 博文的 context-reset + structured-handoff 原则做成了执行架构的明文骨干（executing-plans Phase 3 最完整、brainstorming/writing-plans 部分到位），最大的短板是**对主 agent 上下文体量完全没有 telemetry**，建议先用现有 hook 计数做 plan-level 汇总（建议 1）来获得改进决策的依据。
