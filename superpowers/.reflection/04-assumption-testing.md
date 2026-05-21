# 04 — 假设测试视角下的 superpowers 反思

参考：Anthropic 工程博客 *Harness Design for Long-Running Apps*。本反思仅就 **Assumption Testing / 拆除冗余组件** 一维度展开，逐条对照 superpowers 当前组件，标出"假设的模型缺陷"、Opus 4.7 下是否仍 load-bearing，以及是否可以"停用一周看看"。不修改代码。

## 0. 博客的五条要点（核对锚点）

1. *"Every component in a harness encodes an assumption about what the model can't do on its own, and those assumptions are worth stress testing."*
2. *"I moved to a more methodical approach, removing one component at a time and reviewing what impact it had on the final result."*
3. *"The evaluator is not a fixed yes-or-no decision. It is worth the cost when the task sits beyond what the current model does reliably solo."*
4. Opus 4.6 之后：evaluator 从 *mandatory per-sprint* 降级为 *strategic end-stage*，因为 generator 单独能跑更长的连贯构建。
5. *"Find the simplest solution possible, and only increase complexity when needed"* — 即 simplify-don't-only-add。

下面所有评估以此五条为度量标尺。

---

## 1. 组件 → 假设的模型缺陷 → Opus 4.7 现状 → 是否 load-bearing

