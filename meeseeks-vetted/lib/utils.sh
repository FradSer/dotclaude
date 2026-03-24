#!/bin/bash
#
# lib/utils.sh — shared utilities for meeseeks-vetted hooks
#
# Provides:
#   STOP_CHAR          — canonical verified-tag content
#   state_dir          — session state directory path
#   extract_verified_text — parse <verified> tag from assistant message
#   run_haiku_merge    — call Haiku for one-sentence synthesis

set -euo pipefail

STOP_CHAR="Fully Vetted."

# state_dir — returns the session state directory for the current project.
# Path: ~/.claude/projects/<project-key>/ where project-key = $PWD with '/' → '-'
state_dir() {
  local project_key
  project_key=$(echo "$PWD" | tr '/' '-')
  echo "${HOME}/.claude/projects/${project_key}"
}

# extract_verified_text — extracts content between <verified>...</verified> tags.
# Returns the last match (relevant when multiple tags appear).
extract_verified_text() {
  local msg="${1:-}"
  [[ -z "$msg" ]] && return 0
  # macOS-compatible: use sed instead of grep -P
  echo "$msg" | sed -n 's/.*<verified>\(.*\)<\/verified>.*/\1/p' | tail -1
}

# run_haiku_merge — sends a prompt to Claude Haiku and returns the text response.
# Uses the Anthropic Messages API. Requires ANTHROPIC_API_KEY in the environment.
# Sets VETTED_MERGE_SESSION=1 to prevent hook recursion if claude CLI is involved.
run_haiku_merge() {
  local prompt="${1:-}"
  [[ -z "$prompt" ]] && return 0

  export VETTED_MERGE_SESSION=1

  local api_key="${ANTHROPIC_API_KEY:-}"
  if [[ -z "$api_key" ]]; then
    # Fallback: return empty so callers use their own fallback logic
    return 0
  fi

  local payload
  payload=$(jq -n \
    --arg prompt "$prompt" \
    '{
      model: "claude-haiku-4-5-20251001",
      max_tokens: 256,
      messages: [{role: "user", content: $prompt}]
    }')

  local response
  response=$(curl -sS --max-time 10 \
    -H "x-api-key: ${api_key}" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "$payload" \
    "https://api.anthropic.com/v1/messages" 2>/dev/null) || return 0

  echo "$response" | jq -r '.content[0].text // ""' 2>/dev/null
}
