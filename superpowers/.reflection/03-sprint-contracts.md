# Sprint Contracts 维度反思

对照 Anthropic 《Designing harnesses for long-running AI applications》中"sprint contracts are load-bearing"以及"explicit scope + success criteria agreements before implementation"的论点，对 superpowers v2.8.5 的实现现状做结构化体检。

## 0. 博客侧关键论点（用于对照）

- **契约位置**："Before each sprint, the generator and evaluator negotiated a sprint contract: agreeing on what 'done' looked like for that chunk of work before any code was written." 契约**先于代码**冻结。
- **存在动因**："This existed because the product spec was intentionally high-level, and I wanted a step to bridge the gap between user stories and testable implementation." 契约把 high-level 用户故事桥接到可测试的"done 定义"。
- **协商主体**："The generator proposed what it would build and how success would be verified, and the evaluator reviewed that proposal to make sure the generator was building the right thing. The two iterated until they agreed." 是 **generator ↔ evaluator 真双向协商**，迭代到一致才进入实施。
- **粒度**："Sprint 3 alone had 27 criteria covering the level editor"——单 sprint 27 项具体可测条目（"User can select and delete placed entity spawn points"这种带技术验收）。
- **核心机制**：契约同时承担 **scope（要做什么）+ success criteria（如何验证完成）**，并由独立 evaluator 在执行结束后对照打分。

## 1. Superpowers 中"sprint contract"在哪里被定义/生成？

### 1.1 文件层定义

`skills/executing-plans/references/sprint-contract-template.md:1-20` 是格式权威，对应 6 节固定结构：

```
Section 0  Preamble (Recurring Failure Patterns，可选)
Section 1  Tasks（表格：ID / Subject / Type）
Section 2  Acceptance Criteria（自动从 BDD Then-clauses 派生）
Section 3  Red-Green Pairs（test/impl 配对）
Section 4  Evaluation Criteria Preview（来自 code-v{N}.md checklist）
Section 5  Sign-off（Generator + Timestamp + READY）
```

`skills/executing-plans/references/evaluation-file-formats.md:16-90` 复刻同一格式，定位为"single source of truth"。

### 1.2 生成位置与生产者

`skills/executing-plans/SKILL.md:125-129` 定义生产时机（Phase 3 step 0，每 batch 一次）：

```
0. Sprint Contract (main agent, before spawning coordinator):
   - Write `sprint-contract-batch-{N}.md` from `_index.md`, batch task files,
     BDD scenarios, latest `code-v{N}.md`
   - Acceptance criteria auto-derived from each task file's BDD Then-clauses
   - Contract is never skipped. Rewrite on scope change.
```

`skills/executing-plans/references/batch-execution-playbook.md:39-41`：步骤 0→1→2 必须在**同一 main-agent response** 内完成，Agent tool 作为终结调用。这是反"漂"机制——`lib/loop.sh:286-289` 把"无契约 → 写契约 + handoff + Agent spawn"作为强制下一动作注入。

**生产者明确是 executing-plans main agent**，不是 writing-plans，也不是 coordinator。`sprint-contract-template.md:299-301` 表格栏 `Generator | Executing-plans skill | Writes contract from plan tasks, task files, BDD scenarios, and checklist preview`。

### 1.3 与 brainstorming 的"sprint contract"同名歧义

`skills/brainstorming/references/scope-alignment.md:1-44` 和 `skills/brainstorming/SKILL.md:90-95` **也叫 sprint contract**，但形态完全不同：

- 不是文件，是 brainstorming Phase 1 main agent 在 turn 输出中**inline 记录**的一个 markdown 块（problem / recommended approach / alternatives / assumptions absorbed）
- 没有 Section 1-5 结构，没有 BDD-derived 条目，没有 evaluator preview
- 不参与 evaluator 评分（evaluator 在 Phase 2 才对 design 文件评分，不是对这个 inline contract）

**结论**：同名两层。executing-plans 的 sprint contract 是博客论点的对应物；brainstorming 的"sprint contract"是命名复用，承担的是 brainstorming 自身的 scope lock，与博客描述的 generator/evaluator 协商契约不是同一概念。这种**双重命名**在阅读 SKILL 文件链时容易被混淆——值得在文档层面区分。

## 2. Contract 是否同时包含 scope + success criteria？能否被独立 evaluator 评判？

### 2.1 Scope（要做什么）

`sprint-contract-template.md:46-60` Section 1：Tasks 表格列出 batch 内每个 task 的 ID / Subject / Type。这是 scope 的显式列表。

