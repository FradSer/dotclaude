# Get started with Claude Code hooks

Claude Code hooks are user-defined shell commands that execute at specific points in Claude Code's lifecycle. They provide deterministic control, ensuring certain actions always occur rather than relying on the LLM's discretion.

## Hook Events Overview
*   **PreToolUse**: Runs before tool calls (can block them).
*   **PermissionRequest**: Runs during permission dialogs (can allow/deny).
*   **PostToolUse**: Runs after tool calls complete.
*   **UserPromptSubmit**: Runs when the user submits a prompt.
*   **Notification**: Runs when Claude Code sends notifications.
*   **Stop / SubagentStop**: Runs when Claude or a subagent finishes responding.
*   **SessionStart / SessionEnd**: Runs at the beginning or end of a session.
*   **PreCompact**: Runs before a compact operation.

## Quickstart: Logging Bash Commands
1.  **Prerequisites**: Install `jq`.
2.  **Configuration**: Run `/hooks` and select `PreToolUse`.
3.  **Matcher**: Add a matcher for `Bash`.
4.  **Command**: Add the following command:
    ```bash
    jq -r '"\(.tool_input.command) - \(.tool_input.description // "No description")"' >> ~/.claude/bash-command-log.txt
    ```
5.  **Save**: Select `User settings` to apply this globally.

## Implementation Examples

### Code Formatting (PostToolUse)
Automatically format TypeScript files using Prettier after an edit:
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | { read file_path; if echo \"$file_path\" | grep -q '\\.ts$'; then npx prettier --write \"$file_path\"; fi; }"
          }
        ]
      }
    ]
  }
}
```

### File Protection (PreToolUse)
Block modifications to sensitive files by exiting with a non-zero code (e.g., exit code 2):
```bash
python3 -c "import json, sys; data=json.load(sys.stdin); path=data.get('tool_input',{}).get('file_path',''); sys.exit(2 if any(p in path for p in ['.env', 'package-lock.json', '.git/']) else 0)"
```

### Custom Notifications
Trigger a desktop notification when Claude awaits input:
```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "notify-send 'Claude Code' 'Awaiting your input'"
          }
        ]
      }
    ]
  }
}
```

## Security Considerations
Hooks run automatically with your current environment's credentials. Always review hook implementations before registration to prevent data exfiltration or unauthorized system changes. For more details, refer to the [Hooks reference documentation](/docs/en/hooks).