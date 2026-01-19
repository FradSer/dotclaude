---
description: Generate Chinese patent application forms from technical ideas
---

## Your Task

1. **Load the `patent-architect` skill** using the `Skill` tool.
2. **Understand the Invention**: Extract 技术领域, 技术问题, 技术方案, 技术效果 from the user's input.
3. **Prior Art Search (Mandatory)**: Search patents using SerpAPI or Exa.ai before drafting.
   - Use `${CLAUDE_PLUGIN_ROOT}/scripts/search-patents.sh` or direct API calls
   - Analyze top 3-5 results to identify 最接近的现有技术 and 区别技术特征
4. **Generate Application Form**: Draft patent following `template.md` structure:
   - 背景技术
   - 检索分析 (with comparison table)
   - 发明内容 (核心问题、方案概述、有益效果)
   - 具体实施方式 (at least 3 embodiments)
   - 其他 (创新点、替代方案、缺陷)
5. **Use Patent Terminology**: Follow `reference.md` language conventions - avoid product names, use formal expressions.