| 组件 | 假设的模型缺陷（为何存在） | Opus 4.7 是否仍有该缺陷 | 仍 load-bearing？ | 证据（file:line） |
|---|---|---|---|---|
| **hook: task-start.sh**（UserPromptSubmit）| 模型不会主动持久化"用户原始 prompt"，loop 后续阶段会丢失任务上下文 | **是**：每轮迭代必须从 state file 读 `task`，模型自身不维持跨 stop 的状态 | **是** — 没有它 loop 无法重启 | `hooks/task-start.sh:142-164`（写 `task` / `pending_prompt`），`hooks/stop-hook.sh:52`（依赖该 state 读 `loop_phase`）|
| **hook: stop-hook.sh**（Stop）| 模型 Stop 时不会自动判断"任务真的完成了吗"，需要外部 promise-tag 仲裁 | **部分**：Opus 4.7 单跑也常自我中止，promise 协议仍有效；但 4.7 已能更准确地自报完成 | **是** — Superpower Loop 的入口 | `lib/loop.sh:1-14`（loop_phase 入口语义） |
| **hook: track-changes.sh**（PostToolUse Edit/Write/MultiEdit）| 模型不主动告诉自己"我改了哪些文件"，事后无法做 verification | **是**：跨 Stop 边界后模型不会扫描自己刚写的内容 | **是** — verification 阶段需要 modified_files 列表 | `hooks/track-changes.sh:29-31, 69-71` |
| **hook: track-reads.sh**（PostToolUse Read/Glob/Grep/Bash）| 模型可能"读读读"代替"做做做"——卡在探索而不 spawn sub-agent | **部分**：4.7 比 4.6 更不容易陷入 read-loop，但 executing-plans 长程任务仍偶发 | **可降级** — 阈值（>15 reads）可能太低，等同噪音 | `hooks/track-reads.sh:11-17`（注释明示"the empirical 42-tools-no-Agent symptom"），最近一次 retro `787b923 feat(sp): track read loops in executing-plans` 才加上 |
| **hook: track-spawns.sh**（PostToolUse Agent）| 配合 track-reads/changes：spawn 完成后必须清零，否则 stuck detector 误报 | **是**（只要 track-reads/changes 存在它就 load-bearing）| **是**（依附于 track-reads/changes）| `hooks/track-spawns.sh:41-42` |
| **skill: brainstorming**（slash command）| 模型对开放性多组件需求会"直接开干"，跳过澄清 | **部分**：4.7 在多组件设计上确实更自觉先列假设，但仍会跳 BDD scenarios | **是**，但 Bail-Out（Bucket A）已经把"trivial"路径拆掉 | `skills/brainstorming/SKILL.md:12-48`（已经引入 bail-out + force_override 日志）|
| **skill: writing-plans**（slash command）| 模型在大量任务时不会自动拆 batch、不会写 sprint-contract | **是**：长程任务的批次化仍是 4.7 弱项 | **是** — 但 BDD<3 OR tasks<5 时已经 bail | `skills/writing-plans/SKILL.md:14-26` |
| **skill: executing-plans**（slash command）| 模型不会在 sprint 之间自动 commit / 不会自动 spawn coordinator-per-batch | **是**：4.7 仍然倾向"一个大答复"而不是 batch-wise spawn | **是** — Superpower Loop 核心载体 | `skills/executing-plans/SKILL.md:14-19, 29-31` |
| **skill: retrospective**（slash command）| 模型不会跨 plan 聚合 evaluator 失败模式 / 不会自我更新 checklist | **是**：跨 session 知识沉淀完全靠外部 NDJSON 日志 | **是** | `skills/retrospective/SKILL.md:23-27`（已自带 LOW-YIELD 自我检测，consecutive_zero_change>=2 时自报"该停用"）|
| **skill: systematic-debugging**（slash command）| 模型遇到 bug 会 "guess-fix"，不做根因调查 | **部分**：4.7 自发的根因思考显著改善；该 skill 已自带 Bail-Out（named root cause + named fix 路径） | **可降级** — 直接走 bail-out 路径几乎成主流 | `skills/systematic-debugging/SKILL.md:22-43`（bail-out 三条件即时短路 4 阶段流程） |
| **skill: behavior-driven-development**（internal-only）| 模型不会主动写 Given/When/Then，不会先 RED test 再写代码 | **是**：4.7 仍倾向先写实现再补测试 | **是** — Iron Law 唯一执行点 | `skills/behavior-driven-development/SKILL.md:45-49` |
| **skill: build-like-iphone-team**（internal-only）| 模型默认会"沿用业界惯例"，不会主动 first-principles 砍冗余 | **部分**：4.7 单独 prompt "challenge the premise" 就基本能复现该效果（用户 CLAUDE.md L19 已经明文要求） | **可质疑** — 与 brainstorming + 用户全局 CLAUDE.md 中的"Challenge the premise"重合 | `skills/build-like-iphone-team/SKILL.md:22-32`；用户 `~/.claude/CLAUDE.md` 第 19 行已写"Challenge the premise before implementing" |
| **agent: superpowers-evaluator**（design + code mode）| 模型生成的 design/code 自己会评估为 PASS，需要独立读手 | **部分**：博客明说 Opus 4.6 已把 evaluator 从 *per-sprint mandatory* 改成 *strategic end-stage*；4.7 更甚 | **load-bearing 但降级时机已到** — 应只在 final stage 跑，不应 per-batch 跑 | `agents/superpowers-evaluator.md:64-83`（仍按"每个 sprint contract 一次"的频率被 spawn）；博客 §evaluator value is task-dependent |
| **lib/bail-log.sh + retro-events 三件套**（observations / evolution-log / skill-events）| 模型无法跨 session 自报"我刚 bail 了 / 我刚改了 checklist"，需要 NDJSON 物化 | **是** — 这是博客所说"compact summarization 替代品"的本地实现 | **是** — 但 *4 个* NDJSON channel（bail-out / observations / evolution-log / skill-events）可合并 | `lib/skill-events.sh:42-88` + `lib/observations.sh:1-40` + `lib/evolution-log.sh:1-40` 三者只在 envelope 形态差一格（nest vs merge）|

---

## 2. Opus 4.7 下可以"降级 / 合并 / 删除"的组件

按博客 §2 "remove one component at a time" 思路，给出按可拆除程度排序：

### 2.1 候选：`build-like-iphone-team` skill —— **最高优先级"停用一周看看"**

证据：
- 用户全局 `~/.claude/CLAUDE.md:19` 已经强制 "Challenge the premise before implementing"，与此 skill `skills/build-like-iphone-team/SKILL.md:22-32` 的"First-Principles Thinking: Slash All Redundancy"高度同义。
- 该 skill 是 `internal-only`（plugin.json `skills/` 而非 `commands/`），意味着只在 brainstorming/writing-plans 中被自动加载——而 brainstorming `SKILL.md:10` 已经写明"calibrated for open-ended multi-component problems"，本身就要求 first-principles 思考。
- 没有任何 hook、log、metric 在测它"是否被实际触发"——典型的"装上去就忘"的 scaffolding。
- 触发率几乎不可观测：retro-events 流里没有 `build-like-iphone-team` 通道。

