#!/bin/bash
#
# track-reads.sh — PostToolUse hook: count read-only exploration calls
# (Read, Glob, Grep, Bash) per session.
#
# Bumps state.reads_since_last_spawn by 1 per tool call. Paired with
# track-spawns.sh (resets on Agent PostToolUse) and lib/loop.sh stuck
# detection: when the counter exceeds 15 inside an executing-plans loop
# past iteration 1, the main agent has been re-discovering plan state
# instead of acting (the empirical 42-tools-no-Agent symptom).
#
# Bash is included even though it can run arbitrary commands — in
# practice an executing-plans main agent's legitimate Bash uses are
# limited (setup-superpower-loop.sh in iter 1, git-agent commit in
# Phase 5), so 16+ Bash calls without an Agent spawn is the same
# anti-pattern as 16+ Reads: exploration substituting for action.
#
# Runs async — never blocks tool execution.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=../lib/utils.sh
source "${SCRIPT_DIR}/../lib/utils.sh"

# Runtime-deps check — bail soft if jq is missing.
[[ "${_SUPERPOWERS_DEPS_MISSING:-}" == "1" ]] && exit 0

HOOK_INPUT=$(cat)

SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.session_id // "default"')

# Phase 5 git-agent commits are a legitimate, expected Bash use in
# executing-plans; counting them as read-thrash inflates the STUCK signal
# and can false-trip the read-loop recovery hint. Skip git / git-agent
# invocations (the documented false positive); other Bash still counts.
# `select` yields nothing for non-Bash tools, so _cmd stays empty there.
# A leading `cd <dir> &&` wrapper is stripped so the real command is seen.
_cmd=$(echo "$HOOK_INPUT" | jq -r 'select(.tool_name == "Bash") | .tool_input.command // ""' 2>/dev/null)
if [[ -n "$_cmd" ]]; then
  case "${_cmd#cd *&& }" in
    git\ *|git-agent\ *) exit 0 ;;
  esac
fi

STATE_FILE="$(state_dir)/${SESSION_ID}.superpowers.json"

# Track only inside an active Superpower Loop. reads_since_last_spawn is
# consumed solely by lib/loop.sh's executing-plans stuck detection, which
# requires active=true. Outside a loop this hook used to fire on every
# Read/Glob/Grep/Bash in every session — accumulating a counter nothing
# reads. One jq read here replaces an unconditional lock + tmp+mv on the
# highest-frequency tool path in the plugin.
[[ -f "$STATE_FILE" ]] || exit 0
[[ "$(state_read "$STATE_FILE" '.active // false')" == "true" ]] || exit 0

# Lock acquisition pattern mirrors track-changes.sh — register cleanup
# BEFORE acquire so a failed acquire (and its EXIT) won't release
# someone else's lock.
trap 'release_state_lock "$STATE_FILE"; rm -f "${STATE_FILE}.tmp.$$" 2>/dev/null' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if ! acquire_state_lock "$STATE_FILE"; then
  exit 0
fi

TEMP="${STATE_FILE}.tmp.$$"
jq '.reads_since_last_spawn = ((.reads_since_last_spawn // 0) + 1)' \
  "$STATE_FILE" > "$TEMP" && mv "$TEMP" "$STATE_FILE"

exit 0
