# Hook Usage Patterns

Complete guide to using hooks effectively in Claude Code plugins.

## 5. Hook Usage

**Must Do**

- **Validate Inputs:** In bash hooks, strictly validate all JSON inputs and sanitize variables to prevent injection attacks.
- **Quote Variables:** Always quote bash variables (e.g., `"$CLAUDE_PROJECT_DIR"`) to handle spaces in paths correctly.
- **Return Valid JSON:** Ensure your hooks output valid JSON structures for decisions (`allow`/`deny`) and messages.

**Should Do**

- **Use Prompt Hooks for Logic:** Use `type: "prompt"` (LLM-based) for complex, context-aware decisions (e.g., "Is this code safe?").
- **Use Command Hooks for Speed:** Use `type: "command"` (Bash-based) for deterministic, fast checks (e.g., linting, file existence).
- **Set Timeouts:** Define explicit `timeout` values (default is 60s for commands, 30s for prompts).

**Avoid**

- **Blocking Errors:** Avoid returning exit code `2` (Blocking Error) unless the operation is critical and must be stopped. Use exit code `1` (Non-blocking) or `0` (Success) for warnings.
- **Modifying Global State:** Avoid hooks that change the environment unexpectedly, as they run in parallel and order is not guaranteed.

## Hook Configuration (hooks.json)

**Location:** `hooks/hooks.json`

**Basic Structure:**

```json
{
  "hooks": [
    {
      "name": "hook-name",
      "event": "PreToolUse",
      "command": "${CLAUDE_PLUGIN_ROOT}/hooks/pretooluse.sh",
      "enabled": true,
      "timeout": 30
    }
  ]
}
```

## Hook Types

### Command-Based Hooks

Fast, deterministic checks using bash scripts:

```json
{
  "name": "validate-git-commit",
  "event": "PreToolUse",
  "type": "command",
  "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/validate-commit.sh",
  "timeout": 10
}
```

**Use for:**
- File existence checks
- Syntax validation
- Linting
- Pattern matching
- Quick deterministic decisions

### Prompt-Based Hooks

Complex, context-aware decisions using LLM:

```json
{
  "name": "check-code-safety",
  "event": "PreToolUse",
  "type": "prompt",
  "prompt": "Analyze this code change for security issues...",
  "timeout": 30
}
```

**Use for:**
- Security analysis
- Code quality assessment
- Complex business logic
- Context-dependent decisions
- Natural language understanding

## Hook Events

**Available events:**
- `PreToolUse` - Before tool execution (can allow/deny)
- `PostToolUse` - After tool execution (cannot change result)
- `PermissionRequest` - During permission dialogs (can allow/deny)
- `Stop` - When conversation stops
- `SubagentStop` - When subagent completes
- `SessionStart` - When session begins
- `SessionEnd` - When session ends
- `UserPromptSubmit` - When user submits input
- `PreCompact` - Before context compaction
- `Notification` - On notifications

## Hook Script Best Practices

### Bash Hook Template

```bash
#!/bin/bash

# Read JSON input
INPUT=$(cat)

# Validate JSON
if ! echo "$INPUT" | jq . >/dev/null 2>&1; then
  echo '{"allow": true, "message": "Invalid JSON input"}'
  exit 1
fi

# Extract fields
TOOL_NAME=$(echo "$INPUT" | jq -r '.toolName // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.parameters.file_path // empty')

# Validate required fields
if [ -z "$TOOL_NAME" ]; then
  echo '{"allow": true, "message": "Missing tool name"}'
  exit 1
fi

# Perform check
if [ "$TOOL_NAME" = "Write" ] && [[ "$FILE_PATH" == *.prod.* ]]; then
  echo '{"allow": false, "message": "⚠️ Cannot write to production files"}'
  exit 0
fi

# Allow by default
echo '{"allow": true}'
exit 0
```

### JSON Output Format

**Allow with no message:**
```json
{"allow": true}
```

**Deny with message:**
```json
{"allow": false, "message": "⚠️ Reason for denial"}
```

**Allow with warning:**
```json
{"allow": true, "message": "ℹ️ Warning message"}
```

### Exit Codes

- `0`: Success (allow/deny based on JSON output)
- `1`: Non-blocking error (allow operation, log error)
- `2`: Blocking error (deny operation)

## Portable Paths in Hooks

Always use `${CLAUDE_PLUGIN_ROOT}`:

```json
{
  "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/validate.sh"
}
```

**Never use:**
- Hardcoded absolute paths: `/Users/name/plugins/my-plugin/hooks/script.sh`
- Relative paths: `./hooks/script.sh`
- Home directory: `~/plugins/my-plugin/hooks/script.sh`

## Security Considerations

### Input Validation

```bash
# Always validate and sanitize inputs
TOOL_NAME=$(echo "$INPUT" | jq -r '.toolName // empty' | sed 's/[^a-zA-Z0-9_-]//g')

# Quote all variables
if [ -f "$FILE_PATH" ]; then
  # Process file
fi

# Validate expected values
if [[ ! "$TOOL_NAME" =~ ^(Read|Write|Edit)$ ]]; then
  echo '{"allow": true, "message": "Unknown tool"}'
  exit 1
fi
```

### Prevent Injection

