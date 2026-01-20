# Agent Design Patterns

Complete guide to creating effective agents for Claude Code plugins.

## 3. Agent Design

**Must Do**

- **Define Triggering Examples:** In the `description` field, you **must** include 2-4 `<example>` blocks showing Context, User input, and Assistant response. This is critical for the router to select your agent.
- **Use Second Person:** Write system prompts addressing the agent directly ("You are an expert...", "Your responsibilities are...").
- **Define Output Format:** Clearly specify exactly how the agent should structure its final response.

**Should Do**

- **Inherit Model:** Use `model: inherit` unless you specifically require the capabilities of Opus or the speed of Haiku.
- **Define Permission Mode:** Use `permissionMode` (e.g., `permissionMode: acceptEdits` for trusted refactoring agents) to streamline user interaction, but default to `permissionMode: default` for safety.
- **Explicitly Control Tools:** Use the `tools` (allowlist) or `disallowedTools` (denylist) fields in frontmatter to strictly define agent capabilities.
- **Use Color Coding:** Assign distinct colors (`blue`, `green`, `red`, etc.) to visually distinguish agents in the UI.
- **Structure Prompts:** Follow the pattern: Role → Core Responsibilities → Analysis Process → Quality Standards → Output Format → Edge Cases.

**Avoid**

- **First Person Prompts:** Never write "I am an agent..." in the system prompt.
- **Vague Triggers:** Avoid generic descriptions like "Helps with code." Be specific: "Use this agent when the user asks to refactor a React component."

## Example: Good Agent Description

```yaml
---
name: code-reviewer
description: Use this agent when you need to review code for adherence to project guidelines and best practices.

<example>
Context: User has made changes to a pull request
user: "Can you review my code changes?"
assistant: "I'll use the Task tool to launch the code-reviewer agent to analyze your changes."
<commentary>
The user is asking for code review, which matches the code-reviewer agent's expertise.
</commentary>
</example>

<example>
Context: User is working on refactoring
user: "Check if my refactoring follows best practices"
assistant: "Let me launch the code-reviewer agent to validate your refactoring."
<commentary>
Code quality validation is exactly what the code-reviewer agent specializes in.
</commentary>
</example>

model: opus
color: green
tools: ["Read", "Grep", "Glob"]
---

You are an expert code reviewer specializing in modern software development best practices.

## Your Core Responsibilities

1. Review code for quality, maintainability, and adherence to standards
2. Identify potential bugs, security issues, and performance problems
3. Provide constructive feedback with specific line references

## Review Process

1. Read the changed files
2. Analyze code patterns and structure
3. Check against best practices
4. Generate detailed review report

## Quality Standards

- Flag critical security vulnerabilities
- Identify code smells and anti-patterns
- Suggest specific improvements with examples
- Provide file:line references for all issues

## Output Format

Return a structured review report with:
- Summary of changes analyzed
- Issues categorized by severity (critical/warning/info)
- Specific recommendations for each issue
- Overall code quality assessment

## Edge Cases

- Empty diffs: Report no changes to review
- Non-code files: Skip or provide limited review
- Large PRs: Focus on critical issues first
```

## Agent Frontmatter Fields

**Required:**
- `name`: Agent identifier (3-50 chars, lowercase, hyphens)
- `description`: Trigger conditions with `<example>` blocks
- `model`: inherit/sonnet/opus/haiku
- `color`: blue/cyan/green/yellow/magenta/red

**Optional:**
- `tools`: Tool allowlist array
- `disallowedTools`: Tool denylist array
- `permissionMode`: default/acceptEdits/acceptAll

## System Prompt Structure

Content after frontmatter becomes the agent's system prompt:

```markdown
You are [role description] specializing in [domain].

**Your Core Responsibilities:**
1. [Primary responsibility]
2. [Secondary responsibility]
3. [Additional responsibilities...]

**[Task Name] Process:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Quality Standards:**
- [Standard 1]
- [Standard 2]

**Output Format:**
[Output format description]

**Edge Cases:**
- [Edge case 1]: [Handling approach]
- [Edge case 2]: [Handling approach]
```

## Triggering Example Format

Each `<example>` block must include:

```yaml
<example>
Context: [Scenario description]
user: "[Exact user message]"
assistant: "[How Claude should respond]"
<commentary>
[Why this agent should be triggered]
</commentary>
</example>
```

**Best practices for examples:**
- Include 2-4 examples minimum
- Show diverse triggering scenarios
- Use realistic user messages
- Explain triggering logic in commentary
- Cover both explicit and implicit requests

## Model Selection

- **inherit**: Use parent context's model (recommended default)
- **haiku**: Fast, lightweight tasks (validation, simple checks)
- **sonnet**: Balanced quality and speed (most code tasks)
- **opus**: Complex reasoning, critical decisions

## Color Coding

Assign meaningful colors:
- **blue**: Analysis and review
- **green**: Validation and testing
- **cyan**: Information gathering
- **yellow**: Warnings and checks
- **magenta**: Generation and creation
- **red**: Critical operations

## Permission Modes

- **default**: Prompt for all tool uses (safest)
- **acceptEdits**: Auto-accept Edit tool (for refactoring agents)
- **acceptAll**: Auto-accept all tools (use sparingly)

## Common Patterns

### Read-Only Analysis Agent

```yaml
---
name: code-analyzer
description: [With examples]
model: sonnet
color: blue
tools: ["Read", "Grep", "Glob"]
---
```

### Code Generation Agent

```yaml
---
name: code-generator
description: [With examples]
model: sonnet
color: magenta
tools: ["Read", "Write", "Edit"]
permissionMode: acceptEdits
---
```

### Fast Validation Agent

```yaml
---
name: quick-validator
description: [With examples]
model: haiku
color: yellow
tools: ["Read", "Bash(test:*)"]
---
```

### Complex Reasoning Agent

```yaml
---
name: architect
description: [With examples]
model: opus
color: cyan
tools: ["Read", "Glob", "Grep", "WebFetch"]
---
```

## Validation Checklist

Before finalizing an agent:

- [ ] Name is 3-50 chars, kebab-case
- [ ] Description includes 2-4 `<example>` blocks
- [ ] Each example has Context, user, assistant, commentary
- [ ] Model field is present (inherit/sonnet/opus/haiku)
- [ ] Color field is present
- [ ] System prompt uses second person
- [ ] Output format is clearly specified
- [ ] Tools are restricted appropriately
- [ ] Edge cases are documented

## Common Mistakes

**Mistake 1: Weak Description**
```yaml
# Bad
description: Helps with code review.

# Good
description: Use this agent when you need to review code for quality and best practices.

<example>
Context: Pull request review
user: "Review my changes"
assistant: "I'll launch the code-reviewer agent"
<commentary>
User is asking for code review
</commentary>
</example>
```

**Mistake 2: Missing Examples**
```yaml
# Bad
description: Use for code analysis.

# Good
description: Use for code analysis.

<example>
[Concrete example showing when to trigger]
</example>

<example>
[Another triggering scenario]
</example>
```

**Mistake 3: First Person Prompt**
```markdown
# Bad
I am an agent that reviews code...

# Good
You are an expert code reviewer who...
```

**Mistake 4: Unrestricted Tools**
```yaml
# Bad
tools: ["Read", "Write", "Edit", "Bash"]  # Too permissive

# Good
tools: ["Read", "Grep", "Glob"]  # Read-only for analysis
```
