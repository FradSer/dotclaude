#!/bin/bash
#
# hooks/consolidate-stop.sh — the memory plugin's single Stop hook: Tier A
# auto-consolidation, debounced per project.
#
# Ported from ~/.claude/consolidate-memory.sh (the home dotfiles script,
# verified 2026-07-31 on the Home Lab project), refactored to:
#   - source lib/memory-lib.sh for the escape/debounce/path helpers (single
#     source of truth shared with the skills);
#   - resolve plugin-relative paths via SCRIPT_DIR, matching
#     superpowers/hooks/stop-state-sync.sh's convention;
#   - drain stdin so the harness never blocks on a broken pipe.
#
# Contract: never break a turn. Always exit 0. No memory dir / no cwd ->
# silent skip + log line. A clean pass is silent. The heavy work (the 5-phase
# consolidation prompt) runs backgrounded as `claude -p` so the Stop returns
# immediately.
#
# Reference: https://code.claude.com/docs/en/hooks (Stop)

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"
# shellcheck source=../lib/memory-lib.sh
source "$PLUGIN_ROOT/lib/memory-lib.sh"

INTERVAL=86400  # 24 hours, per project
LOG_FILE="$HOME/.claude/consolidate.log"

# Always drain stdin (the Stop hook payload) so the harness never blocks on a
# broken pipe — matches superpowers/hooks/stop-state-sync.sh:54. We only
# consult the payload when CLAUDE_PROJECT_DIR is unset (the fallback path).
PAYLOAD=$(cat 2>/dev/null || printf '')

CWD="${CLAUDE_PROJECT_DIR:-}"
if [[ -z "$CWD" ]]; then
  if [[ -n "$PAYLOAD" ]]; then
    CWD=$(printf '%s' "$PAYLOAD" | python3 -c "import json,sys;print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null || printf '')
  fi
fi

# No cwd resolved -> nothing to consolidate. Don't break the turn.
if [[ -z "$CWD" ]]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') Skipped: no cwd resolved" >> "$LOG_FILE"
  exit 0
fi

MEMORY_DIR=$(tier_a_dir "$CWD")
STAMP_FILE=$(project_stamp "$CWD")

# No memory dir for this project yet -> nothing to consolidate.
if [[ -z "$MEMORY_DIR" ]] || [[ ! -d "$MEMORY_DIR" ]]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') Skipped: no memory dir for $CWD" >> "$LOG_FILE"
  exit 0
fi

# Debounce check (per project)
if [[ -f "$STAMP_FILE" ]]; then
  LAST=$(cat "$STAMP_FILE" 2>/dev/null || echo 0)
  NOW=$(date +%s)
  DIFF=$((NOW - LAST))
  if [[ "$DIFF" -lt "$INTERVAL" ]]; then
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
