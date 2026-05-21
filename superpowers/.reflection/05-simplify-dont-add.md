# 05 — Simplify, Don't Add

## Blog Principle（引用 + 概括）

Anthropic 工程博文 *Harness Design for Long-Running Apps* 关于"简化优先"的核心论点（WebFetch 摘录）：

> "find the simplest solution possible, and only increase complexity when needed."
>
> "every component in a harness encodes an assumption about what the model can't do on its own, and those assumptions are worth stress testing"

Opus 4.5 → 4.6 演化中具体被删减的组件（同源摘录）：

| 被删/简化的组件 | 状态 | 原因 |
|---|---|---|
| Sprint decomposition | 完全删除 | 4.6 改进了 long-context retrieval，可以"sustain agentic tasks for longer"，不再需要 sprint 切分 |
| Per-sprint evaluator | 简化为 single final pass | 多数任务已落在 4.6 的可靠基线内，不再每个 sprint 都评估 |
| Context resets（针对 4.6 的特定段落） | 隐式删除 | 4.6 不再有 4.5 表现出的 "context anxiety" |

整体效果：从 6 小时 / $200（4.5）降到 3.8 小时 / $125（4.6）—— 用"删"来实现进步。

**我的概括**：博文把 harness 演化定义为**"反复减法"而非"反复加法"**。每个 helper、每条 gate、每个 hook 都是对"模型当前还做不到 X"的假设；模型能力变化后，那些假设过期了就应该被删除，而不是叠加新的补丁。

## superpowers 现状（带命令证据）

### 1. 最近 50 个 commit：feat 15 vs refactor+chore-remove 18

数据来源：

```
git log --oneline -n 50 -- superpowers/ | awk '{print $2}' | sed 's/(.*)//' | sort | uniq -c | sort -rn
```

输出（50 条）：

```
  15 feat:
  14 refactor:
   9 docs:
   4 test:
   4 fix:
   4 chore:
```

`git log --oneline -n 50 -- superpowers/ | grep -iE 'remove|drop|simplif'` 命中 9 条明确的删/简化 commit：

```
c3db9c0 refactor(sp): remove interactive approval gates
7f8e8a0 refactor(sp): simplify phase 4 emission tests
79f9acb refactor(sp): remove legacy merge flag
e3e885a refactor(sp): remove need-vet verification system
7ced933 chore: remove meeseeks-vetted and need-vet plugins
36f1b1e docs(sp): fix evaluator mode, drop plan_evaluator
46b489f docs(sp): simplify evaluation file format guidance
dd86472 docs(sp): drop check types from eval checklist
1201bf9 chore(sp): remove agent-driven-development skill
```

`git log --oneline -n 50 -- superpowers/ | grep -iE '^[a-f0-9]+ feat'` 命中 15 条 feat（**全部是 add**）：

```
787b923 feat(sp): track read loops in executing-plans
069f16b feat(sp): unify retro ndjson channels
0313607 feat(sp): add stall detection and phase recovery
47e9ca1 feat(sp): add v3.0 debt tracker and session guards
2240be4 feat(sp): add post-plan diff and plan logging
0a9d93d feat(sp): add bail-log and plan completion logging
6be640b feat(sp): improve loop logic and stuck detection
ea03264 feat(sp): log plan completion, cap modified files
b725efb feat(sp): add loop reinjection and file tracking
bfdd6a6 feat(sp): add force flag to seed-checklists
81535f6 feat(sp): hard-fail deps check in setup script
f65e200 feat(sp): add format contract & run metrics
8135c68 feat(sp): add seed checklist sections
9641418 feat(sp): add bail-out reference
ff07f31 feat(sp): add systematic-debugging, bump version
```

**结论**：**add / simplify ≈ 15 / 9 ≈ 1.67 : 1**。如果把视野放宽到"non-trivial 简化/删除"（包括 7f8e8a0、272061e、171373c 这类 refactor），比值仍然是 add > simplify。注意 9 条 simplify 中有 4 条（c3db9c0、e3e885a、7ced933、1201bf9）是真的删除组件/skill，其余 5 条只是删局部代码或行为；纯**组件级别删除 4 ：纯组件级别新增至少 6**（bail-log / post-plan-diff / stall detection / track-spawns / track-reads / 4 个 retro ndjson helper）。