`sprint-contract-template.md:85-97` Section 3：Red-Green Pairs 表格定义"哪些是 test 配 impl，红绿态预期是什么"——属于 scope 的执行模式约束。

### 2.2 Success Criteria（如何验证完成）

`sprint-contract-template.md:62-83` Section 2：每个 task 一组 binary checklist（`- [ ] ...`），全部 **auto-derived** from BDD Then-clauses（lines 180-212 派生协议）。例如：

```gherkin
Scenario: Successful login
  Then the response status is 200
  And the response body contains a JWT token
  And the token expires in 24 hours
```

派生为三条 acceptance criteria，每条对应一个 Then 子句。`sprint-contract-template.md:214-222` 强制 binary verifiability（"every criterion must be answerable with yes or no"）。

`sprint-contract-template.md:99-115` Section 4：Evaluation Criteria Preview 表格列出 `code-v{N}.md` 里 evaluator 会用的 checklist item ID + description——**让 generator 在执行前就知道会被怎么评分**。这是博客 calibration loop 的简化版（feedforward 而非协商）。

### 2.3 Evaluator 独立评判路径

`agents/superpowers-evaluator.md:48`：`batch + sprint contract path -> Code mode`。
`agents/superpowers-evaluator.md:66`：`Read sprint contract: sprint-contract-batch-{N}.md. Missing -> blocker, stop.`
`skills/executing-plans/references/batch-execution-playbook.md:130-137`：evaluator 读契约 + checklist + artifacts，输出 evaluation-round-{N}-batch-{M}.md，binary PASS/REWORK/PIVOT。

**评判可独立完成**：契约文件、checklist、artifacts 全部在 plan 目录里物化，evaluator 拿三个路径即可在 fresh context 内打分，不依赖任何对话历史。

**与博客的对比**：博客契约里的 scope + success criteria 是 generator/evaluator 一起谈出来的；superpowers 是 main agent 单方面**从 BDD 机械派生**。后者**消除了协商带宽但也消除了协商**——见 §3。

## 3. Contract 是否在 implementation 之前冻结？

### 3.1 时序锁

`sprint-contract-template.md:283-305` Contract Lifecycle 表格：

| Stage | Actor | Action |
|---|---|---|
| Generation | Executing-plans skill | 写契约 |
| Execution | Generator | 对照 criteria 实施 |
| Grading | Evaluator | 对照 contract 打分 |

`sprint-contract-template.md:305`：`Critical gate: Execution does not start until the contract file exists in the plan directory. The generator MUST NOT begin any task in the batch before writing and reading the contract.`

`skills/executing-plans/SKILL.md:129`：`Contract is never skipped. Rewrite on scope change.`

**硬时序保障**：

1. `batch-execution-playbook.md:39-41`：steps 0-1-2（契约 → handoff → spawn）必须在同一 response 内、Agent 调用为终结动作
2. `lib/loop.sh:251-289`：每次 Stop hook 重入时，扫描 `sprint-contract-batch-*.md` 与 `handoff-summary-*.md` 数量；若契约存在但 handoff summary 缺失，强制注入"你的首个工具调用必须是 Agent tool"
3. `lib/loop.sh:477-479`：edits-stuck 检测——main agent 在未 spawn coordinator 的前提下做 >5 次 Edit/Write/MultiEdit，触发 STUCK，allow-list 显式仅包含 `handoff-state / sprint contract / evaluation report / _index.md (PIVOT only)`

### 3.2 偷偷修改的潜在路径

**路径 A：Rewrite on scope change（SKILL.md:129）**

文档允许重写但**没有定义触发条件**。"scope change"由 main agent 自行判断，无 evaluator 复核步骤。理论上 main agent 可以在 evaluator 输出 REWORK 后改写契约让通过——但实际拦截在：

- evaluator 拿到的是**当前磁盘上的契约**+ artifacts，重写后下一轮评分仍按新契约执行
- `evaluation-round-{N}-batch-{M}.md` 是 append-only（每轮一份），但**契约文件本身是 mutable**，没有 hash/snapshot 保留旧版

**这是最大风险面**：契约被 silently rewrite 后，retrospective 阶段无法看到"契约曾经怎么写过"，只能看到最终态。

**路径 B：PIVOT 修改 _index.md（SKILL.md:171）**

```
On PIVOT: log the recommendation to the evaluation report, apply the
recommended plan modifications to `_index.md` and remaining task files,
then continue with the revised plan (do NOT ask the user)
```

