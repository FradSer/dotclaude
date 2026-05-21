# 08 — Hooks Architecture（钩子架构与安全围栏）反思

维度：钩子是否承担 harness 的"拦截 / 注入纪律 / 防止 model 跑偏"职责，对照 Anthropic 工程博客《Harness Design for Long-Running Apps》。

参考文档：https://www.anthropic.com/engineering/harness-design-long-running-apps

代码基线：`superpowers` v2.8.5（`.claude-plugin/plugin.json:3`）。

---

## 1. 现有 4 类 hook 的职责与定位（observe vs intercept）

| Hook 事件 | 文件 | matcher | async? | 性质 | 证据 |
|---|---|---|---|---|---|
| UserPromptSubmit | `hooks/task-start.sh` | （全量） | 否 | **半干预**：持久化 task 状态 + 规范化 slash command，但不向 model 注入文本 | `task-start.sh:31-90`（解析 prompt / slash command），`task-start.sh:117-166`（仅写 state file，无 stdout 注入） |
| PostToolUse | `hooks/track-changes.sh` | `Edit\|Write\|MultiEdit` | **是** | **观察**：把 `file_path` 累加到 `state.modified_files`，并把 `edits_since_last_spawn += 1` | `track-changes.sh:29-31, 68-71` |
| PostToolUse | `hooks/track-spawns.sh` | `Agent` | **是** | **观察 + 状态重置**：sub-agent 返回后把两个计数器清零 | `track-spawns.sh:40-42` |
| PostToolUse | `hooks/track-reads.sh` | `Read\|Glob\|Grep\|Bash` | **是** | **观察**：`reads_since_last_spawn += 1` | `track-reads.sh:45-48` |
| Stop | `hooks/stop-hook.sh` → `lib/loop.sh::loop_phase` | （全量） | 否 | **强干预**：通过 `decision:"block"` JSON 把 model 拽回循环，直到 `<promise>` tag 出现 | `loop.sh:330-338`（block emission），`loop.sh:401-418`（promise 检测） |

**关键观察**：
- UserPromptSubmit / 3 个 PostToolUse 都**没有**向 model 注入文本。`task-start.sh` 的 statusMessage 是 `"Setting completion criteria..."`（`plugin.json:38`），但脚本本身不写 stdout —— "completion criteria" 的注入实际发生在 Stop hook 的 re-injection（`loop.sh:322-328`），不是 UserPromptSubmit。
- **唯一真正干预 model 行为的是 Stop hook**。其余 hook 都是被动 telemetry，给 Stop hook 储备决策证据。
- PostToolUse 三脚本本质上是同一套"sub-agent 健康度计数器"：track-changes / track-reads `+1`，track-spawns 清零。

---

## 2. PreToolUse hook 缺失：是否需要补？

### 博客主张

> "Every component in a harness encodes an assumption about what the model can't do on its own"
>
> "I gave the evaluator the Playwright MCP, which let it interact with the live page directly **before** scoring each criterion"

博客的拦截器主要是 **sprint contract**（事前约束）和 **evaluator**（事后否决），并未明确鼓吹 PreToolUse 风格的逐 tool 拦截。

### 现状漏洞（基于 superpowers 自身契约）

`loop.sh:469-499` 把 "executing-plans 的 main agent **不允许**直接编辑 / 大量探索"列为 STUCK 条件，但这个判定 **要到 Stop hook 才发生** —— 也就是说违规已经成形（最多 6 次 Edit、16 次 Read）才被拦下。这与博客"reset before drift compounds"的精神一致，但延迟惩罚而非前置拒绝。

### 1–2 个具体场景

**场景 A — executing-plans Phase 3 inline 执行**：
- 规则：`loop.sh:199-201` 明确 "Phase 3 step 2 forbids inline batch execution"。
- 当前路径：main agent 直接 Edit 5+ 个文件 → track-changes.sh 计数 → Stop 时 STUCK banner（`loop.sh:198-201`）触发。已经写了 5 个错的文件、消耗了 5 次 Edit token。
- PreToolUse 拦截方案：当 `state.skill_name == "executing-plans"` 且 `iteration >= 2` 且 `edits_since_last_spawn > 5` 时，对 `Edit|Write|MultiEdit` 返回 `{"decision":"block","reason":"Phase 3 step 2 violation. Spawn the batch coordinator via Agent."}`。**第 6 次 edit 在执行前**就被否决。

**场景 B — read-only thrash（`loop.sh:202-214` 已识别）**：
- 16+ Read/Glob/Grep/Bash 是当前能识别的反模式，但要等 Stop 才告知。
- PreToolUse 拦截方案：同一阈值条件下对 `Read|Glob|Grep|Bash` 返回 block，message = "Run TaskList 而不是再读文件"。

