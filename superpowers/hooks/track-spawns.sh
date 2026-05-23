#!/bin/bash
#
# track-spawns.sh — PostToolUse hook for the Agent tool.
#
# Resets both stuck-detection counters to 0:
#   - state.edits_since_last_spawn (driven by track-changes.sh)
#   - state.reads_since_last_spawn (driven by track-reads.sh)
#
# Together these feed lib/loop.sh's stuck detection: when either counter
# crosses its threshold inside an executing-plans loop past iter 1, the
# main agent has been substituting direct work (edits) or exploration
# (reads) for the contractual Agent-spawn-per-batch flow.
#
# Reset on PostToolUse (not Pre) so increments from sub-agent tool calls
# during the spawn — which fire PostToolUse in the main session too —
# get discarded along with the main-agent operations that preceded the
# spawn. Net semantic for both counters: "main-agent operations since the
# last sub-agent returned."

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=../lib/utils.sh
source "${SCRIPT_DIR}/../lib/utils.sh"

[[ "${_SUPERPOWERS_DEPS_MISSING:-}" == "1" ]] && exit 0

HOOK_INPUT=$(cat)
SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.session_id // ""')
[[ -z "$SESSION_ID" ]] && exit 0
STATE_FILE=$(find_state_file "$SESSION_ID")
[[ -z "$STATE_FILE" ]] && exit 0

trap 'release_state_lock "$STATE_FILE"; rm -f "${STATE_FILE}.tmp.$$" 2>/dev/null' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

acquire_state_lock "$STATE_FILE" || exit 0

TEMP="${STATE_FILE}.tmp.$$"
jq '.edits_since_last_spawn = 0 | .reads_since_last_spawn = 0' \
  "$STATE_FILE" > "$TEMP" && mv "$TEMP" "$STATE_FILE"

exit 0
