# 07 — State & Recoverability

## Blog Principle（引用 + 概括）

Anthropic 工程博文 *Harness Design for Long-Running Apps* 关于"长任务持久化与可恢复性"的论点要从分散的章节里抽：

> "Communication was handled via files: one agent would write a file, another agent would read it and respond either within that file or with a new file that the previous agent would read in turn."

> "context resets—clearing the context window entirely and starting a fresh agent, combined with a structured handoff that carries the previous agent's state and the next steps—addresses both these issues."

> （隐含）"Opus 4.6 ... run coherently for over two hours" 与文中提到的 "$124–$200" 多小时跑批价位，指向 harness 必须能在长跑过程中通过磁盘文件做唯一可信状态。

**我的概括**：博文没有专门一节讲 checkpoint / resume，但它把"用什么作为跨阶段状态"完全压在**文件系统**上——单一可信源是磁盘 artifact（handoff 文件、sprint contract），不是进程内存、不是 env var、不是会话变量。隐含要求有四条：（a）任何中间产物必须落盘；（b）落盘格式要够结构化让陌生 agent 单文件接手；（c）多 agent 通过分文件 / 新文件避免互踩；（d）reset 后用磁盘重建上下文，不依赖 session 连续性。博文**没**讨论 append-only rotation、并发锁、崩溃恢复——这是它假设但没明文写出的工程债，恰是 superpowers 必须自己解决的部分。

## superpowers 现状（带 file:line 证据）

### 1. 状态持久化拓扑：8 处落盘点 + 1 处进程内 env

**单一会话状态文件（每 session 一份 JSON）**：
- 路径模板 `hooks/task-start.sh:11` / `lib/utils.sh:71-75`：`~/.claude/projects/<PWD-tr-/-->/<session_id>.superpowers.json`
- 用 `session_id` 命名，project 用 PWD 替换 `/` 为 `-` 作为 key（`utils.sh:73`）
- 字段集（实测样本，`scripts/setup-superpower-loop.sh:233-241`、`hooks/track-changes.sh:78`、`lib/loop.sh:122`）：
  - `session_id, task, created_at, updated_at`（task-start 写）
  - `pending_prompt, skill_name`（task-start 在续命时写，`task-start.sh:125, 133`）
  - `modified_files[], edits_since_last_spawn, reads_since_last_spawn`（PostToolUse hooks 写）
  - `active, iteration, max_iterations, completion_promise, prompt, started_at, stall_count, last_output_hash`（loop 写）

**项目级 NDJSON 日志（7 个文件，全部在 `<repo_root>/docs/retros/`）**：
- `bail-out-events.jsonl` — `lib/bail-log.sh:57` — 写者：systematic-debugging `SKILL.md:48`；读者：retrospective Phase 5a
- `harness-observations.jsonl` — `lib/observations.sh:50` — 写者：retrospective Phase 5c `SKILL.md:152`、executing-plans `SKILL.md:174`；读者：retrospective 下一轮
- `evolution-log.jsonl` — `lib/evolution-log.sh:49` — 写者：retrospective Phase 4/6 `SKILL.md:97, 202`；读者：retrospective 下一轮的 Phase 0/1
- `skill-events.jsonl` — `lib/skill-events.sh:58` — 写者：systematic-debugging Phase 4 `SKILL.md:262`
- `plans-completed.jsonl` — `lib/loop.sh:61` — 写者：stop-hook 自动，executing-plans 完成时；读者：retrospective 自动 scope + RETROSPECTIVE DUE 计数
- `harness-config.json` — `skills/retrospective/references/harness-config.md:80`（停用 harness 组件的开关文件）
- `checklists/<mode>-v1.md` — `lib/seed-checklists.sh` 写出的评估清单

