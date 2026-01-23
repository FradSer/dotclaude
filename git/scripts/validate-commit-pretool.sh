#!/bin/bash
# PreToolUse hook: Validate conventional commit message format BEFORE execution
# Runs before git commit commands to prevent invalid commits from being created

set -euo pipefail

# Extract heredoc content (full multiline)
extract_heredoc_content() {
  local cmd="$1"
  if [[ "$cmd" =~ cat[[:space:]]+\<\<[[:space:]]*-?[\'\"]?([A-Za-z_][A-Za-z0-9_]*) ]]; then
    local delim="${BASH_REMATCH[1]}"
    echo "$cmd" | awk -v delim="$delim" '
      BEGIN { capturing = 0 }
      $0 ~ "<<.*" delim { capturing = 1; next }
      capturing && $0 ~ "^[[:space:]]*" delim "[[:space:]]*$" { exit }
      capturing { gsub(/^[[:space:]]+/, ""); print }
    '
  fi
}

# Extract file path (handles quoted paths)
extract_file_path() {
  local cmd="$1"
  local flag="$2"
  case "$flag" in
    "-F")
      if [[ "$cmd" =~ -F[[:space:]]+\"([^\"]+)\" ]]; then
        echo "${BASH_REMATCH[1]}"
      elif [[ "$cmd" =~ -F[[:space:]]+\'([^\']+)\' ]]; then
        echo "${BASH_REMATCH[1]}"
      elif [[ "$cmd" =~ -F[[:space:]]+([^[:space:]\"\']+) ]]; then
        echo "${BASH_REMATCH[1]}"
      fi
      ;;
    "--file=")
      if [[ "$cmd" =~ --file=\"([^\"]+)\" ]]; then
        echo "${BASH_REMATCH[1]}"
      elif [[ "$cmd" =~ --file=\'([^\']+)\' ]]; then
        echo "${BASH_REMATCH[1]}"
      elif [[ "$cmd" =~ --file=([^[:space:]\"\']+) ]]; then
        echo "${BASH_REMATCH[1]}"
      fi
      ;;
  esac
}

# Extract -m message (handles heredoc, escaped quotes)
extract_m_message() {
  local cmd="$1"

  # Check for heredoc first
  if [[ "$cmd" =~ cat[[:space:]]+\<\< ]]; then
    extract_heredoc_content "$cmd"
    return
  fi

  # Double quotes with escaped quotes handling
  if [[ "$cmd" =~ -m[[:space:]]+\" ]]; then
    local after_m="${cmd#*-m \"}"
    local result="" i=0 len=${#after_m} prev_char=""
    while [[ $i -lt $len ]]; do
      local char="${after_m:$i:1}"
      if [[ "$char" == "\"" && "$prev_char" != "\\" ]]; then break; fi
      if [[ "$char" == "\\" && "${after_m:$((i+1)):1}" == "\"" ]]; then
        result+="\""; i=$((i+2)); prev_char=""; continue
      fi
      result+="$char"; prev_char="$char"; i=$((i+1))
    done
    echo "$result"
    return
  fi

  # Single quotes
  if [[ "$cmd" =~ -m[[:space:]]+\'([^\']*)\' ]]; then
    echo "${BASH_REMATCH[1]}"; return
  fi

  # Unquoted
  if [[ "$cmd" =~ -m[[:space:]]+([^[:space:]\"\']+) ]]; then
    echo "${BASH_REMATCH[1]}"; return
  fi
}

# Read input from stdin
input=$(cat)

# Extract tool_name and command from tool input
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Only process if this is a Bash tool invocation
if [[ "$tool_name" != "Bash" ]]; then
  exit 0
fi

# Only validate git commit commands (must start with "git commit")
if [[ -z "$command" ]] || ! [[ "$command" =~ ^git[[:space:]]+commit ]]; then
  exit 0
fi

# Skip if this is an amend or other special commit
if [[ "$command" =~ --amend ]] || [[ "$command" =~ --fixup ]] || [[ "$command" =~ --squash ]]; then
  exit 0
fi

# Extract commit message - try all methods
commit_msg=""

# Method 1: -m flag (most common)
if [[ "$command" =~ -m[[:space:]] ]]; then
  commit_msg=$(extract_m_message "$command")
fi

# Method 2: -F flag
if [[ -z "$commit_msg" ]] && [[ "$command" =~ -F[[:space:]] ]]; then
  file_path=$(extract_file_path "$command" "-F")
  if [[ -n "$file_path" ]] && [[ -f "$file_path" ]]; then
    commit_msg=$(cat "$file_path")
  fi
fi

# Method 3: --file= flag
if [[ -z "$commit_msg" ]] && [[ "$command" =~ --file= ]]; then
  file_path=$(extract_file_path "$command" "--file=")
  if [[ -n "$file_path" ]] && [[ -f "$file_path" ]]; then
    commit_msg=$(cat "$file_path")
  fi
fi

# Fail-closed: Block if we cannot extract the message
if [[ -z "$commit_msg" ]]; then
  jq -n '{
    systemMessage: ("VALIDATION BLOCKED: Cannot extract commit message\n\nThe commit message format is not recognized and cannot be validated.\nThis is a security measure to prevent bypassing conventional commit validation.\n\nSupported formats:\n  - git commit -m \"message\"\n  - git commit -F <file>\n  - git commit --file=<file>\n\nIf you believe this is an error, please check your commit command format.")
  }' >&2
  exit 2
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

# 7. Validate commit body format
# Extract body (everything after the first line)
body=$(echo "$commit_msg" | tail -n +2)

# Check if body exists and is not empty (after trimming whitespace)
body_trimmed=$(echo "$body" | sed 's/^[[:space:]]*$//' | grep -v '^$' || true)

if [[ -z "$body_trimmed" ]]; then
  errors+=("Commit body is required. Body must contain bullet points describing changes.")
  errors+=("Format: Use '- <verb> <description>' for each change")
  errors+=("Example:")
  errors+=("  - Add user authentication endpoint")
  errors+=("  - Update middleware to validate tokens")
else
  # Body exists, now validate it has bullet points
  # Look for lines starting with "- " (bullet points)
  bullet_lines=$(echo "$body" | grep -E '^[[:space:]]*-[[:space:]]+' || true)

  if [[ -z "$bullet_lines" ]]; then
    errors+=("Body must contain bullet points (lines starting with '- ')")
    errors+=("Current body format is invalid. Each change should be listed as:")
    errors+=("  - <verb> <description>")
    errors+=("Bullet points can be preceded by context paragraph and followed by explanation")
  else
    # Validate bullet points start with common verbs (soft check with warning)
    # Common imperative verbs for commits
    common_verbs="Add|Remove|Update|Fix|Implement|Create|Delete|Refactor|Optimize|Improve|Rename|Move|Extract|Replace|Merge|Split|Enhance|Reduce|Increase|Prevent|Enable|Disable|Configure|Set|Unset|Reset|Clear|Clean|Deprecate|Restore|Revert|Introduce|Migrate|Upgrade|Downgrade|Consolidate|Simplify|Standardize|Normalize|Validate|Verify|Test|Document|Annotate|Comment|Modify|Adjust|Tweak|Tune|Streamline|Reorganize|Restructure|Rearrange|Rewrite|Redesign|Rebuild|Redo|Revise|Correct|Align|Synchronize|Sync|Preload|Load|Unload|Initialize|Init|Finalize|Register|Unregister|Bind|Unbind|Attach|Detach|Connect|Disconnect|Link|Unlink|Expand|Collapse|Extend|Shorten|Widen|Narrow"

    invalid_bullets=()
    while IFS= read -r line; do
      # Extract the content after "- "
      content=$(echo "$line" | sed -E 's/^[[:space:]]*-[[:space:]]*//')
      # Check if it starts with a common verb (case-insensitive first letter, but verb should be capitalized)
      if ! [[ "$content" =~ ^($common_verbs)[[:space:]] ]]; then
        invalid_bullets+=("$line")
      fi
    done <<< "$bullet_lines"

    if [[ ${#invalid_bullets[@]} -gt 0 ]]; then
      warnings+=("Some bullet points may not start with imperative verbs:")
      for bullet in "${invalid_bullets[@]}"; do
        warnings+=("  $bullet")
      done
      warnings+=("Expected format: '- <Verb> <description>' (Add, Remove, Update, Fix, etc.)")
    fi
  fi
fi

# 8. Validate Co-Authored-By footer
# Check if footer contains Co-Authored-By (required for AI-assisted commits)
if ! echo "$commit_msg" | grep -qE '^Co-Authored-By:[[:space:]]+Claude[[:space:]]+(Sonnet|Opus|Haiku)[[:space:]]+[0-9.]+[[:space:]]+<noreply@anthropic\.com>'; then
  errors+=("Co-Authored-By footer is required for AI-assisted commits")
  errors+=("Format: Co-Authored-By: Claude <Model> <Version> <noreply@anthropic.com>")
  errors+=("Examples:")
  errors+=("  Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>")
  errors+=("  Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>")
  errors+=("  Co-Authored-By: Claude Haiku 4 <noreply@anthropic.com>")
fi

# Output results and block execution if errors found
if [[ ${#errors[@]} -gt 0 ]]; then
  error_list=$(printf "  - %s\n" "${errors[@]}")
  warning_list=""
  if [[ ${#warnings[@]} -gt 0 ]]; then
    warning_list=$(printf "\n\nWarnings:\n  - %s" "${warnings[@]}")
  fi

  jq -n --arg title "$title_line" --arg errors "$error_list" --arg warnings "$warning_list" '{
    systemMessage: ("VALIDATION FAILED: Conventional commit format error\n\nCommit message:\n  \"" + $title + "\"\n\nErrors:\n" + $errors + $warnings + "\n\nRequired format:\n<type>[scope]: <description>\n\n- <Verb> <change description>\n- <Verb> <change description>\n\n[Optional explanation paragraph]\n\nCo-Authored-By: Claude <Model> <Version> <noreply@anthropic.com>\n\nExample:\nfeat(auth): add google oauth login\n\n- Add OAuth 2.0 configuration\n- Implement callback endpoint\n- Update session management\n\nImproves cross-platform sign-in experience.\n\nCo-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>")
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
