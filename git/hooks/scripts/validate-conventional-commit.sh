#!/bin/bash
# PostToolUse hook: Validate conventional commit message format
# Runs after git commit commands to check message compliance

set -euo pipefail

# Read input from stdin
input=$(cat)

# Extract command from tool input
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Only validate git commit commands
if [[ -z "$command" ]] || ! [[ "$command" =~ git[[:space:]]+commit ]]; then
  exit 0
fi

# Extract tool result to check if commit succeeded
tool_result=$(echo "$input" | jq -r '.tool_result // empty')

# Skip if commit failed (let git's error message stand)
if [[ "$tool_result" == *"error:"* ]] || [[ "$tool_result" == *"fatal:"* ]]; then
  exit 0
fi

# Extract commit message from command
# Handles: git commit -m "message", git commit -m 'message'
commit_msg=""

if [[ "$command" =~ -m[[:space:]]+\"([^\"]+)\" ]]; then
  commit_msg="${BASH_REMATCH[1]}"
elif [[ "$command" =~ -m[[:space:]]+\'([^\']+)\' ]]; then
  commit_msg="${BASH_REMATCH[1]}"
elif [[ "$command" =~ -m[[:space:]]+([^[:space:]\"\']+) ]]; then
  commit_msg="${BASH_REMATCH[1]}"
fi

# Handle heredoc style: git commit -m "$(cat <<'EOF'..."
if [[ -z "$commit_msg" ]] && [[ "$command" =~ cat[[:space:]]+\<\<[[:space:]]*[\'\"]?EOF ]]; then
  commit_msg=$(echo "$command" | sed -n "/<<.*EOF/,/EOF/p" | sed '1d;$d' | head -1)
fi

# If we couldn't extract the message, skip validation
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
  errors+=("Format must be: <type>[scope]: <description>")
  errors+=("Valid types: feat, fix, docs, refactor, perf, test, chore, build, ci, style")
fi

# 2. Check for uppercase in description (after the colon)
description=$(echo "$title_line" | sed 's/^[^:]*:[[:space:]]*//')
if [[ "$description" =~ [A-Z] ]]; then
  errors+=("Description must be all lowercase (found uppercase characters)")
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
if [[ "$description" =~ ^(added|removed|updated|fixed|changed|created|deleted|modified)[[:space:]] ]]; then
  warnings+=("Use imperative mood: 'add' not 'added', 'fix' not 'fixed'")
fi

# Output results
if [[ ${#errors[@]} -gt 0 ]]; then
  error_list=$(printf "  - %s\n" "${errors[@]}")
  warning_list=""
  if [[ ${#warnings[@]} -gt 0 ]]; then
    warning_list=$(printf "\n  - %s" "${warnings[@]}")
  fi

  jq -n --arg title "$title_line" --arg errors "$error_list" --arg warnings "$warning_list" '{
    systemMessage: ("Conventional commit validation FAILED for: \"" + $title + "\"\n\nErrors:\n" + $errors + $warnings + "\n\nPlease amend the commit with: git commit --amend -m \"<corrected message>\"")
  }' >&2
  exit 2
elif [[ ${#warnings[@]} -gt 0 ]]; then
  warning_list=$(printf "  - %s\n" "${warnings[@]}")
  jq -n --arg title "$title_line" --arg warnings "$warning_list" '{
    systemMessage: ("Conventional commit validation PASSED with warnings for: \"" + $title + "\"\n\nWarnings:\n" + $warnings)
  }'
  exit 0
else
  # Silent success - no need to clutter output for valid commits
  exit 0
fi
