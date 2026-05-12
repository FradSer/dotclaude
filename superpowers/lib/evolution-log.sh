#!/bin/bash
# lib/evolution-log.sh — thin wrapper that appends one NDJSON line to
# docs/retros/evolution-log.jsonl for retrospective Phase 4 step 3
# (item_* events) and Phase 6 closure (retrospective_run,
# component_reinstated).
#
# Two invocation modes (matching bail-log.sh / observations.sh):
#   1. Sourced: source "${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh"
#              log_evolution_event <event_type> <payload_jq_filter> [args...]
#   2. Executed: bash "${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh" \
#                  <event_type> <payload_jq_filter> [args...]
#
# Schema per line (NDJSON):
#   {"event":     "<event_type>",
#    "timestamp": "<ISO8601 UTC>",
#    ...payload}
#
# The envelope MERGES the caller-supplied payload jq object with
# {event, timestamp} — a flat row that matches the pre-existing
# evolution-log.jsonl schema (see evolution-protocol.md lines 85-170).
# This is distinct from skill-events.sh, which NESTS the payload.
#
# Best-effort throughout — missing jq, unwritable docs/retros, missing
# repo_root, or a `date` failure all silently skip the write and return
# 0. The file deliberately has no top-level `set -e` / `set -u` /
# `set -o pipefail`, so sourcing does not alter the caller's
# error-handling regime.

[[ -n "${_EVOLUTION_LOG_LOADED:-}" ]] && return 0

# shellcheck source=./retro-events.sh
source "$(dirname "${BASH_SOURCE[0]}")/retro-events.sh"

log_evolution_event() {
  local event_type="${1:-}"
  local payload_filter="${2:-}"
  [[ -z "$event_type" || -z "$payload_filter" ]] && return 0
  shift 2

  jq_or_skip || return 0

  local root
  root="$(repo_root_or_skip)" || return 0

  local now
  now="$(timestamp_or_skip)" || return 0

  local log_dir="${root}/docs/retros"
  local log_file="${log_dir}/evolution-log.jsonl"
  ensure_log_dir "$log_dir" || return 0

  # Merge the caller's payload with {event, timestamp}. Result is a flat
  # NDJSON row. jq's `+` on two objects: left-side positions for shared
  # keys + right-side values + right-only keys appended at end. Placing
  # the caller's payload on the LEFT lets the caller control top-level
  # key ordering by referencing `$event` / `$timestamp` inline — the
  # envelope on the right then OVERWRITES those values with the
  # authoritative `--arg event` / `--arg timestamp` while preserving
  # the caller's chosen position. This is the migration-parity contract
  # (006-impl): legacy `evolution-log.jsonl` rows used different
  # unsorted-key orderings per event type — `{timestamp, event, ...}`
  # for `item_added`, `{event, timestamp, ...}` for `retrospective_run`.
  # Each caller now picks the position by including `$event` and
  # `$timestamp` references in its payload filter.
  local merged_program
  merged_program="(${payload_filter}) + {event:\$event, timestamp:\$timestamp}"

  write_jsonl "$log_file" \
    "$merged_program" \
    --arg event "$event_type" \
    --arg timestamp "$now" \
    "$@"
}

_EVOLUTION_LOG_LOADED=1

# Direct execution mode — forward args to log_evolution_event. Sourcing
# this file (BASH_SOURCE[0] != $0) does not trigger this branch.
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
  log_evolution_event "$@"
fi
