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

input=$(cat)

tool_name=$(echo "$input" | jq -r '.tool_name // empty')
command=$(echo "$input" | jq -r '.tool_input.command // empty')

if [[ "$tool_name" != "Bash" ]]; then
  exit 0
fi

if [[ -z "$command" ]] || ! [[ "$command" =~ git[[:space:]]+commit ]]; then
  exit 0
fi

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
  errors+=("Commit body is REQUIRED and MUST contain bullet-point summary.")
  errors+=("Format: Body MUST have bullet points with imperative verbs.")
  errors+=("        Body MUST have explanation paragraph after bullets.")
  errors+=("        Body MAY include context before bullets.")
  errors+=("        Line length: All body lines must be ≤72 characters.")
  errors+=("Example:")
  errors+=("  - Add user authentication endpoint")
  errors+=("  - Update middleware to validate tokens")
  errors+=("  ")
  errors+=("  Improves security by implementing OAuth 2.0 standard.")
else
  # Body exists, now validate it has bullet points
  # Look for lines starting with "- " (bullet points)
  bullet_lines=$(echo "$body" | grep -E '^[[:space:]]*-[[:space:]]+' || true)

  if [[ -z "$bullet_lines" ]]; then
    errors+=("Body MUST contain bullet-point summary (lines starting with '- ')")
    errors+=("Current body format is invalid. Body structure:")
    errors+=("  REQUIRED: Bullet-point summary with imperative verbs")
    errors+=("  REQUIRED: Explanation paragraph after bullets")
    errors+=("  OPTIONAL: Context paragraph before bullets")
    errors+=("  Line length: All body lines must be ≤72 characters")
    errors+=("Example:")
    errors+=("  - Add OAuth 2.0 configuration")
    errors+=("  - Implement callback endpoint")
    errors+=("  ")
    errors+=("  Improves security and user experience.")
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

    # Validate line lengths (≤72 characters per line in body)
    line_too_long=()
    while IFS= read -r line; do
      if [[ ${#line} -gt 72 ]]; then
        line_too_long+=("$line")
      fi
    done <<< "$(echo "$body" | grep -v '^Co-Authored-By:' || true)"

    if [[ ${#line_too_long[@]} -gt 0 ]]; then
      errors+=("Body lines must be ≤72 characters (some lines exceed limit)")
      errors+=("Found $((${#line_too_long[@]})) line(s) that are too long:")
      for long_line in "${line_too_long[@]}"; do
        errors+=("  Line (${#long_line} chars): $(echo "$long_line" | cut -c1-50)...")
      done
    fi

    if [[ ${#invalid_bullets[@]} -gt 0 ]]; then
      warnings+=("Some bullet points may not start with imperative verbs:")
      for bullet in "${invalid_bullets[@]}"; do
        warnings+=("  $bullet")
      done
      warnings+=("Expected format: '- <Verb> <description>' (Add, Remove, Update, Fix, etc.)")
    fi

    # Validate explanation paragraph after bullets (REQUIRED)
    # Find the last bullet line number
    last_bullet_line=$(echo "$body" | grep -n -E '^[[:space:]]*-[[:space:]]+' | tail -1 | cut -d: -f1)

    if [[ -n "$last_bullet_line" ]]; then
      # Get content after the last bullet (excluding Co-Authored-By footer)
      content_after_bullets=$(echo "$body" | tail -n +$((last_bullet_line + 1)) | grep -v '^Co-Authored-By:' | sed 's/^[[:space:]]*$//' | grep -v '^$' || true)

      if [[ -z "$content_after_bullets" ]]; then
        errors+=("Body MUST contain explanation paragraph after bullet points")
        errors+=("The explanation should describe WHY these changes were made")
        errors+=("Example:")
        errors+=("  - Add OAuth 2.0 configuration")
        errors+=("  - Implement callback endpoint")
        errors+=("  ")
        errors+=("  Improves security by implementing industry-standard authentication.")
      fi
    fi
  fi
fi

# 8. Validate Co-Authored-By footer
# Check if footer contains Co-Authored-By (required for AI-assisted commits)
if ! echo "$commit_msg" | grep -qE '^Co-Authored-By:[[:space:]]+Claude[[:space:]]+(Sonnet|Opus|Haiku)[[:space:]]+[0-9.]+[[:space:]]+<noreply@anthropic\.com>'; then
  errors+=("Co-Authored-By footer is required for AI-assisted commits")
  errors+=("Format: Co-Authored-By: <Model Name> <noreply@anthropic.com>")
  errors+=("Example:")
  errors+=("  Co-Authored-By: <Model Name> <noreply@anthropic.com>")
fi

# Output results and block execution if errors found
if [[ ${#errors[@]} -gt 0 ]]; then
  error_list=$(printf "  - %s\n" "${errors[@]}")
  warning_list=""
  if [[ ${#warnings[@]} -gt 0 ]]; then
    warning_list=$(printf "\n\nWarnings:\n  - %s" "${warnings[@]}")
  fi

  jq -n --arg title "$title_line" --arg errors "$error_list" --arg warnings "$warning_list" '{
    systemMessage: ("VALIDATION FAILED: Conventional commit format error\n\nCommit message:\n  \"" + $title + "\"\n\nErrors:\n" + $errors + $warnings + "\n\nRequired format:\n<type>[scope]: <description>\n\n[Optional context paragraph]\n\n- <Verb> <change description> (REQUIRED)\n- <Verb> <change description> (REQUIRED)\n\n<Explanation paragraph> (REQUIRED)\n\nLine length: All body lines must be ≤72 characters\n\nCo-Authored-By: <Model Name> <noreply@anthropic.com>\n\nExample:\nfeat(auth): add google oauth login\n\n- Add OAuth 2.0 configuration\n- Implement callback endpoint\n- Update session management\n\nImproves cross-platform sign-in experience.\n\nCo-Authored-By: <Model Name> <noreply@anthropic.com>")
  }' >&2
  exit 2
elif [[ ${#warnings[@]} -gt 0 ]]; then
  warning_list=$(printf "  - %s\n" "${warnings[@]}")
  jq -n --arg title "$title_line" --arg warnings "$warning_list" '{
    systemMessage: ("WARNING: Commit message has warnings\n  \"" + $title + "\"\n\nWarnings:\n" + $warnings)
  }'
  exit 0
else
  exit 0
fi
