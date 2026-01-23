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

### Parallel Agent Execution

When multiple independent tasks can be performed simultaneously, launch agents in parallel to improve efficiency and reduce total execution time.

**When to Use Parallel Execution**:
- Multiple independent analysis tasks (e.g., code review, security check, UX review)
- Batch processing of unrelated files or components
- Gathering different types of information simultaneously
- Tasks that don't depend on each other's results

**How to Request Parallel Execution**:

```markdown
# Explicit parallel request (recommended)

Launch all agents simultaneously:
- code-reviewer agent
- security-reviewer agent
- ux-reviewer agent

# Or use "in parallel" phrasing

Launch 3 parallel Sonnet agents to review different aspects:
- code-reviewer agent for logic correctness
- security-reviewer agent for vulnerabilities
- ux-reviewer agent for usability
```

**Sequential vs Parallel**:

```markdown
# Sequential (one at a time, when dependencies exist)

1. Use a Haiku agent to check eligibility
2. After it returns, use another Haiku agent to get file list
3. Then launch 5 parallel Sonnet agents for review

# Parallel (independent tasks)

Launch all agents simultaneously:
- code-reviewer agent
- pr-test-analyzer agent
- silent-failure-hunter agent
```

**Best Practices**:
- **Explicitly mention "parallel" or "simultaneously"** when launching multiple agents at once
- **Use descriptive style**: "Launch code-reviewer agent", "Use security-reviewer agent" (preferred over explicit Task tool calls)
- **Specify model tier**: "Use a Haiku agent" (fast), "launch Sonnet agents" (quality), "use Opus agent" (complex)
- **Describe return value**: "ask the agent to return a summary", "agent should return a list of issues"
- **Only use explicit Task tool** when providing full JSON structure for general-purpose agents
- **Consolidate results**: After parallel execution, merge findings and resolve conflicts before presenting final output

**Example: Hierarchical Review Pattern**:

```markdown
## Requirements

1. Perform a leadership assessment with @tech-lead-reviewer to scope architectural risk
2. Launch the required specialized reviews in parallel via the Task tool:
   - @code-reviewer — logic correctness, tests, error handling
   - @security-reviewer — authentication, data protection, validation
   - @ux-reviewer — usability and accessibility
3. Collect outcomes, resolve conflicting feedback, and present consolidated report
```

**Common Patterns**:
- **Multi-stage with parallel middle stage**: Sequential setup → Parallel execution → Sequential consolidation
- **Batch parallel processing**: Launch multiple agents of the same type for different files/components
- **Specialized parallel reviews**: Different agents focus on different aspects (code, security, UX) simultaneously
