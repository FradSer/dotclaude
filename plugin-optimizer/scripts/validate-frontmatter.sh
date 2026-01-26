#!/bin/bash
#
# validate-frontmatter.sh - Validates YAML frontmatter in component files
#
# Usage:
#   Single file: bash validate-frontmatter.sh /path/to/file.md [type]
#   Multiple files: bash validate-frontmatter.sh /path/to/file1.md /path/to/file2.md ...
#   Directory: bash validate-frontmatter.sh /path/to/plugin (finds component files automatically)
#   type: command|agent|skill (optional, auto-detected from path)
#
# Exit codes:
#   0 - All validations passed
#   1 - One or more validations failed
#

# Don't use set -e to allow proper error collection
set +e

# Function to validate a single file
validate_single_file() {
  local FILE_PATH="$1"
  local TYPE="${2}"
  
  local errors=0
  local warnings=0

  # Auto-detect type from path if not provided
  if [ -z "$TYPE" ]; then
    if [[ "$FILE_PATH" == */commands/* ]]; then
      TYPE="command"
    elif [[ "$FILE_PATH" == */agents/* ]]; then
      TYPE="agent"
    elif [[ "$FILE_PATH" == */skills/* ]]; then
      TYPE="skill"
    else
      echo "⚠ WARNING: Cannot auto-detect type from path"
      TYPE="unknown"
    fi
  fi

  echo "Validating frontmatter: $FILE_PATH (type: $TYPE)"
  echo

  # Extract frontmatter (between --- markers)
  local FRONTMATTER=$(sed -n '/^---$/,/^---$/p' "$FILE_PATH" | sed '1d;$d')

  if [ -z "$FRONTMATTER" ]; then
    echo "✗ CRITICAL: No YAML frontmatter found"
    return 1
  fi

  # Basic YAML syntax validation (pure shell, no dependencies)
  local is_yaml_valid=true

  # Check for tabs (YAML doesn't allow tabs for indentation)
  if echo "$FRONTMATTER" | grep -q $'\t'; then
    echo "✗ CRITICAL: YAML cannot use tabs for indentation"
    is_yaml_valid=false
  fi

  # Check for unbalanced quotes
  local quote_count=$(echo "$FRONTMATTER" | grep -o '"' | wc -l | tr -d ' ')
  if [ $((quote_count % 2)) -ne 0 ]; then
    echo "✗ CRITICAL: Unbalanced double quotes in YAML"
    is_yaml_valid=false
  fi

  # Check for basic structure (key: value pattern)
  if ! echo "$FRONTMATTER" | grep -q '^[a-zA-Z_-]\+:'; then
    echo "✗ CRITICAL: No valid YAML key-value pairs found"
    is_yaml_valid=false
  fi

  if [ "$is_yaml_valid" = false ]; then
    return 1
  fi

  echo "✓ Valid YAML syntax"
  echo

  # Type-specific validation
  case "$TYPE" in
    command)
      echo "Checking command frontmatter fields..."

      # Required: description
      if ! echo "$FRONTMATTER" | grep -q "^description:"; then
        echo "✗ CRITICAL: Missing required field 'description'"
        ((errors++))
      else
        echo "✓ description present"
      fi

      # Recommended: argument-hint (optional for commands that accept arguments)
      if ! echo "$FRONTMATTER" | grep -q "^argument-hint:"; then
        echo "⚠ INFO: Missing optional 'argument-hint' field"
        echo "  Note: Only needed if command accepts arguments (helps with autocomplete)"
      else
        echo "✓ argument-hint present"
      fi

      # Check allowed-tools format
      if echo "$FRONTMATTER" | grep -q "^allowed-tools:"; then
        # Check for unrestricted Bash
        if echo "$FRONTMATTER" | grep -E "allowed-tools:.*\bBash\b" | grep -v "Bash(" >/dev/null 2>&1; then
          echo "✗ CRITICAL: Unrestricted 'Bash' in allowed-tools - must use filters like Bash(git:*)"
          ((errors++))
        else
          echo "✓ allowed-tools properly restricted"
        fi
      fi
      ;;

    agent)
      echo "Checking agent frontmatter fields..."

      # Required: name
      if ! echo "$FRONTMATTER" | grep -q "^name:"; then
        echo "✗ CRITICAL: Missing required field 'name'"
        ((errors++))
      else
        local NAME=$(echo "$FRONTMATTER" | grep "^name:" | sed 's/name: *//' | tr -d '"' | tr -d "'")
        # Check kebab-case and length
        if ! [[ "$NAME" =~ ^[a-z0-9]([a-z0-9-]{1,48}[a-z0-9])?$ ]]; then
          echo "✗ CRITICAL: Name '$NAME' must be 3-50 chars, kebab-case, no leading/trailing hyphens"
          ((errors++))
        else
          echo "✓ name: $NAME"
        fi
      fi

      # Required: description
      if ! echo "$FRONTMATTER" | grep -q "^description:"; then
        echo "✗ CRITICAL: Missing required field 'description'"
        ((errors++))
      else
        echo "✓ description present"
      fi

      # Required: model
      if ! echo "$FRONTMATTER" | grep -q "^model:"; then
        echo "✗ CRITICAL: Missing required field 'model'"
        ((errors++))
      else
        local MODEL=$(echo "$FRONTMATTER" | grep "^model:" | sed 's/model: *//' | tr -d '"' | tr -d "'")
        if ! [[ "$MODEL" =~ ^(inherit|sonnet|opus|haiku)$ ]]; then
          echo "✗ CRITICAL: Model '$MODEL' must be: inherit, sonnet, opus, or haiku"
          ((errors++))
        else
          echo "✓ model: $MODEL"
        fi
      fi

      # Required: color
      if ! echo "$FRONTMATTER" | grep -q "^color:"; then
        echo "✗ CRITICAL: Missing required field 'color'"
        ((errors++))
      else
        local COLOR=$(echo "$FRONTMATTER" | grep "^color:" | sed 's/color: *//' | tr -d '"' | tr -d "'")
        if ! [[ "$COLOR" =~ ^(blue|cyan|green|yellow|magenta|red)$ ]]; then
          echo "✗ CRITICAL: Color '$COLOR' must be: blue, cyan, green, yellow, magenta, or red"
          ((errors++))
        else
          echo "✓ color: $COLOR"
        fi
      fi
      ;;

    skill)
      echo "Checking skill frontmatter fields..."

      # Required: name
      if ! echo "$FRONTMATTER" | grep -q "^name:"; then
        echo "✗ CRITICAL: Missing required field 'name'"
        ((errors++))
      else
        echo "✓ name present"
      fi

      # Required: description
      if ! echo "$FRONTMATTER" | grep -q "^description:"; then
        echo "✗ CRITICAL: Missing required field 'description'"
        ((errors++))
      else
        local DESC=$(echo "$FRONTMATTER" | grep "^description:" | sed 's/description: *//')

        # Check if description is empty or too short
        local DESC_LENGTH=$(echo "$DESC" | tr -d ' ' | wc -c | tr -d ' ')
        if [ $DESC_LENGTH -lt 10 ]; then
          echo "⚠ WARNING: Description is too short (minimum 10 characters recommended)"
          ((warnings++))
        else
          echo "✓ description present"
        fi

        # Note: Both formats are acceptable:
        # - Concise imperative: "Create or update .gitignore file"
        # - Third-person with triggers: "This skill should be used when user asks to..."
      fi

      # Recommended: argument-hint (optional for skills that accept arguments)
      if ! echo "$FRONTMATTER" | grep -q "^argument-hint:"; then
        echo "⚠ INFO: Missing optional 'argument-hint' field"
        echo "  Note: Only needed if skill accepts arguments (helps with autocomplete)"
      else
        echo "✓ argument-hint present"
      fi
      ;;

    *)
      echo "Skipping type-specific validation (unknown type)"
      ;;
  esac

  # Check body for second-person in skills
  if [ "$TYPE" = "skill" ]; then
    echo
    echo "Checking skill body writing style..."

    local BODY=$(sed -n '/^---$/,/^---$/!p' "$FILE_PATH" | sed '1,/^---$/d')

    if echo "$BODY" | grep -E "You should|You must|You can|You need to" >/dev/null 2>&1; then
      echo "⚠ WARNING: Skill body should use imperative form, not second person ('You should...')"
      ((warnings++))
    else
      echo "✓ Body uses imperative form"
    fi
  fi

  # Return error count
  if [ $errors -gt 0 ]; then
    echo "✗ Validation failed: $errors error(s), $warnings warning(s)"
    return 1
  elif [ $warnings -gt 0 ]; then
    echo "⚠ Validation passed with $warnings warning(s)"
    return 0
  else
    echo "✓ Validation passed - no issues found"
    return 0
  fi
}

