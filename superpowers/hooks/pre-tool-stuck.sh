#!/bin/bash
#
# pre-tool-stuck.sh — PreToolUse hook that intercepts main-agent
# Edit/Write/MultiEdit calls when the executing-plans loop is past
# iteration 1 and the edits-since-last-spawn counter already exceeds the
# direct-edit allow-list budget. Stops the agent from compounding the
# contract breach — the Stop-hook STUCK banner arrives one turn late,
# after the offending edits have already landed on disk.
#
# Threshold matches the Stop-hook stuck detection in lib/loop.sh:494:
# edits>5 inside executing-plans iter>=2 is the breach signal. The hook
# is READ-ONLY on the state file — no lock acquisition is needed, since
# state_read reads the at-write committed value (writers use tmp+mv
# atomic replace via state_update / track-changes.sh). Dropping the
# lock requirement is what makes PreToolUse interception safe: a Pre
# hook blocked on lock contention would either falsely permit (drop) or
# falsely deny (timeout), and both are worse than reading a slightly
# stale counter.
#
# Output protocol (PreToolUse, Claude Code hooks API):
#   - exit 0 with no JSON → tool call proceeds (default allow)
#   - exit 0 with a hookSpecificOutput.permissionDecision="deny" object →
#     tool call denied + permissionDecisionReason shown. The legacy
#     {"decision":"block"} shape does NOT block PreToolUse (it only blocks
#     Stop/SubagentStop) — verified against code.claude.com/docs hooks ref.
#
# Best-effort like every other superpowers hook: missing deps, missing
# state file, non-integer counters, or any malformed input → silent
# allow (never block the user's session on hook bugs).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=../lib/utils.sh
source "${SCRIPT_DIR}/../lib/utils.sh"

[[ "${_SUPERPOWERS_DEPS_MISSING:-}" == "1" ]] && exit 0

HOOK_INPUT=$(cat)

# One jq pass for both header fields (tool_name gate + session lookup).
# This hook is on the synchronous Edit/Write/MultiEdit path, so every
# fork adds latency to every edit — keep the jq count minimal. Fields are
# joined with the ASCII Unit Separator () rather than a tab: `read`
# collapses runs of whitespace-IFS, which would mis-align an empty leading
# field (e.g. a state file with no skill_name).
TOOL_NAME="" SESSION_ID=""
IFS=$'\037' read -r TOOL_NAME SESSION_ID < <(
  echo "$HOOK_INPUT" | jq -r '[.tool_name // "", .session_id // ""] | join("\u001f")' 2>/dev/null)

case "$TOOL_NAME" in
  Edit|Write|MultiEdit) ;;
  *) exit 0 ;;
esac
[[ -z "$SESSION_ID" ]] && exit 0

STATE_FILE=$(find_state_file "$SESSION_ID")
[[ -z "$STATE_FILE" ]] && exit 0

# One jq pass for all three state fields (same US-separator rationale).
SKILL="" ITER="" EDITS=""
IFS=$'\037' read -r SKILL ITER EDITS < <(
  jq -r '[.skill_name // "", (.iteration // 0 | tostring), (.edits_since_last_spawn // 0 | tostring)] | join("\u001f")' \
    "$STATE_FILE" 2>/dev/null)

[[ "$SKILL" == "executing-plans" ]] || exit 0
[[ "$ITER" =~ ^[0-9]+$ ]] || exit 0
[[ "$EDITS" =~ ^[0-9]+$ ]] || exit 0
[[ $ITER -ge $SP_STUCK_MIN_ITER ]] || exit 0
[[ $EDITS -gt $SP_STUCK_EDIT_BUDGET ]] || exit 0

# Over budget — block before this edit widens the breach. Reason text
# mirrors the Stop-hook STUCK message so the recovery path is identical.
REASON="executing-plans Phase 3 HARD RULE violated: main agent has performed ${EDITS} direct edits since the last Agent spawn (budget = ${SP_STUCK_EDIT_BUDGET}). Spawn a per-batch coordinator via the Agent tool with the sprint contract instead of editing source files directly. See skills/executing-plans/references/batch-execution-playbook.md \"Main Agent's Direct-Edit Allow-List\"."

jq -nc --arg reason "$REASON" \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
exit 0
