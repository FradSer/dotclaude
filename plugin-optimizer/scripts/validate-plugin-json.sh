#!/bin/bash
#
# validate-plugin-json.sh - Validates plugin.json manifest structure and required fields
#
# Usage: bash validate-plugin-json.sh /path/to/plugin
#
# Exit codes:
#   0 - Validation passed
#   1 - Validation failed with errors
#

set -e

PLUGIN_DIR="${1:-.}"
MANIFEST_PATH="$PLUGIN_DIR/.claude-plugin/plugin.json"

errors=0
warnings=0

echo "Validating plugin.json: $MANIFEST_PATH"
echo

# Check if manifest exists
if [ ! -f "$MANIFEST_PATH" ]; then
  echo "✗ CRITICAL: plugin.json not found at $MANIFEST_PATH"
  exit 1
fi

# Basic JSON syntax validation (pure shell)
# Check for basic JSON structure
CONTENT=$(cat "$MANIFEST_PATH")

# Check if starts with { and ends with }
if [[ ! "$CONTENT" =~ ^\{.*\}$ ]]; then
  echo "✗ CRITICAL: Invalid JSON - must start with { and end with }"
  exit 1
fi

# Check for balanced braces
open_braces=$(echo "$CONTENT" | grep -o '{' | wc -l | tr -d ' ')
close_braces=$(echo "$CONTENT" | grep -o '}' | wc -l | tr -d ' ')
if [ "$open_braces" != "$close_braces" ]; then
  echo "✗ CRITICAL: Unbalanced braces in JSON"
  exit 1
fi

# Helper function to extract JSON field value
get_json_field() {
  local file="$1"
  local field="$2"
  grep -o "\"$field\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$file" | sed 's/.*:[ ]*"\([^"]*\)".*/\1/' | head -1
}

# Helper function to check if field exists
has_json_field() {
  local file="$1"
  local field="$2"
  grep -q "\"$field\"[[:space:]]*:" "$file"
}

# Check required fields
echo "Checking required fields..."

if ! has_json_field "$MANIFEST_PATH" "name"; then
  echo "✗ CRITICAL: Missing required field 'name'"
  ((errors++))
