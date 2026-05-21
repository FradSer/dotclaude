# 00 — Devils Advocate

立场：8 个 evaluator 全部从外部立场找缺陷，本报告反向辩护，禁止援引博客作为论据。

## 核心 5 条

### E4 退役 build-like-iphone-team

- 证据：`skills/brainstorming/SKILL.md:97` 显式约束触发条件"If the problem requires challenging assumptions or radical innovation, load `superpowers:build-like-iphone-team` skill in the sprint contract phase."——不是 always-on，是条件加载。`skills/build-like-iphone-team/SKILL.md` 内容是 5 条 Project Purple 原则 + reference 子目录，不是 prompt-injection 类的运行时开销。
- E4 主张"用户全局 CLAUDE.md `Challenge the premise before implementing` 已经覆盖"——但全局 CLAUDE.md 那一行是**一句口号**，没有任何 first-principles slash redundancy / force impossible tech / experience-driven specs 的执行框架。两者粒度不对等。
- 隐藏成本：E4 自己也说"effort：在 plugin.json:27-30 临时移除"——但 brainstorming/SKILL.md:97 也要同步改，否则会 dangling reference；且 README/marketplace 也要 sync。约 4 处改动。
- 替代方案：保留 skill 但加 retro-events 通道追踪触发率（**真正能用证据反驳的方法**），跑 1-2 个 retrospective 周期后再决定。E4 跳过测量步骤直接退役。
- 判定：**SOFTEN**（保留，加 instrumentation；不要直接删）
- 一句话理由：触发条件是 conditional + 内容是 reference 知识，删它的总成本（dangling refs + 失去可控的 first-principles 框架）高于"加 1 个 retro-events 通道观察一个月"。

### E5 把 4 件套 lib 合并为 lib/jsonl-emit.sh

- 证据：5 个 helper 总共 427 行（`observations.sh:68 + evolution-log.sh:81 + skill-events.sh:96 + bail-log.sh:85 + retro-events.sh:97`），但**对应测试是 2126 行**（`test_bail_log_sh.py:176 + test_skill_events_sh.py:485 + test_migration_parity.py:631 + test_evolution_log_sh.py:528 + test_observations_sh.py:306`）。合并需要重写约 1700 行测试或承担测试覆盖率倒退。
- `observations.sh` 自带 terse-row vs rich-row 双 schema（reflection 07 §2 已发现），`skill-events.sh:23-25` 与 `evolution-log.sh` envelope shape 不同（nest vs merge）。一个 dispatch 表能装下但**5 个消费者**（retrospective Phase 1/4/5a/5c/6 + executing-plans Phase 3/4）每个都按文件名 join，合并后 join 维度变 `(file, channel)` 双键。
- 隐藏成本：4 个 ndjson 文件的现网数据（用户实际跑过的 retros）schema 不会自动迁移；合并必须维护 6 个月以上的兼容读取层（参考 reflection 07 建议 5 自己也承认 effort:L）。即 **删 250 行 ＝ 加 ≥100 行兼容层 + 改 ≥1500 行测试 + 维护 2 套 schema 半年**。
- 判定：**SOFTEN**（先合并 envelope schema 让 4 个文件回到单一 wire format，不合并文件本身）
- 一句话理由：4 个 stream 名字看似冗余，但消费查询语义不同（reflection 07 §2 已自证）；合并文件相当于把"按名查"逻辑转移到"按字段过滤"，节省 250 行代码代价是改 1500+ 行测试与历史数据兼容层，净负收益。

### E7 task-start.sh 加孤儿 active loop 扫描（被标 P0 critical）

