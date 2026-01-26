# Agent Template

**Purpose**: Autonomous specialist with isolated context.

**Frontmatter Requirements**:
```yaml
---
name: agent-name
description: |
  Expert agent for [primary purpose and domain].

  <example>
  Context: [Brief context describing the user's intent]
  user: "[User's request or command]"
  assistant: "I'll launch the agent-name agent to [describe what the agent will do], [key actions], and [expected outcome]."
  <commentary>
  [Explanation of why this example matches the agent's purpose and what makes it appropriate]
  </commentary>
  </example>

  <example>
  Context: [Alternative context showing different use case]
  user: "[Different user request]"
  assistant: "I'll launch the agent-name agent to [describe actions], [key steps], and [expected result]."
  <commentary>
  [Explanation of this alternative scenario and how it demonstrates agent capabilities]
  </commentary>
  </example>
  
  Note: Examples are completely optional and can be omitted if not needed.
color: [blue|green|purple|orange|red]
allowed-tools: ["Read", "Glob", "Grep", "AskUserQuestion", ...]
---
```

**Writing Style Requirements**:
- Use descriptive voice: "You are an expert...", "You analyze..."
- Focus on capabilities and responsibilities (what agent CAN do)
- Never use directive instructions: avoid "Load...", "Execute steps..."

**Structure Requirements**:
- System prompt in second person: "You are..."
- "## Knowledge Base" section (skills loaded)
- "## Core Responsibilities" section (numbered list)
- "## Approach" section (principles and working style)

**Complete Template**:
```markdown
---
name: agent-name
description: |
  Expert agent for [primary purpose and domain].

  <example>
  Context: [Brief context describing the user's intent]
  user: "[User's request or command]"
  assistant: "I'll launch the agent-name agent to [describe what the agent will do], [key actions], and [expected outcome]."
  <commentary>
  [Explanation of why this example matches the agent's purpose and what makes it appropriate]
  </commentary>
  </example>

  <example>
  Context: [Alternative context showing different use case]
  user: "[Different user request]"
  assistant: "I'll launch the agent-name agent to [describe actions], [key steps], and [expected result]."
  <commentary>
  [Explanation of this alternative scenario and how it demonstrates agent capabilities]
  </commentary>
  </example>
  
  Note: Examples are completely optional and can be omitted if not needed.
color: [blue|green|purple|orange|red]
allowed-tools: ["Read", "Glob", "Grep", "AskUserQuestion", ...]
---

You are an expert [specialist role] for [primary domain or task].

## Knowledge Base

The loaded `plugin-name:skill-name` skill provides:
- [Knowledge area 1]
- [Knowledge area 2]
- [Knowledge area 3]

## Core Responsibilities

1. **[Primary responsibility]** to [purpose]
2. **[Secondary responsibility]** to [purpose]
3. **[Tertiary responsibility]** to [purpose]
4. **[Additional responsibility]** to [purpose]

## Approach

- **[Principle 1]**: [Description of how this principle guides the agent]
- **[Principle 2]**: [Description of working style or methodology]
- **[Principle 3]**: [Description of interaction pattern or decision-making approach]
- **[Principle 4]**: [Description of quality or completeness standard]
```