**Per-plan handoff 落盘（每 plan 多份 markdown）**：
- `<plan>/handoff-state.md` 滚动 mutable 快照（`skills/executing-plans/SKILL.md:131-138`）
- `<plan>/handoff-summary-{N}.md` 每 batch 不可变记录（`SKILL.md:197`）
- `<plan>/sprint-contract-batch-{N}.md`（被 `loop.sh:87-89` 计数）
- `<plan>/evaluation-report-batch-{N}.md`（由 evaluator 子 agent 写）

**进程内状态（不持久化）**：
- `_SUPERPOWERS_DEPS_CHECKED / _SUPERPOWERS_DEPS_MISSING / _SUPERPOWERS_DEPS_MISSING_NAMES`（`lib/utils.sh:8-22`）——只在 hook 自己的 bash 进程内存活
- `_RETRO_EVENTS_LOADED / _OBSERVATIONS_LOADED / _EVOLUTION_LOG_LOADED / _SKILL_EVENTS_LOADED`（4 个 lib 文件顶部的 source guard）——同上

**关键观察**：**没有 SQLite、没有锁文件中央目录、没有 systemd-journald 之类的 rotation 机制**。所有持久状态是 JSON / NDJSON + 文件系统目录约定。

### 2. 9 个 lib helper 的职责拆分（含重叠分析）

| 文件 | 真正负责的状态 | 写谁 | 读谁 |
|---|---|---|---|
| `utils.sh` | session 状态文件 CRUD + 锁原语 + repo_root 解析 | task-start, stop-hook, track-* | loop.sh, scripts |
| `loop.sh` | session 状态文件中的 loop 字段（active/iteration/promise/stall）+ `plans-completed.jsonl` | stop-hook | — |
| `bail-log.sh` | `bail-out-events.jsonl` | systematic-debugging | retrospective Phase 5a |
| `observations.sh` | `harness-observations.jsonl`（terse-row 变体） | retrospective 5c, executing-plans | retrospective 下轮 |
| `evolution-log.sh` | `evolution-log.jsonl` | retrospective Phase 4/6 | retrospective 下轮 Phase 0/1 |
| `skill-events.sh` | `skill-events.jsonl` | systematic-debugging Phase 4 | retrospective Phase 5a 聚合 |
| `retro-events.sh` | 上面三个 NDJSON 共用原语（`jq_or_skip / write_jsonl / dedup_check`） | 内部 | — |
| `post-plan-diff.sh` | 不写状态，纯读 git；为 retrospective 提供 plan-completion 后续 diff 分类 | — | retrospective Phase 1 |
| `seed-checklists.sh` | 模板文件首次落盘（exist 即拒写） | retrospective 首次 setup | retrospective 评估 |

**职责重叠分析**：

- **`skill-events.jsonl` vs `evolution-log.jsonl`**：两者都以 `{event, timestamp, ...}` 为骨架，区别只在 envelope 策略（nest vs merge，`skill-events.sh:23-25` 明说"distinct from evolution-log.sh, which merges"）。**真实拆分点是消费者**：skill-events 给 Phase 5a 做 skill 实际触发统计，evolution-log 给 Phase 4 做"上一次 retrospective 改了什么"叙事。**结论**：分两个 .jsonl 是必要的（消费查询语义不同），但 schema 几乎同构，**让阅读者花掉本不该花的认知成本**。
- **`harness-observations.jsonl` 的"terse-row" vs "rich-row"**：`observations.sh:14-17` 自己承认这个文件**两种 schema 共存**——terse-row（lib 写）和 rich-row（executing-plans Phase 3/4 + brainstorming Phase 2 自行写）。同一文件双 schema 是真重叠：读者要自行 dispatch。
- **`bail-out-events.jsonl` vs `skill-events.jsonl`**：bail 是"未发射 / 跳过"，skill-events 是"已发射 / 成功"。语义互补不重叠，但**都是 skill 维度的事件 stream**——一个 `skill-events.jsonl` 加 `event:"bail_out"` 行就能合二为一。当前拆开的成本：retrospective Phase 5a 要分别读两个文件做 join（`SKILL.md:55`）。
- **9 个 helper 不是同心圆，是 4 个独立 stream（bail / observations / evolution / skill）+ 1 个 plan completion stream + 4 个支持模块**。同心圆错觉来自命名前缀都是动词性的（log_*），但消费方向完全发散。