# Main execution
# Check if first argument is a directory (batch mode)
if [ -d "${1}" ]; then
  PLUGIN_DIR="${1}"
  # Find component files - only match direct component files, exclude all subdirectories
  # agents/*.md - only files directly in agents/ directory (maxdepth 2: plugin/agents/file.md)
  # commands/*.md - only files directly in commands/ directory (maxdepth 2: plugin/commands/file.md)
  # skills/*/SKILL.md - only SKILL.md directly in skill subdirectories (maxdepth 3: plugin/skills/skill/SKILL.md)
  # This excludes files in references/, examples/, scripts/, assets/, templates/, docs/, tests/, etc.
  AGENT_FILES=$(find "$PLUGIN_DIR/agents" -maxdepth 1 -name "*.md" -type f ! -name "README.md" 2>/dev/null)
  COMMAND_FILES=$(find "$PLUGIN_DIR/commands" -maxdepth 1 -name "*.md" -type f ! -name "README.md" 2>/dev/null)
  SKILL_FILES=$(find "$PLUGIN_DIR/skills" -mindepth 2 -maxdepth 2 -name "SKILL.md" -type f 2>/dev/null)
  
  FILES=$(echo "$AGENT_FILES"$'\n'"$COMMAND_FILES"$'\n'"$SKILL_FILES" | grep -v '^$')
  
  if [ -z "$FILES" ]; then
    echo "⚠ No component files found in $PLUGIN_DIR"
    exit 0
  fi
else
  # Multiple files or single file mode
  FILES="$@"
  if [ -z "$FILES" ]; then
    echo "✗ No files specified"
    exit 1
  fi
fi

total_errors=0
total_warnings=0
files_processed=0
files_failed=0

# Process each file
for FILE_PATH in $FILES; do
  if [ ! -f "$FILE_PATH" ]; then
    echo "⚠ Skipping: File not found: $FILE_PATH"
    continue
  fi
  
  ((files_processed++))
  echo "=========================================="
  
  if validate_single_file "$FILE_PATH"; then
    # Validation passed (may have warnings)
    :
  else
    ((files_failed++))
    total_errors=$((total_errors + 1))
  fi
  echo
done

# Final summary
echo "=========================================="
echo "Summary: Processed $files_processed file(s)"
if [ $files_failed -eq 0 ]; then
  echo "✓ All validations passed"
  exit 0
else
  echo "✗ $files_failed file(s) failed validation"
  exit 1
fi
