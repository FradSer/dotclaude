# 子代理编排（Sub-Agent Orchestration）反思

参考：Anthropic 工程博客 *Harness design for long-running apps* —— Planner / Generator / Evaluator 三角色，文件式异步通信。

## 博客对照基线

WebFetch 抽取要点：

- 三角色分工：
  - **Planner**：把简短 prompt 扩展为完整产品规格；"be ambitious about scope and to stay focused on product context and high level technical design rather than detailed technical implementation"。
  - **Generator**：增量实现 sprint，"performs self-evaluation before handing work to quality assurance"。
  - **Evaluator**：用 Playwright MCP 验证，"grades each sprint against both the bugs it had found and a set of criteria"。
- 通信机制（原文直引）：

  > "Communication was handled via files: one agent would write a file, another agent would read it and respond either within that file or with a new file that the previous agent would read in turn."

- 博客**未涉及**：per-batch coordinator、clean-context spawn 协议、batch 内并发度控制、完成检测信号（最终消息 vs 文件 diff）—— 这是 superpowers 必须自己回答的实现细节。

---

## 问题 1：Planner + Generator + Evaluator 三角色映射是否成立？

**结论**：架构层面成立，但形态比博客更分层。

| 博客角色 | superpowers 实现 | 证据 |
|---|---|---|
| Planner | `superpowers:brainstorming` + `superpowers:writing-plans` 串联 | `skills/brainstorming/SKILL.md:112-148`（设计 4 文件）；`skills/writing-plans/SKILL.md:170-207`（任务化 + Phase 4 反思） |
| Generator | `superpowers:executing-plans` 主代理 → 每批 spawn 一个 **batch coordinator** sub-agent → coordinator 再 spawn N 个 task sub-agent | `skills/executing-plans/SKILL.md:107-145`；`skills/executing-plans/references/batch-execution-playbook.md:60-83` |
| Evaluator | `agents/superpowers-evaluator.md`（独立只读 agent，design + code 两种模式） | `agents/superpowers-evaluator.md:1-93`；`skills/executing-plans/references/batch-execution-playbook.md:128-160` |

**与博客的偏差**：

1. **Planner 被一拆为二**：博客的单一 Planner 在 superpowers 里被切成 brainstorming（设计/BDD）和 writing-plans（任务图 + 依赖图）。两者各自带一组 sub-agent 反思 + evaluator，PASS 后才进下一阶段（`skills/brainstorming/SKILL.md:150-162`、`skills/writing-plans/SKILL.md:179-230`）。这是有意识的延展——博客的 sprint 粒度更粗，superpowers 把 plan 粒度做细到 task。
2. **Generator 多了一层**：博客是 Generator 直接干活，superpowers 是 main agent → batch coordinator → task sub-agent 三层。这一层是为了**保护 main agent 的 context**，下面问题 2 详细讨论。
3. **Evaluator 设计模式分裂**：博客的 evaluator 用 Playwright MCP 跑 UI；superpowers 的 superpowers-evaluator 是文本/grep/Bash-only（`agents/superpowers-evaluator.md:34`），不跑浏览器。这是因为 superpowers 不限于 web app，但代价是它**不能验证博客所强调的 user-facing 行为**——这是一个真实的能力差距。

**额外发现**：`agents/superpowers-evaluator.md:50` 明确拒绝 plan-mode（"Plan-mode evaluation is handled inline by writing-plans Phase 4 sub-agent reflection"）。也就是说 writing-plans 不走独立 evaluator，靠 Phase 4 三个 reflection sub-agent + 自带 checklist（`skills/writing-plans/references/reflection.md:30-122`）顶上。这等价于把 "review" 内嵌在 Planner 里，违反博客 evaluator 的独立性原则——见问题 6 的差距分析。

---

## 问题 2：executing-plans 是否真在每个 batch 起新 sub-agent（clean context）？

**结论**：是的，硬性合约 + hook 强制执行。这是整个仓库最 hardened 的环节。

**直接证据**：

- `skills/executing-plans/SKILL.md:107`：
  > "CRITICAL — Context Reset Principle (Anthropic harness-design blog, principle 1): The main executing-plans agent does NOT execute batch tasks itself. Each batch runs inside a fresh, isolated sub-agent context spawned via the Agent tool (`subagent_type: "general-purpose"`)."

- `skills/executing-plans/SKILL.md:142`：
  > "HARD RULE: Main agent MUST spawn a sub-agent for batch tasks. Direct `Edit`/`Write`/`MultiEdit` of source files violates the contract and trips stuck-detection."

