# Frad 的 `.claude` 配置 ![](https://img.shields.io/badge/A%20FRAD%20PRODUCT-WIP-yellow)

[![Twitter Follow](https://img.shields.io/twitter/follow/FradSer?style=social)](https://twitter.com/FradSer) [![Claude Code](https://img.shields.io/badge/Claude%20Code-Configuration-blue.svg)](https://docs.anthropic.com/en/docs/claude-code) [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**[English](README.md) | 中文**

Claude Code 的高级多智能体配置系统，提供专业智能体和命令模板，加速代码审查、重构、安全审计、技术领导指导和用户体验评估。

## 快速开始

刚接触多智能体系统？从这里开始：

### 1. 同步配置
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/FradSer/dotclaude/main/sync-to-github.sh)
```

### 2. 基础智能体使用
在任何 Claude Code 对话中：
- `@agent-code-reviewer` - 审查代码问题
- `@agent-security-reviewer` - 检查安全漏洞
- `@agent-ux-reviewer` - 评估用户界面设计

### 3. `claude` 中的最佳实践工作流
全面代码质量的三阶段协作流程：

1. **分层审查** - 使用 `/review/hierarchical` 进行彻底的多智能体分析
   - *在继续之前审查和验证 Claude 的分析*

2. **问题创建** - 使用 `/gh/create-issues` 创建 GitHub 问题以跟踪改进
   - *在创建之前检查和完善 Claude 建议的问题*

3. **质量实现** - 使用 `/gh/resolve-issues` 配合智能分支检测、AI 生成名称和 worktree 管理
   - *自动检测现有 worktrees 并提供继续选项*
   - *使用 AI 生成简洁、描述性的分支名称*
   - *审查 Claude 的代码建议并根据你的上下文调整*

每个步骤都需要工程师验证，以确保 Claude 的输出与项目目标和约束保持一致。参见[协作理念](#协作理念)了解合作原则。

### 4. 核心命令
在 Claude Code 中打开这些模板作为检查清单：
- **快速审查**：`commands/review/quick.md`
- **修复问题**：`commands/fix/code-quality.md`
- **提交更改**：`commands/git/commit-and-push.md`

### 5. 下一步
- 浏览[专业智能体](#专业智能体)了解所有可用专家
- 探索[命令模板](#命令模板)了解结构化工作流
- 设置[多智能体协作](#多智能体协作)流水线

---

### 同步详情

<details>
<summary>同步脚本的功能（点击展开）</summary>

- 同步 `~/.claude/{agents,commands,CLAUDE.md}` 与此仓库的相同路径（双向比较）
- **自动本地智能体管理**：检测 `local-agents/` 目录并将智能体复制到项目的 `.claude/agents/`
- 自动检测是在此仓库内运行还是克隆到 `/tmp/dotclaude-sync`
- 为每个项目显示差异，让你交互式选择：使用本地、使用仓库或跳过（支持彩色差异）
- 最后，你可以选择提交和推送（生成 Conventional/Commitizen 风格的消息或回退到内置模板）

**前置条件：**
- `git`, `curl`, `bash 3.2+`（macOS 默认即可）
- 可选：`colordiff`（彩色差异）、`claude` CLI（更好的提交消息生成）

</details>

## 目录结构

```text
dotclaude/
  - agents/                    # 全局智能体（适用于所有项目）
    - code-reviewer.md
    - code-simplifier.md
    - security-reviewer.md
    - tech-lead-reviewer.md
    - ux-reviewer.md
  - local-agents/              # 本地智能体（项目特定）
    - swiftui-clean-architecture-reviewer.md
  - commands/
    - continue.md
    - create-command.md
    - gh/
      - create-issues.md
      - create-pr.md
      - resolve-issues.md
    - git/
      - commit-and-push.md
      - commit.md
      - gitignore.md
      - push.md
    - gitflow/
      - finish-feature.md
      - finish-hotfix.md
      - finish-release.md
      - start-feature.md
      - start-hotfix.md
      - start-release.md
    - refactor.md
    - review/
      - hierarchical.md
      - quick.md
  - CLAUDE.md
  - README.md
  - README-zh.md
  - sync-to-github.sh
```

## 智能体系统

### 全局智能体 (Global Agents)
适用于所有项目的通用专业智能体，存储在 `agents/` 目录：

| 智能体 | 目的 | 专注领域 |
|-------|------|----------|
| **agent-code-reviewer** | 全面代码审查 | 正确性、错误处理、可维护性、最佳实践 |
| **agent-code-simplifier** | 重构和优化 | 可读性、复杂度降低、DRY 原则 |
| **agent-security-reviewer** | 安全审计和加固 | 身份验证/授权、输入验证、依赖扫描 |
| **agent-tech-lead-reviewer** | 架构指导 | 系统设计、技术方向、风险评估 |
| **agent-ux-reviewer** | 用户体验评估 | 可用性启发式、无障碍标准、UI 一致性 |

### 本地智能体 (Local Agents)
项目特定的专业智能体，存储在 `local-agents/` 目录，通过同步脚本复制到项目的 `.claude/agents/`：

| 智能体 | 目的 | 专注领域 | 适用项目 |
|-------|------|----------|----------|
| **swiftui-clean-architecture-reviewer** | SwiftUI Clean Architecture 审查 | 层分离、MVVM 模式、SwiftData 集成、@Observable 模式 | SwiftUI 项目 |

## 命令模板

常见开发任务的结构化工作流：

### 审查工作流
- **`/review/quick`** - 两阶段快速审查流程
- **`/review/hierarchical`** - 多层并行审查与整合输出

### Git 操作
- **`/git/commit.md`** - 结构化提交工作流
- **`/git/commit-and-push`** - 组合提交和推送操作
- **`/git/push`** - 带验证检查的推送
- **`/git/gitignore`** - 生成和管理 .gitignore 文件

### GitFlow 操作
- **`/gitflow/start-feature`** - 启动新功能分支
- **`/gitflow/finish-feature`** - 完成功能开发
- **`/gitflow/start-release`** - 开始发布准备
- **`/gitflow/finish-release`** - 完成发布
- **`/gitflow/start-hotfix`** - 创建热修复分支
- **`/gitflow/finish-hotfix`** - 部署关键修复

### GitHub 集成
- **`/gh/create-issues`** - 使用模板创建问题
- **`/gh/create-pr`** - 使用模板创建拉取请求
- **`/gh/resolve-issues`** - 智能问题解决，包含分支检测、AI 生成名称和 worktree 继续功能

### 开发工具
- **`/continue`** - 恢复中断的工作会话
- **`/create-command`** - 创建新命令模板
- **`/refactor`** - 系统化代码重构检查清单

## 使用模式

### 智能体调用

**全局智能体**（在任何项目中都可用）：
```
@agent-code-reviewer     # 全面代码分析
@agent-security-reviewer # 安全专注审计
@agent-tech-lead-reviewer # 架构指导
@agent-ux-reviewer       # 用户体验评估
@agent-code-simplifier   # 重构辅助
```

**本地智能体**（需要先通过同步脚本复制到项目）：
```
@swiftui-clean-architecture-reviewer # SwiftUI Clean Architecture 审查
```

### 命令驱动工作流
1. **打开命令模板** - 使用 `commands/*.md` 文件作为交互式检查清单
2. **遵循结构化流程** - 每个模板引导你完成特定工作流
3. **保持一致性** - 团队成员间的标准化方法

### 多智能体协作
```bash
# 示例：全面审查流水线
@agent-code-reviewer → @agent-security-reviewer → @agent-tech-lead-reviewer
```

### 协作理念

**Claude Code 作为你的开发伙伴**

将 Claude Code 视为一个异步协作的优秀同事。这种伙伴关系提供专业知识和质量保证，同时需要你在每个步骤进行验证以确保与项目目标一致。

**GitHub 作为协作平台**

GitHub 与 `gh` CLI 创建了 Claude Code 和项目管理之间的无缝集成。问题、拉取请求和提交成为结构化文档，将开发转化为周到的技术写作，其中人类决策和 AI 见解都被捕获和可追踪。

### 同步管理
- 定期运行快速同步以保持与仓库的一致
- 本地与远程更改的交互式差异解决
- 使用 Conventional 风格的自动提交消息生成

---

## 高级用法

参见 `CLAUDE.md` 了解完整的开发指南。要点：

**架构**
- 遵循 SOLID 原则；优先使用组合而不是继承
- 使用依赖注入提高可测试性
- 数据访问使用仓库模式，算法变化使用策略模式

**代码质量**
- 语义命名；避免魔法数字；保持函数简小
- 用有意义的消息覆盖错误场景
- 注释"为什么"而不是"什么"

**开发标准**
- 不确定时先搜索；为核心功能编写测试
- 代码更改时更新文档；Node.js 项目优先使用 `pnpm`
- 提交消息：仅英文，Conventional 风格（≤50 字符）
- 原子提交；无表情符号；PR 使用合并提交

## 常见问题

- 同步脚本是非交互式的吗？它是交互式的：每个项目选择本地或仓库，最后决定是否提交和推送。
- 没有彩色差异？可选安装 `colordiff`；脚本会自动检测并使用它。

## 许可证

MIT License