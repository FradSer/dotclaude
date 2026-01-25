# Agents Component Reference

Plugins can provide specialized subagents for specific tasks that Claude can invoke automatically when appropriate.

- **Location**: `agents/` (plugin root)
- **Format**: YAML frontmatter + Markdown body (system prompt)

## Recommended agent structure (matches plugin agents)

Use this template when you need the canonical agent frontmatter and system prompt structure. See `${CLAUDE_PLUGIN_ROOT}/examples/agent.md` for the complete agent template.

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

## Best practices

- **`description`** SHOULD say *when to use* (routing triggers).
- **Include one example**: Put a single `<example>` block inside `description` (as shown in plugin agent files) to make routing unambiguous.
- **Minimize `tools`**; add `Write/Edit` only when required.
- **Keep prompts short** and define a stable output format.
- **Document conventions** if you use `color` or tool selectors.

## Notes (plugin scope)

- Plugin agents show up in `/agents`.
- If the same `name` exists in multiple scopes, higher-priority scopes override plugin scope.