PIVOT 不修改 batch N 的契约（batch N 已 done 或 escalated），但会修改 `_index.md` 和**未来 batch 的 task files**——这些 task files 是 batch N+1 契约的派生源。所以 PIVOT 间接改未来契约的 scope，**且没有用户介入**。这与博客的"两方迭代到一致才进入下一 sprint"不完全等价：博客是双方协商，superpowers 是 evaluator 单方面推荐 + main agent 单方面应用。

**路径 C：bail-out 完全跳过契约（SKILL.md:19）**

```
If "Execution Plan" YAML lists < 5 tasks in a single batch, bail out:
skip loop, coordinator, sprint contract; execute tasks inline and commit.
```

`references/bail-out.md:23`：`Skip: sprint contract, handoff-state.md, sprint-contract-batch-N.md, evaluation-round-N-batch-M.md, harness-config read, plans-completed.jsonl append.`

小规模工作完全没有契约保护。这是显式 calibration choice（"smaller plans suffer net overhead"），但意味着**契约不是普适保障，是规模门控保障**。

### 3.3 没有"双方迭代直到 agree"的环节

博客原话：`The two iterated until they agreed.`

superpowers 的实现是**单向生成**：

- `sprint-contract-template.md:270-276` Autonomous Resolution Protocol：歧义 criteria 由 main agent 用"single generation pass"自动重写为最具体形式，标记 `[AUTO-RESOLVED]`，**禁止 stall waiting on a separate negotiation loop**（line 276）。
- `skills/brainstorming/SKILL.md:95`：sprint contract 阶段"Do NOT pause to ask for approval"。
- `references/sprint-contract-template.md:5-7`：`The executing-plans skill writes the contract; the evaluator later grades against it.` evaluator 不参与契约编写。

**与博客的差距**：博客的协商是 generator/evaluator 在签约前双向往返；superpowers 是 generator 单方面写，evaluator 只在事后打分（PASS/REWORK），不参与契约本身的定稿。设计取舍合理（避免协商死锁），但**博客标榜契约 load-bearing 的原因之一是双方对齐**——单向派生丢掉了"evaluator 在签约时就发现 scope 漏洞"的早期信号。

## 4. Contract 是否承担 batch handoff 摘要？

这是 superpowers 与博客的**最显著结构差异**。

### 4.1 Superpowers 用 3 个文件做 handoff（不是契约）

`skills/executing-plans/references/handoff-template.md:5-10` 明确分工：

| 文件 | 角色 | 内容 |
|---|---|---|
| `handoff-state.md` | rolling, mutable, rewritten each batch | 下一 coordinator 读的当前累计快照 |
| `handoff-summary-{N}.md` | immutable per-batch record | retrospective + audit 的进度档案 |
| `sprint-contract-batch-{N+1}.md` | per-batch 新契约 | 仅承载 batch N+1 自身的 scope + criteria |

`skills/executing-plans/SKILL.md:131-138`：handoff-state.md 含"Completed task IDs / Modified files / Recurring Failure Patterns / Key architectural decisions"。

**契约本身只承载 batch N+1 自己的 scope**，不重复 batch N 的完成情况。

### 4.2 唯一的跨 batch 摘要注入

`skills/executing-plans/SKILL.md:191`：`Pattern Scan: Read evaluation reports from the plan directory; identify checklist items that FAILed in 2+ distinct batches. Inject "Recurring Failure Patterns" into the next sprint contract preamble UNLESS `recurring_failure_patterns` is disabled`

`sprint-contract-template.md:22-44` Section 0 Preamble：仅当 2+ batches 出现重复失败时注入。

**这就是契约承担的全部跨 batch 上下文**——窄通道，只传"重复失败模式"，不传"上批做了什么 / 下批要承接什么"。后者全部走 handoff-state.md。

### 4.3 与博客的对比

博客没有明示契约必须承担 handoff 摘要，但 principle 1（context reset）要求每个 sprint 的 coordinator 拿到自洽的输入。superpowers 的设计是**契约 + handoff-state 双文件**协同：

- coordinator 从 spawn prompt 拿到两个路径（`SKILL.md:147-148`）
- `batch-execution-playbook.md:47-48`：coordinator step 1 先读 handoff-state（学历史），再读 sprint contract（学本批 scope）

**评价**：分离合理。契约专注"本批 done 定义"，handoff 专注"历史与延续"。比把所有跨 batch 状态塞进契约更清晰。但**两个文件需要同步**——`lib/loop.sh:251-289` 检测 contract/summary 数量不一致就报错（"2 sprint contracts but only 1 handoff-summary" → 提示 spawn coordinator），是这一架构的一致性保障。

## 5. 与博客差距 + 行动建议

### 5.1 主要差距

