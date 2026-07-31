#!/bin/bash
#
# stop-state-sync.sh — the single superpowers Stop hook: mechanical writer for
# every durable docs/retros/*.jsonl side-effect the skills otherwise emit as a
# Claude-instructed step.
#
# Superpowers keeps exactly ONE hook by design. The v3.0.0 teardown deleted the
# continuation loop / stall detector / change-tracking telemetry the old
# stop-hook.sh bundled (native /goal replaced the loop) — correctly. What it
# should NOT have done was demote the deterministic side-effects that rode the
# same removal into Claude-instructed phase steps: empirical audit shows model-
# instructed side-effects are silently dropped (paraphrased or skipped). This
# hook is the state-based safety net for them. Detection is STATE-BASED, never
# keyed off a sentence the model emits; each row is deduped so the normal in-
# skill path (which writes richer rows first) makes the hook a no-op.
#
# Responsibility 1 — plans-completed.jsonl (retrospective Phase 5a reads
# completion_commit ONLY from here). A plan is "complete and unlogged" when:
#   C1  it has >= 1 sprint-contract-batch-*.md          (batches were planned)
#   C2  handoff-summary count >= batch count            (every batch handed off)
#   C3  a git commit touches its handoff-state.md modified-files set
#         (Phase 5 committed — and that commit IS completion_commit, found via
#          git rather than guessed from HEAD)
#   C4  it is not already in plans-completed.jsonl       (first completion only)
#
# Handoff-state file extraction accepts BOTH historical and current templates:
#   files:  "## Modified Files (cumulative)" backtick list
#        OR "## File Ownership" table (first column of data rows)
#   tasks:  "## Completed Task IDs" bullet list
#        OR "## Completed Tasks" table (numeric-ID data rows)
# The current handoff-template.md / evaluation-file-formats.md ship the File
# Ownership + Completed Tasks form; the older unified-retro-events plan used
# the Modified Files / Completed Task IDs form. Both must log.
#
# Responsibility 2 — evolution-log.jsonl backfill. The retrospective skill
# writes these rows as model-instructed steps; the two whose absence is
# self-reinforcing or guard-defeating get a state-based net:
#   2a  retrospective_run watermark — Phase 1 auto-scope reads "plans completed
#       after the most recent retrospective_run". A dropped watermark silently
#       re-analyzes already-analyzed plans every run. Recovered from a retro-*.md
#       report that has no retrospective_run row referencing it.
#   2b  item_added / item_removed — Phase 1's re-proposal guard reads these to
#       avoid re-ADDing a just-REMOVEd item. Recovered by diffing the item IDs
#       of {mode}-v{N}.md against {mode}-v{N-1}.md when no log row references
#       that version. Rationale is unrecoverable from state and is left to the
#       in-skill rich emit; the backfill carries only the guard signal and is
#       marked provenance "hook_backfill".
#
# Fires on EVERY Stop across all sessions/projects. Best-effort throughout
# (missing jq/git, unparseable state all exit 0); never blocks session exit.

set -u

# Drain stdin (hook payload) so the harness never blocks on a broken pipe; we
# derive everything from the filesystem, not from the transcript.
cat >/dev/null 2>&1 || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

command -v jq  >/dev/null 2>&1 || exit 0
command -v git >/dev/null 2>&1 || exit 0

# shellcheck source=../lib/utils.sh
source "${SCRIPT_DIR}/../lib/utils.sh" 2>/dev/null || exit 0
# shellcheck source=../lib/jsonl-emit.sh
source "${SCRIPT_DIR}/../lib/jsonl-emit.sh" 2>/dev/null || exit 0
ROOT="$(repo_root)"
[[ -n "$ROOT" ]] || exit 0
RETROS_DIR="${ROOT%/}/docs/retros"
PLANS_DIR="${ROOT%/}/docs/plans"

EMIT="${SCRIPT_DIR}/../lib/jsonl-emit.sh"
DEDUP_ANCHOR=','  # prefix for dedup_check substring below

