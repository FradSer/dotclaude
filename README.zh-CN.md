# Frad 的 Claude Code 插件集 ![](https://img.shields.io/badge/plugins-13-blue)

[![MIT License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-v0.6+-purple)](https://claude.ai/code)

[English](README.md) | **简体中文**

精心打造的 15 个 Claude Code 插件集合，提供专业的 Agent、Skills 和自动化工具，服务于开发和生产力工作流。

## 可用插件

### [git](git/)

Conventional Git 自动化工具，支持代码质量检查的提交和仓库管理。

**安装：**
```bash
claude plugin install git@frad-dotclaude
```

---

### [gitflow](gitflow/)

GitFlow 工作流自动化，支持功能分支、修复分支和发布分支的语义化版本管理。

**安装：**
```bash
claude plugin install gitflow@frad-dotclaude
```

---

### [github](github/)

GitHub 项目操作，包含质量门控、TDD 工作流和全面验证。

**安装：**
```bash
claude plugin install github@frad-dotclaude
```

---

### [superpowers](superpowers/)

高级开发工作流编排，支持 BDD 与可自我改进的 skill 库。

**安装：**
```bash
claude plugin install superpowers@frad-dotclaude
```

---

### [refactor](refactor/)

代码简化和重构，包含语言特定模式和跨文件优化。

**安装：**
```bash
claude plugin install refactor@frad-dotclaude
```

---

### [swiftui](swiftui/)

SwiftUI Clean Architecture 审查器，支持 iOS/macOS 开发的最佳实践规范。

**安装：**
```bash
claude plugin install swiftui@frad-dotclaude
```

---

### [claude-config](claude-config/)

通过交互式工作流生成 CLAUDE.md 配置，支持环境检测、BDD/TDD 测试选项和本地最佳实践引用。

**安装：**
```bash
claude plugin install claude-config@frad-dotclaude
```

---

### [office](office/)

专利申请书生成、产品需求文档、图片与视频生成、飞书文档创建、智能体浏览器自动化、Lark/Feishu CLI 操作以及 AI 写作俗套检测。

**安装：**
```bash
claude plugin install office@frad-dotclaude
```

---

### [plugin-optimizer](plugin-optimizer/)

根据官方最佳实践验证和优化 Claude Code 插件，支持 Agent 自动修复。

**安装：**
```bash
claude plugin install plugin-optimizer@frad-dotclaude
```

---

### [frontend](frontend/)

Web 前端开发工具包 —— shadcn/ui、Next.js DevTools、React 最佳实践、Supabase、DESIGN.md 设计系统规范，以及无可挑剔的设计技能。

**安装：**
```bash
claude plugin install frontend@frad-dotclaude
```

---

### [autoresearch](autoresearch/)

受 karpathy/autoresearch 启发的自主研究循环 —— 你提供可编辑的目标文件、一个打印单个数值的评分命令以及优化方向；循环运行有边界的实验，仅在分数改善时保留改动，将结果记录到 results.tsv，并通过 stop hook 持续迭代。适用于任意目标，而不止 ML 训练。

**安装：**
```bash
claude plugin install autoresearch@frad-dotclaude
```

---

### [antigravity](antigravity/)

将任务和深度研究委托给运行在远程沙箱中的 Google Gemini Managed Agents（Antigravity），沙箱内可执行代码、调用 Google 搜索和读取网页，完成后把结果读回。异步运行，通过 Monitor 工具轮询直到完成。需要 `GEMINI_API_KEY` 和 `uv`。

**安装：**
```bash
claude plugin install antigravity@frad-dotclaude
```

---

### [acpx](acpx/)

acpx 知识库 - 用于 Agent 间通信的无头 ACP CLI。

**安装：**
```bash
claude plugin install acpx@frad-dotclaude
```

---

### [code-context](code-context/)

五种获取代码上下文的方法：DeepWiki、Context7、Exa、git clone 和网页搜索。

**安装：**
```bash
claude plugin install code-context@frad-dotclaude
```

---

### [utils](utils/)

通用实用工具 Skills，用于文档、写作和项目维护。

**安装：**
```bash
claude plugin install utils@frad-dotclaude
```

---

## 添加新插件

1. 在 `plugin-name/` 下创建插件目录。
2. 添加 `.claude-plugin/plugin.json` 包含所需元数据。
3. 将插件条目添加到 `.claude-plugin/marketplace.json`。
4. 运行 `/utils:update-readme` 同步两个 README 文件。

## 许可证

[MIT](LICENSE)