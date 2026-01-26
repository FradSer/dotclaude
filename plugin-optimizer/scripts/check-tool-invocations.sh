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
  echo "Info: No component files found to check"
  exit 0
fi

echo "Checking explicit core tool invocation anti-patterns (Read, Write, Glob, Grep, Edit)..."
while IFS= read -r file; do
  if grep -E "$CORE_TOOLS_PATTERN" "$file" >/dev/null 2>&1; then
    echo "  Warning: Explicit core tool call found in $file"
    grep -n -E "$CORE_TOOLS_PATTERN" "$file" | while IFS=: read -r line_num match; do
      echo "    Line $line_num: $(echo "$match" | xargs)"
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
    echo "  Warning: Explicit Bash tool call found in $file"
    grep -n -E "$BASH_TOOL_PATTERN" "$file" | grep -v "Bash(" | grep -v '!`' | while IFS=: read -r line_num match; do
      echo "    Line $line_num: $(echo "$match" | xargs)"
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
    echo "  Warning: Unnecessary Task tool mention found in $file"
    grep -n -E "$TASK_TOOL_PATTERN" "$file" | while IFS=: read -r line_num match; do
      echo "    Line $line_num: $(echo "$match" | xargs)"
      echo "    Suggestion: Use descriptive style instead: 'Launch [agent-name] agent'"
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
    echo "  Warning: Verbose tool invocation in $file"
    grep -n -E "Use the (Read|Write|Glob|Grep|Edit|Bash) tool" "$file" | while IFS=: read -r line_num match; do
      echo "    Line $line_num: $(echo "$match" | xargs)"
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
      echo "  Error: Unrestricted Bash in allowed-tools in $file"
      echo "    Suggestion: Use filters like Bash(git:*), Bash(npm:*), etc."
      ((issues++))
    fi
  fi
done <<< "$FILES"

# Detailed suggestions for common anti-patterns
echo
echo "=========================================="
echo "Common anti-patterns and fixes:"
echo
echo "Bad: \"Use Read tool to read the file\""
echo "Good: \"Read the file and extract...\""
echo
echo "Bad: \"Use Bash tool to run git status\""
echo "Good: \"Run \`git status\` to check...\""
echo
echo "Bad: \"Use Task tool to launch code-reviewer agent\""
echo "Good: \"Launch the code-reviewer agent to...\""
echo
echo "Bad: \"allowed-tools: [Bash]\""
echo "Good: \"allowed-tools: [Bash(git:*)]\""
echo

# Summary
echo "=========================================="
echo "Tool Invocation Validation Summary"
echo "=========================================="
if [ $issues -eq 0 ]; then
  echo "Result: Passed - No anti-patterns detected"
  echo
  echo "All tool invocations follow best practices."
  echo "Component content uses proper implicit/explicit patterns."
  echo
  echo "Next Steps:"
  echo "  - Continue with token budget validation"
  echo "  - Run: python3 scripts/count-tokens.py . --all"
  exit 0
else
  echo "Result: Warning - $issues pattern issue(s) found"
  echo
  echo "Tool invocation anti-patterns detected. These don't break"
  echo "functionality but should be fixed for consistency."
  echo
  echo "Recommended Actions:"
  echo "  1. Review items above marked with 'Warning:'"
  echo "  2. Replace explicit tool mentions with descriptive actions"
  echo "  3. Ensure allowed-tools use proper filters (not bare 'Bash')"
  echo "  4. See references/tool-invocations.md for guidance"
  echo
  echo "Plugin is functional - these are style improvements."
  exit 1
fi