建议：在 `plugin.json:27-30` 临时移除 `./skills/build-like-iphone-team/`，跑一周 brainstorming + writing-plans，观察 design 评估结果是否退化。若评估 PASS 率不变，正式 REMOVE。

### 2.2 候选：`superpowers-evaluator` 的 **per-batch 调用频率**降级

证据：
- 博客原文（要点 4）："Opus 4.6 shifted evaluator from mandatory per-sprint to strategic end-stage"。4.7 更进一步。
- `agents/superpowers-evaluator.md:64-83` 仍按"每个 sprint contract"被 spawn——与博客对齐应改成"最终 batch + 显式触发"。
- `agents/superpowers-evaluator.md:4` 已经把 `plan` mode 拒绝、改由 writing-plans Phase 4 inline 处理——这本身就是博客 simplify-don't-add 的实践案例。

建议：保留 evaluator agent，但把 executing-plans 的 spawn 频率从"每个 batch"改成"最终 batch + 显式 `--evaluate` 触发"。一周观察 evaluation-round-* 文件数量是否锐减、PASS 率是否变化。

### 2.3 候选：`track-reads.sh` hook —— **新加的，应放进观察期**

证据：
- 最近一次 commit `787b923 feat(sp): track read loops in executing-plans` 才加这个 hook（5 天内）。
- `hooks/track-reads.sh:11-17` 的注释明确说阈值 15 是 "empirical 42-tools-no-Agent symptom" 推出来的——但样本量极小。
- 4.7 比 4.6 更不容易陷入 read-loop，可能这 hook 90% 触发都是假阳性（用户在做合法的研究探索）。

建议：保留代码但把阈值临时调到 30（或在 `plugin.json:65` 暂时去掉 `Read|Glob|Grep|Bash` matcher），跑一周 executing-plans，统计 stuck detection 真假阳性比。

### 2.4 候选：3 个 NDJSON helper 合并

证据：
- `lib/observations.sh:16-21`、`lib/evolution-log.sh:13-17`、`lib/skill-events.sh:13-25` 三者只在 envelope 形态（merge vs nest）和文件名上不同。
- 三者都 source 同一个 `lib/retro-events.sh:32-95` 内核——已经事实合并，剩下的差异是表面的。

建议：不是 load-bearing 问题，但属于 "simplify-don't-add" 的整理负债——把 3 个 wrapper 合并成 `log_retro_event <channel> <event> <payload>` 单一入口。可放进下一次 retro 的 housekeeping，不需要"停用一周"测试。

### 2.5 候选：`systematic-debugging` 的 4 阶段流程对 4.7 已基本是空跑

证据：
- `skills/systematic-debugging/SKILL.md:22-43` 的 Bail-Out 三条件（命名根因 + 命名修复 + 单文件）现在在用户日常调试中是默认路径。
- 4 阶段流程剩下的真实触发场景是"症状已知、根因未知"——这恰好是 Opus 4.7 单跑能完成的事。
- 该 skill 的存在不是为了"调试"，而是为了"防止 guess-fix"——但 4.7 的 guess-fix 倾向已经大幅降低。

建议：先观察 `bail-out-events.jsonl` 里 systematic-debugging 的 `bail_out` vs `force_override` 比率。如果 `bail_out` 占 95%+，下一次 retro 可以考虑把 4 阶段流程缩成"问一句根因，再修"的更短模板。

---

## 3. 仍 load-bearing 且不能移除的组件

| 组件 | 为何不能移除 |
|---|---|
| **task-start.sh + stop-hook.sh + loop.sh** | Superpower Loop 的入口/出口/状态机。模型自身没有"跨 Stop 恢复"能力——博客要点 1 的典范："encodes an assumption about what the model can't do on its own"，且该假设在 4.7 仍 100% 成立。 |
| **track-changes.sh** | verification 阶段需要 modified_files 列表，模型不会自报。 |
| **brainstorming / writing-plans / executing-plans** | 三阶段瀑布，每个都对应模型在长程任务上的不同缺陷（澄清 / 拆批 / 执行）。Bail-Out 已经按需短路 trivial 路径。 |
| **behavior-driven-development**（internal）| Iron Law（先 RED 再 GREEN）需要单独的训练有素的执行点；4.7 单跑仍倾向先实现再补测。`skills/behavior-driven-development/SKILL.md:45-49` |
| **retrospective**（含 LOW-YIELD 自检）| 跨 session 知识沉淀靠 NDJSON 物化；retrospective 是唯一把这些日志变回 checklist 的回环。其自带的 `consecutive_zero_change >= 2` 警告（`skills/retrospective/SKILL.md:23-27`）已经是"自我假设测试"的最佳实践。 |

