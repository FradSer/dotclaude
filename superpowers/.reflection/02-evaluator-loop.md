# Evaluator Loop 维度反思

对照 Anthropic 《Designing harnesses for long-running AI applications》一文中 Generator/Evaluator 分离、binary PASS/FAIL、hard-threshold grading、calibration loop、以及 Opus 4.5 → 4.6 evaluator 由 per-sprint 退为 strategic end-stage 的论点，对 superpowers v2.8.5 的实现现状做结构化体检。

## 0. 博客侧关键论点（用于对照）

- **GAN 分离**："Taking inspiration from Generative Adversarial Networks (GANs), I designed a multi-agent structure with a generator and evaluator agent." 动机是 LLM 自评会"confidently praising the work—even when... quality is obviously mediocre"。
- **Hard-threshold binary**："Each criterion had a hard threshold, and if any one fell below it, the sprint failed and the generator got detailed feedback."
- **Calibration loop**："I calibrated the evaluator using few-shot examples with detailed score breakdowns. This ensured the evaluator's judgment aligned with my preferences, and reduced score drift across iterations." 且需要"several rounds of this development loop before the evaluator was grading in a way that I found reasonable"。
- **Opus 4.5 → 4.6 退场**：4.5 时代 per-sprint evaluator load-bearing；4.6 之后"I moved the evaluator to a single pass at the end of the run rather than grading per sprint"，且"the evaluator is not a fixed yes-or-no decision. It is worth the cost when the task sits beyond what the current model does reliably solo"。

## 1. Generator 与 Evaluator 是否真正分离？

### 1.1 严格分离的路径（设计 / code 模式）

`superpowers-evaluator` 是独立的 sub-agent，强制 read-only：

- `agents/superpowers-evaluator.md:34-35`：`tools: ["Read", "Grep", "Glob", "Bash"]` + `disallowedTools: ["Write", "Edit", "MultiEdit", "NotebookEdit"]`。这是工具层的硬隔离，比博客描述的"分离 agent"更严格——评估器物理上无法修改 artifacts。
- `agents/superpowers-evaluator.md:87`：`Read-only: no Write/Edit. Document issues; never fix them.` 与"Skeptical: assume issues until verified. Do not anchor to prior assessments."（同文 line 91）一起在系统提示里钉死。
- `skills/executing-plans/references/batch-execution-playbook.md:139`：`Independence: The superpowers-evaluator runs as its own sub-agent regardless of the execution mode used for the batch (Parallel, Linear, Red-Green). It is never fused with an implementation sub-agent.`
- `skills/executing-plans/SKILL.md:107`：batch coordinator 本身也跑在 fresh sub-agent context，evaluator 又是从 coordinator 二次 spawn 的子 agent——双重 context reset，匹配博客 principle 1。

**Design 模式**同样走独立 evaluator：`skills/brainstorming/SKILL.md:154` 明确 `Spawn superpowers:superpowers-evaluator agent (design mode) with the checklist path.`

### 1.2 准分离 / 灰色地带（plan 模式）

plan-mode evaluator **已被永久删除**，由 writing-plans Phase 4 的"reflection sub-agents"代偿：

- `skills/writing-plans/SKILL.md:226`：`There is no separate formal plan-mode evaluator — structural checks ... are fully covered by sub-agent reflection`。
- `skills/retrospective/references/harness-config.md:63`：`plan_evaluator | Plan-mode evaluator was permanently removed in 2.6.0.` Retrospective Phase 5c 必须拒绝该 identifier。
- `skills/writing-plans/references/reflection.md:28`：reflection sub-agents 使用 `subagent_type=general-purpose`，是 fresh context，**但不是独立的 `superpowers-evaluator` agent**，没有 `disallowedTools` 防护，理论上能写文件——与 design/code 模式的硬隔离不对等。
- 实际拦截手段是 `reflection.md:32-43` 的"CHECKLIST RUBRIC (REQUIRED)"prompt-prepend，把 binary PASS/FAIL 协议注入到每个 sub-agent prompt 里。这是软隔离（prompt-level），而 evaluator agent 是硬隔离（tool-level）。

**结论**：design/code 模式有真分离；plan 模式是"用 3 个 general-purpose sub-agent + checklist rubric prompt"近似 evaluator，**算分离但不算硬分离**。`agents/superpowers-evaluator.md:50` 还要求显式拒绝 plan-mode spawn——这把 plan-mode 的"用 reflection 代替 evaluator"决策从软规则升格成了 agent 协议级别的红线。