else
  NAME=$(get_json_field "$MANIFEST_PATH" "name")
  # Check kebab-case
  if ! [[ "$NAME" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    echo "⚠ WARNING: Name '$NAME' should use kebab-case (lowercase with hyphens)"
    ((warnings++))
  else
    echo "✓ name: $NAME"
  fi
fi

if ! has_json_field "$MANIFEST_PATH" "description"; then
  echo "⚠ WARNING: Missing recommended field 'description'"
  ((warnings++))
else
  echo "✓ description present"
fi

# Check for author.name (nested field)
if ! grep -q '"author"[[:space:]]*:[[:space:]]*{' "$MANIFEST_PATH"; then
  echo "✗ CRITICAL: Missing required field 'author'"
  ((errors++))
else
  if ! grep -q '"name"[[:space:]]*:' "$MANIFEST_PATH" | grep -A5 '"author"' "$MANIFEST_PATH" | grep -q '"name"'; then
    # More robust check: look for "name" within reasonable distance of "author"
    author_section=$(sed -n '/"author"/,/}/p' "$MANIFEST_PATH")
    if ! echo "$author_section" | grep -q '"name"'; then
      echo "✗ CRITICAL: Missing required field 'author.name'"
      ((errors++))
    else
      echo "✓ author.name present"
    fi
  else
    echo "✓ author.name present"
  fi
fi

# Check optional but recommended fields
echo
echo "Checking optional fields..."

if ! has_json_field "$MANIFEST_PATH" "version"; then
  echo "⚠ INFO: Missing optional field 'version' (recommended)"
else
  VERSION=$(get_json_field "$MANIFEST_PATH" "version")
  # Check semver format
  if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "⚠ WARNING: Version '$VERSION' should follow semver (X.Y.Z)"
    ((warnings++))
  else
    echo "✓ version: $VERSION (semver)"
  fi
fi

if ! grep -q '"keywords"[[:space:]]*:[[:space:]]*\[' "$MANIFEST_PATH"; then
  echo "⚠ INFO: Missing optional field 'keywords' (helps discoverability)"
else
  echo "✓ keywords present"
fi

# Check for best practices
echo
echo "Checking commands field and path validation..."

# Check commands field format (modern best practice)
if has_json_field "$MANIFEST_PATH" "commands"; then
  # Extract ALL paths from commands array (both valid and invalid formats)
  # Use tr to convert newlines so grep can match multi-line arrays
  all_paths=$(cat "$MANIFEST_PATH" | tr -d '\n' | grep -o '"commands"[[:space:]]*:[[:space:]]*\[[^]]*\]' | sed 's/.*\[//; s/\].*//' | grep -o '"[^"]*"' | tr -d '"')

  if [ -z "$all_paths" ]; then
    echo "✗ CRITICAL: 'commands' array is empty"
    ((errors++))
  else
    echo "Declared command paths in plugin.json:"

    # Validate each path
    while IFS= read -r cmd_path; do
      echo
      echo "  Path: \"$cmd_path\""

      # Check path format: must start with ./ and end with /
      if [[ ! "$cmd_path" =~ ^\./.*\/$ ]]; then
        echo "    ✗ CRITICAL: Invalid format - must be './relative/path/' format"
        echo "    Suggestion: \"./skills/${cmd_path%/}/\" or \"./skills/${cmd_path}/\""
        ((errors++))
        continue  # Skip further validation for this invalid path
      fi

      # Format is correct, now check existence
      clean_path="${cmd_path%/}"
      full_path="$PLUGIN_DIR/$clean_path"

      # Check if directory exists
      if [ ! -d "$full_path" ]; then
        echo "    ✗ ERROR: Directory does not exist at $full_path"
        ((errors++))
      else
        echo "    ✓ Directory exists"

        # Check if SKILL.md exists
        if [ ! -f "$full_path/SKILL.md" ]; then
          echo "    ✗ ERROR: SKILL.md not found in $full_path"
          ((errors++))
        else
          echo "    ✓ SKILL.md found"
        fi
      fi
    done <<< "$all_paths"

    # Check for undeclared skills in skills/ directory
    if [ -d "$PLUGIN_DIR/skills" ]; then
      echo
      echo "Checking for undeclared skills in skills/ directory..."
      undeclared_found=0

      # Get list of valid paths from commands (only well-formed ones)
      valid_commands=$(echo "$all_paths" | grep '^\./.*\/$')

      for skill_dir in "$PLUGIN_DIR/skills"/*/; do
        if [ -d "$skill_dir" ] && [ -f "$skill_dir/SKILL.md" ]; then
          skill_name=$(basename "$skill_dir")
          skill_path="./skills/$skill_name/"

          if ! echo "$valid_commands" | grep -qx "$skill_path"; then
            # Check if skill is user-invocable
            # Extract ONLY the first frontmatter block (line 1 to second ---)
            skill_file="$skill_dir/SKILL.md"
            # Use awk to extract only the first frontmatter block
            user_invocable=$(awk '/^---$/{if(++count==2)exit;next}{if(count==1)print}' "$skill_file" | grep -i "user-invocable" | grep -i "true" || echo "")

            if [ -n "$user_invocable" ]; then
              # user-invocable: true but not in commands - this is an ERROR
              if [ $undeclared_found -eq 0 ]; then
                echo "✗ ERROR: Found user-invocable skills not declared in 'commands' field:"
                undeclared_found=1
              fi
              echo "  - $skill_path (user-invocable: true but not in plugin.json)"
              ((errors++))
            fi
            # If user-invocable is false or missing, it's an internal/knowledge skill - no warning needed
          fi
        fi
      done

      if [ $undeclared_found -eq 0 ]; then
        echo "✓ All user-invocable skills are properly declared"
      fi
    fi
  fi
else
  echo "⚠ INFO: No 'commands' field found"
  echo "  Modern best practice: Explicitly declare skill paths for better maintainability"
  echo "  Example: \"commands\": [\"./skills/optimize/\", \"./skills/deploy/\"]"
fi

# Summary
echo
echo "=========================================="
if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
  echo "✓ Validation passed - no issues found"
  exit 0
elif [ $errors -eq 0 ]; then
  echo "⚠ Validation passed with $warnings warning(s)"
  exit 0
else
  echo "✗ Validation failed: $errors error(s), $warnings warning(s)"
  exit 1
fi
