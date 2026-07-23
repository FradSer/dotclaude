# Frad 的 Claude Code 插件集 ![](https://img.shields.io/badge/plugins-16-blue)

[![MIT License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-v0.6+-purple)](https://claude.ai/code)

[English](README.md) | **简体中文**

精心打造的 16 个 Claude Code 插件集合，提供专业的 Agent、Skills 和自动化工具，服务于开发和生产力工作流。

## 可用插件

### [git](git/)

Conventional Git 自动化工具，支持代码质量检查的提交和仓库管理。

**安装：**
```bash
claude plugin install git@frad-dotclaude
```

---

### [gitflow](gitflow/)

GitFlow 工作流自动化，支持功能分支、修复分支和发布分支的语义化版本管理，并在 finish 后清理过期分支与 worktree。

**安装：**
```bash
claude plugin install gitflow@frad-dotclaude
```

---

### [github](github/)

GitHub 项目操作，包含质量门控、TDD 工作流、全面验证，以及持久的 PR review 监控（/github:review-pr 监控 CI 并对 reviewer 评论做分诊）。

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

### [office](office/)

专利申请书生成、产品需求文档、图片与视频生成、飞书文档创建、智能体浏览器自动化、Lark/Feishu CLI 路由（子 skill 入口已 denest）、Remotion 编程式视频创作以及 AI 写作俗套检测。

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

### [storm](storm/)

基于多视角提问与检索的维基百科风格长文生成 —— Stanford STORM 两阶段"研究→成文"流水线的 Claude 原生移植。给定主题,发现研究 persona、进行基于网络检索的模拟问答,再经由大纲 → 分节 → 润色阶段撰写带引用的文章。每个阶段可独立运行且可恢复。

**安装：**
```bash
claude plugin install storm@frad-dotclaude
```

---

### [hardware](hardware/)

硬件与 EDA 工具集。`use-kicad-cli` skill 驱动 KiCad 9.0 的 `kicad-cli`,完成原理图/PCB 导出、制造产物(gerber、钻孔、贴装坐标、BOM)、3D 模型及 ERC/DRC 检查;`use-openscad` skill 编写 OpenSCAD 代码并驱动 `openscad` CLI,产出参数化 3D/2D 零件及 STL/DXF/PNG。

**安装：**
```bash
claude plugin install hardware@frad-dotclaude
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