### 2. TODO-v3.md 没有任何明确删项，只挂着一个"加 helper"的 add 提案

`/Users/FradSer/Developer/FradSer/dotclaude/superpowers/TODO-v3.md` 全文 36 行，唯一在跟踪的 v3 债务条目 **T-002 "Promote manual-write channels to lib helpers"** 本身就是一个 **add 提案**（行 9-19）：

> "Net add of ~400 LOC for no functional change. Wait until a third channel needs to be added so the pattern is reused at least 3×."（TODO-v3.md:15）

文件确实建了"Anti-add-bias guard"（行 21-29），三条 gate（"是不是真实债务 / 是不是能在当前 PR 内解掉 / fix-now bar 是不是可度量"），但**通篇没有"应该删什么"的债务条目**。换句话说，反 add-bias 体制只挡新增提案进 TODO，**不主动把现有组件标记为可删除**——这就是 §3 要谈的隐藏债。

### 3. lib/ 9 个 helper：retro-events / observations / evolution-log / skill-events 是同一根扁担挑四头

行数证据：

```
wc -l superpowers/hooks/*.sh superpowers/lib/*.sh
```

```
hooks/stop-hook.sh        52
hooks/task-start.sh      168
hooks/track-changes.sh    83
hooks/track-reads.sh      59
hooks/track-spawns.sh     44
lib/bail-log.sh           85
lib/evolution-log.sh      81
lib/loop.sh              502
lib/observations.sh       68
lib/post-plan-diff.sh    164
lib/retro-events.sh       97
lib/seed-checklists.sh   394
lib/skill-events.sh       96
lib/utils.sh             256
                       2149
```

`lib/retro-events.sh:1-12` 自己已经写明它是 **"shared core for the three retro NDJSON helpers (observations.sh, evolution-log.sh, skill-events.sh)"**，暴露 6 个原语（jq_or_skip / timestamp_or_skip / ensure_log_dir / repo_root_or_skip / write_jsonl / dedup_check）。三个 wrapper 的实质差异只有两点：

- **目标文件名不同**：`harness-observations.jsonl` / `evolution-log.jsonl` / `skill-events.jsonl`
- **envelope shape 不同**：observations 用扁平 row（`observations.sh:54-59`），evolution-log 用 "payload + {event,timestamp}" 合并（`evolution-log.sh:63-72`），skill-events 用 "{event,skill,timestamp,repo_root,args_hash, payload:...}" 嵌套（`skill-events.sh:74-87`）

bail-log.sh（`bail-log.sh:44-79`）是更早的实现，与上面三个独立——它甚至没源 retro-events.sh，自己重复了 jq 检查 / timestamp / args_hash / repo_root 流水（`bail-log.sh:50-78`）。也就是说，**5 个 NDJSON channel 的 helper 在概念上是同一个，被切成 5 个文件 + 1 个共享 core**。

按 5 个 channel 数算，平均每个 channel 用 (85+81+97+68+96)/5 ≈ 85 行 + 1 个 jsonl 文件名 + 1 个 schema 描述。同样的能力一个 dispatch 函数（`emit <channel> <payload>`）大约可以收敛到 120-150 行。**净减约 250-300 行 + 4 个文件**。

### 4. "为评估而新增的评估"——069f16b commit 就是教科书例子

`git show 069f16b --stat`（v2.8.3 unify retro ndjson channels）：

```
29 files changed, 4597 insertions(+), 16 deletions(-)
```

其中 lib/ 净增的就是上面 §3 列出的 4 个 helper（evolution-log.sh 81 + observations.sh 68 + retro-events.sh 97 + skill-events.sh 96 = 342 行 helper），但 commit body 里**没有任何一个新功能**——所有 ndjson channel 在 v2.8.3 之前都已经存在，只是从 SKILL.md 的 inline bash 块迁到 lib/。同 commit 增加 **4 个测试文件 = 1991 行测试**（test_evolution_log_sh.py 528 + test_migration_parity.py 631 + test_observations_sh.py 306 + test_retro_events_sh.py 172 + test_skill_events_sh.py 485 + test_systematic_debugging_phase4_emission.py 597），这些测试**只服务于上面那 342 行 helper**——典型的"为评估而新增的评估"。

更深的证据：`docs/retros/meta-retro-2026-05-08-superpowers-v2.8.x.md:18-31`（v2.8.x 自己的元 retro）已经记录过同一类失败模式：

