# Frad 的 Claude Code 插件集 ![](https://img.shields.io/badge/plugins-21-blue)

[![MIT License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-v0.6+-purple)](https://claude.ai/code)

[English](README.md) | **简体中文**

精心打造的 21 个 Claude Code 插件集合，提供专业的 Agent、Skills 和自动化工具，服务于开发和生产力工作流。

## 可用插件

### [git](git/)

Conventional Git 自动化工具，支持代码质量检查的提交和仓库管理，以及 GitFlow 工作流自动化（功能分支、修复分支和发布分支的语义化版本管理，finish 后清理过期分支与 worktree）。

**安装：**
```bash
claude plugin install git@frad-dotclaude
```

---

### [github](github/)

GitHub 项目操作，包含质量门控、TDD 工作流、全面验证，以及持久的 PR review 监控（/github:review-pr 监控 CI 并对 reviewer 评论做分诊）。

**安装：**
```bash
claude plugin install github@frad-dotclaude
```

---

### [mattpocock](mattpocock/)

以 BDD 为先的工程 skills，fork 自 mattpocock/skills v1.2.3，附带自我改进的 checklist 子系统。

**安装：**
```bash
claude plugin install mattpocock@frad-dotclaude
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

专利申请书生成、产品需求文档、图片与视频生成、智能体浏览器自动化、Remotion 编程式视频创作以及 AI 写作俗套检测。

**安装：**
```bash
claude plugin install office@frad-dotclaude
```

---

### [lark](lark/)

飞书/Lark CLI 技能，镜像自 larksuite/cli —— 文档、表格、IM、日历、审批、云盘、知识库、通讯录等。

**安装：**
```bash
claude plugin install lark@frad-dotclaude
```

---

### [marketing](marketing/)

面向 AI Agent 的营销技能，镜像自 coreyhaines31/marketingskills —— CRO、文案写作、SEO、付费广告、广告创意、分析与增长。

**安装：**
```bash
claude plugin install marketing@frad-dotclaude
```

---

### [hyperframes](hyperframes/)

HyperFrames HTML 视频创作技能，镜像自 heygen-com/hyperframes —— keyframes、动画、字幕、动态图形与 remotion-to-hyperframes 转换。

**安装：**
```bash
claude plugin install hyperframes@frad-dotclaude
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

受 karpathy/autoresearch 启发的自主研究循环 —— 给它一个自然语言目标，它会先推断一份推荐契约（目标文件、评估器、实验边界），再逐项与你盘问确认每个决策，然后迭代：先用廉价的串行轮次，遇到平台期后升级为并行的 GAN 锦标赛。适用于任意目标，而不止 ML 训练。

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

### [memory](memory/)

整理 Claude Code 项目的记忆——私人 harness 记忆（~/.claude/projects/<escaped-cwd>/memory）与仓库记忆（docs/memory/），视为单一无分层存储；Stop 时按 24 小时去重自动整理，也提供无需参数的手动 skill。

**安装：**
```bash
claude plugin install memory@frad-dotclaude
```

---

### [pi](pi/)

桥接到 pi (dev/pi)，一个极简终端编程助手。`/pi:delegate` 将编码任务附带文件和 Git 上下文发送给 pi 执行。支持三层持久化配置和通过 `~/.pi/agent/models.json` 的自定义 base URL。

**安装：**
```bash
claude plugin install pi@frad-dotclaude
```

---

### [interfaces](interfaces/)

构建优秀产品界面的 Agent 技能集，涵盖排版、色彩、布局、无障碍、UI 打磨和 UX 文案。单一技能 better-interface（编排器），配六个领域参考包：accessibility、layout、writing、typography、colors 和 ui。

**安装：**
```bash
claude plugin install interfaces@frad-dotclaude
```

---

### [vision](vision/)

Vision Bridge（视觉桥接）。让不支持视觉的模型（如 deepseek）拥有"眼睛"：UserPromptSubmit hook 自动描述图片文件路径，透明本地代理将粘贴截图的 image block 替换为独立视觉服务商的文字描述后转发上游。修复非视觉模型收到截图时出现的 `unknown variant 'image_url'` 400 错误。含 `/vision:bridge` 管理命令。

**安装：**
```bash
claude plugin install vision@frad-dotclaude
```

---

## 添加新插件

1. 在 `plugin-name/` 下创建插件目录。
2. 添加 `.claude-plugin/plugin.json` 包含所需元数据。
3. 将插件条目添加到 `.claude-plugin/marketplace.json`。
4. 运行 `/utils:update-readme` 同步两个 README 文件。

## 许可证

[MIT](LICENSE)