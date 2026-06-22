#!/usr/bin/env bash
#
# PreToolUse hook — redirect bare `git commit` / `git add` to the /git:commit skill.
#
# Background: Claude Code's built-in commit flow (status -> diff -> add -> commit) takes
# priority over single-line CLAUDE.md instructions. Without this hook the agent runs the
# built-in flow instead of the /git:commit skill. This hook intercepts the Bash call and
# denies it with a message pointing at the skill.
#
# Input (stdin JSON): { "tool_name": "Bash", "tool_input": { "command": "..." }, ... }
# Deny convention (current preferred): exit 0 + JSON on stdout
#   { "hookSpecificOutput": { "hookEventName": "PreToolUse",
#       "permissionDecision": "deny", "permissionDecisionReason": "..." } }
#
# Reference: https://code.claude.com/docs/en/hooks (PreToolUse)

set -uo pipefail

input=$(cat)

# Extract the command. Prefer jq; fall back to a tolerant grep so a missing jq never
# blocks legitimate work (fail open — allow the call rather than deny on parse error).
if command -v jq >/dev/null 2>&1; then
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
else
  cmd=$(printf '%s' "$input" | grep -oE '"command"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' | head -1 \
    | sed -E 's/.*"command"[[:space:]]*:[[:space:]]*"(.*)"/\1/' || true)
fi

[ -z "$cmd" ] && exit 0

# Match `git commit` or `git add` as adjacent subcommand tokens, anywhere in the command
# (covers chained forms like `git add . && git commit`).
if printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])git[[:space:]]+(commit|add)([[:space:]]|$)'; then
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Use the /git:commit skill (via the Skill tool) instead of raw git add/git commit. It stages changes and generates a conventional commit message."}}'
  exit 0
fi

exit 0