### 3. 跨 session 恢复路径分析

**场景**：用户中断（关 terminal）→ 第二天回来 → 跑 `claude` 接着干。

`hooks/stop-hook.sh:33` 用 `find_state_file "$HOOK_SESSION"` 找上次状态。关键看 `lib/utils.sh:84-119`：

- **新 session_id 不会匹配旧状态文件**（`utils.sh:102-104` 严格 string-equal `session_id`）。
- **只有当旧状态文件**`session_id`**字段为空（legacy 文件）时**才走 fallback，`utils.sh:106-117` 命中并 stderr 警告 "Cross-session crosstalk possible"。
- 第二天的 Claude 启动时拿到全新 session_id，旧的 `<old-uuid>.superpowers.json` 仍躺在 `~/.claude/projects/<key>/` 但**找不到**它（除非用户手动 rename）。

**会丢的状态**：
- session 状态文件里的 `pending_prompt / skill_name / modified_files / edits_since_last_spawn / reads_since_last_spawn / active=true / iteration / completion_promise / prompt / stall_count / last_output_hash`——**全部丢**，新 session 起 0。
- 如果上次在 loop 中（`active:true`），新 session 不会自动续 loop（`stop-hook.sh:33` 因 session 不匹配走 `exit 0`，`loop_phase` 根本不被调用）。

**能恢复的状态**：
- `<repo_root>/docs/retros/*.jsonl` 全部还在（用户和 session 解耦，repo_root 才是 key）
- per-plan 的 `handoff-state.md / handoff-summary-{N}.md / sprint-contract-*.md / evaluation-report-*.md` 全部还在
- git commit 历史还在

**task-start.sh 能感知"续上次会话"吗**：
- **不能**。`task-start.sh:35-38` 把 `session_id` 当作输入参数读，但**没有任何代码路径**会去扫 `~/.claude/projects/<key>/` 看有没有 `active:true` 的孤儿状态文件并主动提示"上次你在跑 superpower loop / executing-plans，要不要恢复"。
- **找不到旧 session 的 session_id**：新 Claude 启动时没渠道知道昨天的 uuid，除非用户自己保留。
- `setup-superpower-loop.sh:201-213` 倒是有 reentry guard——但只在用户**主动再次跑同一个 slash command 且 session_id 恰好匹配**时才生效。

**评估**：博文要求"file-based handoff carries enough state for the next agent to pick up cleanly"。superpowers 在 **plan 维度**做到了（handoff-state.md 是足够的），但在 **session 维度**完全没做。用户中断后，唯一恢复路径是用户自己 `ls docs/plans/` 找到上次的 plan 目录，然后人肉重新跑 `/superpowers:executing-plans <path>`。**这等于把"哪个任务被中断了"的元数据放在用户脑子里，而不是磁盘上**。

### 4. 多 agent 并发写状态的锁机制

有锁，**但只在 session 状态文件上**：

- `lib/utils.sh:142-172` 的 `acquire_state_lock` 用 mkdir 原子性（POSIX）做互斥，超时 5s，PID-aware stale lock 回收。
- `lib/utils.sh:179-188` 的 `release_state_lock` 只清自己 PID 的锁，安全注册到 EXIT trap。
- `lib/utils.sh:204-223` 的 `state_update` 用 `tmp+mv + lock`，lock 超时**失败响亮**（`utils.sh:221`，不再 silent fallback——这是 v2.8.x 修过的 race）。
- 4 个 hook（task-start / stop-hook / track-changes / track-reads / track-spawns）都遵循"trap-release → acquire → 读改写 → mv"模式（`hooks/track-changes.sh:46-71`、`track-reads.sh:37-47`、`track-spawns.sh:34-42`、`task-start.sh:100-126`）。