- `skills/executing-plans/references/batch-execution-playbook.md:22-37` 明确列出主代理可直接写的"白名单"：`handoff-state.md`、`sprint-contract-batch-{N}.md`、`evaluation-round-{N}-batch-{M}.md`、`_index.md`（PIVOT 时）。其他一律走 sub-agent。

**hook 强制层**：

- `hooks/track-changes.sh:63-78` 每次 `Edit/Write/MultiEdit` 把 `state.edits_since_last_spawn` +1。
- `hooks/track-reads.sh:47` 每次 `Read/Glob/Grep/Bash` 把 `state.reads_since_last_spawn` +1。
- `hooks/track-spawns.sh:41-42` 在 Agent tool 的 PostToolUse 把两个计数器都置 0：
  > "jq '.edits_since_last_spawn = 0 | .reads_since_last_spawn = 0'"
- `lib/loop.sh:486-501` 在每个 Stop hook 触发时读取两个计数器，>5 edits 或 >15 reads（executing-plans loop, iter≥2）即触发 STUCK，注入恢复提示（`lib/loop.sh:198-214`）。

**这是 superpowers 最严格的 Context Reset 实现**：博客只说"context resets matter"，superpowers 用计数器 + STUCK banner 兜底，避免主代理用 inline Edit 绕过 sub-agent 合约。`hooks/track-spawns.sh:11-13` 的注释还点出 reset 的语义是"main-agent operations since the last sub-agent returned"，把 sub-agent 期间 PostToolUse 也清掉的设计是对的。

**主代理实际拥有的内容**：`skills/executing-plans/SKILL.md:111-114` 列出主代理跨 batch 仅持有 `_index.md`、TaskList、`handoff-state.md`、最后 git commit。Batch 执行记录、task 文件、verification 输出、rework 循环全部归 batch coordinator，coordinator 返回后丢弃——这是博客"context reset"原则的合理实现。

---

## 问题 3：file-based async communication 在哪里实现？

**结论**：实现完整且文件契约清晰，但**异步度比博客弱**——superpowers 的 sub-agent 是同步阻塞 spawn，不是博客描述的 async file-passing。

**文件契约清单**（每一项都是 sub-agent 间的接口）：

| 文件 | 写入方 | 读取方 | 证据 |
|---|---|---|---|
| `_index.md` | brainstorming → writing-plans → executing-plans main | 全员 | `skills/writing-plans/SKILL.md:170`、`skills/executing-plans/SKILL.md:39-40` |
| `bdd-specs.md` / `architecture.md` / `best-practices.md` | brainstorming sub-agents | writing-plans + executing-plans + evaluator | `skills/brainstorming/SKILL.md:120-124` |
| `task-NNN-*.md` | writing-plans | executing-plans batch coordinator | `skills/executing-plans/SKILL.md:88`（"do NOT read individual task files during this phase — they are read on-demand during execution"） |
| `sprint-contract-batch-{N}.md` | executing-plans main | batch coordinator + superpowers-evaluator | `skills/executing-plans/SKILL.md:125-130`、`skills/executing-plans/references/evaluation-file-formats.md:16-90` |
| `handoff-state.md` | main agent（每 batch 重写） | 下一 batch coordinator | `skills/executing-plans/SKILL.md:131-138`（"the ONLY cross-batch memory the spawned batch coordinator can rely on"） |
| `handoff-summary-{N}.md` | main agent（不可变快照） | retrospective + audit | `skills/executing-plans/references/handoff-template.md:4-30` |
| `evaluation-round-{N}-batch-{M}.md` | main agent（写入 evaluator 文本输出） | main agent（读 verdict） | `skills/executing-plans/references/evaluation-file-formats.md:91-141` |
| `harness-config.json` / `harness-observations.jsonl` / `evolution-log.jsonl` / `plans-completed.jsonl` | 多方 | retrospective + skill | `skills/retrospective/references/harness-config.md`、`lib/loop.sh:100-108` |

**博客 vs superpowers 的差异**：

- 博客："one agent would write a file, another agent would read it and respond either within that file or with a new file" —— 暗示 **agents are long-lived**，文件作为消息队列。
- superpowers：sub-agent 是**一次性进程**，Agent tool spawn → sub-agent run → return 一段文本 → 主代理读文本。文件不是消息总线，而是**跨进程的持久 state**。`handoff-state.md` 像 KV store，`sprint-contract-batch-{N}.md` + `evaluation-round-*` 像可审计的事件日志。

这种"短命 sub-agent + 持久文件"是博客 file-based 通信的一个有效变体（且更适合 Claude Code 当前 Agent 模型），但**不是博客字面意义上的 async**。

---

## 问题 4：并发度如何控制？同一 batch 内的多个独立任务是单 agent 串行还是多 agent 并行？

