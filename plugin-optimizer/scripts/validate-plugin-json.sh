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

# Check for anti-patterns
echo
echo "Checking for anti-patterns..."

if has_json_field "$MANIFEST_PATH" "commands"; then
  echo "⚠ WARNING: Unnecessary 'commands' field - rely on auto-discovery"
  ((warnings++))
fi

if has_json_field "$MANIFEST_PATH" "agents"; then
  echo "⚠ WARNING: Unnecessary 'agents' field - rely on auto-discovery"
  ((warnings++))
fi

if has_json_field "$MANIFEST_PATH" "skills"; then
  echo "⚠ WARNING: Unnecessary 'skills' field - rely on auto-discovery"
  ((warnings++))
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
