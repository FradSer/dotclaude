#!/bin/bash
#
# hooks/consolidate-stop.sh — the memory plugin's single Stop hook:
# auto-consolidation of the project's memory, debounced per project.
#
# This hook does NOT know any memory logic. It only:
#   1. resolves the session cwd (CLAUDE_PROJECT_DIR, else Stop payload `cwd`);
#   2. probes both space-handling escape forms to find the private memory dir;
#   3. debounces per project (24h);
#   4. backgrounds a headless `claude -p` that reads the instructions in
#      skills/consolidate/SKILL.md (the single source of truth) and runs the
#      full consolidation pass over both memory locations: the private harness
#      memory at $MEMORY_DIR and the repo memory at docs/memory/.
#
# Contract: never break a turn. Always exit 0. No memory dir / no cwd ->
# silent skip + log line. A clean pass is silent.
#
# Reference: https://code.claude.com/docs/en/hooks (Stop)

set -u

INTERVAL=86400  # 24 hours, per project
LOG_FILE="$HOME/.claude/consolidate.log"
# plugin.json substitutes ${CLAUDE_PLUGIN_ROOT}, and the harness also exports it
# to the spawned process; fall back to SCRIPT_DIR for manual runs.
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." >/dev/null 2>&1 && pwd)}"

# Always drain stdin (the Stop hook payload) so the harness never blocks on a
# broken pipe. Only consult the payload when CLAUDE_PROJECT_DIR is unset.
PAYLOAD=$(cat 2>/dev/null || printf '')

CWD="${CLAUDE_PROJECT_DIR:-}"
if [[ -z "$CWD" && -n "$PAYLOAD" ]]; then
  CWD=$(printf '%s' "$PAYLOAD" | python3 -c "import json,sys;print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null || printf '')
fi

# No cwd resolved -> nothing to consolidate. Don't break the turn.
if [[ -z "$CWD" ]]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') Skipped: no cwd resolved" >> "$LOG_FILE"
  exit 0
fi

# Escape the absolute path the way Claude Code names project folders: '/' -> '-'.
# Space handling is inconsistent across versions ('Home Lab' -> '-Home-Lab' but
# 'Work Research' keeps the space), so probe both forms.
PROJECTS_ROOT="$HOME/.claude/projects"
MEMORY_DIR=""
for cand in "$(printf '%s' "$CWD" | sed 's|/|-|g; s| |-|g')" "$(printf '%s' "$CWD" | sed 's|/|-|g')"; do
  if [[ -d "$PROJECTS_ROOT/$cand/memory" ]]; then
    MEMORY_DIR="$PROJECTS_ROOT/$cand/memory"
    break
  fi
done

# No memory dir for this project yet -> nothing to consolidate.
if [[ -z "$MEMORY_DIR" ]]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') Skipped: no memory dir for $CWD" >> "$LOG_FILE"
  exit 0
fi

# Per-project debounce stamp (16-char hash, normalized across macOS/Linux).
PROJECT_HASH=$(printf '%s' "$CWD" | md5 -q 2>/dev/null | cut -c1-16 || printf '%s' "$CWD" | shasum 2>/dev/null | cut -c1-16)
STAMP_FILE="$HOME/.claude/.last-consolidation-${PROJECT_HASH}"

if [[ -f "$STAMP_FILE" ]]; then
  LAST=$(cat "$STAMP_FILE" 2>/dev/null || echo 0)
  NOW=$(date +%s)
  if [[ $(( NOW - LAST )) -lt "$INTERVAL" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') Skipped: $(( NOW - LAST ))s since last run for $CWD (interval: ${INTERVAL}s)" >> "$LOG_FILE"
    exit 0
  fi
fi

# Mark as running immediately (prevent double-fire), then background the pass.
date +%s > "$STAMP_FILE"

(
  echo "$(date '+%Y-%m-%d %H:%M:%S') Starting consolidation for $CWD..." >> "$LOG_FILE"
  claude -p --dangerously-skip-permissions \
    "Read $PLUGIN_ROOT/skills/consolidate/SKILL.md and execute its consolidation instructions for this project. The private harness memory is at $MEMORY_DIR; the repo memory is docs/memory/ relative to the project root (CLAUDE_PROJECT_DIR). Run the full pass over both. Follow the instructions exactly. Report what changed or that nothing was needed." \
    >> "$LOG_FILE" 2>&1
  echo "$(date '+%Y-%m-%d %H:%M:%S') Done for $CWD (exit: $?)" >> "$LOG_FILE"
) &

exit 0
