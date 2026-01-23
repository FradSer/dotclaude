---
name: plugin-best-practices
description: This skill should be used when the user asks to "validate a plugin", "optimize plugin", "check plugin quality", "review plugin structure", "find plugin issues", "check best practices", "analyze plugin", or mentions plugin validation, optimization, or quality assurance.
user-invocable: false
version: 0.1.0
---

# Plugin Best Practices

Validate and optimize Claude Code plugins against official standards.

## Key Validation Rules

**Architecture Guidance**:
- **Prefer Skills over Commands**: Skills are the modern, recommended approach for extending Claude's capabilities. Use Skills for new plugins instead of Commands.
- **Skills vs Agents**: Use Skills for reusable prompts/workflows that run in main conversation context. Use Agents (subagents) for isolated tasks requiring independent context, specific tool restrictions, or specialized system prompts.

**Critical Checks**:
- Verify skills are < 500 lines with progressive disclosure
- Verify agents have clear descriptions for automatic delegation and single responsibility
- Verify agents include 2-4 `<example>` blocks in description (critical for router)
- Check components use kebab-case naming
- Ensure scripts are executable with shebang and `${CLAUDE_PLUGIN_ROOT}` paths
- Validate no explicit tool invocations in component instructions (use implicit descriptions)
- Use AskUserQuestion tool when user confirmation is needed
- Confirm all paths are relative and start with `./`
- Verify components are at plugin root, not inside `.claude-plugin/`
- Confirm skills/commands explicitly declared in plugin.json (recommended)

**Severity Levels**:
- **Critical**: Must fix before plugin works correctly
- **Warning**: Should fix for best practices compliance
- **Info**: Nice to have improvements

## Additional Resources

Load detailed validation patterns from `references/` directory:
- **Components**: `references/components/[type].md` - Validate or create specific components (commands, agents, skills, hooks, mcp-servers, lsp-servers)
- **Structure**: `references/directory-structure.md` - Validate directory layout, file locations, naming conventions
- **Manifest**: `references/manifest-schema.md` - Validate or create plugin.json schema and configuration
- **Tool Usage**: `references/tool-invocations.md` - Check tool invocation patterns in component instructions
- **MCP Patterns**: `references/mcp-patterns.md` - MCP server integration patterns and best practices
- **Debugging**: `references/debugging.md` - Diagnose plugin loading failures, component discovery issues, hook/MCP problems
- **CLI Commands**: `references/cli-commands.md` - Use CLI commands for plugin management
- **TodoWrite Tool**: `references/todowrite-usage.md` - Use TodoWrite tool in plugin components

## Pattern References

### Skill Pattern

```yaml
---
name: skill-name
description: This skill should be used when [specific scenarios or keywords]
argument-hint: [optional-arg]
user-invocable: true
allowed-tools: ["Read", "Grep", "Bash(git:*)", "Bash(chmod:*)", "Edit"]
---

# Skill Title

Use imperative style instructions. Reference $ARGUMENTS for user input.

**Initial request:** $ARGUMENTS

---

**Goal**: What this phase accomplishes

**CRITICAL**: Important instruction or warning (optional)

**Actions**:
1. Specific instruction using imperative style
2. Use tools implicitly (write "Read the file..." not "Use the Read tool")

**Output**: Expected result or deliverable (optional)
```

### Agent Pattern

```yaml
---
name: agent-name
description: Use this agent when [specific scenarios]. Examples:

<example>
Context: [scenario description]
user: "[example user input]"
assistant: "[example agent response]"
<commentary>
[Why this example triggers the agent]
</commentary>
</example>

<example>
[Additional examples - 2-4 total required]
</example>

model: sonnet
color: blue
skills:
  - plugin-name:skill-name
tools: ["Read", "Grep", "Bash(git:*)", "Edit"]
---

You are an expert [role]. [System prompt in second person]

## Core Responsibilities
1. **Responsibility 1**: Description
2. **Responsibility 2**: Description
```
