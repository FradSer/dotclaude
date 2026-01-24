---
name: plugin-best-practices
description: This skill should be used when the user asks to "validate a plugin", "optimize plugin", "check plugin quality", "review plugin structure", "find plugin issues", "check best practices", "analyze plugin", or mentions plugin validation, optimization, or quality assurance.
user-invocable: false
version: 0.2.0
---

# Plugin Best Practices

Validate and optimize Claude Code plugins against official standards.

Use only "MUST", "MUST NOT", "SHOULD", "SHOULD NOT", and "MAY" as defined in RFC 2119. Replace REQUIRED/SHALL with MUST, SHALL NOT with MUST NOT, RECOMMENDED with SHOULD, NOT RECOMMENDED with SHOULD NOT, and OPTIONAL with MAY. See `references/rfc-2119.md`.

## Key Validation Rules

**Architecture Guidance**:
- **Prefer Skills over Commands**: Skills are the modern, recommended approach for extending Claude's capabilities. Use Skills for new plugins instead of Commands.
- **Skills vs Agents**: Use Skills for reusable prompts/workflows that run in main conversation context. Use Agents (subagents) for isolated tasks requiring independent context, specific tool restrictions, or specialized system prompts.

**Skills and plugin.json declaration**:

| Config | User invocable | Claude invocable | Declare in |
|--------|----------------|------------------|------------|
| `user-invocable: false` | No | Yes | `skills` (knowledge-type) |
| (default) or `user-invocable: true` | Yes | Yes | `commands` (instruction-type) |
| `disable-model-invocation: true` | Yes | No | `commands` (instruction-type, no auto-invoke) |

- **Knowledge-type** (`user-invocable: false`) → `skills`: Agent-only knowledge; not in / menu.
- **Instruction-type** (default/`user-invocable: true`) → `commands`: User-invokable via /.
- **`disable-model-invocation: true`** → `commands`: User-only; prevents Claude auto-invoke (interactive config, side effects, recursion prevention).

**Critical Checks**:
- Verify skills are < 500 lines with progressive disclosure
- Verify agents have clear descriptions for automatic delegation and single responsibility
- Verify agents include 2-4 `<example>` blocks in description (critical for router)
- Check components use kebab-case naming
- Ensure scripts are executable with shebang and `${CLAUDE_PLUGIN_ROOT}` paths
- Validate no explicit tool invocations (see `references/tool-invocations.md` for patterns)
- **Verify skill references use qualified names**: Use `plugin-name:skill-name` format, not bare `skill-name`
- Use AskUserQuestion tool when user confirmation is needed
- Confirm all paths are relative and start with `./`
- Verify components are at plugin root, not inside `.claude-plugin/`
- Confirm skills/commands explicitly declared in plugin.json (recommended)
- **Verify skill type vs manifest**: `user-invocable: false` → `skills`; `user-invocable: true` (or default) → `commands`.

**Severity Levels**:
- **Critical**: MUST fix before plugin works correctly
- **Warning**: SHOULD fix for best practices compliance
- **Info**: MAY improve (optional improvements)

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

## Skill Writing Styles

Skills fall into two categories with distinct text structures:

**Instruction-Type** (`user-invocable: true`, declared in `commands`):
- **Purpose**: Execute specific tasks (e.g., `/optimize-plugin`)
- **Style**: Second person "You are...", linear workflow (Phase 1-7)
- **Structure**: Single SKILL.md with complete workflow
- **Content**: Executable commands, detailed steps, inline examples

**Knowledge-Type** (`user-invocable: false`, declared in `skills`):
- **Purpose**: Background knowledge for agents (e.g., `plugin-best-practices`)
- **Style**: Imperative/declarative, topic-based sections
- **Structure**: SKILL.md (< 200 lines) + references/ directory
- **Content**: Validation rules, standards, external doc references

See `references/components/skills.md` for detailed text structure guidance.

## Pattern References

For complete pattern templates and examples, see:
- **Skill patterns**: `references/components/skills.md` (structure, frontmatter, text styles)
- **Agent patterns**: `references/components/agents.md` (frontmatter, examples, hooks)
- **Skill references**: Always use qualified names (`plugin-name:skill-name`) in skill loads and agent frontmatter

### Parallel Agent Execution

Launch multiple agents simultaneously when tasks are independent to improve efficiency.

**Request Parallel Execution**:

```markdown
# Explicit parallel request

Launch all agents simultaneously:
- `code-reviewer` agent
- `security-reviewer` agent
- `ux-reviewer` agent

# Or use "in parallel" phrasing

Launch 3 parallel Sonnet agents to review different aspects
```

**Best Practices**:
- **Explicitly mention "parallel" or "simultaneously"** when launching multiple agents
- **Use descriptive style**: "Launch code-reviewer agent"
- **Consolidate results**: Merge findings and resolve conflicts after parallel execution

**Common Pattern**:

```markdown
1. Sequential setup (if needed)
2. Launch specialized reviews in parallel:
   - `code-reviewer` agent — logic correctness
   - `security-reviewer` agent — vulnerabilities
   - `ux-reviewer agent` — usability
3. Consolidate results
```