**未加锁的写路径**：

- `lib/bail-log.sh:70-78` 的 `jq -nc ... >> $log_file`——**纯 append，无锁**。Bash 的 `>>` 在 POSIX 上对单次小于 PIPE_BUF（一般 4 KiB）的写是原子的，**单行 NDJSON 通常 < 1 KiB 因此安全**。但 systematic-debugging Phase 4 的 payload 没有显式上限，一旦 payload 超过 4 KiB（PIPE_BUF），两个并发写者会交错。
- `lib/observations.sh:53` / `evolution-log.sh:68` / `skill-events.sh:80` 都通过 `retro-events.sh::write_jsonl`（`retro-events.sh:75-82`）——同样是 `>> $log_file`，**同样依赖 PIPE_BUF 假设**。
- `lib/loop.sh:99-108` 写 `plans-completed.jsonl`——**同样 `>> $log_file` 无锁**，但 dedup（`loop.sh:71-75`）做了 200 行 tail-grep，所以即使交错也不会重复计数（只是行可能损坏）。

**是否假设串行**：
- session 状态文件 = 不假设串行，有显式锁
- NDJSON 日志 = 隐式假设"行小到 PIPE_BUF 以下"，没有锁也没有 retry。systematic-debugging `SKILL.md:233` 提到"NEVER `test_stdout, test_stderr, fix_diff`"——这是已经意识到 payload 大小风险并在协议层削减，但**没有在 lib 层做 size guard**。
- per-plan handoff 文件（`handoff-state.md` 等）= 完全假设串行。`executing-plans` 通过 Phase 3 ATOMIC 契约（一个响应里同时写 sprint contract + handoff-state + spawn agent）保证主 agent 是唯一写者，但**两个 batch coordinator 子 agent 并行跑时如果都改 handoff-state.md 就会冲突**（设计上不并行，但没有锁兜底）。

### 5. 长任务下的日志膨胀风险

**全部 NDJSON 都是 append-only，没有任何文件实现 rotation**：

- `bail-log.sh`、`evolution-log.sh`、`observations.sh`、`skill-events.sh`、`loop.sh::_loop_log_plan_completion_if_executing` 五处写者全部用 `>> $log_file`。
- 唯一接近 rotation 的代码：`retro-events.sh:89-95` 的 `dedup_check` 用 `tail -n 200`——这是**读端**对历史的限制，不是写端的 truncate。
- 实测样本：agentbook 项目跑了一个月，`evolution-log.jsonl` 才 724 字节、3 行（前面 Bash 输出）。但这是低吞吐 retrospective 流。

**膨胀风险评估**：
- `skill-events.jsonl` 由 systematic-debugging 每次 fix 写 1 行，正常项目年级膨胀。**低风险**。
- `bail-out-events.jsonl` 同上量级。**低风险**。
- `evolution-log.jsonl` retrospective 每跑一次写若干 `item_*` 事件（一次可能 5–15 行），年级几百行。**低风险**。
- `plans-completed.jsonl` 每 plan 1 行（dedup 后），年级 < 100 行。**低风险**。
- `harness-observations.jsonl` 是**最大潜在膨胀点**：executing-plans `SKILL.md:174` 在 harness 组件被禁用时"per batch"写一行。一个 50-batch 大 plan 一次能写 50 行，多个并发 plan + 多个 disable 组件 × 多个项目 → 月级千行可能。**中等风险**。
- 长跑场景下博文提到的 "$124–$200" 多小时单跑，按 executing-plans 50 iterations × dedup 后只写 1 行 plans-completed，但 `harness-observations.jsonl` 在禁用条件下可能 50 行。**长期还是线性膨胀，没有 cap**。

