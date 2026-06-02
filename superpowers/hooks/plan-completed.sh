#!/bin/bash
#
# plan-completed.sh — Stop hook: mechanical plans-completed.jsonl writer.
#
# The ONE piece of Stop-hook logic the v3.0.0 teardown should have kept. The
# continuation loop / stall detector / change-tracking telemetry the old
# stop-hook.sh bundled were correctly deleted (native /goal replaced the
# loop). This single deterministic side-effect was not a loop concern, yet it
# rode out on the same removal and decayed to a Claude-instructed Phase 6 step
# that empirical audit shows is silently dropped (loop.sh:19-29; absent on
# dotclaude 2026-06). retrospective Phase 5a reads completion_commit ONLY from
# this log, so a missed write silently no-ops the most valuable checklist-
# evolution signal.
#
# Detection is STATE-BASED, not model-utterance-based: the hook does not grep
# for a completion banner (a sentence the model may paraphrase or skip). Each
# Stop it evaluates a condition over durable plan artifacts — the same
# filesystem-derivation philosophy as batch-progress.sh and the same
# condition-each-turn robustness as native /goal. A plan is "complete and
# unlogged" when:
#   C1  it has >= 1 sprint-contract-batch-*.md          (batches were planned)
#   C2  handoff-summary count >= batch count            (every batch handed off)
#   C3  a git commit touches its handoff-state.md modified-files set
#         (Phase 5 committed — and that commit IS completion_commit, found via
#          git rather than guessed from HEAD)
#   C4  it is not already in plans-completed.jsonl       (first completion only)
# When C1..C4 hold the row is written. The model can stay completely silent.
#
# Fires on EVERY Stop across all sessions/projects. Per-plan C4/C4b dedup is
# cheap (anchored substring on tail-200 via jsonl-emit dedup_check). Best-effort
# throughout (missing jq/git, unparseable state all exit 0); never blocks
# session exit and never writes more than one row per plan.

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
PLANS_DIR="${ROOT%/}/docs/plans"
[[ -d "$PLANS_DIR" ]] || exit 0
LOG_FILE="${ROOT%/}/docs/retros/plans-completed.jsonl"

EMIT="${SCRIPT_DIR}/../lib/jsonl-emit.sh"
DEDUP_ANCHOR=','  # prefix for dedup_check substring below

# --- Evaluate the completion condition for each plan ---------------------
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
  EVO_LOG="${ROOT%/}/docs/retros/evolution-log.jsonl"
  if [[ -f "$EVO_LOG" ]]; then
    if grep -Fq "$PLAN_DEDUP" "$EVO_LOG" 2>/dev/null; then
      continue
    fi
    if grep -Fq "\"${PLAN_REL}/\"" "$EVO_LOG" 2>/dev/null; then
      continue
    fi
  fi

  # Modified-files set (backtick items under "## Modified Files (cumulative)").
  # bash 3.2-compatible read loop (no mapfile).
  FILES=()
  while IFS= read -r _line; do
    [[ -n "$_line" ]] && FILES+=("$_line")
  done < <(awk '
    /^## Modified Files \(cumulative\)/ { inblk=1; next }
    inblk && /^## / { inblk=0 }
    inblk {
      line=$0
      while (match(line, /`[^`]+`/)) {
        print substr(line, RSTART+1, RLENGTH-2)
        line=substr(line, RSTART+RLENGTH)
      }
    }
  ' "$HS" 2>/dev/null)
  [[ "${#FILES[@]}" -ge 1 ]] || continue

  # C3: a commit touches those files — confirms Phase 5 ran AND yields the
  # actual completion_commit (robust to later HEAD movement, no HEAD guess).
  COMMIT=$(git -C "$ROOT" log -1 --format=%h -- "${FILES[@]}" 2>/dev/null)
  [[ "$COMMIT" =~ ^[a-f0-9]{7,40}$ ]] || continue

  # Enrichment: task count = bullets under "## Completed Task IDs".
  TASK_COUNT=$(awk '
    /^## Completed Task IDs/ { inblk=1; next }
    inblk && /^## / { inblk=0 }
    inblk && /^[[:space:]]*-[[:space:]]/ { n++ }
    END { print n+0 }
  ' "$HS" 2>/dev/null)
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

exit 0
