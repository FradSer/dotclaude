# Hooks Component Reference

Plugins provide event handlers that respond to Claude Code events automatically.

**Location**: `hooks/hooks.json` in plugin root, or inline in plugin.json

**Format**: JSON configuration with event matchers and actions

## Hook configuration

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format-code.sh"
          }
        ]
      }
    ]
  }
}
```

## Available events

* `PreToolUse`: Before Claude uses any tool
* `PostToolUse`: After Claude successfully uses any tool
* `PostToolUseFailure`: After Claude tool execution fails
* `PermissionRequest`: When a permission dialog is shown
* `UserPromptSubmit`: When user submits a prompt
* `Notification`: When Claude Code sends notifications
* `Stop`: When Claude attempts to stop
* `SubagentStart`: When a subagent is started
* `SubagentStop`: When a subagent attempts to stop
* `SessionStart`: At the beginning of sessions
* `SessionEnd`: At the end of sessions
* `PreCompact`: Before conversation history is compacted

## Hook types

* `command`: Execute shell commands or scripts
* `prompt`: Evaluate a prompt with an LLM (uses `$ARGUMENTS` placeholder for context)
* `agent`: Run an agentic verifier with tools for complex verification tasks

## Best Practices

### Must Do
- **Validate Inputs**: In bash hooks, strictly validate all JSON inputs and sanitize variables to prevent injection.
- **Quote Variables**: Always quote bash variables (e.g., `"$CLAUDE_PROJECT_DIR"`) to handle spaces in paths.
- **Return Valid JSON**: Ensure hooks output valid JSON structures for decisions (`allow`/`deny`) and messages.

### Avoid
- **Blocking Errors**: Avoid returning exit code `2` (Blocking Error) unless the operation is critical and MUST be stopped. Use `1` (Non-blocking) or `0` (Success) otherwise.
- **Modifying Global State**: Avoid hooks that change the environment unexpectedly, as execution order is not guaranteed.

## Implementation Reference

### Exit Codes
- `0`: Success (use JSON output for allow/deny)
- `1`: Non-blocking error (allow, log warning)
- `2`: Blocking error (deny operation)

### Bash Hook Template
```bash
#!/bin/bash
INPUT=$(cat)

# Validate JSON
if ! echo "$INPUT" | jq . >/dev/null 2>&1; then
  echo '{"allow": true, "message": "Invalid input"}'
  exit 1
fi

# Extract and validate
TOOL=$(echo "$INPUT" | jq -r '.toolName // empty')
if [ -z "$TOOL" ]; then
  echo '{"allow": true, "message": "Missing tool"}'
  exit 1
fi

# Perform check
if [[ condition ]]; then
  echo '{"allow": false, "message": "⚠️ Denied"}'
  exit 0
fi

echo '{"allow": true}'
exit 0
```