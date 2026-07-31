#!/bin/bash

INPUT=$(cat)
# Guard: jq is required to parse the hook's JSON input. If it is missing,
# refuse to evaluate rather than silently treating an empty COMMAND as safe
# (which would let dangerous git commands execute unchecked).
if ! command -v jq >/dev/null 2>&1; then
  echo "BLOCKED: jq not available — refusing to evaluate commands without JSON parsing" >&2
  exit 2
fi
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

# Guard: if jq could not extract a command (missing key → "null", parse
# error → empty, or unparseable input), refuse to evaluate rather than
# defaulting to ALLOW — a security hook that lets commands through on
# unparseable input defeats its own purpose.
if [[ -z "$COMMAND" || "$COMMAND" == "null" ]]; then
  echo "BLOCKED: could not parse command from hook input — refusing to evaluate" >&2
  exit 2
fi

DANGEROUS_PATTERNS=(
  "git push"
  "git reset --hard"
  "git clean -fd"
  "git clean -f"
  "git branch -D"
  "git checkout \."
  "git restore \."
  "push --force"
  "reset --hard"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "BLOCKED: '$COMMAND' matches dangerous pattern '$pattern'. The user has prevented you from doing this." >&2
    exit 2
  fi
done

exit 0