### 1.3 brainstorming 是否仍存在自评？

brainstorming 是 generator（写设计），evaluator 在 Phase 2 Step 2 才被 spawn（`skills/brainstorming/SKILL.md:154`）。但 design 文件的写入是 main brainstorming agent 在 Phase 2 Step 1 完成的，evaluator 拿到的已经是 main agent 整合后的成品——这与博客的 generator/evaluator 双 agent 描述一致，**未发现 self-evaluation 残留**。

## 2. Binary 还是 1-5 主观打分？

`grep -rn -E "1-5|1 to 5|scale of|rating|score [0-9]" superpowers/skills/ superpowers/agents/` 在所有 SKILL 与 evaluator 文件里 **零命中**（见会话搜索结果）。

明确的硬约束：

- `agents/superpowers-evaluator.md:89`：`Binary verdicts: PASS or REWORK (PIVOT in code mode). No "borderline", no "PASS with notes", no "Recommendations" section. When a check feels ambiguous, the artifact is wrong -- emit FAIL.` ——比博客更激进：把"the checklist itself is ambiguous"也判 FAIL 并要求经 retrospective 修 checklist，禁止 evaluator 自创第三态。
- `lib/seed-checklists.sh` v1 design 模板里所有 5 项（JUST-01 / REQ-TRACE-01 / SCEN-CONC-01 / ARCH-01 / RISK-02）每个都给了 `Check method: grep -nE ...` 或具体短语清单，并标注 `# Type: computational` 或 `# Type: inferential` 让评估更可重复——是 hard-threshold 的具体落地（脚本中 105-200 行）。
- `skills/executing-plans/references/sprint-contract-template.md:62-67`：acceptance criteria 是从 BDD Then-clauses **自动派生**的，每条 Then 一条 binary checklist 项；`step 2` 要求"every criterion must be answerable with yes or no"。

唯一一处"score"出现在 `skills/executing-plans/references/blocker-and-escalation.md:48`：`Affected task IDs and scores` ——上下文是 pivot escalation 的证据栏，但整个 evaluator 协议里没有 score 字段输出（`evaluation-file-formats.md:102-141` 的 Evaluation Report 格式没有 score 列）。这是文档残留措辞，不影响实际行为。

**结论**：binary 与 hard-threshold 落实完整，比博客示例更严格（连"PASS with notes"都禁掉）。`1-5` 主观打分**零残留**。

## 3. Calibration loop（少样本对齐）实现在哪？

博客的 calibration loop 是"用 few-shot example 让 evaluator 与 maintainer 偏好对齐，迭代多轮直到打分合理"。superpowers 的对照实现是 **checklist evolution loop**——形态不同但解决同一问题：

### 3.1 演化机制（已实现）

- `skills/retrospective/SKILL.md:62-67`：Phase 2 Pattern Analysis 四类分析（failure frequency / plateau tasks / never-failing / variety gaps）。
- `skills/retrospective/references/evolution-protocol.md:6-12`：4 种 proposal 类型 + 阈值（ADD: 2+ plans，REMOVE: 10+ reports zero-fail，MODIFY: 2+ false positives，PROMOTE: pass rate >80% across 3+ plans）。
- `skills/retrospective/references/evolution-protocol.md:50-58`：never mutate existing checklist files，每轮 retrospective 写 `{mode}-v{N+1}.md`，原版本保留——版本化对齐，可审计。
- `lib/evolution-log.sh` 把 `item_added / item_removed / item_modified / item_promoted / retrospective_run / component_reinstated` 写入 `docs/retros/evolution-log.jsonl`（schema 在 `evolution-protocol.md:80-170`），形成闭环可观测的"对齐历史"。
- `skills/retrospective/SKILL.md:53` Phase 1 step 5 + `evolution-protocol.md:180-182`：next-run 必须读这份历史，**禁止重复提议刚被 REMOVE 掉的项**（除非新证据 materially different），明确防 ping-pong——这是博客没显式提到、但 superpowers 多走了一步的 self-correction。

### 3.2 双层零产出保护