**Phase 5a 的 `tail -n 200` 假设的隐藏成本**：`retrospective/SKILL.md:55` 读 bail-out-events.jsonl 时"every row and aggregate"，**没有限制 row 数**——一旦 bail-out-events.jsonl 真的膨胀到 10k 行（不太可能，但 multi-year 项目可能），主 agent 上下文会被聚合输入直接撑爆。**没有上游 rotation 兜底**。

### 6. 与博文 file-based async communication 的差距

| 博文要求 | superpowers 现状 | 差距 |
|---|---|---|
| 文件作为唯一 cross-agent state | session 状态文件 + handoff-state.md + sprint contract + evaluation report + NDJSON streams 全部落盘 | **基本对齐**。env var 只有 deps-checked / loaded guard 两个进程内变量，无业务状态 |
| handoff artifact 够 self-contained | per-plan 维度做到（`SKILL.md:131-138`）；per-session 维度**没做** | **session 中断恢复完全没路径**：新 Claude 启动不会扫旧 `active:true` 状态文件 |
| 新文件 / 同文件回写以避免互踩 | session 状态文件加锁；NDJSON 日志靠 PIPE_BUF；handoff-state.md 单写者契约 | **隐式假设**（PIPE_BUF size、handoff 单写者）未在代码里 enforce |
| 长跑稳定性（$124–$200） | 主 agent context-reset OK；状态文件锁 OK | **日志无 rotation**、**没有 cross-session resume**、**没有崩溃后的 in-flight handoff 修复** |

## 差距分析（按 gap-level 排序）

### Gap A — 跨 session 没有恢复发现机制 [gap-level: critical]

**证据**：`hooks/task-start.sh:35-94` 全程只用本次 hook 输入的 `session_id`；`lib/utils.sh:84-119` 的 `find_state_file` 在 session_id 不等时只回退到 `session_id == ""` 的 legacy 文件并 stderr 警告。新 session 完全感知不到 `<old-uuid>.superpowers.json` 里 `active:true` 的孤儿 loop。

**与博文差距**：博文要求 handoff 文件让"下一个 agent 接管"。superpowers 的"下一个 agent"必须**和上一个共享 session_id 才能接管**，这违背了 file-based handoff 的精神——本质上把 session 当成了内存上下文，而不是落盘锚点。

**实际影响**：用户中断 `/superpowers:executing-plans` 后，第二天 Claude 启动**没有任何提示**。用户必须人肉记忆 plan path 重新跑 slash command。在博文描述的 3–6 小时长跑场景里，断电 / wifi 中断 / Claude 进程崩溃任一情况都会让 active loop 默默失效，用户可能数小时后才发现。

### Gap B — NDJSON 日志全部无 rotation，依赖 PIPE_BUF [gap-level: moderate]

**证据**：5 个写路径（`bail-log.sh:70`、`loop.sh:99`、`retro-events.sh:80` 派生的 observations/evolution/skill）全部 `>> $log_file`。无 size cap、无 line-count cap、无定期 archive。

**与博文差距**：博文没显式讨论 rotation，但 "$124-$200 多小时" 单跑的实证场景已经超出"演示项目"门槛。一旦 superpowers 进入正式 multi-month 生产仓库，`harness-observations.jsonl` 在禁用条件下线性膨胀。retrospective `SKILL.md:55` 又是无 LIMIT 全读，**读放大风险随写时间线性增长**。

**实际影响**：当前每个项目下日志都是字节级（实测 724 B），但风险是**复利性**——retrospective 跑得越多、evolution-log 越长，下一次 retrospective 读取它的 cost 也越大。没有 alarm 阈值。

### Gap C — NDJSON 写无锁，payload size 隐式契约 [gap-level: moderate]

**证据**：`retro-events.sh:75-82` 的 `write_jsonl` 用 `jq -nc <filter> [args] >> $log_file 2>/dev/null || true`。无锁。systematic-debugging `SKILL.md:233` 显式禁止 `test_stdout/stderr/fix_diff` 进 payload——这是协议层 size discipline，但 lib 层没有 size assert。

