#!/bin/bash
# lib/skill-events.sh — thin wrapper that appends one NDJSON line to
# docs/retros/skill-events.jsonl for systematic-debugging Phase 4
# (fix_completed) and future producing skills.
#
# Two invocation modes (matching bail-log.sh / observations.sh /
# evolution-log.sh):
#   1. Sourced: source "${CLAUDE_PLUGIN_ROOT}/lib/skill-events.sh"
#              log_skill_event <skill> <event> <payload_jq_filter> [args...]
#   2. Executed: bash "${CLAUDE_PLUGIN_ROOT}/lib/skill-events.sh" \
#                  <skill> <event> <payload_jq_filter> [args...]
#
# Schema per line (NDJSON):
#   {"event":     "<event>",
#    "skill":     "<skill>",
#    "timestamp": "<ISO8601 UTC>",
#    "repo_root": "<project root>",
#    "args_hash": "<sha1[:12] of joined args, or empty>",
#    "payload":   { ...caller-supplied object }}
#
# The envelope NESTS the payload (distinct from evolution-log.sh, which
# merges). This keeps the `(skill, event)` clustering key in Phase 5a
# from colliding with payload field names: even if the caller's payload
# object has `event` or `skill` keys, they live inside `payload.`, not
# at the top level.
#
# args_hash: sha1[:12] of the joined positional args after
# <payload_jq_filter>. `shasum -a 1` first, fall back to `sha1sum`.
# When both are absent, args_hash="" and other fields populate normally
# (§2.2 of the design).
#
# Best-effort throughout — missing jq, unwritable docs/retros, missing
# repo_root, or a `date` failure all silently skip the write and return
# 0. No top-level `set -` (NF3) so sourcing preserves the caller's
# error-handling regime.

[[ -n "${_SKILL_EVENTS_LOADED:-}" ]] && return 0

# shellcheck source=./retro-events.sh
source "$(dirname "${BASH_SOURCE[0]}")/retro-events.sh"

log_skill_event() {
  local skill="${1:-}"
  local event="${2:-}"
  local payload_filter="${3:-}"
  [[ -z "$skill" || -z "$event" || -z "$payload_filter" ]] && return 0
  shift 3

  jq_or_skip || return 0

  local root
  root="$(repo_root_or_skip)" || return 0

  local now
  now="$(timestamp_or_skip)" || return 0

  local log_dir="${root}/docs/retros"
  local log_file="${log_dir}/skill-events.jsonl"
  ensure_log_dir "$log_dir" || return 0

  # Compute args_hash from the joined positional args after the payload
  # filter — these are the caller's --arg/--argjson pairs that uniquely
  # identify this invocation. Empty hash is a valid degradation state
  # per §2.2 (neither shasum nor sha1sum on PATH).
  local args_hash=""
  local joined
  joined="$(printf '%s\n' "$@")"
  if command -v shasum >/dev/null 2>&1; then
    args_hash=$(printf '%s' "$joined" | shasum -a 1 2>/dev/null | awk '{print $1}' | cut -c1-12)
  elif command -v sha1sum >/dev/null 2>&1; then
    args_hash=$(printf '%s' "$joined" | sha1sum 2>/dev/null | awk '{print $1}' | cut -c1-12)
  fi

  # Build the envelope with the payload NESTED under `payload`. Top-level
  # keys are exactly {event, skill, timestamp, repo_root, args_hash,
  # payload} — payload's own keys cannot shadow the envelope.
  local envelope_program
  envelope_program="{event:\$event, skill:\$skill, timestamp:\$timestamp, repo_root:\$repo_root, args_hash:\$args_hash, payload: (${payload_filter})}"

  write_jsonl "$log_file" \
    "$envelope_program" \
    --arg event "$event" \
    --arg skill "$skill" \
    --arg timestamp "$now" \
    --arg repo_root "$root" \
    --arg args_hash "$args_hash" \
    "$@"
}

_SKILL_EVENTS_LOADED=1

# Direct execution mode — forward args to log_skill_event. Sourcing this
# file (BASH_SOURCE[0] != $0) does not trigger this branch.
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
  log_skill_event "$@"
fi
