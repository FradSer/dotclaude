#!/bin/bash
#
# track-changes.sh — PostToolUse hook: accumulate modified files per session
#
# Fires after Write, Edit, and MultiEdit tool calls succeed.
# Extracts the file_path from tool_input and appends it to the session state
# file's modified_files array (deduped). stop-hook.sh reads this list to
# include modified files in its verification prompt.
#
# Runs async — never blocks tool execution.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=../lib/utils.sh
source "${SCRIPT_DIR}/../lib/utils.sh"

# Runtime-deps check — bail soft if jq/perl are missing.
[[ "${_SUPERPOWERS_DEPS_MISSING:-}" == "1" ]] && exit 0

HOOK_INPUT=$(cat)

SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.session_id // "default"')

# Extract file paths: Edit/Write expose tool_input.file_path (string);
# MultiEdit exposes tool_input.edits[].file_path (array). The // chain
# falls through to the array branch only when file_path is absent/null.
# Note: avoid mapfile — macOS ships bash 3.2 which lacks it.
FILE_PATHS_RAW=$(echo "$HOOK_INPUT" | jq -r '
  .tool_input | .file_path // (.edits[]?.file_path) // empty
' 2>/dev/null | sort -u)

# Nothing to track if no file paths resolved
[[ -z "$FILE_PATHS_RAW" ]] && exit 0

# Build array from newline-separated output (bash 3.2 compatible)
FILE_PATHS=()
while IFS= read -r line; do
  [[ -n "$line" ]] && FILE_PATHS+=("$line")
done <<< "$FILE_PATHS_RAW"

[[ ${#FILE_PATHS[@]} -eq 0 ]] && exit 0

STATE_FILE="$(state_dir)/${SESSION_ID}.superpowers.json"

# Track only inside an active Superpower Loop. modified_files and
# edits_since_last_spawn are consumed solely by lib/loop.sh — the first
# re-injection snapshot and executing-plans stuck detection — both of which
# require active=true. Outside a loop this hook used to fire on every
# Edit/Write/MultiEdit in every session (any repo, loop or not), accumulating
# state nothing reads. One jq read here replaces an unconditional lock +
# tmp+mv on the synchronous-equivalent hot path.
[[ -f "$STATE_FILE" ]] || exit 0
[[ "$(state_read "$STATE_FILE" '.active // false')" == "true" ]] || exit 0

# Register cleanup BEFORE acquire — release_state_lock is PID-aware so a
# failed acquire (and the resulting EXIT) won't clobber another process's
# lock. INT/TERM chain through EXIT to release on signal kills.
trap 'release_state_lock "$STATE_FILE"; rm -f "${STATE_FILE}.tmp.$$" 2>/dev/null' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Acquire exclusive lock — concurrent writers (task-start.sh, parallel
# track-changes invocations) would otherwise clobber the state file via
# interleaved tmp+mv. Drop this update on contention rather than blocking
# tool execution.
if ! acquire_state_lock "$STATE_FILE"; then
  exit 0
fi

# Append all paths to the active-loop session state (dedup via unique). Bump
# .edits_since_last_spawn by 1 — one tool call regardless of how many files
# MultiEdit touched, because the counter measures "main-agent edit operations
# since the last Agent tool returned" and one tool invocation is one
# operation. track-spawns.sh resets it back to 0 on PostToolUse Agent.
TEMP="${STATE_FILE}.tmp.$$"
jq '.modified_files = ((.modified_files // []) + $ARGS.positional | unique)
    | .edits_since_last_spawn = ((.edits_since_last_spawn // 0) + 1)' \
  "$STATE_FILE" --args "${FILE_PATHS[@]}" > "$TEMP" && mv "$TEMP" "$STATE_FILE"

exit 0