# Extract modified-file paths from handoff-state.md.
# Accepts either:
#   - "## Modified Files (cumulative)" section with `backtick` paths (legacy)
#   - "## File Ownership" markdown table, first column of data rows (current
#     handoff-template.md / evaluation-file-formats.md)
# Prefers Modified Files when both exist (legacy explicit list).
_extract_modified_files() {
  local hs="$1"
  awk '
    /^## Modified Files \(cumulative\)/ { mod=1; own=0; next }
    /^## File Ownership/                { if (!mod_seen) own=1; mod=0; next }
    /^## / {
      if (mod) mod_seen=1
      mod=0; own=0; next
    }
    mod {
      line=$0
      while (match(line, /`[^`]+`/)) {
        print substr(line, RSTART+1, RLENGTH-2)
        line=substr(line, RSTART+RLENGTH)
      }
      mod_seen=1
    }
    own {
      # Skip header / separator rows: "| File Path |" or "|---|"
      if ($0 ~ /^\|[[:space:]]*[-:]+/) next
      if ($0 ~ /^\|[[:space:]]*[Ff]ile [Pp]ath/) next
      if ($0 ~ /^\|/) {
        # First cell between leading | and next |
        line=$0
        sub(/^\|[[:space:]]*/, "", line)
        sub(/[[:space:]]*\|.*/, "", line)
        if (line != "" && line !~ /^-+$/) print line
      }
    }
  ' "$hs" 2>/dev/null
}

# Count completed tasks from handoff-state.md.
# Accepts either:
#   - "## Completed Task IDs" bullet list (legacy)
#   - "## Completed Tasks" markdown table with numeric-ID data rows (current)
_extract_task_count() {
  local hs="$1"
  awk '
    /^## Completed Task IDs/ { ids=1; tbl=0; next }
    /^## Completed Tasks/    { if (!ids_seen) tbl=1; ids=0; next }
    /^## / {
      if (ids) ids_seen=1
      ids=0; tbl=0; next
    }
    ids && /^[[:space:]]*-[[:space:]]/ { n++; ids_seen=1 }
    tbl {
      if ($0 ~ /^\|[[:space:]]*[-:| ]+$/) next
      if ($0 ~ /^\|[[:space:]]*ID[[:space:]]*\|/) next
      # Data row whose first cell is a task id (digits, optional -suffix)
      if ($0 ~ /^\|[[:space:]]*[0-9]+([.-][A-Za-z0-9_-]+)?[[:space:]]*\|/) n++
    }
    END { print n+0 }
  ' "$hs" 2>/dev/null
}

# =========================================================================
# Responsibility 1: plans-completed.jsonl (only when plans exist)
# =========================================================================
if [[ -d "$PLANS_DIR" ]]; then
  LOG_FILE="${RETROS_DIR}/plans-completed.jsonl"
  for HS in "$PLANS_DIR"/*-plan/handoff-state.md; do
    [[ -f "$HS" ]] || continue
    PLAN_DIR="$(dirname "$HS")"

    # C1: batches were planned (active contracts only; exclude archived .vN).
    B=$(find "$PLAN_DIR" -maxdepth 1 -name 'sprint-contract-batch-*.md' \
      ! -name 'sprint-contract-batch-*.v*.md' 2>/dev/null | wc -l | tr -d ' ')
    [[ "$B" =~ ^[0-9]+$ && "$B" -ge 1 ]] || continue

    # C2: every batch handed off.
    H=$(find "$PLAN_DIR" -maxdepth 1 -name 'handoff-summary-*.md' 2>/dev/null | wc -l | tr -d ' ')
    [[ "$H" =~ ^[0-9]+$ && "$H" -ge "$B" ]] || continue

    # repo-relative plan path, no trailing slash — the dedup key.
    PLAN_REL="${PLAN_DIR#"${ROOT%/}/"}"
    PLAN_REL="${PLAN_REL%/}"
    PLAN_DEDUP="${DEDUP_ANCHOR}\"plan\":\"${PLAN_REL}\""

    # C4 (cheap, do before git): already logged?
    if dedup_check "$LOG_FILE" "$PLAN_DEDUP"; then
      continue
    fi

    # C4b: skip plans a retrospective has already analyzed (evolution-log.jsonl).
    # Anchored ,"plan":"<path>" for item_* rows; quoted "<path>/" for plans_analyzed.
    EVO_LOG="${RETROS_DIR}/evolution-log.jsonl"
    if [[ -f "$EVO_LOG" ]]; then
      if grep -Fq "$PLAN_DEDUP" "$EVO_LOG" 2>/dev/null; then
        continue
      fi
      if grep -Fq "\"${PLAN_REL}/\"" "$EVO_LOG" 2>/dev/null; then
        continue
      fi
    fi

    # Modified-files set — dual-format (see _extract_modified_files).
    # bash 3.2-compatible read loop (no mapfile).
    FILES=()
    while IFS= read -r _line; do
      [[ -n "$_line" ]] && FILES+=("$_line")
    done < <(_extract_modified_files "$HS")
    [[ "${#FILES[@]}" -ge 1 ]] || continue

    # C3: a commit touches those files — confirms Phase 5 ran AND yields the
    # actual completion_commit (robust to later HEAD movement, no HEAD guess).
    COMMIT=$(git -C "$ROOT" log -1 --format=%h -- "${FILES[@]}" 2>/dev/null)
    [[ "$COMMIT" =~ ^[a-f0-9]{7,40}$ ]] || continue

    # Enrichment: task count from dual-format completed-tasks section.
    TASK_COUNT=$(_extract_task_count "$HS")
    [[ "$TASK_COUNT" =~ ^[0-9]+$ ]] || TASK_COUNT=0

    FILES_JSON=$(printf '%s\n' "${FILES[@]}" | jq -R . 2>/dev/null | jq -cs . 2>/dev/null)
    [[ -n "$FILES_JSON" ]] || FILES_JSON='[]'

    # Write (executed-mode jsonl-emit auto-injects timestamp + repo_root).
    bash "$EMIT" plans-completed \
      '{event:"plan_completed",plan:$plan,repo_root:$repo_root,task_count:($tc|tonumber),batch_count:($bc|tonumber),completion_commit:$cc,completion_modified_files:$files,timestamp:$timestamp}' \
      --arg plan "$PLAN_REL" \
      --arg tc "$TASK_COUNT" \
      --arg bc "$B" \
      --arg cc "$COMMIT" \
      --argjson files "$FILES_JSON" \
      2>/dev/null || true
  done
fi

# =========================================================================
# Responsibility 2: evolution-log.jsonl backfill (only when retros exist)
# =========================================================================
if [[ -d "$RETROS_DIR" ]]; then
  EVO_LOG="${RETROS_DIR}/evolution-log.jsonl"

  # --- 2a: retrospective_run watermark -----------------------------------
  # A retro-*.md report with no retrospective_run row referencing it means the
  # Phase 6 closure emit was dropped. Backfill the minimal watermark (event +
  # timestamp + report); auto-scope reads only existence + timestamp. The rich
  # fields (counts, plans_analyzed) stay the in-skill emit's job.
  for REPORT in "$RETROS_DIR"/retro-*.md; do
    [[ -f "$REPORT" ]] || continue
    REPORT_BASE="$(basename "$REPORT")"
    if [[ -f "$EVO_LOG" ]] && \
       grep -F "$REPORT_BASE" "$EVO_LOG" 2>/dev/null | grep -Fq 'retrospective_run'; then
      continue
    fi
    REPORT_REL="${REPORT#"${ROOT%/}/"}"
    bash "$EMIT" evolution-log \
      '{event:"retrospective_run",timestamp:$timestamp,plans_analyzed:[],report:$report,provenance:"hook_backfill"}' \
      --arg report "$REPORT_REL" \
      2>/dev/null || true
  done

  # --- 2b: item_added / item_removed from checklist version diff ----------
  # Item header forms: "### ID -- description" or "### ID: description".
  # The ID is the first whitespace token after "### ", colon stripped.
  CHECKLISTS_DIR="${RETROS_DIR}/checklists"
  _checklist_ids() {
    awk '/^### / { id=$2; sub(/:.*/,"",id); if (id != "") print id }' "$1" 2>/dev/null | sort -u
  }
  if [[ -d "$CHECKLISTS_DIR" ]]; then
    for MODE in design plan code; do
      N=0
      for f in "$CHECKLISTS_DIR/${MODE}-v"*.md; do
        [[ -f "$f" ]] || continue
        v="${f##*/${MODE}-v}"; v="${v%.md}"
        [[ "$v" =~ ^[0-9]+$ ]] || continue
        [[ "$v" -gt "$N" ]] && N="$v"
      done
      [[ "$N" -ge 2 ]] || continue
      CUR="$CHECKLISTS_DIR/${MODE}-v${N}.md"
      PREV="$CHECKLISTS_DIR/${MODE}-v$((N - 1)).md"
      [[ -f "$CUR" && -f "$PREV" ]] || continue
      CV="${MODE}-v${N}.md"

      # Skill already logged this version's evolution (rich rows present)?
      if [[ -f "$EVO_LOG" ]] && \
         grep -Fq "\"checklist_version\":\"${CV}\"" "$EVO_LOG" 2>/dev/null; then
        continue
      fi

      while IFS= read -r id; do
        [[ -n "$id" ]] || continue
        bash "$EMIT" evolution-log \
          '{timestamp:$timestamp,event:"item_added",provenance:"hook_backfill",mode:$mode,item_id:$item_id,checklist_version:$cv,rationale:"backfilled from checklist version diff"}' \
          --arg mode "$MODE" --arg item_id "$id" --arg cv "$CV" \
          2>/dev/null || true
      done < <(comm -13 <(_checklist_ids "$PREV") <(_checklist_ids "$CUR"))

      while IFS= read -r id; do
        [[ -n "$id" ]] || continue
        bash "$EMIT" evolution-log \
          '{timestamp:$timestamp,event:"item_removed",provenance:"hook_backfill",mode:$mode,item_id:$item_id,checklist_version:$cv,rationale:"backfilled from checklist version diff"}' \
          --arg mode "$MODE" --arg item_id "$id" --arg cv "$CV" \
          2>/dev/null || true
      done < <(comm -23 <(_checklist_ids "$PREV") <(_checklist_ids "$CUR"))
    done
  fi
fi

exit 0