- `skills/retrospective/SKILL.md:21-27` Pre-Check B + `executing-plans/SKILL.md:226-228`：`consecutive_zero_change >= 2` 时切换到 LOW-YIELD 模式（不要催 retrospective）。匹配博客"calibration 需要多轮迭代"，并加了"低产出别空转"的负反馈。

### 3.3 一处缺位：博客式 few-shot 校准缺席

博客的 calibration **本质上是把 maintainer 的样例打分塞进 evaluator prompt**——即 `superpowers-evaluator.md` 系统提示里硬编码若干 maintainer-graded 范例。当前文件 (`agents/superpowers-evaluator.md`) 完全没有 few-shot 范例段，只有协议描述和 4 个 `<example>` block（但那 4 个是描述何时 spawn agent 的，不是打分范例）。

`skills/brainstorming/references/evaluation-checklist-reference.md:33-56` 倒是有一份"Calibration Example"，但这是 **reference 文件**，evaluator agent 的 spawn prompt（`brainstorming/SKILL.md:154` 与 `executing-plans/SKILL.md:140-158`）都没有把它注入到 evaluator 上下文。换言之，**这份 calibration 样例对运行中的 evaluator 是不可见的**——L3 reference 给人看的，evaluator agent 从来不读。

**结论**：calibration loop 用 checklist evolution + evolution-log + LOW-YIELD 三件套补齐了博客的整体目标，但少了博客明确点名的"few-shot examples in evaluator prompt"那一步。`evaluation-checklist-reference.md` 的 Calibration Example 没有进入 evaluator 的运行时上下文。

## 4. Evaluator 频率：per-batch 还是 end-stage？是否过度调用？

**当前默认是 per-batch**，可通过 `harness-config.json` 关闭：

- `skills/executing-plans/SKILL.md:154-156`：`Default: "Spawn superpowers:superpowers-evaluator for batch evaluation after all tasks pass their Verification Gate"`，关闭分支用 `evaluator_per_batch` identifier。
- `skills/executing-plans/references/batch-execution-playbook.md:124-160`：每个 batch 在 Verification Gate 后强制 spawn 一次，max 2 rework rounds 然后 escalate；与博客 4.5 时代的"mandatory per-sprint"形态完全一致。
- `skills/retrospective/references/harness-config.md:49-54`：唯一的退场机制是 retrospective Phase 5c 把 `evaluator_per_batch` 加进 disabled list。**没有"按 batch 数量自动降级到 end-stage"**——也就是说，无论 batch 数是 2 还是 20，默认都是 per-batch。
- `skills/retrospective/SKILL.md:113-122` Phase 5a：`If all tasks in recent plans pass on first round (no REWORK), recommend reducing evaluation frequency`——这是"reduce frequency"建议，**没有 end-stage 模式可切换**，只能整体禁用 + harness-observation 观察 + 下一轮 promote 到永久移除。从 `harness-config.md:49-54` 的语义看，`evaluator_per_batch` 是**全开 or 全关二选一**，没有中间档（如"每 3 个 batch 一次"或"plan 结束时一次"）。

**博客的 4.6 状态是"end-stage single pass"。superpowers 的对应实现只有"per-batch 默认 on / 一键禁用全部"**——没有 4.6 描述的"per-batch → strategic end-stage"那一档。

**过度调用证据**：

- `skills/retrospective/references/analysis-patterns.md:90`：`Evaluator | All tasks PASS on first round in 3+ consecutive plans → Flag the evaluator as a removal candidate`。说明历史上确实碰到过"3 个 plan 连续 first-pass-PASS"——`sprint-contract-template.md:26` 直接承认"first-pass-PASS plans, where every batch's evaluator returned PASS without rework. Empirically observed across 7-batch real plans"。
- 7-batch 都 first-pass-PASS 时仍然每个 batch 都 spawn 一次 evaluator——这是博客 4.6 直接定性为"not worth the cost when the task sits within what the current model does reliably solo"的反例。

### 4.1 design evaluator 也是同款问题

`skills/brainstorming/SKILL.md:108-110` Phase 1.5 + `harness-config.md:54`：design_evaluator 同样是默认开 + 仅可全禁。但 brainstorming 每个 plan 只跑一次 evaluator，所以单次成本 << per-batch，这里问题没那么尖锐。