```bash
# Bad - Vulnerable to injection
eval "$COMMAND"
sh -c "$USER_INPUT"

# Good - Use validated, quoted variables
case "$TOOL_NAME" in
  "Write")
    # Handle Write tool
    ;;
  "Edit")
    # Handle Edit tool
    ;;
esac
```

## Common Hook Patterns

### Prevent Writes to Certain Files

```bash
#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.parameters.file_path // empty')

if [[ "$FILE_PATH" == *.env ]] || [[ "$FILE_PATH" == *credentials* ]]; then
  echo '{"allow": false, "message": "⚠️ Cannot modify sensitive files"}'
  exit 0
fi

echo '{"allow": true}'
exit 0
```

### Validate Git Commit Messages

```bash
#!/bin/bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.parameters.command // empty')

if [[ "$COMMAND" == git\ commit* ]]; then
  # Extract commit message
  if [[ "$COMMAND" =~ -m[[:space:]]\"([^\"]+)\" ]]; then
    MSG="${BASH_REMATCH[1]}"

    # Validate conventional commit format
    if ! [[ "$MSG" =~ ^(feat|fix|docs|chore|refactor|test|ci):\ .{3,} ]]; then
      echo '{"allow": false, "message": "⚠️ Commit message must follow conventional commits format"}'
      exit 0
    fi
  fi
fi

echo '{"allow": true}'
exit 0
```

### Check Code Style Before Edit

```bash
#!/bin/bash
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.toolName // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.parameters.file_path // empty')

if [ "$TOOL_NAME" = "Edit" ] && [[ "$FILE_PATH" == *.js ]]; then
  # Run eslint on file
  if ! eslint "$FILE_PATH" --quiet 2>/dev/null; then
    echo '{"allow": true, "message": "⚠️ File has linting errors. Consider fixing before editing."}'
    exit 0
  fi
fi

echo '{"allow": true}'
exit 0
```

### Log Tool Usage

```bash
#!/bin/bash
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.toolName // empty')

# Log to file
echo "$(date): $TOOL_NAME used" >> "${CLAUDE_PROJECT_DIR}/.claude/tool-usage.log"

# Always allow
echo '{"allow": true}'
exit 0
```

## Timeout Configuration

Set appropriate timeouts based on hook complexity:

```json
{
  "hooks": [
    {
      "name": "quick-check",
      "type": "command",
      "timeout": 5
    },
    {
      "name": "lint-analysis",
      "type": "command",
      "timeout": 30
    },
    {
      "name": "security-scan",
      "type": "prompt",
      "timeout": 60
    }
  ]
}
```

**Guidelines:**
- Simple checks: 5-10 seconds
- Linting/validation: 20-30 seconds
- Complex analysis: 30-60 seconds
- Never exceed 60 seconds for commands

## Testing Hooks

### Manual Testing

```bash
# Test hook script directly
echo '{"toolName": "Write", "parameters": {"file_path": "test.env"}}' | bash hooks/scripts/validate.sh

# Expected output:
# {"allow": false, "message": "⚠️ Cannot modify sensitive files"}
```

### Debug Mode

Use `claude --debug` to see hook execution:

```bash
claude --debug
# Shows:
# - Which hooks triggered
# - Hook input/output
# - Execution time
# - Errors
```

## Hook .local.md Pattern

Alternative to JSON configuration:

```yaml
---
name: warn-console-log
enabled: true
event: file
pattern: console\.log\(
action: warn
---

🔍 **Console.log detected**

You're adding a console.log statement. Please consider:
- Is this for debugging or should it be proper logging?
- Will this ship to production?
- Should this use a logging library instead?
```

## Common Mistakes

**Mistake 1: Unquoted Variables**
```bash
# Bad
if [ -f $FILE_PATH ]; then

# Good
if [ -f "$FILE_PATH" ]; then
```

**Mistake 2: No Input Validation**
```bash
# Bad
TOOL_NAME=$(echo "$INPUT" | jq -r '.toolName')
# Uses value directly without validation

# Good
TOOL_NAME=$(echo "$INPUT" | jq -r '.toolName // empty')
if [ -z "$TOOL_NAME" ]; then
  echo '{"allow": true, "message": "Missing tool name"}'
  exit 1
fi
```

**Mistake 3: Hardcoded Paths**
```json
// Bad
"command": "/Users/myuser/plugins/my-plugin/hooks/script.sh"

// Good
"command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/script.sh"
```

**Mistake 4: Invalid JSON Output**
```bash
# Bad
echo "Error: Invalid input"  # Not JSON

# Good
echo '{"allow": true, "message": "Error: Invalid input"}'
```

## Validation Checklist

Before deploying hooks:

- [ ] All variables are quoted
- [ ] JSON input is validated
- [ ] Exit codes are appropriate
- [ ] JSON output is valid
- [ ] Timeouts are set
- [ ] Paths use ${CLAUDE_PLUGIN_ROOT}
- [ ] Security: No eval, no injection risks
- [ ] Tested with sample inputs
- [ ] Error handling is complete
- [ ] Messages are user-friendly

## Additional Resources

For more hook patterns and advanced usage, see:
- Hook development skill documentation
- Official plugin examples
- Security best practices guide
