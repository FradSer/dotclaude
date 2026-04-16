---
name: create-prd
description: This skill should be used when the user asks to "create PRD", "write product requirements document", or mentions "PRD", "产品需求文档", "创建PRD", "写PRD", "生成PRD".
user-invocable: true
argument-hint: "--md | --lark [--folder-token TOKEN_OR_URL | --wiki-node TOKEN_OR_URL | --wiki-space ID_OR_URL]"
allowed-tools: ["Read", "Write", "AskUserQuestion", "Glob", "Bash(lark-cli:*)", "Skill"]
---

# PRD 创建

按照以下阶段将产品想法转化为完整的中文 PRD 文档。所有 PRD 内容使用中文撰写。

## 输出模式

根据 `$ARGUMENTS` 确定输出模式：

| 参数 | 模式 | 输出 |
|------|------|------|
| `--md`（默认） | 本地 Markdown | 保存为 `.md` 文件到项目目录 |
| `--lark` | 飞书云文档 | 通过 `lark-cli` 创建飞书文档，充分使用飞书富文本特性 |

`--lark` 模式可附加位置参数（互斥），支持 token 或飞书 URL：
- `--folder-token` -- 创建到指定文件夹（token 如 `fldcnXXXX` 或 URL 如 `https://xxx.feishu.cn/drive/folder/fldcnXXXX`）
- `--wiki-node` -- 创建到知识库节点下（token 如 `wikcnXXXX` 或 URL 如 `https://xxx.feishu.cn/wiki/wikcnXXXX`）
- `--wiki-space` -- 创建到知识空间根目录（ID 如 `7000000000000000000`、URL 如 `https://xxx.feishu.cn/wiki/settings/7000000000000000000`，或 `my_library` 表示个人知识库）

用户传入 URL 时直接透传给 `lark-cli`，无需手动提取 token。未指定位置参数时，创建到用户个人空间根目录。

## 阶段 0：导入上下文

检查是否存在已有的设计或需求文档：

1. 在当前项目中搜索 `docs/`、`prd/` 目录或用户指定的文件
2. 如果找到相关文档，提取关键信息（问题陈述、目标用户、核心功能）作为预填充内容
3. 如果没有找到，跳过此阶段

## 阶段 1：确定 PRD 类型

询问用户需要哪种类型的 PRD：

- **完整版**（推荐）：包含所有标准章节，适合复杂项目和重要功能
- **精简版**：仅包含核心章节，适合小功能快速迭代
- **单页版**：单页概要，适合概念验证和高层汇报

记录选择结果，确定后续章节结构。

## 阶段 2：收集信息

按 `references/prd-interview-questions.md` 中的提问清单，逐个收集信息。每次只问一个问题，等待回答后再继续下一个。

- 基础信息（7 项）：所有类型都需要
- 完整版额外信息（5 项）：仅完整版需要
- AI Agent 边界信息：当 PRD 将由 AI 编码代理消费时收集

如果阶段 0 已提取到预填充内容，展示给用户确认或修改，跳过已有信息的提问。

## 阶段 3：生成 PRD 文档

基于收集的信息生成 PRD：

1. **选择模板**：
   - 完整版：参考 `references/prd-template-full.md`
   - 精简版：参考 `references/prd-template-brief.md`
   - 单页版：参考 `references/prd-template-onepager.md`

2. **填充内容**：使用收集的信息填充每个章节，遵循 `references/prd-best-practices.md` 中的编写原则

3. **AI Agent 可消费性**：
   - 每个需求写成离散的、可验证的条目（列表优于长段落）
   - 非目标用正向约束表述（"禁止实现 X" 而非仅列出排除范围）
   - P0 功能拆分为 5-15 分钟的代理工作阶段，每阶段带可测试检查点
   - 完整版中包含三层边界框架：自主执行 / 需确认 / 禁止操作

4. **质量要求**：
   - 问题陈述包含具体数据或研究支持
   - 目标符合 SMART 原则
   - 成功指标明确量化
   - 避免模糊词汇（"大约"、"可能"、"尽量"）
   - 使用主动语态和明确动词

5. **格式**：
   - `--md` 模式：标准 Markdown，清晰的标题层次，合理使用列表和表格
   - `--lark` 模式：Lark-flavored Markdown，参照下方"飞书文档增强"章节

## 阶段 4：验证并保存

按 `references/prd-validation-checklist.md` 执行验证，包括完整性检查、SMART 目标验证、内容质量检查、BDD 验收标准检查。

### `--md` 模式

验证通过后保存文件：
- 文件名格式：`PRD-[产品名称]-[YYYYMMDD].md`
- 优先保存到 `docs/` 或 `prd/` 目录，否则保存到当前工作目录
- 保存后报告路径和文件摘要

### `--lark` 模式

验证通过后创建飞书文档：