- 证据：实测全仓 887 个 `*.superpowers.json`，其中 `active:true` 仅 9 个，**全部 `session_id="default"` 且 `skill_name=null`**——这是 v2.5 之前的 legacy schema，且最新一条 `2026-05-01`（≈19 天前）。新 session 不可能写出 `default` session_id 的文件（`hooks/task-start.sh:142-164` 一定会写真 UUID）。
- `lib/utils.sh:96-117` 的 legacy fallback 路径**已经处理了这种情况**——find_state_file 命中 legacy 文件会 stderr 警告 `Cross-session crosstalk possible — consider removing stale state files`。E7 提议加孤儿扫描 = 把"已有 stderr 警告"升级成"主动 resume 提示"，是 UX 改进，不是 critical 数据丢失修复。
- 隐藏成本：scan 逻辑要决定 (a) 多久算"孤儿"（如 24h 未更新？）(b) 同一 cwd 多个孤儿怎么排序 (c) resume 提示用户拒绝后如何标记，否则下次又会被扫到。这是新增 ≥80 行 task-start.sh 逻辑 + 测试。
- 真正的根本修复是**清掉 legacy 文件**：9 个文件、`rm` 即可、零代码改动。
- 判定：**SOFTEN**（保留思路，降级 P0→P2；先做一次性 legacy cleanup script，证明 P2 之后仍有新增孤儿再补 task-start.sh 扫描）
- 一句话理由：19 天没新增孤儿 + 9/887=1% 比例 + legacy fallback 已存在 → 不构成 critical。先 cleanup 再观察，比直接加 80 行 hook 代码合理。

### E8 补 PreToolUse hook

- 证据：`lib/loop.sh:493-498` 的 STUCK 阈值（executing-plans + iter>=2 + edits>5 OR reads>15）已经定义，但触发时机是 Stop hook。E8 主张"前置一拍"。**合理**。复用 `state_read` + 相同常量、matcher 只在 `state.skill_name == "executing-plans"` 时生效，对其他 skill 零开销。
- 隐藏成本：PreToolUse 是同步阻塞调用，每次 Edit/Write/MultiEdit/Read/Glob/Grep/Bash 都要打开 state 文件、读取计数、比对阈值——`track-changes.sh:57-59` 的 `acquire_state_lock` 拿不到锁就 drop 在 PostToolUse 是"漏报"，在 PreToolUse 同样的策略会导致"该拦的没拦"，且 Pre 必须同步等待否则失去拦截语义。需要重新设计 lock acquisition（轮询而非 drop），影响每次 tool 调用 ~10ms 延迟。
- E8 还有第二条建议"Stop hook 引入独立 evaluator 验证"——这条**强烈反对**：每次 Stop 都 spawn evaluator agent 是 evaluator-of-everything 反模式，token 成本爆炸（每个 loop iteration 多一次完整 agent run）。已经有 promise tag 字符串匹配（`loop.sh:406`）做存在性 + 一致性双重校验。
- 判定：**SOFTEN**（同意 PreToolUse 思路，但限定 scope 到 edits>5 一种 stuck kind；拒绝 Stop hook evaluator）
- 一句话理由：前置 STUCK 拦截 ROI 合理但要先解决 PreToolUse 同步 lock 设计；evaluator-on-every-Stop 是过度工程。

### E10 superpowers 整体在 Opus 4.7 下是否还 load-bearing（根问题）

- 证据：reflection 04 §1 表格自己列出 12 个组件中 **8 个标"是"或"是"（仍 load-bearing）**：task-start.sh / stop-hook.sh / track-changes.sh / track-spawns.sh / brainstorming / writing-plans / executing-plans / retrospective / BDD / superpowers-evaluator。即使是它认为可降级的 4 个，也没一个判 CONCEDE。
- 反向证据：4 月以来 81 次 commit（`git log --since=2026-04-01 -- superpowers/`），其中包含 5 次明确 remove（`1201bf9 remove agent-driven-development`、`7ced933 remove meeseeks-vetted`、`e3e885a remove need-vet`、`79f9acb remove legacy merge flag`、`c3db9c0 remove interactive approval gates`）——E5 论据"从未删除组件"事实错误，superpowers 的演化里**simplify 路径是 active 的**。
- 真正 load-bearing 的硬证据：`executing-plans/SKILL.md:142` HARD RULE + `lib/loop.sh:493-498` STUCK 阈值 + `hooks/track-spawns.sh:41-42` 计数重置——这是一套被 codify 在 hook + skill + state file 三层的契约系统，任何单 Claude prompt 都做不到等价效果。这与"Opus 4.7 更聪明就不需要 harness"无关——harness 的目的是**跨 session 的纪律 + 多 agent 隔离**，模型聪明度提升不消除这类需求。
- 隐藏成本：如果真按"用一周看一组件"逐个证伪退役，reflection 04 自己列了 5 周实验计划——这本身就是相当大的工程投入，且每次"停用-观察-恢复"循环对用户当前正在跑的 plan 是破坏性的。
- 判定：**HOLD**
- 一句话理由：harness 的 load-bearing 性来自跨 session 纪律和多 agent 隔离合约（hook + state + skill 三层强制），不来自"模型不够聪明"——所以 Opus 4.7 升级不构成退役理由。

