---
name: create-prd
description: This skill should be used when the user asks to "create PRD", "write product requirements document", or mentions "PRD", "产品需求文档", "创建PRD", "写PRD", "生成PRD".
user-invocable: true
allowed-tools: ["Read", "Write", "AskUserQuestion", "Glob"]
---

# PRD 创建

按照以下阶段将产品想法转化为完整的中文 PRD 文档。所有 PRD 内容使用中文撰写。

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

5. **格式**：Markdown，清晰的标题层次，合理使用列表和表格

## 阶段 4：验证并保存

按 `references/prd-validation-checklist.md` 执行验证，包括完整性检查、SMART 目标验证、内容质量检查、BDD 验收标准检查。

验证通过后保存文件：
- 文件名格式：`PRD-[产品名称]-[YYYYMMDD].md`
- 优先保存到 `docs/` 或 `prd/` 目录，否则保存到当前工作目录
- 保存后报告路径和文件摘要

## 阶段 5：后续步骤

保存完成后，提示用户后续选项：

- 将 PRD 转化为实施计划和任务拆分
- 进一步细化待解决问题中的设计决策
- 分享给团队评审并收集反馈

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
