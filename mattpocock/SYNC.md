# SYNC.md — 与上游 mattpocock/skills 的同步手册

本文档记录 mattpocock 插件如何与上游 [mattpocock/skills](https://github.com/mattpocock/skills) 保持同步。**每次同步前先读此文档**——它包含上次同步（2026-08-07，v1.2.0 → v1.2.3）踩过的坑和固化的决策。

## 当前基线

| 项 | 值 |
|---|---|
| 上游 tag | **v1.2.3**（检查最新：`git ls-remote --tags https://github.com/mattpocock/skills.git`） |
| 本地插件版本 | **0.1.3**（`mattpocock/.claude-plugin/plugin.json`） |
| 注册 skill 数 | **27**（新增 tdd 作为 BDD Automation 参考） |

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
- **`engineering/tdd`**：上游注册；本地刻意用 `bdd` 替代——**tdd 完整镜像但不注册**（见决策）

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
| `mattpocock/.claude-plugin/plugin.json` | version、description（v1.2.x）、`skills` 数组增删 |
| `.claude-plugin/marketplace.json` | mattpocock 条目 version、description 必须与 plugin.json 一致 |
| `mattpocock/README.md` | **Version:**、**Registered skills (N)** 及分组、v1.2.x |
| `README.md` + `README.zh-CN.md`（顶层） | mattpocock 段的 v1.2.x（**手动同步**，`/utils:update-readme` 禁模型，见记忆 project_readme_sync_manual） |

各 bucket 索引 README（`skills/engineering/README.md`、`skills/productivity/README.md`、`skills/in-progress/README.md`）也需反映结构变化。

### 9. 验证

```bash
python3 plugin-optimizer/scripts/validate-plugin.py mattpocock
# 退出码 0 = 无 MUST 违规；2 = token 预算超限（需 refactor）
```

- plugin.json 每个 skill 路径 → 目录含有效 SKILL.md（name+description frontmatter）
- 每个 `/mattpocock:` 引用 → 已存在且已注册
- 移动后无死链、无旧路径残留、无 `TOTAL_MINUTES` 之类已删变量残留

### 10. 提交推送

用 `/git:commit-and-push`。git-agent 会按 scope 拆原子提交。

## 本次同步（2026-08-07, v1.2.0→v1.2.3）的教训

1. **fork 当初漏了整批上游文件**——35 个 `agents/openai.yaml`、`PHASE-BOUNDARIES.md`、`wait-what`、`writing-for-agents`、`engineering/tdd`。教训：同步不能只 diff 增量，必须做"上游有而本地没有"的完整性扫描。
2. **wizard 的 `disable-model-invocation` 残留**（独立审计抓到，高严重度）——从 in-progress 移到 engineering 时，flag 从 in-progress 的 user-invoked 带了过来，但 ask-matt/README 已描述为 model-invoked，语义矛盾。教训：**移动 skill 到不同 invocation 形态的 bucket 时，必须检查并清除 frontmatter 的 invocation flag**。
3. **多文件核心变更后跑独立审计 agent**——51 个文件变更，自审通过后仍由无实现上下文的 agent 抓到 wizard flag 缺陷。符合项目"fresh-agent audit for multi-file changes"规则。
4. **CI 的 bypass 提示是正常的**——直接 push main 时 GitHub 提示 "Required status check ci-success is expected" 是 push 时点的异步提示，CI 随后跑完且通过。不是失败信号。

## 决策记录（勿擅自更改）

- **tdd 历史**：最初（2026-08-07）完整镜像上游 engineering/tdd 但不注册，作为参考优化 bdd。2026-08-08 重写为 **BDD-driven TDD**（BDD Automation 阶段实现参考），注册到 plugin.json。bdd 的 Automation 阶段委托给 tdd，两者构成统一 BDD 管道。
- **为什么 wizard/to-questionnaire 移到上游位置**：用户明确要求"移到上游位置并注册"（wizard → engineering/，to-questionnaire → productivity/）。
- **bdd 为什么新建 agents**：用户要求"参考 tdd 建 bdd 的 agents"，已按 tdd 极简形态建好。
- **2026-08-08 tdd 改造**：上游 tdd 镜像不再保留，重写为 **BDD-driven TDD**（BDD Automation 阶段实现参考：red-green 循环、seams、mocking、anti-patterns），注册到 plugin.json。所有流程中 tdd 均为 bdd 驱动的 Automation 阶段，非独立实践。SYNC.md 决策表同步。
