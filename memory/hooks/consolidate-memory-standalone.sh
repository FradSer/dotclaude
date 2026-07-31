#!/bin/bash
#
# Memory consolidation hook — runs after Claude Code stops.
# Debounced per project: only runs once per INTERVAL seconds per project.
# Memory dir follows the session's cwd (escaped the way Claude Code names
# project folders: absolute path with '/' -> '-', spaces -> '-' or kept).
#
# This is the standalone root-dotfiles copy. The dotclaude `memory` plugin's
# hooks/consolidate-stop.sh is the shared/plugin form (sourcing lib/memory-lib.sh).
# Keep this self-contained so it runs without the plugin enabled.

set -u

INTERVAL=86400  # 24 hours in seconds
LOG_FILE="$HOME/.claude/consolidate.log"

# Always drain stdin (the Stop hook payload) so the harness never blocks on a
# broken pipe.
PAYLOAD=$(cat 2>/dev/null || printf '')

# Resolve the session's project directory. Prefer CLAUDE_PROJECT_DIR; fall back
# to the `cwd` field of the Stop hook's stdin JSON payload.
CWD="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$CWD" ]; then
  if [ -n "$PAYLOAD" ]; then
    CWD=$(printf '%s' "$PAYLOAD" | python3 -c "import json,sys;print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null || printf '')
  fi
fi

# No cwd resolved -> nothing to consolidate. Don't break the turn.
if [ -z "$CWD" ]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') Skipped: no cwd resolved" >> "$LOG_FILE"
  exit 0
fi

# Escape the absolute path to Claude Code's project-folder convention:
# '/' -> '-'. Space handling is inconsistent across Claude Code versions
# ('Home Lab' -> 'Home-Lab' but 'Work Research' keeps the space), so probe
# both forms and use whichever project folder actually exists.
escape_dir() {
  printf '%s' "$1" | sed 's|/|-|g'
}
ESCAPED_SP2DASH=$(printf '%s' "$CWD" | sed 's|/|-|g; s| |-|g')
ESCAPED_SP_KEEP=$(escape_dir "$CWD")
PROJECTS_ROOT="$HOME/.claude/projects"
MEMORY_DIR=""
for cand in "$ESCAPED_SP2DASH" "$ESCAPED_SP_KEEP"; do
  if [ -d "$PROJECTS_ROOT/$cand/memory" ]; then
    MEMORY_DIR="$PROJECTS_ROOT/$cand/memory"
    break
  fi
done

# Per-project debounce stamp (16-char hash, normalized across macOS/Linux).
PROJECT_HASH=$(printf '%s' "$CWD" | md5 -q 2>/dev/null | cut -c1-16 || printf '%s' "$CWD" | shasum 2>/dev/null | cut -c1-16)
STAMP_FILE="$HOME/.claude/.last-consolidation-${PROJECT_HASH}"

# No memory dir for this project yet -> nothing to consolidate.
if [ -z "$MEMORY_DIR" ] || [ ! -d "$MEMORY_DIR" ]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') Skipped: no memory dir for $CWD" >> "$LOG_FILE"
  exit 0
fi

# Debounce check (per project)
if [ -f "$STAMP_FILE" ]; then
  LAST=$(cat "$STAMP_FILE" 2>/dev/null || echo 0)
  NOW=$(date +%s)
  DIFF=$((NOW - LAST))
  if [ "$DIFF" -lt "$INTERVAL" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') Skipped: ${DIFF}s since last run for $CWD (interval: ${INTERVAL}s)" >> "$LOG_FILE"
    exit 0
  fi
fi

# Mark as running immediately (prevent double-fire)
date +%s > "$STAMP_FILE"

# Run consolidation in background via headless Claude
(
  echo "$(date '+%Y-%m-%d %H:%M:%S') Starting consolidation for $CWD..." >> "$LOG_FILE"

  claude -p --dangerously-skip-permissions \
    "You are performing a memory consolidation pass over all files in ${MEMORY_DIR}/.

Phase 1 — Read: Read every memory file including MEMORY.md.

Phase 2 — Normalize:
- Convert ALL relative dates ('yesterday', 'last week', '5 weeks ago', 'recently', 'months ago') to absolute dates (YYYY-MM-DD). Today is $(date '+%Y-%m-%d').
- Ensure every frontmatter has name, description, and metadata.type fields.

Phase 3 — Deduplicate and Resolve:
- Merge entries that appear in multiple files — keep the most detailed version, remove the rest.
- When contradictions exist, keep the MOST RECENT value and delete the stale one. If recency is unclear, keep the more specific/detailed entry.

Phase 4 — Prune (importance-aware):
- KEEP: memories about active projects, current infrastructure, user preferences, working tools.
- KEEP: memories cross-referenced by [[links]] from multiple other files (high connectivity = high importance).
- PRUNE: memories about dormant projects with no activity in 6+ months, unless they contain durable architectural decisions or lessons learned.
- PRUNE: interview prep, event-specific notes, or time-bound references that have passed their relevance window — retain only transferable insights.
- PRUNE: entries that are purely operational snapshots (disk usage, RAM stats) older than 3 months — mark remaining snapshots with their capture date.

Phase 5 — Rebuild:
- If any files were added, removed, or renamed, rebuild MEMORY.md as a clean index.
- Keep MEMORY.md under 50 lines — one entry per memory file with a short hook.

Output a brief summary of changes made. If no changes were needed, say so." \
    >> "$LOG_FILE" 2>&1

  echo "$(date '+%Y-%m-%d %H:%M:%S') Done for $CWD (exit: $?)" >> "$LOG_FILE"
) &

exit 0
