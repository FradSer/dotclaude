# SYNC.md — 与上游 mattpocock/skills 的同步手册

本文档记录 mattpocock 插件如何与上游 [mattpocock/skills](https://github.com/mattpocock/skills) 保持同步。**每次同步前先读此文档**——它包含历次同步/改造踩过的坑和固化的决策。

## 当前基线

| 项 | 值 |
|---|---|
| 上游 tag | **v1.3.2 + 3 commits**（2026-11-04 同步至 HEAD `4ae2317ddb22b046e26455e4f9c9b3aaaf62212d`；检查最新：`git ls-remote --tags https://github.com/mattpocock/skills.git`） |
| 机器可读基线 | `upstream-selection.json`：`comparedCommit=c55ee46073ed923f86ce59a5eb3b6d895095d1b7`、`comparisonTag=v1.3.2`、`resolvedTagCommit=d1478fcb140db0b93c0c8df17bcfd311844749d0`、`latestCheckedCommit=4ae2317ddb22b046e26455e4f9c9b3aaaf62212d` |
| 本地插件版本 | **0.2.0**（`mattpocock/.claude-plugin/plugin.json`，2026-11-04 上游同步） |
| 注册 skill 数 | **31**（27 + implement-spec / pr / retro 毕业 + deslop 新增；resolving-merge-conflicts 保留） |

基线不再只靠本文件的散文记录：`scripts/check-upstream-sync.py` 校验 `upstream-selection.json` 的四个 commit 字段、每个上游 `SKILL.md` 的 selected/excluded 分类、每个 `/mattpocock:` 引用、所有相对链接以及宿主语法禁词。同步后必跑（见「验证」）。

四个 revision 字段各司其职，不要混用：`comparedCommit` 是本次同步的**内容基线**（上次同步到的上游 commit，用于算增量）；`comparisonTag` 是可读的发布标记（v1.3.2）；`resolvedTagCommit` 记录该 tag 实际指向的 commit；`latestCheckedCommit` 是本次审查到的最新上游树（HEAD）。checker 用 `git rev-parse` 把四者逐一对照真实 checkout。`deletedUpstream` 记录上游已删但 fork 保留的 skill，`preservedLocalSkill` 必须同时出现在 `localOnly`，避免同一 skill 被分类两次却无人负责。

## 本次同步（2026-11-04，v1.2.3 + 50 commits → v1.3.2 + 3 commits）的记录

1. **CONTEXT.md → GLOSSARY.md 全局改名**：上游在 v1.3.0 把领域词汇文件名全部改掉。本次一次性采纳：`git mv CONTEXT.md GLOSSARY.md`、`git mv domain-modeling/CONTEXT-FORMAT.md GLOSSARY-FORMAT.md`，并机械替换所有 `CONTEXT*.md` 引用（0 残留）。不要逐文件部分采纳，否则读写路径会脱节。
2. **三个 skill 毕业**：`implement-spec`、`pr`、`retro` 从 `in-progress/` 用 `git mv` 移到 `engineering/` 并注册；正文按 fork 约定改写（`/mattpocock:` 前缀、Skill tool 用 `"mattpocock:<name>"`、description 补触发语）。`chief-of-staff`、`software-factory` 是新增 beta skill，按上游约定只镜像进 `in-progress/`、不注册。
3. **upstream 删除 resolving-merge-conflicts**：fork 有意保留（已注册且带本地 CRITICAL 块），在 `upstream-selection.json` 的 `deletedUpstream` + `localOnly` 中显式记录理由，不再当作漂移。
4. **wizard/template.sh**：吸收上游 11 处真实修复（0600 权限、符号链接写入、EOF 处理、Readline 光标、引号往返、`run_wizard` 包裹）。保留 `# Everything above the "STAGES" marker...` 头与 `# STAGES: author this section` 分隔行逐字不变（`evals/wizard-template-frozen` 依赖），并跑 `bash -n`。
5. **参考 pi-matt-pocock 的移植决策**：只移植纯内容而非运行时机器——`code-review` 加 AI slop 五类基线 + 因果证据标准，新增 `deslop` skill，`writing-for-agents` 加 model-aware 审计段，新增 `upstream-selection.json` + Python 同步 checker。**明确不移植**：catalog 网关、单 `/matt-pocock` 入口、`setActiveTools` 渐进工具、`matt_pocock_ask` / macOS 弹窗、64 KiB resolver、持久化工作流状态机——Claude Code 原生已有 skills 自动发现、`disable-model-invocation`、per-skill 斜杠命令、AskUserQuestion、subagent 与 hooks。
6. **API 事实核对**：当前官方文档确认 `plugin.json` 的 `skills` 字段是「补充扫描目录」、条目必须是目录；`commands` 是 legacy 格式。调用可见性由 SKILL.md frontmatter（`user-invocable` / `disable-model-invocation`）控制，不由 `commands` vs `skills` 控制。顶层 `CLAUDE.md` 里「注册到 skills 就内部不可见」的说法已过时；本次未改 manifest 结构，只在 README 记录。

### 验证哲学

- 同步缺陷先复现失败再修复：每个新检查先有一个故意植入的反例并确认返回非零退出码，再移除反例确认通过。
- 扫描器必须有 should-fail 用例：复制临时 fork，删掉一个 `SKILL.md` 或改坏一个 commit，确认 checker 报违规且 exit 1。本次实际跑过的反例（均 exit 1）：缺 `schemaVersion`、commit 非 40 位 hex、`selected` 少一项、`selected` 指向不存在的本地路径、重复 upstream skill、clone 中多出一个未分类 `SKILL.md`、删掉 setup 的 legacy `CONTEXT.md` 迁移行、去掉 diagnosing-bugs 的内容修复句、`openai.yaml` 里出现裸 `/to-spec`。
- 多文件核心变更后跑独立审计 agent：审计者不读本次实现上下文。
- 结构 checklist PASS 不等于形态正确：每个新增交付面先论证 null alternative（现有 references 文件 + 平台原生能力）。
- 区分「检查器加载了规则」和「规则实际生效」；只报告检查实际验证到的范围。

### 2026-11-04 原生特性评估（Claude Code 2.1.317）

用 workflow 研究 pi 运行时与当前 Claude Code 原生能力后，逐项做了对抗验证。结论：**本插件保持纯内容形态**，不新增 hook、agents/、状态机、monitor 或 userConfig。

已采用（零新增文件、零新增机器）：
1. 验证流程加 `claude plugin validate ./mattpocock --strict`。实测 `success: true`、manifest errors/warnings 全空；与本地 `validate-plugin.py` 互补（前者查官方 schema，后者查 token 预算与仓库风格）。

评估后明确不采用（附理由，避免下次同步重复讨论）：
- **pi 完成门槛内容移植（曾短暂实施后回退）**：`procedures/implement.md:18`、`code-review.md:105` 与 `src/workflow.ts:171-175` 的 `workflowGuidance()` 都含完成/编排指导。经独立对抗裁决（3 票中 2 票 REVERT），结论是**不移植**：该指导修复的是 pi 自身 v0.2.2 的运行时回归（旧 guidance 让长任务在有 teammate 结果未返回时提前停止），fork 无此状态机；4 个 eval 全绿且都不覆盖 `implement` / `code-review` / `implement-spec`，无观察到的失败；全局 `CLAUDE.md` 已有「完成请求的结果、不反复请示」的等效规则（null alternative）；其中「不为可信路径加防御性默认值」又与同轮已加的 AI slop `Defensive clutter` 基线重复。若将来复现出 fork 自身的过早结束缺陷，先写 Given/When/Then eval 再按 procedure 正文移植，不要直接复制运行时 guidance。
- `paths`：glob 相对 CWD，会限制通用流程 skill 的自动激活，反而降低可用性。
- `when_to_use`：字段未弃用（官方文档仍列出），但与 description 合计 1536 字符会被截断；31 个 description 已约 1608 tokens，再加长触发语加剧上下文成本。
- `context: fork` + `agent`：启动看不到对话历史的全新 subagent；`handoff`、`to-spec`、`grill-with-docs` 依赖对话上下文，不能用。
- `hooks`（skill 级 / Stop / PreToolUse）：skill 级 hook 注册后整会话有效；Stop/PreToolUse 阻塞回合会卡住 headless eval（`tdd-direct-gate` 依赖 prose CRITICAL 门控）。prompt-based hook 的精确返回 JSON 未经核实，不使用。
- `experimental.evals`：`evals/` 已是 CLI 默认值，加它是 no-op，且本地 validator 会报 `experimental` 未知字段（should 级）。
- `userConfig` / `monitors` / `channels`：插件无凭据、无服务、无长驻进程；issue tracker 的既有单一来源是 `setup-matt-pocock-skills`。`userConfig` 值虽可在 SKILL.md 正文以 `${user_config.KEY}` 替换，但这里没有需要用户配置的量。
- `agents/` 目录 + `skills:` 预加载：code-review 现有正文已把两个评审 brief（含 smell/AI slop 基线）完整内联给 fresh subagent，加插件 agent 属重复。plugin subagent 还会忽略 hooks/mcpServers/permissionMode。
- 仓库惯例核对：内联 `plugin.json` hooks 是既有写法（git-agent/github/superpowers/autoresearch），但本插件没有需要 hook 的事件；CI 目前只跑本地 validator，checker 是未跟踪新文件，提交前不往 CI 加步骤。
- `--profile directory --strict` 当前唯一失败项是 `ICON_MISSING`；仓库 23 个插件均不提供图标，属有意不为，不加二进制资源。

## 核心原则

> **同步 = 先拉上游 → 对比 diff → 再选择性修改（sync → compare → modify）。禁止整体覆盖。**

本地是 fork 而非 git subtree/remote 跟踪，且 fork 时有**大量刻意定制**。整目录覆盖会毁掉定制。同步的每一步都要区分：**本地有意定制（保留）** vs **上游演进（吸收）**。

## 同步流程

### 1. 检查上游新版本

```bash
git ls-remote --tags https://github.com/mattpocock/skills.git
# 若出现比 v1.2.3 更新的 tag，记下 tag 名
```

### 2. Clone 上游到临时目录

```bash
cd /tmp && rm -rf skills-upstream && git clone https://github.com/mattpocock/skills.git skills-upstream
cd skills-upstream && git worktree add /tmp/skills-old <当前基线tag>   # 例如 v1.2.3
git worktree add /tmp/skills-new <新tag或main>
```

### 3. 三路对比，分类差异

```bash
# A. 上游增量：v1.2.3 → 新版本的 skills/ 内容变化
git diff <旧tag> <新tag> -- skills/

# B. 结构性遗漏：上游有但本地没有的文件/目录
diff -rq /tmp/skills-new/skills mattpocock/skills | grep "Only in /tmp/skills-new"

# C. 内容差异：本地 vs 上游（判定哪些是定制、哪些该吸收）
diff -rq /tmp/skills-new/skills mattpocock/skills | grep "differ"
```

**对每处差异分类：**

| 类型 | 处理 |
|---|---|
| 上游**正文演进**（非本地改动区） | 吸收（Edit 合并，保留本地 frontmatter/CRITICAL 块） |
| 本地**有意定制** | 保留，不覆盖 |
| 上游**新增文件/目录** | 补齐（copy 或 cp -R） |
| 本地**独有文件**（bdd、writing-great-skills、deprecated 等） | 保留，不动 |

### 4. 应用内容增量

逐文件 `diff` 上游新旧版本，对上游改动的正文段落用 Edit 吸收，**保留**本地 frontmatter（description/`disable-model-invocation`）、`/mattpocock:` 前缀、`CRITICAL:` 块、`AskUserQuestion` 工具化改写。

**已知上游演进点**（v1.2.0→v1.2.3，供参考）：
- `diagnosing-bugs`：`## Redact` 安全节、redacted 措辞、hitl-loop 脚本注释
- `code-review`/`codebase-design/DESIGN-IT-TWICE`/`improve-codebase-architecture`：harness-neutral（去掉硬编码 `Agent tool`/`general-purpose`）
- `wizard`：移除 `TOTAL_MINUTES` 时间估算

### 5. 补齐结构性遗漏（重点——上次漏过）

上次 fork 当初漏掉一整批上游文件，同步时必须检查：

- **`agents/openai.yaml`**：上游每个 skill 都有（35 个），本地若缺全部补齐。`find <上游>/skills -name openai.yaml`
- **`ask-matt/PHASE-BOUNDARIES.md`**（上游有，本地曾缺）
- **整目录 skill**：`wait-what`、`writing-for-agents`（上游注册，本地曾缺）
- **`engineering/tdd`**：上游注册；本地改写成 **BDD-driven TDD**（BDD Automation 阶段实现参考），**已注册**（见决策）

检查命令：
```bash
# 上游有但本地没有的文件（0 输出 = 完整）
for f in $(find /tmp/skills-new/skills -type f | sed 's|/tmp/skills-new/skills/||'); do
  [ -f "mattpocock/skills/$f" ] || echo "MISSING: $f"
done
```

### 6. 结构决策检查（跟随既定决策，不要临场改）

| 决策 | 规则 |
|---|---|
| **tdd** | 重写为 BDD Automation 阶段实现参考（red-green 循环、seams、mocking、anti-patterns），注册到 plugin.json 作为 `/mattpocock:tdd`。不再镜像上游 tdd。 |
| **bdd** | BDD 生命周期（Discovery→Formulation→Automation），注册；Automation 阶段委托给 BDD-driven `/mattpocock:tdd` |
| **wizard** | 在 `skills/engineering/`（不在 in-progress），注册，**model-invoked**（无 `disable-model-invocation`） |
| **to-questionnaire** | 在 `skills/productivity/`，注册，user-invoked（保留 `disable-model-invocation: true`） |
| **wait-what / writing-for-agents** | 在 `skills/productivity/`，注册，镜像上游 |
| 未注册 bucket | `in-progress/` `misc/` `personal/` `deprecated/` 不上架，但文件保持全量 fork |

**移动 skill 用 `git mv`** 保留历史，且移动后检查：in-progress/README 等旧索引无残留引用。

### 7. 更新 ask-matt（router）

`skills/engineering/ask-matt/SKILL.md` 是路由文档，引用所有 skill。新增/移动 skill 后：
- 恢复上游对相关 skill 的引用（Standalone / Crossing sessions 部分）
- 所有命令用 `/mattpocock:` 前缀（**禁止裸 `/tdd`、`/setup-matt-pocock-skills` 等**）
- 引用必须能解析到已注册且存在的 skill 目录

### 8. 同步元数据（四处，缺一不可）

| 文件 | 改什么 |
|---|---|
| `mattpocock/.claude-plugin/plugin.json` | version、description（上游 tag / HEAD）、`skills` 数组增删 |
| `.claude-plugin/marketplace.json` | mattpocock 条目 version、description 必须与 plugin.json 一致 |
| `mattpocock/README.md` | **Version:**、**Registered skills (N)** 及分组、上游 tag / HEAD |
| `README.md` + `README.zh-CN.md`（顶层） | mattpocock 段的上游 tag / HEAD（**手动同步**，`/utils:update-readme` 禁模型，见记忆 project_readme_sync_manual） |

各 bucket 索引 README（`skills/engineering/README.md`、`skills/productivity/README.md`、`skills/in-progress/README.md`）也需反映结构变化。

### 9. 验证

```bash
# 1. 上游清单 + 引用 + 链接 + 宿主语法（离线）
python3 mattpocock/scripts/check-upstream-sync.py
# 2. 与已克隆的上游 checkout 做完整清单/revision/正文对比（不会 clone/fetch）
python3 mattpocock/scripts/check-upstream-sync.py --upstream /path/to/mattpocock-skills
# 3. 官方 manifest / 组件严格校验（Claude Code 2.1.275+；未知字段与缺失元数据都算失败）
claude plugin validate ./mattpocock --strict
# 4. 结构与 token 校验（退出码 0 = 无 MUST 违规；2 = token 预算超限）
python3 plugin-optimizer/scripts/validate-plugin.py mattpocock
# 5. 可选行为回归（在仓库根目录跑；双臂 with-without，约 40 USD 上限）
claude plugin eval ./mattpocock --runs 1 --concurrency 2 --scaffold --trust-plugin \
  --no-publish --allow-tools "Bash" "Write" "Edit" --max-cost-usd 40 --json /tmp/eval-full.json
```

- plugin.json 每个 skill 路径 → 目录含有效 SKILL.md（name+description frontmatter）
- 每个 `/mattpocock:` 引用 → 已存在且已注册（checker 强制）
- 每个相对 markdown 链接 → 目标存在（fenced/行内代码块中的示例路径除外）
- 移动后无死链、无旧路径残留、无 `TOTAL_MINUTES` 之类已删变量残留
- `upstream-selection.json` 四个 commit 字段均为 40 位小写 hex；`--upstream` 时校验 HEAD、tag 与 compared commit（含 comparedCommit 必须是记录的基线且为 HEAD 祖先）
- 16 个上游内容修复标记（`CONTENT_FIX_MARKERS`）在**离线与 `--upstream` 两种模式都校验**，不需要上游 checkout；曾误放在 `--upstream` 分支导致离线漏检，已修正。反例：把 diagnosing-bugs 的 `prove the mutation landed` 删掉，离线必须 exit 1。
- `claude plugin validate --strict` 与本地 `validate-plugin.py` 是两套互补检查：前者核对官方 manifest/组件 schema（含 `experimental.*`、`userConfig`、`hooks` 内联等新字段），后者额外做 token 预算与仓库风格检查。两者都要 exit 0。
- `--profile directory` 会额外做插件目录上架检查；当前唯一未通过项是 `ICON_MISSING`（仓库没有任何插件提供图标，属有意不为），不要为消除它新增图标二进制文件。
- 最近一次本机全套双臂 eval（2026-11-04、Claude Code 2.1.317、插件 0.2.0、`--model` 省略继承会话模型）：`overallScore=1`、4/4 通过、`meanDelta=0.458`、`partial=false`、3067s、$15.80。这是**本机一次性运行记录**，结果目录在 `evals/results/`（已 gitignore，不随仓库分发），fresh clone 上不存在该路径，不要当作可解析引用。两个正 delta（`tdd-direct-gate` +1、`wizard-template-frozen` +0.833）对应的 without 臂恰好都机械失败，双臂干净完成的两案 delta 均为 0；因此它只能证明「with 臂无错跑完」，不能证明插件因果增益。历史 2026-10-09 基线（2.1.295 / 0.1.5）同为 4/4、`meanDelta=0.467`，配置不同不可直接等价比较。`bdd-feature-first` 与 `tdd-direct-gate` 锁 BDD 定制，`wizard-template-frozen` 锁模板冻结库，回归即需在同步提交中一并修复。
- 首次显式传 `--model hunyuan-eval/hy4-dev` 的全套运行以 `overallScore=0.429`、1/4 通过失败，根因是 `unrecognized_model` 而非插件回归（4 个 case 的 delta 全为 0）。修复方式见下一条。
- 首次在未信任目录跑 eval 必须加 `--trust-plugin`（非交互/CI 环境不会弹出确认）；`claude plugin eval` 的 `--eval-dir` 默认取 manifest 的 `experimental.evals`，否则 `evals/`。
- **不要给 `claude plugin eval` 传 `--model` 裸代理 id**：本机 `ANTHROPIC_DEFAULT_*_MODEL=hunyuan-eval/hy4-dev[1m]`、`settings.json` 的 `model: haiku` 已把 eval 子进程映射到当前会话模型。显式传 `--model hunyuan-eval/hy4-dev`（代理 `/v1/models` 里的裸 id）会让子进程报 `[claude-code:unrecognized_model]`，表现为 arm 卡死、`timed out`、耗尽 `max_turns`，且 with/without 双臂 `delta` 全为 0。不传 `--model` 即「用当前模型」。同理 judge 也不必显式传 `--judge-model`。
- eval 的 `--ablation with-without` 无需显式传：路径目标解析到插件时 harness 自动加 no-plugin 基线臂，并已在 stdout 打印 "Ablation: defaulting to with-without"。
- 认证：`ANTHROPIC_AUTH_TOKEN` + `ANTHROPIC_BASE_URL` 必须导出到父 shell，让每个 `claude -p` 子进程继承；本机是本地代理，不要替换成 `sk-dummy`。
- `scaffold.sh` 的 `git commit` 带 `-c commit.gpgsign=false`（全局 `commit.gpgsign=true` 在干净 HOME / 无密钥环境会让 fixture 提交整体失败）；fixture 文案与 grader 判据统一用 `node --test`，与 prompt 强制的 runner 一致（曾写 `npm test`，会让 LLM judge 因字面不匹配误判）。

### 10. 提交推送

用 `/git:commit-and-push`。git-agent 会按 scope 拆原子提交。

## 本次同步（2026-08-07, v1.2.0→v1.2.3）的教训

1. **fork 当初漏了整批上游文件**——35 个 `agents/openai.yaml`、`PHASE-BOUNDARIES.md`、`wait-what`、`writing-for-agents`、`engineering/tdd`。教训：同步不能只 diff 增量，必须做"上游有而本地没有"的完整性扫描。
2. **wizard 的 `disable-model-invocation` 残留**（独立审计抓到，高严重度）——从 in-progress 移到 engineering 时，flag 从 in-progress 的 user-invoked 带了过来，但 ask-matt/README 已描述为 model-invoked，语义矛盾。教训：**移动 skill 到不同 invocation 形态的 bucket 时，必须检查并清除 frontmatter 的 invocation flag**。
3. **多文件核心变更后跑独立审计 agent**——51 个文件变更，自审通过后仍由无实现上下文的 agent 抓到 wizard flag 缺陷。符合项目"fresh-agent audit for multi-file changes"规则。
4. **CI 的 bypass 提示是正常的**——直接 push main 时 GitHub 提示 "Required status check ci-success is expected" 是 push 时点的异步提示，CI 随后跑完且通过。不是失败信号。

## 2026-08-08 改造：superdev→mattpocock 改名 + tdd 改制 + 交叉引用修复

### 改名
- 插件目录 `superdev/` → `mattpocock/`（git mv，134 文件）
- plugin name `superdev` → `mattpocock`，displayName → `Matt Pocock Skills`
- skill 前缀 `/superdev:` → `/mattpocock:`
- marketplace.json、SYNC.md、README、CLAUDE.md 等元数据同步
- 记忆文件 `project_superdev_fork.md` → `project_mattpocock_fork.md`

### tdd 改制
- 上游 tdd 镜像不再保留，重写为 **BDD-driven TDD**（BDD Automation 阶段实现参考）
- 注册到 plugin.json（skill 数 26→27），不再镜像上游 tdd
- 所有流程中 tdd 均为 bdd 驱动的 Automation 阶段，非独立实践
- bdd 的 SKILL.md 引言更新为 Discovery→Formulation→Automation 生命周期，Automation 委托给 tdd
- tdd 顶部新增 CRITICAL 检查：直接调用时先问用户 Gherkin 场景是否已定义，否则 redirect 到 bdd

### 交叉引用修复
- `code-review`：Spec 轴明确"Gherkin scenarios (from `/mattpocock:bdd`) are authoritative acceptance criteria"
- `to-tickets`：开篇增加"each ticket should map to one or more scenarios"
- `diagnosing-bugs`：修复后增加"run `/mattpocock:code-review` over the fix"
- `to-spec`：Gherkin 场景引用从 `tdd` 改为 `bdd`（Formulation 归 bdd，非 Automation）
- `ask-matt`：Standalone 节增加 bdd 和 tdd 条目；主流程描述改为 `bdd`(Discovery→Formulation)→`tdd`(Automation)；移除 Crossing sessions 中的误放
- `writing-great-skills`：示例从 TDD 改为 BDD
- `bdd/references/bdd-best-practices.md`：BDD vs TDD 段改为 BDD→TDD 统一管道描述

### 交叉引用验证
- `ask-matt` 引用 26 个 skill，全部已注册，无遗漏
- 由独立审计 agent 在隔离 worktree 中核验 8 条关键流程，全部 PASS
- `python3 validate-plugin.py mattpocock` → PASSED no issues

### 教训
1. **tdd 的 `disable-model-invocation` 不宜加**——另一个 skill 无法加载 user-invoked skill，bdd/implement 需要能调 tdd。用 SKILL.md 顶部 CRITICAL 检查替代技术门控。
2. **bdd 和 tdd 的职责划分必须显式写入各自的 SKILL.md 引言**——bdd 说"Automation 委托给 tdd"，tdd 说"若直接调用先检查场景是否已定义"。否则模型可能独立调 tdd 跳过 BDD 场景定义。
3. **ask-matt 的 Standalone 节容易遗漏新 skill**——新增/注册 skill 后必须检查 ask-matt 是否提及。
4. **skill 的引用位置语义重要**——bdd/tdd 放在 Crossing sessions 下是错误（它们不是 session 边界选项），应放在 Standalone。每次新增 skill 要确认归类正确。

## 2026-09-23 上游同步（v1.2.3 + 50 commits → HEAD）

### 新增文件（7 个，全部 in-progress，未注册）

- `in-progress/implement-spec/`：spec 实现编排（task graph + subagent 并发）
- `in-progress/pr/`：PR body 模板（from humanlayer/show-me）
- `in-progress/retro/`：编码回顾（navigation、automated checks、coding standards 等维度）

### 全局变更

1. **Em-dash 移除**：全仓库 `—` 替换为 `:`/`,`/`;`/括号（约 60 个文件受影响）
2. **跨 skill 调用术语标准化**：从 "Run the `/skill` skill" 改为 "Call the Skill tool with `skill-name`"
3. **User-invoked skill 互调限制**：skills 不再调用其他 user-invoked skills
4. **YAML frontmatter 冒号修复**：description 中含未引用冒号的已加引号

### 具体 skill 更新

- **domain-modeling**：trigger 改为 "discussing codebase terminology, writing CONTEXT.md, or recording ADR"；移除 "another skill needs to maintain" caveat
- **code-review**：implementation steps 措辞澄清
- **grilling**：questions 间加 HR；em-dash 移除
- **grill-me**：移除 "holds decisions" 措辞
- **grill-with-docs**：移除 "single writer" 段落
- **wait-what**：CONTEXT-MAP.md 修复
- **diagnosing-bugs**：Phase 6 标题从 "Cleanup + post-mortem" 改为 "Cleanup"
- **wayfinder/triage/improve-codebase-architecture**：跨 skill 调用术语更新

### 教训

1. **上游无新 tag 时同步到 HEAD**：v1.2.3 后有 50+ commits，包含 3 个新 skill 和大量术语/格式统一。即使无新 tag，也应定期同步以保持 fork 一致性。
2. **Em-dash 移除是机械变更**：可批量处理，但需注意本地 CRITICAL 块和 frontmatter 中的 em-dash 应保留（本地定制）。
3. **新增 in-progress skill 不自动注册**：遵循上游约定，in-progress bucket 的 skill 不上架，仅当成熟后移到 engineering/productivity 才注册。

## 决策记录（勿擅自更改）

- **tdd 历史**：最初（2026-08-07）完整镜像上游 engineering/tdd 但不注册，作为参考优化 bdd。2026-08-08 重写为 **BDD-driven TDD**（BDD Automation 阶段实现参考：red-green 循环、seams、mocking、anti-patterns），注册到 plugin.json。所有流程中 tdd 均为 bdd 驱动的 Automation 阶段，非独立实践。不再镜像上游 tdd——上游 tdd 的 diff 内容需手动审阅吸收，不整文件覆盖。
- **为什么 wizard/to-questionnaire 移到上游位置**：用户明确要求"移到上游位置并注册"（wizard → engineering/，to-questionnaire → productivity/）。
- **bdd 为什么新建 agents**：用户要求"参考 tdd 建 bdd 的 agents"，已按 tdd 极简形态建好。
- **tdd 的 `disable-model-invocation` 不加**：bdd/implement 的 SKILL.md 依赖加载 tdd，user-invoked 会阻断。用 SKILL.md 顶部 CRITICAL 检查替代技术门控。
