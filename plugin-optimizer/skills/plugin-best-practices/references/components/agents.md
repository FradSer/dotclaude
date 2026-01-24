# Agents Component Reference

Plugins can provide specialized subagents for specific tasks that Claude can invoke automatically when appropriate.

- **Location**: `agents/` (plugin root)
- **Format**: YAML frontmatter + Markdown body (system prompt)

## Recommended agent structure (matches plugin agents)

```markdown
---
name: code-reviewer
description: Use this agent when reviewing code changes for quality and security. Trigger when user asks "review my changes", "do a code review", or after a refactor. Examples:

<example>
Context: User asks for code review
user: "Can you review this?"
assistant: "I'll use the code-reviewer agent to review the changes."
<commentary>
Direct review request should route to this agent.
</commentary>
</example>

model: inherit
color: blue
tools: ["Read", "Glob", "Grep", "Bash"]
---

You are a senior code reviewer.

## Core Responsibilities

1. Identify critical issues first (security, correctness)
2. Flag warnings (maintainability, performance)
3. Provide specific, actionable suggestions

## Output Format

Output format:
## Critical issues
- ...
## Warnings
- ...
## Suggestions
- ...
```

## Frontmatter

### Official subagent fields

- **Required**: `name`, `description`
- **Optional**: `tools`, `disallowedTools`, `model`, `permissionMode`, `skills`, `hooks`

### Plugin conventions (best-practice extensions)

- **`color`**: UI hint for agent category.
- **Tool selectors / matchers (example: `Bash(test:*)`)**: Some setups allow constrained tool usage encoded in `tools`. If unsupported, enforce the constraint via `hooks`.

### Color Coding

- `blue`: Analysis/review
- `green`: Validation/testing
- `cyan`: Information gathering
- `yellow`: Warnings/checks
- `magenta`: Generation/creation
- `red`: Critical operations

## Hooks (define hooks for subagents)

Two ways to configure hooks:

- **Frontmatter hooks**: active only while that subagent runs.
- **`settings.json` hooks**: run in the main session on subagent start/stop.

### Hooks in subagent frontmatter

| Event | Matcher input | When it fires |
| --- | --- | --- |
| `PreToolUse` | Tool name | Before the subagent uses a tool |
| `PostToolUse` | Tool name | After the subagent uses a tool |
| `Stop` | (none) | When the subagent finishes |

```markdown
---
name: code-reviewer
description: Review code changes with automatic linting.
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-command.sh $TOOL_INPUT"
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "./scripts/run-linter.sh"
---
```

Note: `Stop` hooks in frontmatter are automatically converted to `SubagentStop` events.

### Project-level hooks (`settings.json`)

| Event | Matcher input | When it fires |
| --- | --- | --- |
| `SubagentStart` | Agent type name | When a subagent begins execution |
| `SubagentStop` | Agent type name | When a subagent completes |

```json
{
  "hooks": {
    "SubagentStart": [
      {
        "matcher": "db-agent",
        "hooks": [
          { "type": "command", "command": "./scripts/setup-db-connection.sh" }
        ]
      }
    ],
    "SubagentStop": [
      {
        "matcher": "db-agent",
        "hooks": [
          { "type": "command", "command": "./scripts/cleanup-db-connection.sh" }
        ]
      }
    ]
  }
}
```

## Patterns

```markdown
---
name: analyzer
description: Read-only analysis specialist. Trigger for "analyze", "inspect", "explain how this works". Examples:

color: blue
tools: ["Read", "Glob", "Grep", "Bash"]
model: inherit
---
```

```markdown
---
name: generator
description: Generate/refactor code with minimal edits. Trigger when user asks to "implement", "add feature", or "refactor". Examples:

color: magenta
tools: ["Read", "Write", "Edit"]
model: sonnet
permissionMode: acceptEdits
---
```

```markdown
---
name: validator
description: Fast validation/checks. Trigger when user asks to "run tests", "lint", or "validate". Examples:

color: yellow
tools: ["Read", "Bash(test:*)"]
model: haiku
---
```

```markdown
---
name: db-reader
description: Execute read-only database queries.
tools: ["Bash"]
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-readonly-query.sh"
---
```

## Best practices

- **`description`** SHOULD say *when to use* (routing triggers).
- **Include one example**: Put a single `<example>` block inside `description` (as shown in plugin agent files) to make routing unambiguous.
- **Minimize `tools`**; add `Write/Edit` only when required.
- **Keep prompts short** and define a stable output format.
- **Document conventions** if you use `color` or tool selectors.

## Notes (plugin scope)

- Plugin agents show up in `/agents`.
- If the same `name` exists in multiple scopes, higher-priority scopes override plugin scope.