---

## 4. simplify-don't-add 原则在 superpowers 现状中的执行情况

**部分执行，但存在系统性漂移。**

正面证据：
- `MEMORY.md` 记录 **JUST-01 / vocabulary 闸门** 抵抗了"知识平台被拒"等 add-bias（这是 simplify-don't-add 在 retrospective 层的胜利）。
- `skills/brainstorming/SKILL.md:12-48` 引入 Bail-Out（trivial 路径不进 loop）—— 这是 simplify。
- `skills/writing-plans/SKILL.md:14-26` 引入 BDD<3 OR tasks<5 bail —— 这是 simplify。
- `skills/systematic-debugging/SKILL.md:22-43` 引入 named-root-cause bail —— 这是 simplify。
- `agents/superpowers-evaluator.md:4` 把 plan-mode 路由回 writing-plans Phase 4 inline 处理 —— 这是 simplify。
- `lib/retro-events.sh` 把 3 个 NDJSON 通道的内核合并 —— 这是 simplify。

负面证据（add-bias 残留）：
- 5 个 hook 是 27 天内累积上去的（`MEMORY.md project_superpowers_hooks.md` 标 v2.8.3：4 钩 + 9 文件 lib/ helper 层），其中 **track-reads.sh 是最近 5 天新加** —— 典型的"再加一层 scaffolding 看看"反射。
- `MEMORY.md project_v3_debt_tracker.md` 已标 *"T-002 fix-now bar 已被 retro-events helper 层跨过，tracker 待更新"* —— 即 retro-events 三件套是越过了 fix-now 闸门加进来的（add-bias 实证）。
- `build-like-iphone-team` 自上线后没有任何观测数据证明它被实际加载/有效 —— 是 add-without-measure 的标本。
- **没有任何 component 真正被 REMOVE 过**（gitlog 看不到 hook 的删除提交）—— 这与博客 §2 "remove one component at a time and review the impact" 直接矛盾。

结论：JUST-01/vocabulary 闸门管住了 **设计文档** 的 add-bias，但没管住 **harness scaffolding 自身** 的 add-bias。两者的闸门需要分开。

---

## 5. 行动建议：下一次 retro 推荐的"停用一周看看"实验

按优先级排序（建议每次只关一个，符合博客 §2 "one component at a time"）：

1. **第一周 — 停用 `build-like-iphone-team` skill**：从 `plugin.json:27-30` 临时移除。观察 brainstorming evaluator 的 design 评估 PASS 率是否变化。预期：不变（与全局 CLAUDE.md "Challenge the premise" 重合）。
2. **第二周 — 把 `superpowers-evaluator` 的 spawn 频率从 per-batch 改成 final-batch**：在 `executing-plans/SKILL.md` 的 Phase 3-4 loop 修改 spawn 触发条件。观察 evaluator 阻挡的 sprint 数量是否下降到接近零。预期：与博客 4.6 结论一致——降级合理。
3. **第三周 — 把 `track-reads.sh` 阈值从 15 提到 30**：在 `lib/loop.sh` 的 stuck detector 内调阈值。观察 stuck detection 是否仍能抓住真正的 read-loop。预期：假阳性减少 80%+，真阳性不变。
4. **第四周 — 把 `systematic-debugging` 的 4 阶段流程压成 2 阶段（根因问 + 修）**：基于第 1-3 周的 bail-out 比率决定是否动手。
5. **退役整理（不需要"停用"）— 合并 3 个 NDJSON wrapper**：housekeeping 重构，不需要观察期。

---

## 6. 一句话结论

superpowers 已经在 *trivial 路径* 上正确地执行了 simplify-don't-add（5 个 bail-out + JUST-01 闸门），但在 *harness scaffolding 自身* 上仍是 add-only：27 天加了 5 个 hook + 9 个 lib helper，**没有任何组件被退役过**——这正是博客要点 2 警告的反模式。下一次 retro 应首先把 `build-like-iphone-team` 拉去"停用一周"。