**与博文差距**：博文 file-based communication 的隐含假设是单写者或显式 lock。superpowers 把"行小于 PIPE_BUF（≈ 4 KiB）"当成了硬规则，但没有在 `write_jsonl` 里 assert 或 split。

**实际影响**：今天没造成可见 bug——payload 都是结构化短 JSON。但**未来新 skill 接入 lib helper 时**，若不知道 PIPE_BUF 隐含契约直接传大 payload，会出现两个并发 write 的字节交错，产生不可解析 NDJSON 行，retrospective Phase 5a 整体 aggregate 静默吃错数据。

### Gap D — handoff-state.md 写入不是原子 swap [gap-level: minor]

**证据**：reflection 01 已经记过（`.reflection/01-context-management.md:111-115` 的"建议 3"），但仍未实施。`executing-plans` Phase 3 step 1 是直写 `handoff-state.md`，没有 tmp+mv。

**与博文差距**：博文 file-based 通信里"另一个 agent 读"的契约依赖文件读到一致状态。当前若 batch coordinator 子 agent 在主 agent 写一半时读，会拿到截断内容。

**实际影响**：实际上 Phase 3 是 ATOMIC（主 agent 一次响应内完成"写 handoff + spawn agent"），所以读时序错开。**但没有 enforce**，没有 lib 层兜底。

### Gap E — skill-events / bail-out / evolution / observations 四个 stream schema 几乎同构却分文件 [gap-level: minor]

**证据**：`skill-events.sh:13-19` 和 `evolution-log.sh:13-17` 的 envelope 仅 nest vs merge 差异，`bail-log.sh:18-24` 的 schema 也是 `{event, skill, reason, args_hash, repo_root, timestamp}` 同骨架，`observations.sh:14-21` 是同骨架的 terse 变体。

**与博文差距**：博文鼓励 file-based，但没要求 file-per-event-type。superpowers 把"消费者查询语义不同"翻译成了"4 个文件"，**实际读者复杂度反而上升**——retrospective Phase 5a 要分别读 bail-out-events.jsonl 和 skill-events.jsonl 再 join，Phase 5c 又要读 harness-observations.jsonl。

**实际影响**：阅读 / 维护成本。新人理解状态拓扑要看 4 个 schema。同构数据用 `event_class` 字段分类、单文件可能更简洁。但**这不是紧急修复**——4 个文件运作正确，只是 cosmetics 债。

### Gap F — `~/.claude/projects/<key>/` 目录无清理 [gap-level: minor]

**证据**：`find /Users/FradSer/.claude/projects -name "*.superpowers.json" | wc -l` 输出 887。`utils.sh:71-75` 的 `state_dir` 用 PWD-tr 命名，每个 cwd 一个目录，每个 session 一个 JSON。没有 GC、没有 TTL、没有"清理 30 天前 inactive 文件"。

**与博文差距**：博文 file-based 通信也没讨论 GC，但 887 个孤儿 state file（其中很多 < 200 字节）随着用户使用线性增长。一旦哪天 `find_state_file` 退化到全目录扫（legacy fallback path），887 次 `jq -r '.session_id'` 是真延迟。

**实际影响**：今天每个 session 状态文件目录里只有 1–5 个文件（同一 cwd 多次启动 Claude），扫描成本可忽略。**但 887 已经在用户 home 占空间**，且没有"superpowers 清理"命令。低优先，但应有意识。

## 行动建议（按 impact / effort 排序）

### 建议 1：task-start.sh 增加"孤儿 active loop"扫描 + 提示 [effort: M, impact: high]

**做什么**：`task-start.sh` 在新 session 第一次写状态前，先 `find "$STATE_DIR" -name '*.superpowers.json'` 找 `active:true` 且 `updated_at` 在 24 小时内的孤儿文件。若找到，emit systemMessage（非阻塞）："发现 N 个未完成的 Superpower Loop（last updated X 小时前），cwd Y。要恢复请 `/superpower-loop --resume <plan>` 或 `rm <path>` 清理。" 同时把孤儿文件 mark 成 `active:false` 避免下次再提示。

