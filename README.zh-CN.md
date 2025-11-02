# FradSer 的 Claude Code 插件市场 ![](https://img.shields.io/badge/A%20FRAD%20PRODUCT-green)

[![Twitter Follow](https://img.shields.io/twitter/follow/FradSer?style=social)](https://twitter.com/FradSer) [![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin%20Marketplace-blue.svg)](https://docs.anthropic.com/en/docs/claude-code/plugins) [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**[English](README.md) | 中文**

`FradSer/dotclaude` 是一个跨平台工作流市场，涵盖代码审查、Git 自动化、GitHub 操作、SwiftUI 架构审查和开发者工具套件。所有命令/智能体都在 `prompts/` 维护，运行 `pnpm build:prompts` 会自动生成 Claude、Cursor、Codex、Gemini 的产物及 `.claude-plugin/marketplace.json`。

## 插件安装

<details>
<summary>Claude Code 安装说明</summary>

如何在 Claude Code 中安装和使用本市场的插件。

#### 1. 添加插件市场

```bash
/plugin marketplace add FradSer/dotclaude
```

当清单名称是 `fradser-dotclaude` 时，Claude 会生成 `<插件>@fradser-dotclaude` 形式的安装标识。

#### 2. 安装所需插件

```bash
# 打开插件面板，在界面中浏览并安装
/plugin

# 或者在已知安装标识时直接安装
/plugin install review@fradser-dotclaude
/plugin install git@fradser-dotclaude
/plugin install github@fradser-dotclaude
/plugin install swift@fradser-dotclaude
/plugin install utils@fradser-dotclaude
```

> 建议先安装 `review@fradser-dotclaude` 与 `git@fradser-dotclaude` 作为核心组合，再按需添加其他插件。

</details>

<details>
<summary>Cursor 安装说明</summary>

```bash
cd path/to/this/repo

cp -r dist/cursor/ $HOME/.cursor
```

这会将 `dist/cursor/` 中的所有 Cursor 命令文件复制到 Cursor 配置目录，使其在 Cursor 命令面板中可用。

</details>

<details>
<summary>Codex 安装说明</summary>

```bash
cd path/to/this/repo

cp -r dist/codex/ $HOME/.codex
```

这会将 `dist/codex/` 中的所有 Codex 提示文件复制到 Codex 配置目录，使其作为参考提示可用。

</details>

## 插件目录

### review（`plugins/code-review-toolkit`）· 生产力
多智能体代码审查系统，帮助维持高质量。
- **包含智能体：** `@code-reviewer`、`@security-reviewer`、`@tech-lead-reviewer`、`@ux-reviewer`、`@code-simplifier`
- **命令模板：** `/hierarchical`、`/quick`、`/refactor`
- **适用场景：** 全栈审查、安全评估、架构把关、指导式重构

### git（`plugins/git`）· 开发
约定式 Git 与 GitFlow 自动化。
- **命令模板：** `/commit`、`/push`、`/commit-and-push`、`/gitignore`
- **GitFlow 命令：** `/start-feature`、`/finish-feature`、`/start-release`、`/finish-release`、`/start-hotfix`、`/finish-hotfix`
- **适用场景：** 原子化提交、分支规约、自动生成 .gitignore

### github（`plugins/github`）· 生产力
带质量闸口的 GitHub 项目操作工具包。
- **命令模板：** `/create-issues`、`/create-pr`、`/resolve-issues`
- **亮点：** 基于 worktree 的问题解决、自动标签管理、PR 前安全与质量检查

### swift（`plugins/swiftui`）· 开发
专注 SwiftUI Clean Architecture 的审查智能体。
- **智能体：** `@swiftui-clean-architecture-reviewer`
- **适用场景：** 强制执行 MVVM + Clean Architecture 分层、SwiftData 集成审核、平台合规性检查

### utils（`plugins/utils`）· 生产力
日常自动化实用工具。
- **命令模板：** `/continue`、`/create-command`
- **适用场景：** 恢复中断会话、脚手架新的命令模板

---

## CLAUDE.md 同步工具

**独立的全局 CLAUDE.md 配置文件同步工具。**

`sync-to-github.sh` 脚本用于在 `$HOME/.claude` 和本 GitHub 仓库之间同步 `CLAUDE.md` 文件。此功能独立于上述插件安装。

### 使用方法

**本地运行（如果已克隆本仓库）：**
```bash
bash sync-to-github.sh
```

**远程运行（单行命令）：**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/FradSer/dotclaude/main/sync-to-github.sh)
```

### 选项

```bash
sync-to-github.sh [选项]

选项：
  -y, --yes, --non-interactive   无提示运行；需要指定 --prefer
      --prefer <local|repo>      发现差异时选择数据源（默认：repo）
      --branch <name>            覆盖目标分支（默认：main）
      --exclude <pattern>        添加额外的排除模式（可重复使用）
      --https                    使用 HTTPS 而非 SSH 克隆
  -h, --help                     显示此帮助
```

### 示例

**非交互模式（优先使用本地更改）：**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/FradSer/dotclaude/main/sync-to-github.sh) --yes --prefer local
```

**非交互模式（优先使用仓库版本）：**
```bash
bash sync-to-github.sh --yes --prefer repo
```

**交互模式（提示选择）：**
```bash
bash sync-to-github.sh
```

## 仓库结构

```text
dotclaude/
├── .claude-plugin/              # Claude 插件市场清单（构建时自动生成）
├── dist/                        # 构建产物（Claude/Cursor/Codex/Gemini）
│   ├── claude/plugins/...       # Claude 插件包
│   ├── cursor/commands/...      # Cursor 命令文件
│   ├── codex/prompts/...        # Copilot 参考提示
│   └── gemini/commands/...      # Gemini 命令 TOML
├── prompts/                     # 跨平台规范化定义
│   ├── <plugin>/plugin.yaml
│   ├── <plugin>/commands/*.yaml
│   └── <plugin>/agents/*.yaml
├── config/platforms/*.yaml      # 平台产物配置
├── docs/                        # 各平台集成指南
├── scripts/build/index.mjs      # 多平台生成器（pnpm build:prompts）
└── archive/                     # 归档的传统 Claude 插件文件
```

详细的开发策略（如强制 TDD、Clean Architecture 守则、工具链约定）请参阅 [`CLAUDE.md`](CLAUDE.md)。

## 常见问题

- **如何更新插件？** 使用 `/plugin update review@fradser-dotclaude`（替换为需要的插件名称）或重新安装。
- **可以 Fork 并定制吗？** 可以。Fork 仓库后更新插件内容、调整 `.claude-plugin/marketplace.json`，再让团队指向你的版本。
- **是否可以只安装部分插件？** 可以。每个插件相互独立，根据工作流选择需要的组合即可。
- **代码审查一定要调用所有智能体吗？** 不必。`review` 插件同时提供多个专家，按需唤起即可。

## 许可证

MIT 协议，详情见 [LICENSE](LICENSE)。
