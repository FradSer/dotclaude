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

## Exit Codes

| Code | Meaning | Use Case |
|------|---------|----------|
| `0` | Success | Allow operation, silent or with JSON output |
| `1` | Non-blocking error | Allow operation, show warning to user |
| `2` | Blocking error | Deny operation, show error to Claude |

## Best Practices

### Must Do

- **Validate Inputs**: Strictly validate all JSON inputs and sanitize variables to prevent injection
- **Quote Variables**: Always quote bash variables (e.g., `"$CLAUDE_PROJECT_DIR"`) to handle spaces
- **Return Structured JSON**: Use `hookSpecificOutput` schema for LLM-parseable responses
- **Early Exit**: Exit early for non-matching tools/commands to reduce processing
- **Single JSON Parse**: Extract all needed values in one `jq` call, not multiple

### Avoid

- **Plain Text Output**: Claude cannot parse plain text; always use JSON
- **Dead Code**: Remove unused variables and unreachable code paths
- **Missing Context**: Always provide `additionalContext` for remediation guidance
- **Warning Output Without Action**: If exit 0, output is ignored; either enforce or remove the check
- **Blocking Errors for Non-Critical Issues**: Reserve exit 2 for security/correctness, not style

## AI-Native Structured Output

AI-native hooks MUST return structured JSON that Claude can parse and act upon.

### Response Schema

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow" | "deny" | "ask",
    "permissionDecisionReason": "Human-readable explanation",
    "additionalContext": "LLM-friendly guidance for remediation",
    "updatedInput": { }
  }
}
```

### Field Reference

| Field | Events | Purpose |
|-------|--------|---------|
| `permissionDecision` | PreToolUse, PermissionRequest | `allow`, `deny`, or `ask` (prompt user) |
| `permissionDecisionReason` | All | Explanation shown to user |
| `additionalContext` | All | LLM-friendly guidance for remediation |
| `updatedInput` | PreToolUse | Modified tool parameters before execution |
| `systemMessage` | All | Legacy field; prefer structured output above |

### Output Destination

- **Exit 2 (blocking)**: Output to `stderr`
- **Exit 0/1 (non-blocking)**: Output to `stdout`

## Decision Examples

### PreToolUse: Allow

```bash
jq -n '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "allow"
  }
}'
exit 0
```

### PreToolUse: Deny with Guidance

```bash
jq -n --arg reason "Dangerous command blocked" --arg context "Use 'git clean -fd' instead of 'rm -rf'" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $reason,
    additionalContext: $context
  }
}' >&2
exit 2
```

### PreToolUse: Ask User

```bash
jq -n '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "ask",
    permissionDecisionReason: "This operation modifies production files"
  }
}'
exit 0
```

### PermissionRequest: Auto-Approve

```bash
jq -n '{
  hookSpecificOutput: {
    hookEventName: "PermissionRequest",
    decision: {
      behavior: "allow",
      updatedInput: { "autoApprove": true }
    }
  }
}'
exit 0
```

## Performance Patterns

### Single JSON Parse

Parse stdin once and reuse values. Avoid multiple `jq` invocations.

```bash
# BAD: Multiple parses
tool_name=$(echo "$input" | jq -r '.tool_name')
command=$(echo "$input" | jq -r '.tool_input.command')
file_path=$(echo "$input" | jq -r '.tool_input.file_path')

# GOOD: Single parse with variable capture
read -r tool_name command file_path < <(
  echo "$input" | jq -r '[.tool_name, .tool_input.command, .tool_input.file_path] | @tsv'
)
```

### Early Exit Pattern

Exit early for non-matching conditions to reduce processing.

```bash
# Early exits for non-matching tools
if [[ "$tool_name" != "Bash" ]]; then
  exit 0
fi

# Skip patterns that don't need validation
if [[ ! "$command" =~ git[[:space:]]+commit ]]; then
  exit 0
fi
```

## LLM-Friendly Error Messages

Structure error messages with four components:

1. **What failed**: Clear, specific error title
2. **Why it failed**: Root cause explanation
3. **How to fix**: Actionable remediation steps
4. **Example**: Correct format demonstration

```bash
# BAD: Vague error
errors+=("Invalid commit message")

# GOOD: Comprehensive guidance
errors+=("Commit title must follow conventional format")
errors+=("Expected: <type>[scope]: <description>")
errors+=("Example: feat(auth): add oauth login")
```

### Additional Context Pattern

Provide structured remediation guidance for LLM understanding.

```bash
jq -n \
  --arg title "$title_line" \
  --arg errors "$error_list" \
  --arg context "To fix: 1) Use lowercase description, 2) Add body with bullets, 3) Include Co-Authored-By footer" \
  '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: ("Commit validation failed: " + $title),
      additionalContext: ($errors + "\n\n" + $context)
    }
  }' >&2
exit 2
```

## Dead Code Elimination

Remove unused variables and dead code paths to improve maintainability.

```bash
# BAD: Unused warning collection
warnings=()
warnings+=("Non-critical issue")
# warnings never used - dead code since exit 0 ignores output

