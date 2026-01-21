# Agents Component Reference

Plugins can provide specialized subagents for specific tasks that Claude can invoke automatically when appropriate.

**Location**: `agents/` directory in plugin root

**File format**: Markdown files describing agent capabilities

## Agent structure

```markdown
---
description: What this agent specializes in
capabilities: ["task1", "task2", "task3"]
---

# Agent Name

Detailed description of the agent's role, expertise, and when Claude should invoke it.

## Capabilities
- Specific task the agent excels at
- Another specialized capability
- When to use this agent vs others

## Context and examples
Provide examples of when this agent should be used and what kinds of problems it solves.
```

## Integration points

* Agents appear in the `/agents` interface
* Claude can invoke agents automatically based on task context
* Agents can be invoked manually by users
* Agents work alongside built-in Claude agents

## Best Practices

### Must Do
- **Concise Goal**: The goal description should be approximately 20 words or less - clear and direct.
- **Define Triggering Examples**: You **must** include 2-4 `<example>` blocks in the description showing Context, User input, and Assistant response. This is critical for the router.
- **Use Second Person**: Write system prompts addressing the agent directly ("You are an expert...", "Your responsibilities are...").
- **Define Output Format**: Clearly specify exactly how the agent should structure its final response.

### Avoid
- **First Person Prompts**: Never write "I am an agent..." in the system prompt.
- **Vague Triggers**: Avoid generic descriptions like "Helps with code." Be specific: "Use this agent when..."

## Configuration Reference

### Model Selection
- `inherit`: Default, uses parent context model
- `haiku`: Fast validation/checks
- `sonnet`: Balanced quality/speed
- `opus`: Complex reasoning

### Color Coding
- `blue`: Analysis/review
- `green`: Validation/testing
- `cyan`: Information gathering
- `yellow`: Warnings/checks
- `magenta`: Generation/creation
- `red`: Critical operations

## Common Agent Patterns

### Read-Only Agent
```yaml
name: analyzer
model: sonnet
color: blue
tools: ["Read", "Grep", "Glob"]
```

### Code Generation Agent
```yaml
name: generator
model: sonnet
color: magenta
tools: ["Read", "Write", "Edit"]
permissionMode: acceptEdits
```

### Fast Validation
```yaml
name: validator
model: haiku
color: yellow
tools: ["Read", "Bash(test:*)"]
```
