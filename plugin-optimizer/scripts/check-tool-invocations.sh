#!/bin/bash
#
# check-tool-invocations.sh - Detects explicit tool call anti-patterns
#
# Usage: bash check-tool-invocations.sh /path/to/plugin
#
# Exit codes:
#   0 - No anti-patterns found
#   1 - Anti-patterns detected
#

set -e

PLUGIN_DIR="${1:-.}"

issues=0

echo "Checking for explicit tool invocation anti-patterns in: $PLUGIN_DIR"
echo

# Anti-pattern regex patterns
# Only core file operations should be implicit.
# Interaction/System tools (AskUserQuestion, TaskCreate, etc) represent specific workflow steps and are OK to call explicitly.
CORE_TOOLS_PATTERN="(Use|Call|Using) (the )?(Read|Write|Glob|Grep|Edit) tool"
BASH_TOOL_PATTERN="(Use|Call|Using) (the )?Bash tool"
TASK_TOOL_PATTERN="(Use|Call) (the )?Task tool to launch [a-z-]+"

# Files to check (excluding README.md)
FILES=$(find "$PLUGIN_DIR" -type f \( -path "*/commands/*.md" -o -path "*/agents/*.md" -o -path "*/skills/*/SKILL.md" \) ! -name "README.md" 2>/dev/null)

if [ -z "$FILES" ]; then
  echo "⚠ No component files found to check"
  exit 0
fi

echo "Checking explicit core tool invocation anti-patterns (Read, Write, Glob, Grep, Edit)..."
while IFS= read -r file; do
  if grep -E "$CORE_TOOLS_PATTERN" "$file" >/dev/null 2>&1; then
    echo "⚠ WARNING: Explicit core tool call found in $file"
    grep -n -E "$CORE_TOOLS_PATTERN" "$file" | while IFS=: read -r line_num match; do
      echo "  Line $line_num: $(echo "$match" | xargs)"
    done
    ((issues++))
  fi
done <<< "$FILES"

echo
echo "Checking Bash tool calls..."
while IFS= read -r file; do
  # Find explicit Bash tool calls, but exclude allowed patterns:
  # - Inline execution: pattern !`command` (exclamation mark + backtick + command + backtick)
  # - allowed-tools config: Bash(git:*)
  if grep -E "$BASH_TOOL_PATTERN" "$file" | grep -v "Bash(" | grep -v '!`' >/dev/null 2>&1; then
    echo "⚠ WARNING: Explicit Bash tool call found in $file"
    grep -n -E "$BASH_TOOL_PATTERN" "$file" | grep -v "Bash(" | grep -v '!`' | while IFS=: read -r line_num match; do
      echo "  Line $line_num: $(echo "$match" | xargs)"
    done
    ((issues++))
  fi
done <<< "$FILES"

echo
echo "Checking Task tool specific patterns..."
while IFS= read -r file; do
  # Find "Use Task tool to launch specific-agent" patterns
  # Allow: "Use Task tool" with JSON structure (general-purpose agents)
  if grep -E "$TASK_TOOL_PATTERN" "$file" >/dev/null 2>&1; then
    echo "⚠ WARNING: Unnecessary Task tool mention found in $file"
    grep -n -E "$TASK_TOOL_PATTERN" "$file" | while IFS=: read -r line_num match; do
      echo "  Line $line_num: $(echo "$match" | xargs)"
      echo "  Suggestion: Use descriptive style instead: 'Launch [agent-name] agent'"
    done
    ((issues++))
  fi
done <<< "$FILES"

# Additional checks for specific patterns
echo
echo "Checking for other tool invocation anti-patterns..."

# Check for "Use the X tool" patterns
while IFS= read -r file; do
  if grep -E "Use the (Read|Write|Glob|Grep|Edit|Bash) tool" "$file" >/dev/null 2>&1; then
    echo "⚠ WARNING: Verbose tool invocation in $file"
    grep -n -E "Use the (Read|Write|Glob|Grep|Edit|Bash) tool" "$file" | while IFS=: read -r line_num match; do
      echo "  Line $line_num: $(echo "$match" | xargs)"
    done
    ((issues++))
  fi
done <<< "$FILES"

# Check frontmatter for unrestricted Bash in allowed-tools
echo
echo "Checking allowed-tools configurations..."
while IFS= read -r file; do
  # Extract frontmatter
  FRONTMATTER=$(sed -n '/^---$/,/^---$/p' "$file" 2>/dev/null | sed '1d;$d')

  if echo "$FRONTMATTER" | grep -q "allowed-tools:"; then
    # Check for unrestricted Bash (not Bash(filter:*))
    if echo "$FRONTMATTER" | grep -E "allowed-tools:.*\bBash\b" | grep -v "Bash(" >/dev/null 2>&1; then
      echo "✗ CRITICAL: Unrestricted Bash in allowed-tools in $file"
      echo "  Suggestion: Use filters like Bash(git:*), Bash(npm:*), etc."
      ((issues++))
    fi
  fi
done <<< "$FILES"

# Detailed suggestions for common anti-patterns
echo
echo "=========================================="
echo "Common anti-patterns and fixes:"
echo
echo "❌ \"Use Read tool to read the file\""
echo "✅ \"Read the file and extract...\""
echo
echo "❌ \"Use Bash tool to run git status\""
echo "✅ \"Run \`git status\` to check...\""
echo
echo "❌ \"Use Task tool to launch code-reviewer agent\""
echo "✅ \"Launch the code-reviewer agent to...\""
echo
echo "❌ \"allowed-tools: [Bash]\""
echo "✅ \"allowed-tools: [Bash(git:*)]\""
echo

# Summary
echo "=========================================="
if [ $issues -eq 0 ]; then
  echo "✓ No tool invocation anti-patterns found"
  exit 0
else
  echo "⚠ Found $issues issue(s) with tool invocations"
  echo
  echo "These are not critical errors but should be fixed to follow best practices."
  echo "See references/tool-invocations.md for detailed guidance."
  exit 1
fi