**为什么**：闭合 Gap A——博文要求"another agent picks up cleanly"，目前续命路径完全缺失。这是**唯一一个会让长跑用户在生产中遇到的真实 critical 问题**：断网 / 关 terminal 后所有状态被静默孤立。effort M 是因为要新加 resume 子命令，但发现机制本身只是几行 jq + emit。

### 建议 2：retro-events.sh::write_jsonl 加 PIPE_BUF size guard + 简单 advisory lock [effort: S, impact: med]

**做什么**：`retro-events.sh:75-82` 写之前用 `jq -nc` 拿到行长度，超过 3 KiB stderr 警告 + 截断 payload 关键字段。同时引入 `flock`（Linux）/ `lockf`（macOS 通过 perl 模拟）做 advisory lock；获取失败 fallback 到现在的 `>>`。

**为什么**：闭合 Gap C 的可观测部分。size guard 立刻防御未来 payload 滥用；lock 失败 fallback 保留 best-effort 契约。effort S 因为只动一个文件，不破坏现有调用方。

### 建议 3：plans-completed.jsonl + evolution-log.jsonl 引入"超过 1 MB rotate"策略 [effort: M, impact: med]

**做什么**：新增 `lib/log-rotate.sh`，在 `write_jsonl` 之前检查目标文件大小，超过 1 MB 时 `mv $f $f.1.gz`（gzip 压档）+ 创建新 $f。retrospective 读取时**只读当前活动文件**（历史归档另由 `--include-archives` 显式 opt-in）。

**为什么**：闭合 Gap B。1 MB 阈值远超日常需求但低到能在异常膨胀时及时触发。这把博文隐含的"file-based state 必须可持续"做成了机制。effort M 因为要 (a) 写 rotation lib (b) 验证 retrospective 在缺少历史 archive 时仍能正常工作。

### 建议 4：handoff-state.md 写入改 tmp+mv [effort: S, impact: low]

**做什么**：reflection 01 建议 3 的延续。`executing-plans` Phase 3 step 1 的"Write handoff-state.md"改成"Write handoff-state.md.tmp; mv handoff-state.md.tmp handoff-state.md"。教学层（SKILL.md 文本）说明 + 可选的 hook 校验。

**为什么**：闭合 Gap D。effort S、风险低、收益是把"主 agent 一次响应内 ATOMIC"从惯例变成机械保证。impact 评 low 因为今天还没出过 bug；做与不做都成立，但成本极低。

### 建议 5：合并 bail-out / skill-events 到单一 `skill-events.jsonl` 加 `outcome` 字段 [effort: L, impact: low]

**做什么**：把 `bail_out / force_override` 当作 `skill-events.jsonl` 里 `outcome: "bail" | "force_override" | "success"` 的另一种行；废弃 `bail-out-events.jsonl`（保留读取兼容 6 个月）。retrospective Phase 5a 改为单文件聚合。

**为什么**：闭合 Gap E。effort L 因为要兼容旧文件、改 retrospective 读取逻辑、还可能影响下游报告模板。impact low——不解决新问题，只降低维护成本。**优先级最低，retrospective 数据真的显示 Phase 5a join 成为瓶颈再做**。

## 一句话结论

superpowers 在 **plan 维度**把博文的 file-based handoff 做到位（session 状态文件加锁 + handoff-state/sprint-contract 全部落盘 + NDJSON 事件流四路），但在 **session 维度完全没有恢复发现机制**——新 Claude 启动不会扫旧 `active:true` 孤儿状态文件，长跑断线后状态被静默孤立；建议优先实现 `task-start.sh` 的孤儿扫描 + resume 提示（建议 1），其余 rotation / lock / 单文件合并都是后置工程债。