**结论**：superpowers 当前停留在博客描述的 4.5 形态（per-sprint mandatory），缺少 4.6 的"strategic end-stage"中间档。harness-config 的 evaluator_per_batch 是 binary 开关，无法做到博客提议的"task sits beyond what the current model does reliably solo → 才开 evaluator"的智能调度。

## 5. design / plan / code checklist 独立性与演化在生效吗？

### 5.1 三模式 checklist 独立

- `lib/seed-checklists.sh` 用 `case "$MODE" in design)... plan)... code)` 三分支生成三套独立 v1（脚本 56-200+ 行）。
- `skills/retrospective/references/evolution-protocol.md:88-97`：`item_added` 事件的 `mode` 字段为 `design|plan|code`，version 也是 per-mode 独立递增（`{mode}-v{N+1}.md`）。
- `skills/retrospective/SKILL.md:82` Phase 3：`EVO-6: Max 3 proposals per mode per retrospective run`——rate limit 按 mode 独立。
- consumer 各自读各自的：design 模式 → `brainstorming/SKILL.md:154` 读 `design-v{N}.md`；plan 模式 → `writing-plans/SKILL.md:228-230` 读 `plan-v{N}.md`；code 模式 → `executing-plans/SKILL.md:149` 读 `code-v{N}.md`。

三模式确实独立，没有耦合。

### 5.2 演化是否真在生效

**机制完整**，但**默认状态下 plan 模式的演化反馈链条最弱**：

- `executing-plans/SKILL.md:203` 在 plan 完成时输出 evolution candidates（item failed in 3+ batches 或需要 3+ rework rounds），retrospective Phase 1 → Phase 3 把它们升为 ADD/MODIFY/PROMOTE proposal，Phase 4 auto-apply。完整闭环，没有"评估出问题但没人读"的死信。
- 但 plan-mode 没有正式的 evaluation report 文件（`evaluation-file-formats.md:256` 明确："Plan-mode evaluation has no formal report. ... No `evaluation-plan-round-*.md` file is written"）。retrospective Phase 1 步骤 4 要"read all evaluation report files. Extract per-item results"——plan-mode 无文件可读，只能依赖 reflection 子 agent 在 main agent turn output 里留的 inline summary，**这个 summary 不持久化到磁盘**，跨 plan 的 plateau / never-failing 分析对 plan 模式来说近乎无源。
- `skills/retrospective/references/analysis-patterns.md:11` 明说 plan-mode 的失败分析依赖 evaluation report files——这与 plan-mode 不写 report 的设计直接冲突。
- 结果：design 与 code checklist 能正常演化，plan checklist 演化几乎只能靠"出问题被下游 code-mode 评估器抓到再反推"的间接信号。

### 5.3 evolution-log 与 retrospective-due 闭环

- `executing-plans/SKILL.md:222-227`：每 3 个 plan 完成而无 retrospective 时弹 RETROSPECTIVE DUE；`consecutive_zero_change >= 2` 时降级为 LOW-YIELD 提示。
- `lib/evolution-log.sh` + `lib/observations.sh` 是这套闭环的事件层。`retrospective_run` 事件强制写入（`retrospective/SKILL.md:191-208`），是 calibration loop 的"我跑过了"标记。
- `evolution-protocol.md:147-167` 的 `component_reinstated` 事件 + Phase 5b post-plan-diff veto 是 v2.7 → v2.8 加的反 add-bias 机制（与你已知的 v2.7 systemic miscalibration 修复对应）。

机制完整、有审计、防 ping-pong——比博客描述更工程化。

**结论**：design/code 模式的 checklist 演化真在生效；plan 模式的演化由于没有 evaluation report 文件，跨 plan 信号近乎为零，依赖 Phase 4 reflection inline summary 的人工抽样。

## 6. 差距 + 行动建议（按优先级）