### 结论

**建议补 PreToolUse hook**。理由是 superpowers 已经在 Stop hook 里 codify 了 STUCK 阈值（`loop.sh:494-498`），但执行时机晚一拍：Stop 只在用户 turn 结束后触发，token 已经烧掉、错文件已经落盘。PreToolUse 是"把 Stop 已有的判定前置到调用时刻"，**复用现有 state、不引入新规则**。这正好对应博客"the harness encodes assumptions about model limitations"—— STUCK 阈值就是已被编码的假设，目前只是动作时点错。

补 PreToolUse 的成本：1 个脚本，复用 `state_read`/`acquire_state_lock`/同一阈值常量；matcher 仅在 `executing-plans` 活跃时生效，对其他 skill 零开销。

---

## 3. PostToolUse async race condition 风险

`track-reads.sh` 和 `track-changes.sh` 均标 `async: true`（`plugin.json:50, 61, 70`）。三个脚本都用 `acquire_state_lock`（`track-changes.sh:57-59`、`track-reads.sh:41-43`、`track-spawns.sh:38`）：

- **优势**：拿不到锁就 `exit 0`（drop），不阻塞 tool。
- **劣势 — 漏报**：高频 Read（如 Grep 1k 文件）下多个 PostToolUse 进程**同一时刻竞锁**，最先拿到的写入 `reads_since_last_spawn += 1`，**后续 drop 的就漏报**了。`track-reads.sh:41-43`：
  ```
  if ! acquire_state_lock "$STATE_FILE"; then
    exit 0
  fi
  ```
- **场景**：main agent 一次响应里发起 8 个 Grep 并行 → 8 个 PostToolUse 几乎同时启动 → 实际只有 1–2 个成功加锁写入 → `reads_since_last_spawn` 远低于 8，可能不到 STUCK 阈值（>15）。
- **结果**：STUCK 检测**会漏判**，main agent 探索行为不会被拦下。

**缓解建议**：
- 改成 atomic increment（`flock` + 短 critical section 已有，但当前是"拿不到锁就放弃"，不是"轮询直到拿到"）。
- 或者改成 append-only event log（每次 PostToolUse 写一行 jsonl），Stop hook 一次性 count，避免竞锁。

---

## 4. task-start.sh 的 "completion criteria"：硬阈值还是软引导？

**答案：完全没有 completion criteria 注入逻辑。**

- `plugin.json:38` 的 statusMessage `"Setting completion criteria..."` 是**字面骗局**：`task-start.sh` 通读完毕（`task-start.sh:1-168`），唯一动作是把 prompt 写到 state file，没有任何 stdout、没有 systemMessage 注入、没有 promise tag 生成。
- 真正的 "completion criteria" 是 **completion promise**，由 SKILL.md 内嵌约定（如 brainstorming/writing-plans/executing-plans 在 Phase 6 输出 `<promise>X</promise>`），由 Stop hook 的 `extract_promise_text` (`loop.sh:404-409`) 校验。
- 这是**软引导 + 硬校验**的混合：
  - 软：SKILL.md 描述什么是完成（model 自己决定 promise 文本）。
  - 硬：Stop hook 用 regex 死匹配 `<promise>…</promise>`，没有就 block re-inject（`loop.sh:451-461` 还设了 3 次 stall 上限）。

**与 evaluator-loop 的二值判定关系**：
- evaluator-loop（`agents/superpowers-evaluator.md`）做的是 PASS/FAIL checklist 二值判定，输出 verdict。
- 而 Stop hook 的 promise 检测是 **存在性检验**（出现 tag = 完成），**不是质量检验**。
- 两者并不同维度：promise 答"model 自认完成没？"；evaluator 答"内容真完成没？"。当前实现是 Stop 信 model 的自报，**没有独立 evaluator 兜底**（见下一节）。

---

## 5. Stop hook 是否做独立验证（GAN 评估器思想）？

**没有。Stop hook 只是 promise tag detector + 计数器消费方。**

- 流程（`loop.sh:343-501`）：
  1. 读 state.active → 不活跃就放行。
  2. 读 transcript 最后一条 assistant message。
  3. `extract_promise_text` 匹配 promise tag → 命中即"完成"，清状态、退出（`loop.sh:412-418`）。
  4. 未命中 → STUCK 检测 + re-inject 继续 loop（`loop.sh:493-501`）。
- 没有调用 evaluator agent；没有跑测试；没有 lint / typecheck；没有 git diff 验证。
- 唯一接近 "独立验证" 的是 **stall 检测**（`loop.sh:439-461`）：三次连续 hash 相同就强制清状态，但这是反"刷屏"机制，不是质量评审。