> "real bug fixes ≈ 80 lines. The remaining ~1,400 lines are mechanism additions, predicated on a sample of 1."（meta-retro:31）

> "post-plan-diff.sh + references/post-plan-diff.md + tests + Pre-Check A + Phase 5b veto gate + Phase 5a 1-plan ADD override + component_reinstated event schema | **~700** | **New mechanism**, not a fix"（meta-retro:27）

这条元 retro 已经独立给出 R1-R4 四个回撤目标（meta-retro:43-48），明确点名 R1 Phase 5b veto gate、R2 Pre-Check A、R3 task_count/batch_count、R4 LOW-YIELD prompt——但**到 2026-05-20 的当前 HEAD（787b923）没有任何一条被执行**。这是 retro 系统识别出可删项后未自我执行的典型证据。

retrospective 自身也是过度生长的范例：`skills/retrospective/SKILL.md` 222 行，Phase 5 拆成 5a / 5b / 5c / 5d 四个子阶段；Phase 6 单独 30 行只为算 `consecutive_zero_change` 一个标量（`SKILL.md:191-208`），需要协调 `evolution-log.jsonl`、`harness-config.json`、`harness-observations.jsonl`、`bail-out-events.jsonl`、`plans-completed.jsonl` 五个文件——这五条 channel 就是 §3 那四个 helper + bail-log 的产物。

### 5. 反 add-bias 体制实际**有**拒绝过 add 提案——但执行方式仍是"加一道闸门"

证据：`docs/retros/2026-05-09-v3-considered-deferred.md`。这份 retro 是 add-bias 体制起作用的最强证据：

- v3.x knowledge platform brainstorm 在同一 session 内输出了 **~880 行的 6 文件 design 文件夹**（_index.md 159 / architecture.md 213 / bdd-specs.md 469 / best-practices.md 204 + 两份 evaluation），然后**整个被拒**（行 7-9）
- 拒绝原因来自一个 sub-agent 的自我批判（行 21-27 表格），引用包括 "structurally replicates v2.8.x add-bias: 28 requirements / 4 phases / multi-channel architecture, no external review gate, no 'don't do' path"
- 落地结果：design 文件夹被删，retro 文件保留作为"considered, deferred, do not implement"的审计痕迹（行 9: "DESIGN-CONSIDERED-DEFERRED — DO NOT IMPLEMENT"）
- 同步落地了 4 个 mechanism 改动来防止下次同样路过：JUST-01 checklist item / evaluator §0 read / writing-plans NOT-JUSTIFIED gate / brainstorming Phase 2.5 vocab-reconciliation（retro:114）

第二个证据是 vocabulary 闸门：retro:40 记录了 `_index.md:92` 把"privacy tier"写成 `public/project/local`，但本 retro 自己用 `local-only / cross-session / cross-project / external`——这种"同一 session 内同一概念两套词"被 brainstorming Phase 2.5 vocab-reconciliation 当作 add-bias 的早期信号拦截。

**但**：这一类拒绝**自身是通过"加一层闸门"实现的**（JUST-01 是新增 checklist 条目；NOT-JUSTIFIED gate 是新增 SKILL.md 段落；vocab-reconciliation 是新增 Phase 2.5）。即"反 add-bias 体制"是用 add 来反 add 的——这本身是 §4 列举的 meta-retro R1 critique 在 v3 层级的复刻：

> "Auto-veto suppresses 5b candidates from the user. The user no longer sees the candidate."（meta-retro:84-86）

唯一一处真正"删掉而不是加闸门"的拒绝是 retro:7 那条 880 行 design 文件夹的删除（B-variant: 删除 + 留单文件 retro），且这条删除是**人类 maintainer 在主 session 选择**，不是任何 helper / hook 自动执行。

### 6. README 仍把 "Internal Skills" 块 + lib/ 全清单暴露给用户

`README.md:115-126, 165-193` 把内部 skill (BDD / iPhone-team) 和整个 hooks/lib/ 目录树都列出来；§163-193 的 File Structure 树**与现实不同步**——它仍写着 `hooks/` 三件套（task-start / track-changes / stop-hook）和 `lib/` 两件套（utils + loop），但 wc 的现实是 hooks/ 5 个 + lib/ 9 个。文档已经追不上 add 速度。