**结论**：架构上支持，文档承诺**并行**，但实现路径含糊，主代理-侧并行未真正成立。

**架构层（main agent → coordinator）**：**每批只 spawn 一个 coordinator**。`skills/executing-plans/SKILL.md:140-145` 只描述单个 Agent tool 调用，无"多 coordinator 并行"概念。这一层就是 1 batch = 1 sub-agent。

**Batch 内层（coordinator → task sub-agents）**：文档承诺并行：

- `skills/executing-plans/references/batch-execution-playbook.md:58-62`：
  > "Does the batch have 2+ tasks? YES → Parallel mode (spawn one Task sub-agent per task)"
- 同文件 76-83 行 Parallel Mode："Spawn one Task sub-agent per task via the Agent tool ... Wait for all sub-agents to complete"。
- 同文件 78：worktree 隔离的 hint "If sub-agents edit overlapping files, add `isolation: "worktree"` for isolation"。

**但这一层有 3 个问题**：

1. **没有 max-parallelism 上限**。每 batch "3-6 tasks"（`skills/executing-plans/SKILL.md:97`），全开有可能撞 Agent tool 并发限制；没有 batch 大小 vs 并发度的硬上限说明。
2. **`isolation: "worktree"` 没有实施细节**。整个仓库 grep `worktree` 只在 `references/batch-execution-playbook.md:78` 一处出现，没有 hook、没有脚本兜底、没有 race-condition 处理。一旦多 sub-agent 改同文件，没有人挡。
3. **Linear Mode 是不诚实的回退**：`references/batch-execution-playbook.md:86-91` 写 Linear Mode 是 "single-task batches or unavoidable sequential dependencies"，且允许 "Execute task directly or via single subagent"。`directly` 这个词与 Phase 3 HARD RULE（`SKILL.md:142`）冲突——coordinator 自己可以 inline 执行，但合约的"必须 spawn"是主代理-侧的。Linear Mode 在 coordinator 上下文里是允许 inline 的，这点没有清晰标注。

**Red-Green Pair 模式**（`references/batch-execution-playbook.md:64-71`）：测试任务先 spawn，确认 Red，再 spawn impl 任务——这是**串行**的，文档第 3 条说"Multiple pairs across batches run in parallel"是 batch 间，不是 batch 内。

---

## 问题 5：sub-agent 退出后，主代理如何知道它做完了什么？

**结论**：依赖 **sub-agent 的最终消息文本** + **持久文件**双通道，不是 file diff 检测。

**主通道：结构化返回文本**（`references/batch-execution-playbook.md:98-100`、`SKILL.md:160-169`）：

```
Verdict: PASS | REWORK_ESCALATED | PIVOT
Completed task IDs: [001, 002, ...]
Evidence blocks: [ {task_id, verification_command, status, last_20_lines_of_output} ]
Modified files: [path/to/file1, ...]
Evaluation report path: evaluation-round-{N}-batch-{M}.md
...
```

- 主代理**信任** coordinator 报告的 verdict + evidence。`SKILL.md:188-189`：
  > "Evidence is drawn from the coordinator's return payload — do NOT re-run verification in the main context."

**辅通道：文件**（持久化的 ground truth）：

- `evaluation-round-{N}-batch-{M}.md` —— evaluator 跑出来的报告，独立 sub-agent 写文本，main agent 写文件（`agents/superpowers-evaluator.md:40`）。
- `handoff-summary-{N}.md` —— 每个 batch 不可变快照。
- `handoff-state.md` —— 跨 batch state 累计。
- Git diff —— `git show` 是用户最终的 audit surface（`SKILL.md:205-214`）。

**这有两个风险**：

1. **没有 file-diff 校验**。Coordinator 报告"Modified files: [a.py, b.py]"是否真的就是 a.py 和 b.py？如果 sub-agent 撒谎或漏报，主代理不会知道（除非 evaluator 也独立读这两个文件）。`hooks/track-changes.sh:78` 把 `modified_files` 累计到 state 里，但主代理是否对账 coordinator 返回 vs hook 累计的 modified_files？我没找到对账逻辑——这是一个**潜在缺口**。
2. **Evaluator PASS 在 verification gate 之后**（`references/batch-execution-playbook.md:130-160`）。但博客的 evaluator 是 sprint-grade，类似 GAN 角色；superpowers 的 evaluator 也跑 verification commands（`agents/superpowers-evaluator.md:67-68`："Run verification commands yourself; never trust prior reports"）——好，但 evaluator 也只用文本 grep + Bash，**不跑端到端行为**。

---

## 问题 6：与博客的差距 + 行动建议

### 差距 D1：Planner 角色过度切分，evaluator 独立性不完整

