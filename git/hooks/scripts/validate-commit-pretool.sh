#!/bin/bash
# PreToolUse hook: Validate conventional commit message format BEFORE execution
# Runs before git commit commands to prevent invalid commits from being created

set -euo pipefail

# Read input from stdin
input=$(cat)

# Extract command from tool input
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Only validate git commit commands
if [[ -z "$command" ]] || ! [[ "$command" =~ git[[:space:]]+commit ]]; then
  exit 0
fi

# Skip if this is an amend or other special commit
if [[ "$command" =~ --amend ]] || [[ "$command" =~ --fixup ]] || [[ "$command" =~ --squash ]]; then
  exit 0
fi

# Extract commit message from command
# Handles multiple formats:
# 1. git commit -m "message"
# 2. git commit -m 'message'
# 3. git commit -m "$(cat <<'EOF'...)"
commit_msg=""

# Try double quotes
if [[ "$command" =~ -m[[:space:]]+\"([^\"]+)\" ]]; then
  commit_msg="${BASH_REMATCH[1]}"
# Try single quotes
elif [[ "$command" =~ -m[[:space:]]+\'([^\']+)\' ]]; then
  commit_msg="${BASH_REMATCH[1]}"
# Try unquoted (simple case)
elif [[ "$command" =~ -m[[:space:]]+([^[:space:]\"\']+) ]]; then
  commit_msg="${BASH_REMATCH[1]}"
fi

# Handle heredoc style: git commit -m "$(cat <<'EOF'..."
if [[ -z "$commit_msg" ]] && [[ "$command" =~ cat[[:space:]]+\<\<[[:space:]]*[\'\"]?EOF ]]; then
  # Extract the first line of the heredoc content
  commit_msg=$(echo "$command" | sed -n "/<<.*EOF/,/^[[:space:]]*EOF/p" | sed '1d;$d' | head -1 | sed 's/^[[:space:]]*//')
fi

# If we couldn't extract the message, skip validation
# (might be using -F file or other method)
if [[ -z "$commit_msg" ]]; then
  exit 0
fi

# Get just the title line (first line)
title_line=$(echo "$commit_msg" | head -1)

# Validation results
errors=()
warnings=()

# Valid types (conventional commits standard)
valid_types="feat|fix|docs|refactor|perf|test|chore|build|ci|style"

# 1. Check format: <type>[optional scope][!]: <description>
if ! [[ "$title_line" =~ ^($valid_types)(\([a-z0-9_-]+\))?!?:[[:space:]].+ ]]; then
  errors+=("Invalid format. Must be: <type>[scope]: <description>")
  errors+=("Valid types: feat, fix, docs, refactor, perf, test, chore, build, ci, style")
  errors+=("Example: feat(auth): add login validation")
fi

# 2. Check for uppercase in description (after the colon)
if [[ "$title_line" =~ : ]]; then
  description=$(echo "$title_line" | sed 's/^[^:]*:[[:space:]]*//')
  if [[ "$description" =~ [A-Z] ]]; then
    errors+=("Description must be all lowercase (found uppercase)")
  fi
fi

# 3. Check length (< 50 chars for title)
title_length=${#title_line}
if [[ $title_length -ge 50 ]]; then
  errors+=("Title must be <50 characters (current: $title_length)")
fi

# 4. Check for period at end
if [[ "$title_line" =~ \.$ ]]; then
  errors+=("Title should not end with a period")
fi

# 5. Check for imperative mood (warn on common past tense patterns)
if [[ "$title_line" =~ :[[:space:]]+(added|removed|updated|fixed|changed|created|deleted|modified)[[:space:]] ]]; then
  warnings+=("Use imperative mood: 'add' not 'added', 'fix' not 'fixed'")
fi

# 6. Check that description exists and is not empty
if [[ "$title_line" =~ :[[:space:]]*$ ]]; then
  errors+=("Description cannot be empty")
fi

# Output results and block execution if errors found
if [[ ${#errors[@]} -gt 0 ]]; then
  error_list=$(printf "  - %s\n" "${errors[@]}")
  warning_list=""
  if [[ ${#warnings[@]} -gt 0 ]]; then
    warning_list=$(printf "\n\nWarnings:\n  - %s" "${warnings[@]}")
  fi

  jq -n --arg title "$title_line" --arg errors "$error_list" --arg warnings "$warning_list" '{
    systemMessage: ("VALIDATION FAILED: Conventional commit format error\n\nCommit message:\n  \"" + $title + "\"\n\nErrors:\n" + $errors + $warnings + "\n\nRequired format: <type>[scope]: <description>\n   Example: feat(auth): add login validation\n   - Use lowercase in description\n   - Keep title under 50 characters\n   - Use imperative mood (add, fix, update)")
  }' >&2
  exit 2
elif [[ ${#warnings[@]} -gt 0 ]]; then
  warning_list=$(printf "  - %s\n" "${warnings[@]}")
  jq -n --arg title "$title_line" --arg warnings "$warning_list" '{
    systemMessage: ("WARNING: Commit message has warnings\n  \"" + $title + "\"\n\nWarnings:\n" + $warnings)
  }'
  exit 0
else
  # Silent success - no need to clutter output for valid commits
  exit 0
fi