1. **CRITICAL** -- 先读取 `${CLAUDE_PLUGIN_ROOT}/skills/lark/lark-shared/SKILL.md` 完成认证检查
2. 读取 `${CLAUDE_PLUGIN_ROOT}/skills/lark/lark-doc/SKILL.md` 了解文档创建指南
3. 读取 `${CLAUDE_PLUGIN_ROOT}/skills/lark/lark-doc/references/lark-doc-create.md` 了解 `docs +create` 的完整参数和 Lark-flavored Markdown 语法
4. 将 PRD 内容转换为 Lark-flavored Markdown（参照"飞书文档增强"章节）
5. 使用 `lark-cli docs +create` 创建文档：
   ```bash
   lark-cli docs +create --title "PRD-[产品名称]-[YYYYMMDD]" \
     [--folder-token TOKEN_OR_URL | --wiki-node TOKEN_OR_URL | --wiki-space ID_OR_URL] \
     --markdown "<lark-flavored-markdown>"
   ```
6. 对于较长的 PRD，分段创建以提高成功率：
   - 先用 `docs +create` 创建文档（包含前半部分内容）
   - 再用 `docs +update --mode append` 追加剩余章节
7. 如果文档中包含空白画板（`board_tokens` 不为空）：
   - 读取 `${CLAUDE_PLUGIN_ROOT}/skills/lark/lark-whiteboard-cli/SKILL.md`
   - 为每个画板填充实际内容（流程图、架构图等）
   - 确认所有画板都有实际内容后才算完成
8. 保存后报告文档 URL

## 阶段 5：后续步骤

保存完成后，提示用户后续选项：

- 将 PRD 转化为实施计划和任务拆分
- 进一步细化待解决问题中的设计决策
- 分享给团队评审并收集反馈

## 飞书文档增强

**CRITICAL** -- `--lark` 模式下，生成的 Markdown 内容必须使用 Lark-flavored Markdown 语法，充分利用飞书文档的富文本能力，不要只写纯 Markdown。

### 必须使用的飞书特性

| PRD 章节 | 飞书特性 | 说明 |
|----------|----------|------|
| 项目元数据（版本/日期/负责人） | `<lark-table>` 增强表格 | 首行表头，列宽合理分配 |
| 关键风险/假设/依赖 | `<callout>` 高亮块 | 风险用红色/橙色，假设用蓝色，依赖用黄色 |
| 核心目标/成功指标 | `<callout emoji="..." background-color="light-green">` | 突出关键 OKR 和量化指标 |
| 功能优先级对比（P0/P1/P2） | `<grid cols="3">` 分栏 | 三列并排展示不同优先级 |
| 用户旅程/业务流程 | `<whiteboard type="blank">` 画板 | 用流程图绘制，创建后用 lark-whiteboard-cli 填充 |
| 系统架构/技术方案 | `<whiteboard type="blank">` 画板 | 用架构图绘制，创建后用 lark-whiteboard-cli 填充 |
| 里程碑/时间线 | `<whiteboard type="blank">` 画板 | 用里程碑图绘制 |
| 非目标/范围排除 | `<callout emoji="..." background-color="light-red">` | 红色高亮，明确标注禁止范围 |
| 术语表/缩写对照 | 两列 Markdown 表格 | 简洁的对照表 |
| 决策记录 | `<callout>` + 引用块 | 记录关键决策及理由 |

### 画板使用规则

PRD 涉及以下内容时，主动插入空白画板并后续填充：

- 用户旅程 / 业务流程 -- flowchart
- 系统架构 / 模块关系 -- architecture
- 数据流转 / 状态机 -- flowchart
- 里程碑 / 时间线 -- milestone
- 组织 / 团队分工 -- organization

不适用画板的情况：纯文字描述、数据密集型内容（用表格）、用户明确要求仅文本。

### 格式原则

- 标题层级不超过 4 层
- 章节之间用分割线 `---` 分隔，保持视觉节奏
- 文档开头不要写与 title 重复的一级标题（飞书自动生成）
- callout 不过度使用，加粗只强调核心词
- 使用 `<text color="red">` 等为关键指标或状态着色
- 飞书自动生成目录，无需手动添加

## 质量原则

- **数据驱动**：用具体数据和用户研究支持问题陈述
- **SMART 目标**：具体、可衡量、可实现、相关、有时限
- **简洁清晰**：避免冗长，功能描述足够清晰供开发团队直接实施
- **协作导向**：PRD 是协作工具，语气促进讨论而非命令
- **双受众设计**：PRD 同时服务人类团队和 AI 编码代理

## 支持文件

- `references/prd-interview-questions.md` -- 信息收集提问清单
- `references/prd-validation-checklist.md` -- 验证清单
- `references/prd-template-full.md` -- 完整版模板
- `references/prd-template-brief.md` -- 精简版模板
- `references/prd-template-onepager.md` -- 单页版模板
- `references/prd-best-practices.md` -- 最佳实践指南
- `references/prd-examples.md` -- 高质量 PRD 示例
- `${CLAUDE_PLUGIN_ROOT}/skills/lark/` -- Lark CLI skills（`--lark` 模式）