- **现状**：writing-plans 用 inline Phase 4 sub-agent reflection 顶替独立 plan-mode evaluator（`agents/superpowers-evaluator.md:24-29`、`skills/writing-plans/references/reflection.md:1-122`），评审与生成在**同一个 SKILL 的同一个 Loop 内**。
- **博客原则**：evaluator 是独立 agent，"grades" 而非 self-review。
- **影响**：plan 评审存在 self-grading 风险。Phase 4 反思虽然 spawn 了 fresh sub-agent，但 prompt 由 writing-plans 主代理生成，绑 checklist 也在主代理这边，**checklist 自身的偏差**会被吃进。
- **建议（高）**：补一个独立 `superpowers-plan-evaluator` agent，或扩展现有 superpowers-evaluator 支持 plan 模式（取消 `agents/superpowers-evaluator.md:50` 的硬拒绝）。配套要给 plan 模式定 PASS/REWORK 二元 verdict + checklist 路径。

### 差距 D2：Evaluator 没有 user-facing 行为验证能力

- **现状**：`agents/superpowers-evaluator.md:34` `tools: ["Read", "Grep", "Glob", "Bash"]`，没有 browser/MCP UI 自动化。
- **博客做法**：Playwright MCP 在真实 UI 上跑黑盒。
- **影响**：对 web app/UI 工程，superpowers evaluator 只能 grep 文本和跑 unit tests，**user journey 类 bug 漏检**。
- **建议（中）**：为 evaluator 加可选 Playwright MCP / Puppeteer 工具配置，由 sprint contract 声明 "需要 UI 验证"。

### 差距 D3：Batch 内并发度无上限、无 worktree 实施细节

- **现状**：`references/batch-execution-playbook.md:76-78` 承诺 Parallel mode，但无 max-concurrency、无 worktree 工作流脚本。
- **影响**：3-6 task 的 batch 全开 + 文件冲突时无隔离，会出 race；或被 Agent tool 限流静默退化为串行。
- **建议（高）**：要么收紧到"Parallel 上限 N（如 3），>N 串行"，要么补 `lib/worktree-isolation.sh` 真实启动 worktree。当前文档 promise 与代码实现之间存在缺口。

### 差距 D4：Sub-agent 返回不与 hook 累计的 modified_files 对账

- **现状**：`hooks/track-changes.sh:78` 在 state 里累计 modified_files；coordinator 也自报 modified_files；主代理只读后者。
- **影响**：sub-agent 漏报会被静默接受。
- **建议（中）**：在 Phase 4 step 1（`SKILL.md:181-189`）加一步：用 hook 累计的 modified_files 与 coordinator 报告的 modified_files 求差集，差集非空则降级到 REWORK 并附"undeclared modifications"证据。

### 差距 D5：Linear Mode 的 "Execute task directly" 与 HARD RULE 自相矛盾

- **现状**：`references/batch-execution-playbook.md:90` "Execute task directly or via single subagent following BDD principles"，但同文件 22-37 行的 HARD RULE 说主代理只能写白名单文件。
- **澄清**：HARD RULE 是 **main agent** 视角，Linear Mode 是 **coordinator** 视角（coordinator 自己已在 sub-agent context 里，可以 inline）。但这点在文档里没有显式标注。
- **建议（低）**：在 batch-execution-playbook.md "Linear Mode" 段首加一句"Linear Mode runs inside the coordinator's already-isolated context; the HARD RULE above governs main-agent behavior, not coordinator behavior."

### 差距 D6：sub-agent 之间的"文件式异步通信"实际是同步阻塞

- **现状**：Agent tool spawn 是 synchronous blocking call，main agent 在 sub-agent 返回前不能干别的事。
- **博客做法**：file-based async 暗示 agents 是 long-running 进程。
- **影响**：跨 batch **串行**，无法在 batch N coordinator 跑着的时候同时启动 batch N+1 准备工作。
- **建议（低/受限）**：这是 Claude Code Agent tool 当前模型的限制，无法在 skill 层完全解决。但可以做**部分异步**：main agent 在 spawn coordinator **之前**预生成 batch N+1 的 sprint contract 草稿（不依赖 batch N 输出的部分），减少串行长尾。可作为 v2.9 优化项放进 `TODO-v3.md`。

---

## 最高优先级建议

**D3（batch 内并发度）+ D1（plan evaluator 独立性）** 并列最高。D3 是已 promise 但未实现的代码-文档差距（用户跑大 batch 会真踩到），D1 是博客原则违背（plan 评审被 self-grading 污染）。两者都不是"如何"的猜测，是"是否兑现"的事实问题，应优先关闭。