## 其余 5 条快速判定

| 编号 | 立场 | 一句话理由 |
|------|------|-----------|
| E1 (context/token telemetry) | SOFTEN | 加 tool-call 计数汇总合理，但博文也承认 API 不直接暴露 token；属可选 telemetry。 |
| E2 (evaluator few-shot calibration) | HOLD | `seed-checklists.sh` 已经给每个 item 写 `Check method: grep -nE ...`，比 few-shot 范例更结构化也更可执行，不需要再加范例。 |
| E3 (sprint contract rewrite 无 audit) | HOLD | `lib/bail-log.sh` + `observations.sh` 已是事件层，contract rewrite 走 git 日志即可审计，不需新机制。 |
| E6 (batch 并发上限 + worktree) | SOFTEN | 文档 promise 与实现缺口存在，但"加 max-concurrency N"低 effort 合理；worktree 实施是中等 effort 但用户实际跑大 batch 频率未观测到。 |
| E9 (handoff-state.md 加 tmp+mv) | SOFTEN | reflection 07 自己评 impact:low 因为"今天还没出过 bug"——同意 effort:S 但不紧迫。 |

## 揭穿伪低垂果实（≥ 2 条）

- **E5（合并 5 个 jsonl helper）**：表面 effort S（净减 250-300 行），实际改 2126 行测试 + 维护 ≥6 个月兼容层 + 现网 .jsonl 文件 schema 迁移。reflection 05 §6 第 1 条号称"最该被删/合并"，但 reflection 07 §6 建议 5 自己评 effort:L、impact:low——同一 idea 在两份报告里 effort 估算差 1-2 个量级，说明 E5 的"低垂"是错觉。
- **E7（task-start.sh 加孤儿扫描，标 P0 critical）**：表面是补救数据丢失，实际现状是 1% 比例 + 19 天无新增 + legacy fallback 已存在；真正零成本修复是 `find ... -name "*.superpowers.json" | xargs grep -l '"session_id":"default"' | xargs rm`。E7 标 P0 跳过了"先证伪现有 legacy fallback 失效"这一步。
- **E2（evaluator 加 few-shot calibration 范例）**：表面 effort 是"在 seed-checklists.sh 模板每个 item 后加 calibration block"，实际现状 `lib/seed-checklists.sh` 已经为每个 item 写 `# Type: computational / inferential` 标签 + `Check method: grep -nE ...` —— 这是比博客 few-shot 更可机器执行的形式，新增 prose 范例反而会让 evaluator 在 ambiguous 区间漂移。

## 反向 Top-3（如果 superpowers 现状反而该 add 某项）

1. **legacy state file cleanup script**：一次性 `scripts/cleanup-legacy-state.sh` 删除 `session_id=="default"` 的 .superpowers.json 文件，零代码改动消除 reflection 07 提出的 99% Gap A 担忧。
2. **build-like-iphone-team 触发率追踪**：在 brainstorming/SKILL.md:97 加载该 skill 的位置 emit 一条 `skill-events.jsonl` 行 `event:"sub_skill_loaded", skill:"build-like-iphone-team"`，让 retrospective 用真实数据决定 E4 的 keep/remove，而不是 reflection 04 现在的"显然没人用"猜测。
3. （无第 3 条；前两条已覆盖核心反向需求，不凑数）

## 最终立场

HOLD: 3 (E2 / E3 / E10) / SOFTEN: 6 (E1 / E4 / E5 / E6 / E7 / E8 partial / E9) / CONCEDE: 0 / 总 10
（E8 整体 SOFTEN 因为 PreToolUse 同意 + Stop evaluator 反对，按主要立场计为 SOFTEN）

最强反对意见（一句）：8 份 evaluator 报告里**没有一条 P0 是基于真实事故数据**（887 state 文件 1% active + 19 天无新增 + 5 次组件 remove 已发生）——它们都是"博客说应该这样所以现状不够"的形式审查，而 superpowers 的实际演化数据显示 simplify 路径活跃、harness 三层契约 load-bearing，不需要按博客形态重写。
