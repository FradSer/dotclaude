#!/bin/bash
#
# track-changes.sh — PostToolUse hook: accumulate modified files per session
#
# Fires after Write, Edit, and MultiEdit tool calls succeed.
# Extracts the file_path from tool_input and appends it to the session state
# file's modified_files array (deduped). verify-work.sh reads this list to
# include the actual code changes in its verification prompt.
#
# Runs async — never blocks tool execution.

set -euo pipefail

# Guard: running inside the merge sub-session — skip everything
[[ "${VETTED_MERGE_SESSION:-}" == "1" ]] && exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=../lib/utils.sh
source "${SCRIPT_DIR}/../lib/utils.sh"

HOOK_INPUT=$(cat)

SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.session_id // "default"')
FILE_PATH=$(echo "$HOOK_INPUT" | jq -r '.tool_input.file_path // ""')

# Nothing to track if no file path
[[ -z "$FILE_PATH" || "$FILE_PATH" == "null" ]] && exit 0

STATE_FILE="$(state_dir)/${SESSION_ID}.vetted.json"

if [[ -f "$STATE_FILE" ]]; then
  # Append to existing session state (dedup via unique)
  TEMP="${STATE_FILE}.tmp.$$"
  jq --arg file "$FILE_PATH" \
    '.modified_files = ((.modified_files // []) + [$file] | unique)' \
    "$STATE_FILE" > "$TEMP" && mv "$TEMP" "$STATE_FILE"
else
  # State file not yet created (e.g. first prompt had @mention with null user_prompt).
  # Don't create a stub here — task-start.sh will create the file on the next
  # prompt with real content. Silently skip to avoid persisting task: "".
  :
fi

exit 0