## 关注问题逐条回答

**Q1：最近 50 个 commit 在 add 还是 simplify？**

数字答：**add ≈ 15，simplify/remove ≈ 9，比值 1.67 : 1，整体仍偏 add**。在组件级别（drop skill / drop helper / drop hook）的纯减法只有 4 条（c3db9c0 删 AskUserQuestion 闸门、e3e885a 删 need-vet、7ced933 删 meeseeks-vetted 插件、1201bf9 删 agent-driven-development skill），而组件级别的纯加法至少 6 条（bail-log / post-plan-diff / stall detection / track-spawns / track-reads / 4 个 retro ndjson helper）。

加号比减号多——但比此前糟糕过。c3db9c0 (2026-05-15) 删除"interactive approval gates" 是近期最像 4.6 范式的简化（不再 mid-stream 问用户，直接落盘 + 让 git diff 做 review surface）；这是好兆头，但还只是一次。

**Q2：TODO-v3.md / retrospective 有明确删项吗？**

TODO-v3.md 全文只有 1 条 v3 债务（T-002），是**加 helper**的提案，没有删项。meta-retro-2026-05-08 §5 明列了 R1-R4 四个 retract 目标（删 Pre-Check A、删 Phase 5b veto、删 task_count/batch_count、删 LOW-YIELD prompt），共 -240 至 -260 行（meta-retro:170），**触发条件已写明**（T1 ≥3 项目 / T2 用户反馈 / T3 2026-08-06 calendar / T4 maintainer observation），但截至 HEAD 仍未执行——T3 calendar 距离触发还差 2.5 个月。所以"有规划的删项"存在，但**还没落地到代码**。

**Q3：lib/ 9 个 helper 有重叠吗？**

是。retro-events.sh + observations.sh + evolution-log.sh + skill-events.sh + bail-log.sh 共 427 行，本质是 5 个 jsonl channel 的薄 wrapper。retro-events.sh 自己已经承认 "shared core for the three retro NDJSON helpers"——把 bail-log 也合并进来后变成"5 个 channel 的共享 core"。一个 dispatch 设计可以在 120-150 行内做完，**净减 250-300 行 + 4 个文件**。

**Q4：有"为评估而新增的评估"吗？**

069f16b commit：29 files 4597 行 +/ 16 行 -，引入 4 个 lib helper（342 行）+ 5 个测试文件（2719 行 test code）+ 2719 行测试只测试那 342 行 helper。同 commit 没有任何 user-facing 新功能。这是教科书例子。retrospective Phase 5/6 调度 5 个 jsonl channel 算 `consecutive_zero_change` 一个标量，也是同类。

**Q5：v3 反 add-bias 体制真的拒绝过 add 提案吗？**

是，但用"加闸门"的方式拒绝的。`docs/retros/2026-05-09-v3-considered-deferred.md` 完整拒绝了一份 880 行 6 文件 v3.x knowledge platform design——sub-agent 在同 session 内自我批判命中、人类 maintainer 接受、整个 design 文件夹被删（行 7-9）。同时 JUST-01 / NOT-JUSTIFIED gate / vocab-reconciliation Phase 2.5 三条新闸门同步落地（行 114）——典型的"为防 add-bias 而 add 闸门"。

第二个例子：v3 retro §5 的"Phase 0 已 ship"声明被审计为不实——`harness-observations.jsonl` 和 `evolution-log.jsonl` 在 design 写时仍是 manual write，没有 lib helper（行 79-89）。这一条诚实记录后变成 TODO-v3.md T-002，且 T-002 自带"等到第三个 channel 出现才合并"的延迟 bar——这是反 add-bias 体制**实际拒绝了一次"立刻加 lib helper"的诱惑**。

**Q6：3-5 个具体可删/合并组件名**

