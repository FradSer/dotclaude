#!/bin/bash
# lib/observations.sh — terse-row helper that appends one NDJSON line to
# docs/retros/harness-observations.jsonl for retrospective Phase 5c's
# refusal gate (`component_unsupported`, `component_unknown`).
#
# Two invocation modes (matching bail-log.sh):
#   1. Sourced: source "${CLAUDE_PLUGIN_ROOT}/lib/observations.sh"
#              log_harness_observation <component> <outcome> <reason>
#   2. Executed: bash "${CLAUDE_PLUGIN_ROOT}/lib/observations.sh" \
#                  <component> <outcome> <reason>
#
# Schema per line (terse-row variant; rich-row producers in
# executing-plans Phase 3/4 and brainstorming Phase 2 keep their own
# richer schema — see architecture.md §"harness-observations.jsonl"):
#
#   {"event":   "<outcome>",
#    "component":"<component>",
#    "reason":  "<reason>",
#    "repo_root":"<project root>",
#    "timestamp":"<ISO8601 UTC>"}
#
# Best-effort throughout — missing jq, unwritable docs/retros, missing
# repo_root, or a `date` failure all silently skip the write and return
# 0. The file deliberately has no top-level `set -e` / `set -u` /
# `set -o pipefail`, so sourcing does not alter the caller's
# error-handling regime.

# Module load guard: a second source of this file from a sibling
# wrapper in the same shell session must be a no-op. Matches the idiom
# used by `evolution-log.sh`, `skill-events.sh`, and `retro-events.sh`.
[[ -n "${_OBSERVATIONS_LOADED:-}" ]] && return 0

# shellcheck source=./retro-events.sh
source "$(dirname "${BASH_SOURCE[0]}")/retro-events.sh"

log_harness_observation() {
  local component="${1:-}"
  local outcome="${2:-}"
  local reason="${3:-}"

  jq_or_skip || return 0

  local root
  root="$(repo_root_or_skip)" || return 0

  local now
  now="$(timestamp_or_skip)" || return 0

  local log_dir="${root}/docs/retros"
  local log_file="${log_dir}/harness-observations.jsonl"
  ensure_log_dir "$log_dir" || return 0

  write_jsonl "$log_file" \
    '{event:$event, component:$component, reason:$reason, repo_root:$repo_root, timestamp:$timestamp}' \
    --arg event "$outcome" \
    --arg component "$component" \
    --arg reason "$reason" \
    --arg repo_root "$root" \
    --arg timestamp "$now"
}

_OBSERVATIONS_LOADED=1

# Direct execution mode — forward args to log_harness_observation.
# Sourcing this file (BASH_SOURCE[0] != $0) does not trigger this branch.
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
  log_harness_observation "$@"
fi