# GOOD: Either use or remove
# Option 1: Remove entirely
# Option 2: Integrate into additionalContext
if [[ ${#warnings[@]} -gt 0 ]]; then
  additional_context=$(printf "- %s\n" "${warnings[@]}")
fi
```

## Input Validation

### JSON Validation

Always validate JSON input before parsing.

```bash
input=$(cat)

# Validate JSON structure
if ! echo "$input" | jq -e . >/dev/null 2>&1; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "allow",
      permissionDecisionReason: "Invalid JSON input, allowing operation"
    }
  }'
  exit 1
fi
```

### Field Existence

Check for required fields before accessing with defaults.

```bash
# Use jq's default values for safety
tool_name=$(echo "$input" | jq -r '.tool_name // empty')

# Exit gracefully if critical fields missing
if [[ -z "$tool_name" ]]; then
  exit 0
fi
```

### Sanitization

Prevent injection by quoting all variables.

```bash
# BAD: Unquoted variable
if [[ $command =~ dangerous ]]; then
  echo "Blocked: $command"
fi

# GOOD: Quoted variable
if [[ "$command" =~ dangerous ]]; then
  echo "Blocked: $command"
fi
```

## Security Considerations

### Fail-Open Pattern

Hooks run with user permissions. Validate before denying, not before allowing.

```bash
# Fail-open for safety - if validation cannot run, allow the operation
if ! can_validate; then
  exit 0
fi

# Only deny when certain
if is_dangerous; then
  deny_with_reason
  exit 2
fi
```

### Timeout Protection

Set timeouts for external operations.

```bash
# Use timeout for network/file operations
if ! timeout 5 git rev-parse --git-dir >/dev/null 2>&1; then
  exit 0  # Not a git repo, skip validation
fi
```

### Path Validation

Validate file paths before operations.

```bash
# Resolve and validate paths
resolved_path=$(realpath -q "$file_path" 2>/dev/null || echo "$file_path")

# Block access to sensitive paths
case "$resolved_path" in
  */.git/*|*/.env|*/secrets/*)
    jq -n --arg path "$resolved_path" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: ("Protected path: " + $path)
      }
    }' >&2
    exit 2
    ;;
esac
```

## Complete AI-Native Template

```bash
#!/bin/bash
# PreToolUse hook: [Description]
# Runs before [event] to [purpose]

set -euo pipefail

# Read and validate input
input=$(cat)
if ! echo "$input" | jq -e . >/dev/null 2>&1; then
  exit 0  # Fail-open on invalid input
fi

# Single-pass extraction
read -r tool_name command < <(
  echo "$input" | jq -r '[.tool_name // "", .tool_input.command // ""] | @tsv'
)

# Early exit for non-matching tools
if [[ "$tool_name" != "Bash" ]]; then
  exit 0
fi

# Early exit for non-matching commands
if [[ ! "$command" =~ target_pattern ]]; then
  exit 0
fi

# Validation logic
errors=()

# ... validation checks ...

# Output based on results
if [[ ${#errors[@]} -gt 0 ]]; then
  error_list=$(printf "  - %s\n" "${errors[@]}")
  jq -n \
    --arg reason "Validation failed" \
    --arg context "$error_list" \
    '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $reason,
        additionalContext: $context
      }
    }' >&2
  exit 2
fi

# Silent success
exit 0
```

## Anti-Patterns

### Plain Text Output

```bash
# BAD: Plain text, Claude cannot parse
echo "Error: Invalid commit format"
exit 2

# GOOD: Structured JSON
jq -n --arg msg "Invalid commit format" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $msg
  }
}' >&2
exit 2
```

### Missing Remediation Context

```bash
# BAD: No guidance for remediation
errors+=("Format error")

# GOOD: Actionable guidance
errors+=("Format error: missing type prefix")
errors+=("Expected: feat|fix|docs|refactor|test|chore")
errors+=("Example: feat(auth): add login")
```

### Warnings That Vanish

```bash
# BAD: Warnings output but exit 0 - user never sees them
warnings+=("Non-ideal format")
echo "Warnings: $warnings"
exit 0

# GOOD: Either enforce or remove
# Option 1: Make it an error
errors+=("Non-ideal format is not allowed")

# Option 2: Remove the check entirely
```

## Testing Hooks

### Manual Testing

```bash
# Test hook directly with sample input
echo '{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}' | \
  ./hooks/validate-command.sh

# Expected: exit 2 with deny JSON on stderr
```

### Debug Mode

Add debug output controlled by environment variable.

```bash
debug_log() {
  if [[ "${DEBUG_HOOK:-}" == "1" ]]; then
    echo "[DEBUG] $*" >&2
  fi
}

debug_log "Processing tool: $tool_name"
```

## Summary Checklist

- [ ] Structured JSON output with `hookSpecificOutput`
- [ ] `permissionDecision` for PreToolUse/PermissionRequest
- [ ] `additionalContext` for LLM guidance
- [ ] Single JSON parse with variable capture
- [ ] Early exit for non-matching conditions
- [ ] No dead code (unused variables, unreachable paths)
- [ ] Input validation with graceful fallback
- [ ] All bash variables quoted
- [ ] Fail-open on validation errors (except for security)
- [ ] Test with sample inputs