1. **合并 `lib/{retro-events,observations,evolution-log,skill-events}.sh` 为单文件 `lib/jsonl-emit.sh`**（净减 250-300 行 + 3 个文件）。bail-log.sh 同步并入。理由：5 个 wrapper 的差异只是文件名 + envelope shape，dispatch 表能装下。
2. **删 `superpowers/skills/retrospective/SKILL.md` 中的 Pre-Check A 整段（行 15-20）+ Phase 5b post-plan-diff veto 段（行 122-136）**。这是 meta-retro R1+R2，已规划，触发条件 T3 calendar = 2026-08-06，但完全可以**当前 commit 就执行**，因为 N=1 over-correction 的事实没有改变，T3 只是 calendar 慢刀。
3. **删 `superpowers/lib/loop.sh:97-105` 中 task_count/batch_count 提取 + `loop.sh:122-130` 中对应 jq 字段**（meta-retro R3）。零 downstream consumer（meta-retro:47 grep 验证）。
4. **删 `superpowers/skills/retrospective/SKILL.md` Phase 6 `consecutive_zero_change` 计算 + LOW-YIELD pre-check 整套**（meta-retro R4 + U3）。LOW-YIELD 现在是 dead code（需要 ≥2 zero-change retro 才能触发，目前 N<2）。
5. **删 `superpowers/skills/build-like-iphone-team/`**（内部 skill，README:121-123）或将其从 `superpowers/.claude-plugin/plugin.json` 解注册。它只在 brainstorming "需要 unconventional approach"时被 load——这是模糊触发条件，且 brainstorming 自己已经有 Phase 2 三路 sub-agent 探索机制。这条候选证据偏弱，待观察先标 5b candidate。

## Anthropic 模式与 superpowers 现状对照

| 维度 | Anthropic 4.5→4.6 范式 | superpowers 当前 |
|---|---|---|
| 演化主轴 | 模型变强 → 删 sprint / 删 per-sprint eval / 删 context anxiety 补丁 | 模型变强假设未触发任何组件删除；50 commits add:simplify = 15:9 |
| 评估器位置 | 从 per-sprint 退化为 single final pass | 仍保留 per-batch evaluator（README:142）+ design evaluator + Phase 5b veto + Pre-Check A，**evaluator 的 evaluator 嵌套** |
| 假设测试机制 | 删一个组件、跑一遍、看模型还行不行（assumption testing） | 反方向：Phase 5c 一次只 disable 一个组件、观察一轮 plan、再判 promote/reinstate（同形但**保守得多**） |
| 反 add-bias 工具 | 删（model 能做了就不做） | 加（JUST-01 / NOT-JUSTIFIED gate / vocab-reconciliation）—— "用 add 反 add" |
| Helper 数量演化 | 减少 | 5 个 jsonl channel helper + 5 个 hook + 9 个 lib，仍在涨 |

唯一与博文同向的 commit 是 **c3db9c0 (refactor(sp): remove interactive approval gates)**——它把 brainstorming / debugging / planning 里的 AskUserQuestion mid-stream 询问全部删除，让 post-commit git diff 做 review surface。这是 4.6 范式（"agent 能 sustain longer，不再需要 mid-stream 问"）。可是只有一条；其余 14 条 refactor 多数是局部调整。

## 结论

反 add-bias 体制**确实拒绝过一次大型 add 提案**（v3 knowledge platform 880 行设计被回拒），证明体制有效；但体制本身的**实现方式仍是 add（加闸门、加 checklist 条目、加 vocab-reconciliation Phase）**，所以净效应是"用慢速 add 反快速 add"。50 commits 范围内的 add/simplify 比 ≈ 15/9 ≈ 1.67，组件级别 6/4 = 1.5，**整体仍处在 add 主导阶段**。

最尖锐的问题：retro 系统**已经识别出**自己有 -240 ~ -260 行的可删项（meta-retro R1-R4），但执行被锁在 calendar 触发器上（T3 = 2026-08-06）。如果反 add-bias 体制真的相信"每个组件都是可被删除的假设"，今天就应该跑 v2.9.0 retract patch，而不是等 2.5 个月。这是 Anthropic 范式与现状最大的方向差。

最该被删/合并的一个组件：**`lib/{retro-events,observations,evolution-log,skill-events}.sh` 四件套（合并为单一 `lib/jsonl-emit.sh`，净减 250-300 行 + 3 个文件）**——理由是 069f16b commit body 自己承认这次只是"unify"既有 channel 的 dispatcher，并没有引入新行为；引入它的 commit 同时把测试代码膨胀到 2719 行（其中 631 行是 test_migration_parity.py 专门验证迁移前后行为不变）——把 4 个 wrapper 折回单文件后，migration-parity 测试可以连同 4 个 wrapper 测试一起退役。这是 §3 + §4 的合证据，也是 §6 第 1 条建议。
