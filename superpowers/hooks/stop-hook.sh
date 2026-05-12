#!/bin/bash
#
# stop-hook.sh — Stop hook entry point.
#
# Delegates to lib/loop.sh::loop_phase for Superpower Loop iteration.
# loop_phase either exits (loop is actively iterating) or returns 0 to allow
# session exit.
#
# State file: ~/.claude/projects/<project-key>/<session_id>.superpowers.json

set -euo pipefail

# Short-circuit when running inside an LLM sub-session.
# Two-flag rationale: utils.sh::run_haiku_merge + TODO-v3.md T-003.
[[ "${SUPERPOWERS_SUBSESSION:-}" == "1" || "${SUPERPOWERS_MERGE_SESSION:-}" == "1" ]] && exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=../lib/utils.sh
source "${SCRIPT_DIR}/../lib/utils.sh"
# shellcheck source=../lib/loop.sh
source "${SCRIPT_DIR}/../lib/loop.sh"

# Runtime-deps check — bail soft if jq/perl are missing so the user can
# always Stop the session cleanly. Surface a Claude-Code-visible
# systemMessage (stdout JSON + exit 0) so the silent skip is observable —
# previously the Stop hook went mute on missing deps and the user could
# not tell loop continuation / state writes had been disabled.
if [[ "${_SUPERPOWERS_DEPS_MISSING:-}" == "1" ]]; then
  emit_deps_missing_systemmessage
  exit 0
fi

HOOK_INPUT=$(cat)
HOOK_SESSION=$(echo "$HOOK_INPUT" | jq -r '.session_id // ""')
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // ""')

STATE_FILE=$(find_state_file "$HOOK_SESSION")
[[ -z "$STATE_FILE" ]] && exit 0

# Guard: corrupted JSON — remove under lock so we don't race with a
# track-changes.sh that's mid-tmp+mv on the same path. Lock timeout
# falls through to an unlocked rm so the user is never blocked by a
# pathological lock holder.
if ! jq empty "$STATE_FILE" 2>/dev/null; then
  echo "Warning: State file corrupted, removing: $STATE_FILE" >&2
  if acquire_state_lock "$STATE_FILE" 10; then
    rm -f "$STATE_FILE"
    release_state_lock "$STATE_FILE"
  else
    rm -f "$STATE_FILE"
  fi
  exit 0
fi

# Loop iteration (may exit; returns 0 to allow session exit)
loop_phase "$STATE_FILE" "$TRANSCRIPT_PATH"