| 优先级 | 差距 | 证据 | 建议 |
|--------|------|------|------|
| P0 | 缺少博客 4.6 的"strategic end-stage / per-batch 智能切换"中间档 | `executing-plans/SKILL.md:154` 默认 per-batch；`harness-config.md:49-54` 只能 binary 开关；`analysis-patterns.md:90` 已观测到 3+ plan 连续 first-pass-PASS | 在 `harness-config.md` 加 `evaluator_mode: per_batch \| end_stage \| disabled` 三档；end_stage 模式让 executing-plans 在所有 batch verification gate 通过后才 spawn 一次 evaluator，跨整个 plan 评分。先把现有 `evaluator_per_batch` 二档保留作向后兼容 |
| P0 | evaluator 运行时上下文缺少 few-shot calibration 样例 | `agents/superpowers-evaluator.md` 整个系统提示无样例；`brainstorming/references/evaluation-checklist-reference.md:33-56` 的 Calibration Example 是 L3 reference，evaluator 不读 | 把每个 checklist item 的 1-2 个 maintainer-graded PASS/FAIL 范例（含证据片段）直接内联到 `seed-checklists.sh` 的 v1 模板里（每个 `### ITEM-ID` 后面加 `**Calibration Examples:**` 子节）；evaluator 读 checklist 文件时就自动加载样例。retrospective evolution 时附带演化样例 |
| P1 | plan-mode 没有持久化 evaluation report，跨 plan 演化信号近零 | `evaluation-file-formats.md:256` 明确不写 plan-mode report；`analysis-patterns.md:11` 要求读 evaluation report files；`writing-plans/SKILL.md:226` 把 reflection 子 agent 的输出留在 main agent turn output（瞬态） | 让 writing-plans Phase 4 在 reflection 整合后把每个 sub-agent 的 PASS/FAIL 结果序列化为 `evaluation-plan-round-{N}.md`（用 evaluator 同款格式），与 design/code 模式对齐。retrospective Phase 1 步骤 4 就有跨 plan 的 plan-mode 数据可读 |
| P1 | plan-mode reflection sub-agent 是软隔离（general-purpose + prompt rubric），不是硬隔离 | `writing-plans/references/reflection.md:28` 用 `subagent_type=general-purpose`；`agents/superpowers-evaluator.md:50` 显式拒绝 plan-mode spawn | 二选一：(a) 取消 evaluator agent 对 plan-mode 的拒绝，把 plan 模式纳入同一 evaluator agent（增加 plan-mode 检查项），获得硬隔离；(b) 把 reflection 子 agent 工具集显式收紧为 `["Read", "Grep", "Glob"]`（不在 frontmatter 而在 spawn prompt 里宣告——general-purpose 没法限制 tool，所以这条只能走 (a)）。推荐 (a) |
| P2 | "score" 一词在文档残留 | `executing-plans/references/blocker-and-escalation.md:48` `"Affected task IDs and scores"` 与 binary 协议不一致 | 改为 `Affected task IDs and FAIL items`，与全文 binary 协议一致 |
| P2 | evaluator agent 的 `<example>` block 描述何时 spawn，但没有打分范例 | `agents/superpowers-evaluator.md:6-31` 三个 example 全是 spawn 决策示范 | 在 system prompt 末尾追加一个"Grading example"小节：一份完整的 PASS 报告 + 一份完整的 REWORK 报告，让 evaluator 在 spawn 时立刻看到目标输出形态。配合 P0 的 calibration 样例 |
| P3 | EVO-6 rate limit 与 calibration loop 的迭代速度不匹配 | `retrospective/SKILL.md:82` 每个 mode 每次最多 3 proposals | 这是反过度演化的护栏，目前合理。但当 P1 落地（plan-mode 写 report 后）短期内 plan-mode 信号会激增，可临时允许 EVO-6 = 5 三轮以追上积压 |

## 7. 整体判断

- **GAN 分离**：design / code 模式硬隔离到位（tool-level disallowedTools），plan 模式是 prompt-level 软隔离。
- **Binary PASS/FAIL + hard threshold**：执行到位且比博客更严格（`evaluator-agent.md:89` 连"PASS with notes"都禁）。1-5 主观打分零残留。
- **Calibration loop**：用 checklist evolution + evolution-log + LOW-YIELD self-check 实现了博客的总体意图，**但缺最直接的那一步——few-shot examples 进 evaluator 系统提示**。
- **频率**：停留在博客 4.5 形态（per-batch mandatory，可一键全禁），**缺 4.6 的 end-stage 中间档**，已有 7-batch 全 first-pass-PASS 的过度调用证据。
- **三模式独立性**：design / plan / code checklist 文件、版本、log mode 完全独立；但 **plan 模式因为不写 report，演化反馈链路最弱**。
- **整体最高优先级**：先落 P0 两条（evaluator_mode 三档 + checklist 内联 calibration 样例）。两条都是高 ROI 的纯增量改动，不需要重写任何已有机制。