**对照博客**：
> "Separating the agent doing the work from the agent judging it proves to be a strong lever"
>
> "Each criterion had a hard threshold, and if any one fell below it, the sprint failed"

superpowers 已经有 `superpowers-evaluator` agent（`plugin.json:17-19`），但**没有挂钩到 Stop hook**：evaluator 由 SKILL.md 文本指示 model 自己去 spawn，model 可以跳过。GAN 思想在文档层存在，在 hook 层缺位。

---

## 6. 钩子间的依赖、共享状态与 async 失败感知

### 共享状态

所有 5 个 hook（task-start + 3 个 PostToolUse + stop-hook）共享同一份 state file：`~/.claude/projects/<key>/<session_id>.superpowers.json`（`task-start.sh:92-94`、`track-changes.sh:44`、`track-reads.sh:32`、`track-spawns.sh:30`、`stop-hook.sh:33`）。

写者依赖 `acquire_state_lock` / `release_state_lock`（`utils.sh` 提供）维护互斥。

### 隐式顺序

- UserPromptSubmit 必须先建立 state file（或由 track-changes stub 兜底，`track-changes.sh:73-81`，track-reads 同款兜底 `track-reads.sh:50-56`）。
- PostToolUse 三脚本互相不依赖，但都依赖 state file 存在。
- Stop hook 假定 state file 已存在（`stop-hook.sh:33-34`：`[[ -z "$STATE_FILE" ]] && exit 0`），且 modified_files / counter 字段已更新到位。

### async 失败的感知机制：**没有**

- `plugin.json:50/61/70` 标 `async: true` 的三个 hook 失败后没有任何观测：
  - 没有错误日志写入 state file。
  - 没有 systemMessage 给 model。
  - 没有 retry。
- 唯一 fallback 是 `_SUPERPOWERS_DEPS_MISSING` 检测（`track-changes.sh:19`、`track-reads.sh:27`、`track-spawns.sh:26`），但只覆盖"jq/perl 装没装"，不覆盖 jq 报错、磁盘满、锁竞争失败。
- "拿不到锁就 exit 0" 完全静默（见第 3 节漏报问题）。

**这意味着**：track-reads.sh 在高并发下漏报 → STUCK 检测失效 → main agent 探索 200 次 Read 也不会被拦 → 用户看到 token 飞涨但找不到信号。**这是一个 silent failure mode**，与博客"observability of the system is critical"原则相悖。

---

## 7. 与博客的差距 + 行动建议

### 主要差距

| 博客原则 | superpowers 现状 | gap 等级 |
|---|---|---|
| Sprint contract 事前约束 | SKILL.md 文档级，无 hook 注入 | 中 |
| Evaluator GAN-style 独立否决 | evaluator agent 存在，但 Stop hook 不调用 | **高** |
| Playwright MCP 等外部验证 | 完全缺失，Stop 只信 promise tag | **高** |
| Reset on drift | Stop re-inject + stall 强清 | 较好 |
| Harness encodes assumptions | STUCK 阈值已编码，但执行时点偏晚 | 中 |
| Observability | async hook 失败静默 | **高** |

### 行动建议（按优先级）

1. **补 PreToolUse hook**（见第 2 节场景 A/B）。复用 STUCK 阈值，前置一拍。低风险高 ROI。
2. **Stop hook 引入独立验证**：promise 命中后，spawn `superpowers-evaluator` agent，PASS 才清状态、FAIL 重新 inject。把 evaluator 从"文档建议"升级成"hook 强制"。
3. **PostToolUse 改为 atomic counter or append-only log**：解决 async 漏报，保证 STUCK 检测可信。
4. **async hook 失败可观测**：失败时写一行 `state.hook_errors[]`，Stop hook 在 systemMessage 里告警。
5. **task-start.sh 注入 completion criteria**：当 skill_name 已知时，从 SKILL.md 抽取一行 hard-threshold 描述，作为 systemMessage 注入（兑现 statusMessage 的字面承诺）。

---

## 关键证据索引

- 4 类 hook 注册：`.claude-plugin/plugin.json:31-85`
- async 标记：`plugin.json:50, 61, 70`
- task-start 无 stdout 注入：`hooks/task-start.sh:31-168`
- track-* async 静默 drop：`track-changes.sh:57-59`、`track-reads.sh:41-43`、`track-spawns.sh:38`
- Stop hook 唯一拦截点：`lib/loop.sh:330-338`（block JSON）
- promise 仅是存在性检验：`lib/loop.sh:401-418`
- STUCK 阈值与延迟惩罚：`lib/loop.sh:469-501`
- stall 强清：`lib/loop.sh:439-461`
- _SUPERPOWERS_DEPS_MISSING 是唯一的 async 失败兜底：`track-changes.sh:19`、`track-reads.sh:27`、`track-spawns.sh:26`
