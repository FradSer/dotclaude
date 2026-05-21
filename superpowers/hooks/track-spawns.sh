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
# shellcheck source=../lib/jsonl-emit.sh
source "${SCRIPT_DIR}/../lib/jsonl-emit.sh"

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

# Batch-boundary telemetry — emit one rich row to harness-observations.jsonl
# capturing the counters this spawn is about to zero. This is the data source
# for retrospective Phase 5 to verify the "reset > compaction" hypothesis
# from reflection 01-context-management.md. Emit only for an active loop with
# a non-empty batch; failures here must never block the reset below.
edits_count=0 reads_count=0 is_active=false skill_name=""
IFS=$'\t' read -r edits_count reads_count is_active skill_name < <(
  jq -r '[(.edits_since_last_spawn // 0), (.reads_since_last_spawn // 0), (.active // false), (.skill_name // "")] | @tsv' \
    "$STATE_FILE" 2>/dev/null) || true

if [[ "$is_active" == "true" ]] && { [[ "$edits_count" -gt 0 ]] 2>/dev/null || [[ "$reads_count" -gt 0 ]] 2>/dev/null; }; then
  root=$(repo_root_or_skip 2>/dev/null) || root=""
  now=$(timestamp_or_skip 2>/dev/null) || now=""
  if [[ -n "$root" && -n "$now" ]]; then
    log_dir="${root}/docs/retros"
    if ensure_log_dir "$log_dir" 2>/dev/null; then
      write_jsonl "${log_dir}/harness-observations.jsonl" \
        '{event:"batch_spawn", component:"track-spawns", timestamp:$timestamp, repo_root:$repo_root, skill_name:$skill, session_id:$sid, edits_in_batch:($edits|tonumber), reads_in_batch:($reads|tonumber)}' \
        --arg timestamp "$now" \
        --arg repo_root "$root" \
        --arg skill "$skill_name" \
        --arg sid "$SESSION_ID" \
        --arg edits "$edits_count" \
        --arg reads "$reads_count" 2>/dev/null || true
    fi
  fi
fi

TEMP="${STATE_FILE}.tmp.$$"
jq '.edits_since_last_spawn = 0 | .reads_since_last_spawn = 0' \
  "$STATE_FILE" > "$TEMP" && mv "$TEMP" "$STATE_FILE"

exit 0
