#!/bin/bash
#
# stop-hook.sh — Stop hook entry point.
#
# Thin dispatcher that delegates to two responsibilities:
#   Phase 1 (lib/loop.sh) — Superpower Loop iteration
#   Phase 2 (lib/vet.sh)  — Work verification (need-vet)
#
# Phase 1 either exits (loop is actively iterating) or returns so Phase 2 runs.
# Phase 2 always exits.
#
# State file: ~/.claude/projects/<project-key>/<session_id>.superpowers.json

set -euo pipefail

# Guard: running inside the merge sub-session — exit immediately
[[ "${SUPERPOWERS_MERGE_SESSION:-}" == "1" ]] && exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=../lib/utils.sh
source "${SCRIPT_DIR}/../lib/utils.sh"
# shellcheck source=../lib/loop.sh
source "${SCRIPT_DIR}/../lib/loop.sh"
# shellcheck source=../lib/vet.sh
source "${SCRIPT_DIR}/../lib/vet.sh"

HOOK_INPUT=$(cat)
HOOK_SESSION=$(echo "$HOOK_INPUT" | jq -r '.session_id // ""')
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // ""')
LAST_MSG=$(echo "$HOOK_INPUT" | jq -r '.last_assistant_message // ""')

STATE_FILE=$(find_state_file "$HOOK_SESSION")
[[ -z "$STATE_FILE" ]] && exit 0

# Guard: corrupted JSON — remove and allow exit
if ! jq empty "$STATE_FILE" 2>/dev/null; then
  echo "Warning: State file corrupted, removing: $STATE_FILE" >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# Phase 1: loop iteration (may exit; returns 0 to fall through)
loop_phase "$STATE_FILE" "$TRANSCRIPT_PATH"

# Phase 2: work verification (always exits)
vet_phase "$STATE_FILE" "$LAST_MSG" "$TRANSCRIPT_PATH"
