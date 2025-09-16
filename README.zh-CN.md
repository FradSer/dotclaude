
# Frad 的 `.claude` 配置 ![](https://img.shields.io/badge/A%20FRAD%20PRODUCT-WIP-yellow)

[![Twitter Follow](https://img.shields.io/twitter/follow/FradSer?style=social)](https://twitter.com/FradSer) [![Claude Code](https://img.shields.io/badge/Claude%20Code-Configuration-blue.svg)](https://docs.anthropic.com/en/docs/claude-code) [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**[English](README.md) | 中文**

Claude Code 的高级多智能体配置系统，提供专业智能体和结构化命令模板，加速开发工作流程，包括代码审查、重构、安全审计、架构指导和用户体验评估。

## 🚀 快速开始

### 1. 安装配置
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/FradSer/dotclaude/main/sync-to-github.sh)
```

### 2. 核心智能体
在任何 Claude Code 对话中可用：
- **`@agent-code-reviewer`** - 全面代码分析和最佳实践
- **`@agent-security-reviewer`** - 安全漏洞评估
- **`@agent-tech-lead-reviewer`** - 架构指导和技术方向
- **`@agent-ux-reviewer`** - 用户界面和体验评估
- **`@agent-code-simplifier`** - 代码重构和复杂度降低

### 3. 推荐工作流
**三阶段质量保证流程：**

1. **🔍 分析** - 使用 `/review/hierarchical` 进行多智能体代码分析
2. **📋 规划** - 使用 `/gh/create-issues` 创建可跟踪的改进任务
3. **⚡ 实现** - 使用 `/gh/resolve-issues` 配合智能分支管理

> **💡 最佳实践**：在每个阶段验证 Claude 的建议，确保与项目目标保持一致。

### 4. 关键命令
在 Claude Code 中打开这些命令模板：
- **`/review/quick`** - 快速两阶段代码审查
- **`/git/commit-and-push`** - 结构化提交工作流
- **`/continue`** - 恢复中断的工作会话

### 5. 下一步
- 浏览[智能体系统](#智能体系统)了解所有可用专家
- 探索[命令模板](#命令模板)了解结构化工作流
- 查看[使用模式](#使用模式)了解有效协作

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

## 📁 目录结构

```text
dotclaude/
├── agents/                    # 🤖 全局智能体（所有项目）
│   ├── code-reviewer.md
│   ├── code-simplifier.md
│   ├── security-reviewer.md
│   ├── tech-lead-reviewer.md
│   └── ux-reviewer.md
├── local-agents/              # 🎯 项目特定智能体
│   └── swiftui-clean-architecture-reviewer.md
├── commands/                  # ⚡ 工作流模板
│   ├── continue.md
│   ├── create-command.md
│   ├── refactor.md
│   ├── gh/                    # GitHub 工作流
│   │   ├── create-issues.md
│   │   ├── create-pr.md
│   │   └── resolve-issues.md
│   ├── git/                   # Git 操作
│   │   ├── commit-and-push.md
│   │   ├── commit.md
│   │   ├── gitignore.md
│   │   └── push.md
│   ├── gitflow/               # GitFlow 工作流
│   │   ├── finish-feature.md
│   │   ├── finish-hotfix.md
│   │   ├── finish-release.md
│   │   ├── start-feature.md
│   │   ├── start-hotfix.md
│   │   └── start-release.md
│   └── review/                # 代码审查工作流
│       ├── hierarchical.md
│       └── quick.md
├── CLAUDE.md                  # 开发指南
├── README.md
├── README.zh-CN.md
└── sync-to-github.sh          # 配置同步脚本
```

## 🤖 智能体系统

### 全局智能体
适用于所有项目的通用专家：

| 智能体 | 用途 | 专业领域 |
|-------|------|----------|
| **`@agent-code-reviewer`** | 代码质量分析 | 正确性、可维护性、最佳实践 |
| **`@agent-code-simplifier`** | 重构辅助 | 复杂度降低、DRY 原则、现代化 |
| **`@agent-security-reviewer`** | 安全评估 | 漏洞检测、安全编码实践 |
| **`@agent-tech-lead-reviewer`** | 技术领导 | 架构、设计模式、技术方向 |
| **`@agent-ux-reviewer`** | 用户体验审计 | 可用性、无障碍性、界面一致性 |

### 本地智能体
项目特定专家（通过同步脚本复制）：

| 智能体 | 目标 | 专业领域 |
|-------|------|----------|
| **`@swiftui-clean-architecture-reviewer`** | SwiftUI | Clean Architecture、MVVM、SwiftData 模式 |

## ⚡ 命令模板

常见开发任务的结构化工作流模板：

### 🔍 代码审查
- **`/review/quick`** - 快速两阶段审查流程
- **`/review/hierarchical`** - 多智能体并行分析，结果整合

### 🌿 Git 操作
- **`/git/commit`** - 结构化提交工作流，符合约定式消息
- **`/git/commit-and-push`** - 组合提交和推送，包含验证
- **`/git/push`** - 带预检查的推送
- **`/git/gitignore`** - 生成和管理 .gitignore 文件

### 🚀 GitFlow 工作流
- **`/gitflow/start-feature`** - 初始化功能分支
- **`/gitflow/finish-feature`** - 完成并合并功能
- **`/gitflow/start-release`** - 准备发布分支
- **`/gitflow/finish-release`** - 完成并标记发布
- **`/gitflow/start-hotfix`** - 创建紧急修复分支
- **`/gitflow/finish-hotfix`** - 部署关键补丁

### 🐙 GitHub 集成
- **`/gh/create-issues`** - 使用模板和标签生成问题
- **`/gh/create-pr`** - 创建具有结构化描述的拉取请求
- **`/gh/resolve-issues`** - 智能问题解决，包含自动分支和 worktree 管理

### 🛠️ 开发工具
- **`/continue`** - 恢复中断的工作会话
- **`/create-command`** - 生成新命令模板
- **`/refactor`** - 系统化代码改进检查清单

## 💡 使用模式

### 命令驱动工作流
1. **📋 打开模板** - 在 Claude Code 中使用命令文件作为交互式检查清单
2. **🎯 遵循工作流** - 每个模板提供结构化的分步指导
3. **🤝 保持一致性** - 团队成员和项目间的标准化方法

### 智能体协作

**顺序审查**（彻底分析）：
```bash
@agent-code-reviewer → @agent-security-reviewer → @agent-tech-lead-reviewer
```

**并行专业化**（针对性专业知识）：
```bash
@agent-ux-reviewer        # UI/UX 专注
@agent-security-reviewer  # 安全专注
@agent-code-simplifier    # 重构专注
```

**项目特定**（同步后）：
```bash
@swiftui-clean-architecture-reviewer  # SwiftUI 项目
```

### 🤝 协作理念

**人机协作伙伴关系**
Claude Code 作为你的专业开发伙伴，提供专家分析和建议，而你保持决策权和项目上下文控制。

**GitHub 集成**
`gh` CLI 创建无缝工作流，将问题、拉取请求和提交转化为结构化文档，捕获人类决策和 AI 见解。

**验证驱动开发**
每个自动化步骤都包含人类验证点，确保 AI 建议与项目目标和约束保持一致。

---

## 📚 高级用法

查看 [`CLAUDE.md`](CLAUDE.md) 了解全面的开发指南，包括：

- **🏗️ 架构** - SOLID 原则、依赖注入、设计模式
- **✨ 代码质量** - 语义命名、错误处理、文档标准
- **🔄 开发标准** - TDD、原子提交、约定式提交消息
- **🛠️ 技术栈** - Node.js (`pnpm`)、Python (`uv`)、特定语言最佳实践

## ❓ 常见问题

**问：同步脚本是交互式的吗？**  
答：是的 - 你可以为每个项目选择本地或仓库版本，最后决定是否提交和推送。

**问：如何获得彩色差异显示？**  
答：安装 `colordiff` - 脚本会自动检测并在可用时使用它。

**问：可以为我的项目自定义智能体吗？**  
答：可以 - 在 `local-agents/` 中添加项目特定智能体，然后运行同步脚本。

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE)。