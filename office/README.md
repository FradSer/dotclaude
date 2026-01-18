# Office Plugin

Specialized Claude Skill for patent application generation and intellectual property workflows.

## Overview

The Office Plugin provides specialized tools for patent attorneys and IP professionals to generate patent applications, manage IP workflows, and handle patent-related documentation.

## Skills

### `/office:patent-architect`

Generates structured Chinese patent application forms (专利申请表) from technical ideas.

**Metadata:**

| Field | Value |
|-------|-------|
| Allowed Tools | `Read`, `Grep`, `Glob`, `WebFetch`, `WebSearch`, `Write`, `Edit`, `Bash` |

**Goal**: Transform technical ideas into complete Chinese patent application forms (专利申请表).

**Workflow:**
```
用户输入技术想法 → 专利检索 (SerpAPI/Exa.ai) → 对比分析 → 生成申请表
```

**What it does:**
1. **Understand the Invention**: Extract 技术领域, 技术问题, 技术方案, 技术效果
2. **Prior Art Search (Mandatory)**: Search existing patents using SerpAPI and Exa.ai
3. **Generate Application Form**: Output structured patent application with all required sections

**Usage:**
```bash
/office:patent-architect \"Mobile Payment Authentication System\"
```

**Features:**
- **Dual Search Strategy**: Uses both SerpAPI (structured search) and Exa.ai (semantic search)
- **Automatic prior art search**: Searches patent databases before drafting
- **Chinese patent application form generation**: Complete 专利申请表 structure
- **Patent terminology compliance**: Uses proper patent language
- **Multiple embodiment generation**: Provides at least 3 implementation examples

**Prior Art Search Methods:**

| Method | Best For |
|--------|----------|
| SerpAPI Google Patents | Patent number lookup, assignee/inventor filtering, exact keyword matching |
| Exa.ai Semantic Search | Concept-level matching, finding similar inventions, natural language queries |

**Output Structure:**
```markdown
# 背景技术
[现有技术状况、存在的问题、技术挑战]

# 检索分析
检索过程及结论...

# 发明内容
1. 本发明要解决的核心技术问题
2. 技术方案概述
3. 有益效果

# 具体实施方式
## 实施例一：[场景]
## 实施例二：[场景]
## 实施例三：[场景]

# 其他
## 1. 关键创新点
## 2. 本技术方案潜在的替代方案
## 3. 本技术方案的缺陷
```

**Language Rules:**

| Avoid | Use |
|-------|-----|
| 产品名称 (iPhone) | 移动终端设备 |
| UI 术语 (按钮、页面) | 用户交互元素、显示界面 |
| 品牌名称 | 通用技术术语 |
| 口语化表达 | 专利规范用语 |

**Common Patent Expressions:**
- "一种..."
- "包括/包含"
- "用于..."
- "其特征在于"
- "所述..."
- "根据...确定..."
- "响应于..."
- "配置为..."

**Reference Files:**
- `reference.md` - SerpAPI details and format specifications
- `examples.md` - Complete application form examples

## Requirements

- **API Keys Required**:
  - `SERPAPI_KEY` - For Google Patents search (get from serpapi.com)
  - `EXA_API_KEY` - For semantic patent search (get from dashboard.exa.ai)

**Setup:**
```bash
export SERPAPI_KEY="your_serpapi_key"
export EXA_API_KEY="your_exa_api_key"
# Add to ~/.zshrc or ~/.bashrc for persistence
source ~/.zshrc
```

## Best Practices

- Provide detailed technical descriptions for better patent drafts
- Include specific implementation details and embodiments
- Use technical terminology appropriate for the patent field
- Review generated content for accuracy and completeness
- Always verify prior art search results
- Customize embodiments based on actual use cases

## Troubleshooting

### API keys not set

**Issue**: Patent search fails with authentication error

**Solution**:
- Verify environment variables are set: `echo $SERPAPI_KEY`
- Add exports to shell configuration file
- Run `source ~/.zshrc` after adding exports
- Get API keys from respective services

### Search returns no results

**Issue**: Prior art search finds no relevant patents

**Solution**:
- Try different keyword combinations
- Use both technical terms and natural language
- Broaden search scope initially
- Check if domain-specific filters are too restrictive

### Output format issues

**Issue**: Generated form doesn't match expected structure

**Solution**:
- Review reference.md and examples.md for correct format
- Ensure input describes a technical invention
- Provide more specific technical details

## Author

Frad LEE (fradser@gmail.com)

## Version

1.0.0
