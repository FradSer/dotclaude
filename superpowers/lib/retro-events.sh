#!/bin/bash
# lib/retro-events.sh — shared core for the three retro NDJSON helpers
# (observations.sh, evolution-log.sh, skill-events.sh).
#
# Exposes six primitives used by every channel wrapper:
#   - jq_or_skip           jq presence check (0 if present, 1 otherwise)
#   - timestamp_or_skip    ISO-8601 UTC timestamp on stdout (1 on failure)
#   - ensure_log_dir       mkdir -p one abs path (0/1)
#   - repo_root_or_skip    project root from utils.sh::repo_root (1 if empty)
#   - write_jsonl          jq -nc <filter> [args] >> <log_file>; always 0
#   - dedup_check          tail -200 | grep -qF <substring>; 0 if found
#
# Contract mirrors `lib/bail-log.sh`:
#   1. Best-effort — every primitive may fail without aborting the caller.
#   2. No top-level `set -e` / `set -u` / `set -o pipefail`. Sourcing
#      MUST NOT change the caller's error-handling regime.
#   3. Sourceable + executable safe: file is library-only (no exec footer),
#      but the module loader idiom below makes double-source a no-op.
#
# Load guard: callers can source this file from multiple wrappers in the
# same shell session without re-running the utils.sh deps check.
[[ -n "${_RETRO_EVENTS_LOADED:-}" ]] && return 0

# Source utils.sh exactly once. utils.sh self-guards via
# `_SUPERPOWERS_DEPS_CHECKED`, so re-sourcing from a sibling wrapper is
# also a no-op — `_SUPERPOWERS_DEPS_CHECKED=1` survives across this file
# being loaded for the first time.
_RETRO_EVENTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
# shellcheck source=./utils.sh
source "${_RETRO_EVENTS_DIR}/utils.sh"

# Returns 0 if `jq` is in PATH, 1 otherwise. Callers chain
# `jq_or_skip || return 0` so the wrapper exits silently on missing jq.
jq_or_skip() {
  command -v jq >/dev/null 2>&1
}

# Prints ISO-8601 UTC timestamp on stdout (`2026-05-12T00:00:00Z` shape).
# Returns 1 if `date` errors or yields an empty string — callers chain
# `ts=$(timestamp_or_skip) || return 0` to skip the write on date failure.
timestamp_or_skip() {
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
  if [[ -z "$now" ]]; then
    return 1
  fi
  printf '%s' "$now"
}

# `mkdir -p <abs_path>`; returns 0 on success, 1 on failure. The
# wrapper's caller chains `ensure_log_dir "$d" || return 0`.
ensure_log_dir() {
  local dir="${1:-}"
  [[ -z "$dir" ]] && return 1
  mkdir -p "$dir" 2>/dev/null
}

# Prints the resolved project root on stdout (via utils.sh::repo_root).
# Returns 1 if `repo_root` came back empty — chain
# `root=$(repo_root_or_skip) || return 0` to skip.
repo_root_or_skip() {
  local root
  root="$(repo_root)"
  if [[ -z "$root" ]]; then
    return 1
  fi
  printf '%s' "$root"
}

# Append one NDJSON line to <log_file> by running
#   jq -nc "<jq_program>" [jq_args...]
# All failures (jq parse error, fs write error, missing log dir) are
# swallowed by redirecting stderr to /dev/null and the trailing `|| true`.
# Returns 0 unconditionally — best-effort append contract.
write_jsonl() {
  local log_file="${1:-}"
  local jq_program="${2:-}"
  shift 2 || return 0
  [[ -z "$log_file" || -z "$jq_program" ]] && return 0
  jq -nc "$jq_program" "$@" >> "$log_file" 2>/dev/null || true
  return 0
}

# Returns 0 if <substring> appears in the last 200 lines of <log_file>.
# Returns 1 if the substring is not found OR the file is missing.
# Used by wrappers (e.g. systematic-debugging Phase 4) to suppress a
# duplicate emission within the same session — mirrors the dedup pattern
# in `loop.sh::_loop_log_plan_completion_if_executing`.
dedup_check() {
  local log_file="${1:-}"
  local substring="${2:-}"
  [[ -z "$log_file" || -z "$substring" ]] && return 1
  [[ -f "$log_file" ]] || return 1
  tail -n 200 "$log_file" 2>/dev/null | grep -qF -- "$substring"
}

_RETRO_EVENTS_LOADED=1
