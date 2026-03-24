#!/bin/bash
#
# track-changes.sh — PostToolUse hook: accumulate modified files per session
#
# Fires after Write, Edit, and MultiEdit tool calls succeed.
# Extracts the file_path from tool_input and appends it to the session state
# file's modified_files array (deduped). verify-work.sh reads this list to
# include modified files in its verification prompt.
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

# Extract file paths: Edit/Write expose tool_input.file_path (string);
# MultiEdit exposes tool_input.edits[].file_path (array). The // chain
# falls through to the array branch only when file_path is absent/null.
mapfile -t FILE_PATHS < <(
  echo "$HOOK_INPUT" | jq -r '
    .tool_input | .file_path // (.edits[]?.file_path) // empty
  ' 2>/dev/null | sort -u
)

# Nothing to track if no file paths resolved
[[ ${#FILE_PATHS[@]} -eq 0 ]] && exit 0

STATE_FILE="$(state_dir)/${SESSION_ID}.vetted.json"

if [[ -f "$STATE_FILE" ]]; then
  # Append all paths to existing session state (dedup via unique)
  TEMP="${STATE_FILE}.tmp.$$"
  jq '.modified_files = ((.modified_files // []) + $ARGS.positional | unique)' \
    "$STATE_FILE" --args "${FILE_PATHS[@]}" > "$TEMP" && mv "$TEMP" "$STATE_FILE"
else
  # State file not yet created (e.g. first prompt had @mention with null user_prompt).
  # Create a minimal stub so modified files are not lost — task-start.sh will
  # populate the task field on the next prompt with real content.
  jq -n \
    --args -- "${FILE_PATHS[@]}" \
    '{task: "", modified_files: $ARGS.positional}' \
    > "$STATE_FILE"
fi

exit 0
