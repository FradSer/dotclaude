#!/bin/bash
# Shared utilities for superpowers hooks and scripts

# Return the project-scoped state directory path (~/.claude/projects/<key>/)
# Usage: DIR=$(state_dir)
state_dir() {
  local project_key
  project_key=$(echo "${PWD:-$HOME}" | tr '/' '-')
  echo "$HOME/.claude/projects/${project_key}"
}

# Find the state file owned by a given session ID.
# Scans all *.superpowers.json files in the state dir and matches session_id.
# Falls back to the first file without a session_id (legacy compat).
# Usage: FILE=$(find_state_file "$SESSION_ID")
find_state_file() {
  local session_id="$1"
  local dir
  dir="$(state_dir)"
  [[ -d "$dir" ]] || return

  # Collect matching files; handle zero matches gracefully
  local files
  files=$(find "$dir" -maxdepth 1 -name '*.superpowers.json' 2>/dev/null) || return
  [[ -z "$files" ]] && return

  local candidate
  for candidate in $files; do
    [[ -f "$candidate" ]] || continue
    local candidate_session
    candidate_session=$(jq -r '.session_id // ""' "$candidate" 2>/dev/null || echo "")
    if [[ -z "$candidate_session" ]] || [[ "$candidate_session" == "$session_id" ]]; then
      echo "$candidate"
      return
    fi
  done
}

# Read a field from a JSON state file.
# Usage: VAL=$(state_read "$STATE_FILE" ".field")
state_read() {
  local file="$1"
  local query="$2"
  jq -r "$query" "$file" 2>/dev/null || echo ""
}

# Atomically update a JSON state file via jq filter.
# Uses tmp+mv pattern to avoid partial writes.
# Usage: state_update "$STATE_FILE" --arg key val '.field = $key'
state_update() {
  local file="$1"
  shift
  local temp="${file}.tmp.$$"
  jq "$@" "$file" > "$temp" && mv "$temp" "$file"
}

# Extract text from <promise>...</promise> tags (multiline-safe via Perl)
# Usage: TEXT=$(extract_promise_text "$MESSAGE")
extract_promise_text() {
  echo "$1" | perl -0777 -pe \
    's/.*?<promise>(.*?)<\/promise>.*/$1/s; s/^\s+|\s+$//g; s/\s+/ /g' \
    2>/dev/null || echo ""
}

# Extract the last assistant text block from a transcript file.
# Returns the final text content block from assistant messages.
# Usage: TEXT=$(extract_last_assistant_text "$TRANSCRIPT_PATH" [MAX_LINES])
extract_last_assistant_text() {
  local transcript_path="$1"
  local max_lines="${2:-100}"
  [[ -f "$transcript_path" ]] || return

  local last_lines
  last_lines=$(grep '"role":"assistant"' "$transcript_path" | tail -n "$max_lines")
  [[ -z "$last_lines" ]] && return

  set +e
  echo "$last_lines" | jq -rs '
    map(.message.content[]? | select(.type == "text") | .text) | last // ""
  ' 2>/dev/null
  set -e
}

# --- Vet utilities ---

# Canonical verified-tag content marker
STOP_CHAR="Fully Vetted."

# Extract content between <verified>...</verified> tags.
# Returns the last match (relevant when multiple tags appear).
# macOS-compatible: uses sed instead of grep -P.
# Usage: TEXT=$(extract_verified_text "$MESSAGE")
extract_verified_text() {
  local msg="${1:-}"
  [[ -z "$msg" ]] && return 0
  echo "$msg" | sed -n 's/.*<verified>\(.*\)<\/verified>.*/\1/p' | tail -1
}

# Send a prompt to Claude Haiku and return the text response.
# Uses Claude Code native auth via `claude --bare` (no API key env vars needed).
# Sets SUPERPOWERS_MERGE_SESSION=1 to prevent hook recursion.
# Usage: RESULT=$(run_haiku_merge "Synthesize a summary from: ...")
run_haiku_merge() {
  local prompt="${1:-}"
  [[ -z "$prompt" ]] && return 0

  # Guard against recursion — hooks check this var and exit immediately.
  # --bare also skips hook loading in the sub-session.
  export SUPERPOWERS_MERGE_SESSION=1

  # Use Claude Code native auth. --bare skips hooks/plugins to prevent recursion.
  local result
  result=$(claude --bare \
    --model claude-haiku-4-5-20251001 \
    --output-format text \
    -p "$prompt" \
    2>/dev/null) || return 0

  echo "$result"
}
