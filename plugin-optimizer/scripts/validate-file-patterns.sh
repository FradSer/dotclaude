#!/bin/bash
#
# validate-file-patterns.sh - Validates file naming and structure conventions
#
# Usage: bash validate-file-patterns.sh /path/to/plugin
#
# Exit codes:
#   0 - Validation passed
#   1 - Validation failed with errors
#

set -e

PLUGIN_DIR="${1:-.}"

errors=0
warnings=0

echo "Validating file patterns and structure in: $PLUGIN_DIR"
echo

# Check manifest location
echo "Checking manifest location..."
if [ ! -f "$PLUGIN_DIR/.claude-plugin/plugin.json" ]; then
  echo "✗ CRITICAL: plugin.json must be in .claude-plugin/ directory"
  ((errors++))
else
  echo "✓ plugin.json in correct location"
fi

# Check for misplaced components (inside .claude-plugin/)
echo
echo "Checking for misplaced components..."
if [ -d "$PLUGIN_DIR/.claude-plugin/commands" ] || \
   [ -d "$PLUGIN_DIR/.claude-plugin/agents" ] || \
   [ -d "$PLUGIN_DIR/.claude-plugin/skills" ]; then
  echo "✗ CRITICAL: Components (commands/agents/skills) must be at plugin root, not inside .claude-plugin/"
  ((errors++))
else
  echo "✓ No components inside .claude-plugin/"
fi

# Check kebab-case naming for component files
echo
echo "Checking file naming conventions (kebab-case)..."

# Check commands
if [ -d "$PLUGIN_DIR/commands" ]; then
  while IFS= read -r file; do
    filename=$(basename "$file" .md)
    if ! [[ "$filename" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
      echo "⚠ WARNING: Command file not kebab-case: $file"
      ((warnings++))
    fi
  done < <(find "$PLUGIN_DIR/commands" -name "*.md" -type f 2>/dev/null)
fi

# Check agents
if [ -d "$PLUGIN_DIR/agents" ]; then
  while IFS= read -r file; do
    filename=$(basename "$file" .md)
    if ! [[ "$filename" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
      echo "⚠ WARNING: Agent file not kebab-case: $file"
      ((warnings++))
    fi
  done < <(find "$PLUGIN_DIR/agents" -name "*.md" -type f 2>/dev/null)
fi

# Check skills
if [ -d "$PLUGIN_DIR/skills" ]; then
  # Check skill directory names
  while IFS= read -r dir; do
    dirname=$(basename "$dir")
    if ! [[ "$dirname" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
      echo "⚠ WARNING: Skill directory not kebab-case: $dir"
      ((warnings++))
    fi

    # Check for SKILL.md in subdirectory
    if [ ! -f "$dir/SKILL.md" ]; then
      echo "✗ CRITICAL: Missing SKILL.md in skill directory: $dir"
      ((errors++))
    fi
  done < <(find "$PLUGIN_DIR/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
fi

if [ $warnings -eq 0 ] && [ $errors -eq 0 ]; then
  echo "✓ All file names follow kebab-case convention"
fi

# Check for ${CLAUDE_PLUGIN_ROOT} usage in scripts and configs
echo
echo "Checking for portable path references..."

hardcoded_paths=0

# Check hooks.json
if [ -f "$PLUGIN_DIR/hooks/hooks.json" ]; then
  if grep -E '"/[^$].*\.(sh|py|js)"' "$PLUGIN_DIR/hooks/hooks.json" >/dev/null 2>&1; then
    echo "⚠ WARNING: hooks.json may contain hardcoded absolute paths"
    echo "  Use \${CLAUDE_PLUGIN_ROOT} instead"
    ((warnings++))
    ((hardcoded_paths++))
  fi
fi

# Check .mcp.json
if [ -f "$PLUGIN_DIR/.mcp.json" ]; then
  if grep -E '"/[^$].*\.(sh|py|js)"' "$PLUGIN_DIR/.mcp.json" >/dev/null 2>&1; then
    echo "⚠ WARNING: .mcp.json may contain hardcoded absolute paths"
    echo "  Use \${CLAUDE_PLUGIN_ROOT} instead"
    ((warnings++))
    ((hardcoded_paths++))
  fi
fi

if [ $hardcoded_paths -eq 0 ]; then
  echo "✓ No hardcoded absolute paths detected"
fi

# Check skill structure
echo
echo "Checking skill directory structure..."

if [ -d "$PLUGIN_DIR/skills" ]; then
  skill_count=0
  while IFS= read -r skill_dir; do
    ((skill_count++))
    skill_name=$(basename "$skill_dir")

    # Check for SKILL.md
    if [ ! -f "$skill_dir/SKILL.md" ]; then
      echo "✗ CRITICAL: Missing SKILL.md in $skill_name/"
      ((errors++))
    fi

    # Check SKILL.md size (should be lean, <3000 words ~15KB)
    if [ -f "$skill_dir/SKILL.md" ]; then
      size=$(wc -c < "$skill_dir/SKILL.md")
      if [ "$size" -gt 30000 ]; then
        echo "⚠ WARNING: SKILL.md in $skill_name/ is large (>30KB)"
        echo "  Consider using progressive disclosure (move details to references/)"
        ((warnings++))
      fi
    fi

    # Check for references/ if SKILL.md is large
    if [ ! -d "$skill_dir/references" ] && [ -f "$skill_dir/SKILL.md" ]; then
      size=$(wc -c < "$skill_dir/SKILL.md")
      if [ "$size" -gt 15000 ]; then
        echo "⚠ INFO: $skill_name/ has large SKILL.md but no references/ directory"
        echo "  Consider creating references/ for detailed content"
      fi
    fi
  done < <(find "$PLUGIN_DIR/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)

  if [ $skill_count -eq 0 ]; then
    echo "⚠ INFO: skills/ directory exists but is empty"
  else
    echo "✓ Checked $skill_count skill(s)"
  fi
fi

# Check directory structure best practices
echo
echo "Checking directory structure best practices..."

# Warn about generic directory names
for generic_name in "utils" "misc" "temp" "helpers"; do
  if [ -d "$PLUGIN_DIR/$generic_name" ]; then
    echo "⚠ WARNING: Avoid generic directory name: $generic_name/"
    echo "  Use descriptive names instead"
    ((warnings++))
  fi
done

# Check for README
if [ ! -f "$PLUGIN_DIR/README.md" ]; then
  echo "⚠ INFO: Missing README.md in plugin root"
  echo "  Recommended for plugin documentation"
else
  echo "✓ README.md present"
fi

# Component count summary
echo
echo "Component summary:"
cmd_count=$(find "$PLUGIN_DIR/commands" -name "*.md" -type f 2>/dev/null | wc -l || echo "0")
agent_count=$(find "$PLUGIN_DIR/agents" -name "*.md" -type f 2>/dev/null | wc -l || echo "0")
skill_count=$(find "$PLUGIN_DIR/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l || echo "0")

echo "  Commands: $cmd_count"
echo "  Agents: $agent_count"
echo "  Skills: $skill_count"

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
