#!/bin/bash
# lib/bail-log.sh — append bail-out and --force-override events to
# docs/retros/bail-out-events.jsonl for retrospective Phase 5a analysis.
#
# Two invocation modes:
#   1. Sourced: source "${CLAUDE_PLUGIN_ROOT}/lib/bail-log.sh"; bail_log ...
#   2. Executed: bash "${CLAUDE_PLUGIN_ROOT}/lib/bail-log.sh" <skill> <event> [reason] [args]
#
# `event` is one of:
#   bail_out        — bail-out check fired and the skill is short-circuiting
#   force_override  — `--force` token detected and the skill is bypassing the check
#
# Append-only; never blocks the caller. Best-effort throughout — missing jq,
# unwritable cwd, or missing docs/retros all silently skip the write. The
# helper deliberately has no `set -e` so sourcing does not alter the caller's
# error-handling regime.
#
# Schema per line (NDJSON):
#   {"event":"bail_out|force_override",
#    "skill":"<skill>",
#    "reason":"<short>",
#    "args_hash":"<sha1[:12] of args>",
#    "cwd":"<PWD>",
#    "timestamp":"<ISO8601 UTC>"}
#
# args_hash is a salt-free first-12-chars sha1 of the supplied args string —
# enough to group repeat invocations of the same trivial input across a
# session, not enough to recover the original prose. Empty when neither
# shasum nor sha1sum is in PATH.

bail_log() {
  local skill="${1:-unknown}"
  local event="${2:-bail_out}"
  local reason="${3:-}"
  local args="${4:-${ARGUMENTS:-}}"

  command -v jq >/dev/null 2>&1 || return 0

  local log_dir="${PWD}/docs/retros"
  local log_file="${log_dir}/bail-out-events.jsonl"
  mkdir -p "$log_dir" 2>/dev/null || return 0

  local now args_hash=""
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "")
  [[ -z "$now" ]] && return 0

  if command -v shasum >/dev/null 2>&1; then
    args_hash=$(printf '%s' "$args" | shasum -a 1 2>/dev/null | awk '{print $1}' | cut -c1-12)
  elif command -v sha1sum >/dev/null 2>&1; then
    args_hash=$(printf '%s' "$args" | sha1sum 2>/dev/null | awk '{print $1}' | cut -c1-12)
  fi

  jq -nc \
    --arg event "$event" \
    --arg skill "$skill" \
    --arg reason "$reason" \
    --arg args_hash "$args_hash" \
    --arg cwd "$PWD" \
    --arg ts "$now" \
    '{event:$event, skill:$skill, reason:$reason, args_hash:$args_hash, cwd:$cwd, timestamp:$ts}' \
    >> "$log_file" 2>/dev/null || true
}

# Direct execution mode — forward args to bail_log. Sourcing this file
# (BASH_SOURCE[0] != $0) does not trigger this branch.
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
  bail_log "$@"
fi