| 维度 | 博客 | superpowers v2.8.5 | 差距评估 |
|---|---|---|---|
| 契约存在性 | per-sprint contract before code | per-batch contract before spawn | 持平 |
| Scope + Success criteria | both 同时显式 | both 同时显式（Section 1 + 2） | 持平 |
| 协商主体 | generator ↔ evaluator 双向迭代 | main agent 单方面 auto-derive from BDD | **差距大**（取舍合理但丢早期对齐） |
| Criteria 粒度 | 27 项/sprint，含技术验收 | 由 Then-clause 数量决定，无下限 | **风险**（BDD 稀薄 → criteria 稀薄） |
| 契约不可变性 | 隐含（implementation 后不改） | 显式允许 "Rewrite on scope change" 无审计 | **差距**（最大风险点） |
| Independent evaluator 评判 | 是 | 是（agents/superpowers-evaluator.md code mode） | 持平 |
| Handoff 责任 | 未明 | 拆分到 handoff-state + handoff-summary | superpowers 更清晰 |
| 小规模工作 | 未明 | bail-out 完全跳过 | 取舍 |

### 5.2 行动建议（优先级排序）

**P0 — 契约不可变性 + 审计**

`SKILL.md:129` "Rewrite on scope change" 无触发条件、无 evaluator 复核、无历史保留。建议：

- 契约 rewrite 时把旧版本归档为 `sprint-contract-batch-{N}.v{M}.md`（类似 evaluation-round 命名），不覆盖
- 在 `sign-off` section 加 `Revision: {M}` 字段，每次重写递增
- retrospective Phase 1 把"契约重写次数 > 1 的 batch"作为 signal 纳入分析

证据：`sprint-contract-template.md:7`（"Execution does not start until the contract file exists"）保证了**初版**冻结，但**没保护 rewrite 路径**。

**P1 — Briefly evaluator pre-sign-off check（弱协商代偿）**

不必引入完整双向迭代（会增加 N 倍 token 成本与可能死锁），但可以在契约 sign-off 前让 evaluator 做一次**轻量验收**，输出"contract READABLE / contract AMBIGUOUS / contract INCOMPLETE"三态：

- AMBIGUOUS / INCOMPLETE 触发 main agent 自动改写一轮（沿用现有 Autonomous Resolution Protocol），仍然不暂停
- 这把"evaluator 在事后发现 criteria 不能打分"的成本前移到签约时
- 实现位置：`batch-execution-playbook.md:39` 的 atomic 步骤里增加 step 0.5

**P2 — 命名歧义解决**

`brainstorming/references/scope-alignment.md` 和 `executing-plans/references/sprint-contract-template.md` **都叫 sprint contract** 但是两个对象。建议：

- 把 brainstorming 阶段的 inline 块改名为 "Scope Lock" 或 "Brainstorm Contract"
- 仅保留 executing-plans 的 per-batch `sprint-contract-batch-{N}.md` 使用"sprint contract"术语
- 减少阅读 SKILL 文件链时的歧义

**P3 — Criteria 稀薄保护**

`sprint-contract-template.md:62` "auto-derive only" 把 criteria 完全依赖于 BDD Then-clauses 的数量与质量。如果 BDD 写得稀薄，契约也稀薄。建议：

- 在 sprint-contract-template.md `Acceptance Criteria Derivation` step 3 (Edge Cases) 后追加"Minimum criteria density"检查：每个 impl task ≥ 2 条 criteria，否则在契约里标 `[CRITERIA-SPARSE]` 让 evaluator 在事后能识别（不暂停）
- 当前 §225-240 已有 edge case 派生指引但没有最低数量门控

**P4 — Bail-out 跳过契约的 audit signal**

`references/bail-out.md:23` 跳过契约的同时也跳过了 evaluator。`bail-log.sh executing-plans bail_out` 已记录事件（line 33-37），但当前没有把"跳过契约后实际触发返工"的事件回灌——可以让 git post-plan-diff（`lib/post-plan-diff.sh`）把 bail-out 后 24h 内的 `fix:` / `refactor:` commit 反向标记为"契约缺失导致的隐性 rework"，给 retrospective Phase 5a 提供 calibration 信号。

### 5.3 总评

Sprint contracts 在 superpowers 中**结构上 load-bearing 程度与博客对等**：先于代码、独立评判、scope+criteria 同时显式、与 handoff 配合形成 context-reset 友好的执行环。**最大单点风险是"Rewrite on scope change"无审计**——其他差距（单向派生、无协商）都是合理 calibration 取舍，但允许 silently rewrite 是不可观察的失败模式。
