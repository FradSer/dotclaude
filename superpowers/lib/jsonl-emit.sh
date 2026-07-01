#!/bin/bash
# lib/jsonl-emit.sh — single channel-agnostic NDJSON emitter for the
# docs/retros/*.jsonl audit streams.
#
# Two invocation modes:
#
#   1. SOURCED — primitives for composing envelopes inline:
#
#        jq_or_skip                       rc 0 if jq in PATH
#        timestamp_or_skip                prints ISO-8601 UTC; rc 1 on date failure
#        repo_root_or_skip                prints utils.sh::repo_root; rc 1 if empty
#        ensure_log_dir <dir>             mkdir -p; rc 1 on failure
#        write_jsonl <file> <jq> [args]   jq -nc >> file; always rc 0
#        dedup_check <file> <substring>   rc 0 if substring in tail -200
#
#   2. EXECUTED — single dispatch with explicit channel name:
#
#        bash jsonl-emit.sh <channel> <jq_program> [--arg|--argjson ...]
#
#      <channel> is the basename written to docs/retros/<channel>.jsonl.
#      The script auto-injects two args before the caller's args:
#        --arg timestamp <ISO-8601 UTC>
#        --arg repo_root <repo root>
#      so the caller's jq program can reference $timestamp and $repo_root
#      without re-deriving them. Every other envelope field (event, skill,
#      component, payload, args_hash, etc.) is the caller's responsibility
#      — there are no per-channel envelope shapes hard-coded here.
#
# Best-effort throughout — missing jq, unwritable docs/retros, missing
# repo_root, or a `date` failure all silently skip the write and return
# 0. No top-level `set -` so sourcing never alters the caller's
# error-handling regime.

[[ -n "${_JSONL_EMIT_LOADED:-}" ]] && return 0

_JSONL_EMIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
# shellcheck source=./utils.sh
source "${_JSONL_EMIT_DIR}/utils.sh"

jq_or_skip() { command -v jq >/dev/null 2>&1; }

timestamp_or_skip() {
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
  if [[ -z "$now" ]]; then
    return 1
  fi
  printf '%s' "$now"
}

ensure_log_dir() {
  local dir="${1:-}"
  [[ -z "$dir" ]] && return 1
  mkdir -p "$dir" 2>/dev/null
}

repo_root_or_skip() {
  local root
  root="$(repo_root)"
  if [[ -z "$root" ]]; then
    return 1
  fi
  printf '%s' "$root"
}

# Append one NDJSON line. All failures swallowed; rc is always 0.
write_jsonl() {
  local log_file="${1:-}"
  local jq_program="${2:-}"
  shift 2 || return 0
  [[ -z "$log_file" || -z "$jq_program" ]] && return 0
  jq -nc "$jq_program" "$@" >> "$log_file" 2>/dev/null || true
  return 0
}

# Returns 0 if <substring> appears in the last 200 lines of <log_file>.
dedup_check() {
  local log_file="${1:-}"
  local substring="${2:-}"
  [[ -z "$log_file" || -z "$substring" ]] && return 1
  [[ -f "$log_file" ]] || return 1
  tail -n 200 "$log_file" 2>/dev/null | grep -qF -- "$substring"
}

_JSONL_EMIT_LOADED=1

# Executed-mode dispatcher. Sourcing (BASH_SOURCE[0] != $0) skips this.
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
  channel="${1:-}"
  jq_program="${2:-}"
  if [[ -z "$channel" || -z "$jq_program" ]]; then
    exit 0
  fi
  shift 2

  jq_or_skip || exit 0
  root=$(repo_root_or_skip) || exit 0
  now=$(timestamp_or_skip) || exit 0
  log_dir="${root}/docs/retros"
  ensure_log_dir "$log_dir" || exit 0
  log_file="${log_dir}/${channel}.jsonl"
  write_jsonl "$log_file" "$jq_program" \
    --arg timestamp "$now" \
    --arg repo_root "$root" \
    "$@"
fi
