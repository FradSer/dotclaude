#!/usr/bin/env bash
# cleanup-legacy-state.sh — remove idle superpowers state files left over
# from finished sessions in ~/.claude/projects/*/.
#
# Background: every UserPromptSubmit hook fires task-start.sh which creates
# a per-session *.superpowers.json. Most sessions never enter a loop, so
# their state files are written once and abandoned (active != true). Over
# months these accumulate (this repo had 887 globally at the last audit).
# Pre-v2.5 sessions also wrote session_id="default" instead of a UUID;
# those orphans can carry a stale active:true that no live session will
# ever clear (find_state_file is now UUID-strict and never reaches them).
#
# Safe deletion criteria (both required):
#   1. .active != true (never touch a state file that claims an open loop)
#   2. mtime older than --days N (default 7)
#
# Default is DRY-RUN — pass --force to actually delete. The script prints
# every match in dry-run mode so you can review before committing.
#
# Usage:
#   bash scripts/cleanup-legacy-state.sh                 # dry-run, 7+ days
#   bash scripts/cleanup-legacy-state.sh --days 30       # dry-run, 30+ days
#   bash scripts/cleanup-legacy-state.sh --force         # delete, 7+ days
#   bash scripts/cleanup-legacy-state.sh --root /alt     # alt projects dir

set -euo pipefail

DAYS=7
FORCE=0
ROOT="${HOME}/.claude/projects"
INCLUDE_LEGACY_DEFAULT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)    FORCE=1; shift ;;
    --days)     DAYS="$2"; shift 2 ;;
    --days=*)   DAYS="${1#*=}"; shift ;;
    --root)     ROOT="$2"; shift 2 ;;
    --root=*)   ROOT="${1#*=}"; shift ;;
    --include-legacy-default)
      # Also delete session_id="default" orphans even when .active == true.
      # No live session writes that id, so an active:true on one is stale.
      INCLUDE_LEGACY_DEFAULT=1; shift ;;
    -h|--help)
      grep -E '^# ' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "error: unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required" >&2
  exit 2
fi

if [[ ! -d "$ROOT" ]]; then
  echo "error: projects dir not found: $ROOT" >&2
  exit 2
fi

# find lacks a portable >=N-days flag, so convert to minutes for -mmin.
MINUTES=$(( DAYS * 24 * 60 ))

# bash 3.2 (macOS) has no `mapfile`; collect via while-read. Display fields
# ride parallel arrays so the dry-run preview never re-parses a file.
candidate_count=0
to_delete=()
d_sid=()
d_skill=()
d_upd=()
skipped_active=0
skipped_unparseable=0

while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  candidate_count=$((candidate_count + 1))

  # One jq pass yields both the verdict and the preview fields. Empty
  # output means jq could not parse the file. The `--include-legacy-default`
  # flag is the only thing that lets an active file be deleted, and only
  # when session_id=="default" (a UUID-emitting live session never writes
  # that, so such files are legacy orphans).
  # Join with the ASCII Unit Separator (), not a tab: `read` collapses
  # runs of whitespace-IFS, which would drop an empty skill_name field and
  # mis-align the rest. US is non-whitespace, so empty fields survive.
  # `|| true` keeps jq's non-zero exit on a corrupt file from tripping
  # set -e — an empty $row is the unparseable signal handled just below.
  row=$(jq -r '
    (if .active == true then
       (if .session_id == "default" then "active-legacy" else "active" end)
     else "idle" end) as $verdict
    | [$verdict, (.session_id // ""), (.skill_name // ""), (.updated_at // "")]
    | join("\u001f")' "$f" 2>/dev/null || true)
  if [[ -z "$row" ]]; then
    skipped_unparseable=$((skipped_unparseable + 1))
    continue
  fi

  IFS=$'\037' read -r verdict sid skill upd <<< "$row"
  case "$verdict" in
    active)
      skipped_active=$((skipped_active + 1)); continue ;;
    active-legacy)
      [[ "$INCLUDE_LEGACY_DEFAULT" == "1" ]] || { skipped_active=$((skipped_active + 1)); continue; } ;;
  esac

  to_delete+=("$f")
  d_sid+=("$sid")
  d_skill+=("$skill")
  d_upd+=("$upd")
done < <(find "$ROOT" -maxdepth 2 -name '*.superpowers.json' -type f -mmin +"$MINUTES" 2>/dev/null)

if [[ $candidate_count -eq 0 ]]; then
  echo "no candidates: 0 files older than ${DAYS} days under ${ROOT}"
  exit 0
fi

mode="dry-run"
[[ "$FORCE" == "1" ]] && mode="DELETE"

echo "=== superpowers state cleanup [${mode}] ==="
echo "root:     ${ROOT}"
echo "age:      >${DAYS} days"
echo "found:    ${candidate_count} candidate(s)"
echo "skip(active):       ${skipped_active}"
echo "skip(unparseable):  ${skipped_unparseable}"
echo "target:   ${#to_delete[@]} file(s)"
echo ""

if [[ ${#to_delete[@]} -eq 0 ]]; then
  echo "nothing to do."
  exit 0
fi

# Preview up to 50 targets from the parallel arrays — no re-parsing.
echo "first $([ ${#to_delete[@]} -lt 50 ] && echo ${#to_delete[@]} || echo 50) target(s):"
shown=0
for i in "${!to_delete[@]}"; do
  [[ $shown -ge 50 ]] && break
  printf '  %s | %-22s | %s | %s\n' \
    "${d_sid[$i]:0:8}" "${d_skill[$i]:-(no skill)}" "${d_upd[$i]:-?}" "${to_delete[$i]}"
  shown=$((shown + 1))
done

if [[ "$FORCE" != "1" ]]; then
  echo ""
  echo "dry-run only. Re-run with --force to delete."
  exit 0
fi

echo ""
echo "deleting ${#to_delete[@]} file(s)..."
deleted=0
failed=0
for f in "${to_delete[@]}"; do
  if rm -f "$f" 2>/dev/null; then
    deleted=$((deleted + 1))
  else
    failed=$((failed + 1))
    echo "  failed: $f" >&2
  fi
done

echo "deleted: ${deleted}"
[[ "$failed" -gt 0 ]] && echo "failed:  ${failed}" >&2

exit 0
