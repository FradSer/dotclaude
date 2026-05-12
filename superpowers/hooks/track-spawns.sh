#!/bin/bash
#
# track-spawns.sh — PostToolUse hook for the Agent tool.
#
# Resets state.edits_since_last_spawn to 0. Paired with track-changes.sh
# which bumps the counter on every Edit/Write/MultiEdit. Together they
# feed lib/loop.sh's stuck detection: when the counter exceeds 5 inside
# an executing-plans loop past iteration 1, the main agent has been
# editing batch files inline instead of spawning a coordinator.
#
# Reset on PostToolUse (not Pre) so increments from sub-agent tool calls
# during the spawn — which fire PostToolUse in the main session too —
# get discarded along with the main-agent edits that preceded the spawn.
# Net semantic: "edits the main agent has made since the last sub-agent
# returned."

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=../lib/utils.sh
source "${SCRIPT_DIR}/../lib/utils.sh"

[[ "${_SUPERPOWERS_DEPS_MISSING:-}" == "1" ]] && exit 0

HOOK_INPUT=$(cat)
SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.session_id // "default"')
STATE_FILE="$(state_dir)/${SESSION_ID}.superpowers.json"

[[ -f "$STATE_FILE" ]] || exit 0

trap 'release_state_lock "$STATE_FILE"; rm -f "${STATE_FILE}.tmp.$$" 2>/dev/null' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

acquire_state_lock "$STATE_FILE" || exit 0

TEMP="${STATE_FILE}.tmp.$$"
jq '.edits_since_last_spawn = 0' "$STATE_FILE" > "$TEMP" && mv "$TEMP" "$STATE_FILE"

exit 0
