#!/bin/bash
#
# lib/docs-index.sh — Single source of truth for the docs/README.md index.
#
# Maintains a pipe-delimited markdown table at docs/README.md (one row per
# design/plan/retro folder) so the four superpowers writer skills can
# discover prior artifacts and avoid re-extending stale conclusions.
#
# Replaces the implicit "no top-level map" state with a controlled-vocabulary
# index consulted at skill Initialization and updated at skill commit time.
#
# Usage:
#   docs-index.sh list   [--kind <design|plan|retro>] [--status <prefix>]
#   docs-index.sh show   <path>
#   docs-index.sh upsert <kind> <path> [--status <status>] [--summary <summary>]
#   docs-index.sh set-status <path> <new-status>
#   docs-index.sh rebuild
#
# Exit codes:
#   0 — success (list/show found, upsert/set-status/rebuild written)
#   1 — internal failure (disk error, README.md not writable, repo_root empty)
#   2 — usage error (unknown subcommand, unknown kind/status, bad args)
#   3 — soft "not in index" (show/set-status on an absent path — recoverable;
#       callers should upsert first)
#
# Atomicity: every write goes to docs/README.md.tmp.$$ then `mv` over the
# target, so a crash leaves either the old or the new file, never a torn
# half-table. See docs/plans/2026-07-04-docs-index-design/architecture.md
# for the full design.

set -euo pipefail

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
# Resolve to an absolute path without `cd` — the bash `pwd` builtin in some
# environments echoes the path twice, corrupting command substitution. A
# leading-`/` check is sufficient; the script is always invoked by absolute
# path from the test harness and the skills.
case "$SCRIPT_DIR" in
  /*) : ;;
  *) SCRIPT_DIR="$PWD/$SCRIPT_DIR" ;;
esac
# shellcheck source=utils.sh
source "${SCRIPT_DIR}/utils.sh"

usage() {
  cat >&2 <<'EOF'
Usage: docs-index.sh <subcommand> [args]

Subcommands:
  list        Print all rows (or filtered by --kind/--status) to stdout
  show        Print the single row for <path>, or exit 3 if absent
  upsert      Insert or update the row for <kind> <path>
  set-status  Change the status of an existing row
  rebuild     Rescan docs/ and rewrite the whole index

Exit codes:
  0  success
  1  internal failure
  2  usage error
  3  not in index (recoverable)
EOF
}

# Header preamble + table header written by seed_header() and by make_index()
# in the test fixture. Format of a data row (one literal line):
#   | <path> | <kind> | <status> | <summary> | <updated> |
# parse_rows emits the inner 5 fields joined by " | " (no leading/trailing
# pipes) for every data row in ${ROOT}/docs/README.md. Preamble lines before
# the table header are skipped, as is the separator line (|---|---|...).
parse_rows() {
  local root="$1" file
  file="${root}/docs/README.md"
  [[ -f "$file" ]] || return 0
  awk '
    # Skip everything until we reach the table header row.
    state == 0 {
      if ($0 ~ /^\| path \|/) state = 1
      next
    }
    # Skip the separator line (|---|---|...).
    state == 1 {
      if ($0 ~ /^\|---/) { state = 2; next }
      # Tolerate a missing separator: any data row here still counts.
      state = 2
    }
    state == 2 {
      if ($0 ~ /^\| /) {
        # Strip leading "| " and trailing " |", then print.
        line = $0
        sub(/^\| /, "", line)
        sub(/ \|$/, "", line)
        print line
      }
    }
  ' "$file"
}

# Canonical table header (preamble + header + separator). Used by
# seed_header() and as the top of an upsert-created index.
seed_header() {
  cat <<'EOF'
# Docs Index

> Auto-maintained by `lib/docs-index.sh`. One row per design/plan/retro folder.
> Last rebuild: 2026-07-04

| path | kind | status | summary | updated |
|---|---|---|---|---|
EOF
}

validate_kind() {
  local kind="$1"
  case "$kind" in
    design|plan|retro) printf '%s' "$kind"; return 0 ;;
    *)
      echo "upsert: unknown kind '$kind' (expected: design|plan|retro)" >&2
      exit 2 ;;
  esac
}

# Reject paths that escape the repo root. A path starting with "/" is absolute
# (lives outside docs/); a path containing ".." as a segment can traverse above
# the repo root. Both are usage errors (exit 2). Otherwise return 0.
validate_path() {
  local path="$1"
  if [[ -z "$path" ]]; then
    return 0
  fi
  if [[ "$path" == /* ]]; then
    echo "docs-index: path must not be absolute: '$path'" >&2
    exit 2
  fi
  # Reject ".." as a complete path segment (leading, trailing, or interior).
  # Match "../foo", "foo/../bar", "foo/..", or bare "..".
  local rest="$path"
  while [[ -n "$rest" ]]; do
    local seg
    seg="${rest%%/*}"
    if [[ "$seg" == ".." ]]; then
      echo "docs-index: path must not contain parent traversal: '$path'" >&2
      exit 2
    fi
    # Strip the consumed segment + one leading "/" if present.
    if [[ "$rest" == */* ]]; then
      rest="${rest#*/}"
    else
      rest=""
    fi
  done
  return 0
}

# If docs/README.md exists but contains no pipe-delimited table header line
# matching "^| path |", the index is malformed prose. Consult commands (list,
# show, upsert, set-status) MUST exit 2 with a diagnostic; rebuild does NOT
# call this (it regenerates from filesystem truth).
assert_valid_index() {
  local root="$1" file
  file="${root}/docs/README.md"
  [[ -f "$file" ]] || return 0
  if ! grep -q '^| path |' "$file" 2>/dev/null; then
    echo "docs/README.md is not a valid index table" >&2
    exit 2
  fi
  return 0
}

validate_status() {
  local status="$1"
  case "$status" in
    wip|active|reference) printf '%s' "$status"; return 0 ;;
    implemented:[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f])
      printf '%s' "$status"; return 0 ;;
    superseded-by:*)
      local rest="${status#superseded-by:}"
      if [[ -n "$rest" ]]; then printf '%s' "$status"; return 0; fi
      ;;
    expired:*)
      local rest="${status#expired:}"
      if [[ -n "$rest" ]]; then printf '%s' "$status"; return 0; fi
      ;;
  esac
  echo "upsert: unknown status '$status'" >&2
  exit 2
}

# Default status when --status is omitted: wip for design/plan, active for retro.
default_status_for_kind() {
  case "$1" in
    retro) printf 'active' ;;
    *)     printf 'wip' ;;
  esac
}

# Truncate summary to 72 chars; if longer, append "…" (so the visible width
# stays readable). Bash substring slicing is used to avoid awk for this step.
truncate_summary() {
  local s="$1"
  if [[ "${#s}" -gt 72 ]]; then
    printf '%s…' "${s:0:71}"
  else
    printf '%s' "$s"
  fi
}

cmd_list() {
  local root kind_filter status_filter
  root="$(repo_root)"
  kind_filter=""
  status_filter=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --kind)   kind_filter="${2:-}"; shift 2 ;;
      --status) status_filter="${2:-}"; shift 2 ;;
      *) echo "list: unknown argument '$1'" >&2; exit 2 ;;
    esac
  done
  # Validate --kind against the controlled vocabulary (no-op if empty).
  if [[ -n "$kind_filter" ]]; then
    case "$kind_filter" in
      design|plan|retro) : ;;
      *) echo "list: unknown kind '$kind_filter' (expected: design|plan|retro)" >&2; exit 2 ;;
    esac
  fi
  # --status is a prefix — any prefix is allowed; do NOT validate.
  local rows row field_kind field_status prefix
  assert_valid_index "$root"
  rows="$(parse_rows "$root")"
  [[ -z "$rows" ]] && return 0
  while IFS= read -r row; do
    [[ -z "$row" ]] && continue
    # Split into fields on " | ". Use awk for robustness with summaries that
    # may themselves contain " | " — we only need fields 2 and 3 here, and
    # the table format guarantees the first three pipes are field separators.
    field_kind="$(printf '%s' "$row" | awk -F' \\| ' '{print $2}')"
    field_status="$(printf '%s' "$row" | awk -F' \\| ' '{print $3}')"
    if [[ -n "$kind_filter" && "$field_kind" != "$kind_filter" ]]; then
      continue
    fi
    if [[ -n "$status_filter" ]]; then
      # Prefix match: value before ":" OR whole value.
      prefix="${field_status%%:*}"
      if [[ "$prefix" != "$status_filter" && "$field_status" != "$status_filter" ]]; then
        continue
      fi
    fi
    printf '%s\n' "$row"
  done <<<"$rows"
  return 0
}

cmd_show() {
  local root target rows row field_path
  root="$(repo_root)"
  if [[ $# -lt 1 ]]; then
    echo "show: missing <path> argument" >&2
    exit 2
  fi
  target="$1"
  validate_path "$target"
  assert_valid_index "$root"
  rows="$(parse_rows "$root")"
  while IFS= read -r row; do
    [[ -z "$row" ]] && continue
    field_path="$(printf '%s' "$row" | awk -F' \\| ' '{print $1}')"
    if [[ "$field_path" == "$target" ]]; then
      printf '%s\n' "$row"
      return 0
    fi
  done <<<"$rows"
  return 3
}

cmd_upsert() {
  local root kind path status summary
  root="$(repo_root)"
  if [[ $# -lt 2 ]]; then
    echo "upsert: usage: upsert <kind> <path> [--status <status>] [--summary <summary>]" >&2
    exit 2
  fi
  kind="$1"; shift
  path="$1"; shift
  status=""
  summary=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --status)  status="${2:-}"; shift 2 ;;
      --summary) summary="${2:-}"; shift 2 ;;
      *) echo "upsert: unknown argument '$1'" >&2; exit 2 ;;
    esac
  done
  kind="$(validate_kind "$kind")"
  if [[ -z "$path" ]]; then
    echo "upsert: <path> must be non-empty" >&2
    exit 2
  fi
  validate_path "$path"
  assert_valid_index "$root"
  if [[ -n "$status" ]]; then
    status="$(validate_status "$status")"
  else
    status="$(default_status_for_kind "$kind")"
  fi
  summary="$(truncate_summary "$summary")"
  local today
  today="$(date +%Y-%m-%d)"
  local file tmp
  file="${root}/docs/README.md"
  tmp="${file}.tmp.$$"
  mkdir -p "${root}/docs"
  local rows existing_row found=0
  rows="$(parse_rows "$root")"
  local new_row="${path} | ${kind} | ${status} | ${summary} | ${today}"
  local out_rows=()
  if [[ -n "$rows" ]]; then
    local row field_path
    while IFS= read -r row; do
      [[ -z "$row" ]] && continue
      field_path="$(printf '%s' "$row" | awk -F' \\| ' '{print $1}')"
      if [[ "$field_path" == "$path" ]]; then
        if [[ "$found" -eq 0 ]]; then
          out_rows+=("$new_row")
          found=1
        fi
        # Drop duplicates of the same path (defensive — keeps idempotent
        # upsert from accumulating duplicates if the index ever had them).
      else
        out_rows+=("$row")
      fi
    done <<<"$rows"
  fi
  if [[ "$found" -eq 0 ]]; then
    out_rows+=("$new_row")
  fi
  # Sort rows by path (field 1) lexicographic.
  local sorted
  sorted="$(printf '%s\n' "${out_rows[@]}" | LC_ALL=C sort)"
  {
    seed_header
    local r
    while IFS= read -r r; do
      [[ -z "$r" ]] && continue
      printf '| %s |\n' "$r"
    done <<<"$sorted"
  } > "$tmp"
  mv -f "$tmp" "$file"
  return 0
}

# Map a status value to a category token (wip/active/implemented/superseded/
# expired/reference) by taking the prefix before the first ":". Bare words
# (wip/active/reference) map to themselves; parameterized statuses collapse to
# their category. Used by transition_allowed() so the matrix reasons over
# categories, not exact strings.
status_category() {
  local status="$1"
  local prefix="${status%%:*}"
  case "$prefix" in
    wip|active|implemented|superseded-by|expired|reference)
      # Normalize "superseded-by" → "superseded" so the matrix token is short.
      case "$prefix" in
        superseded-by) printf 'superseded' ;;
        *)             printf '%s' "$prefix" ;;
      esac
      ;;
    *)
      # Unknown status — return the raw value; transition_allowed() will treat
      # any unknown category as terminal (no transitions out).
      printf '%s' "$prefix"
      ;;
  esac
}

# Transition matrix (see best-practices.md §Status Taxonomy — Transition Rules).
#   wip         → anything allowed
#   active      → anything allowed
#   implemented → only wip allowed (rework after ship)
#   superseded  → nothing allowed (terminal; resurrection is retro-only, OOB)
#   expired     → nothing allowed (terminal; resurrection is retro-only, OOB)
#   reference   → nothing allowed (sticky)
# Any unknown category is terminal (no transitions).
transition_allowed() {
  local from_cat to_cat
  from_cat="$(status_category "$1")"
  to_cat="$(status_category "$2")"
  case "$from_cat" in
    wip|active)
      return 0
      ;;
    implemented)
      if [[ "$to_cat" == "wip" ]]; then
        return 0
      fi
      return 1
      ;;
    *)
      # superseded / expired / reference / unknown — terminal.
      return 1
      ;;
  esac
}

cmd_set_status() {
  local root target new_status
  root="$(repo_root)"
  if [[ $# -lt 2 ]]; then
    echo "set-status: usage: set-status <path> <new-status>" >&2
    exit 2
  fi
  target="$1"; shift
  new_status="$1"; shift
  # Validate the new status against the controlled vocabulary. validate_status
  # exits 2 on a miss — which is the right code for "unknown status".
  new_status="$(validate_status "$new_status")"
  validate_path "$target"
  assert_valid_index "$root"
  local rows row field_path field_kind field_status field_summary field_updated
  local found=0
  local new_rows=()
  rows="$(parse_rows "$root")"
  if [[ -n "$rows" ]]; then
    while IFS= read -r row; do
      [[ -z "$row" ]] && continue
      field_path="$(printf '%s' "$row" | awk -F' \\| ' '{print $1}')"
      if [[ "$field_path" == "$target" && "$found" -eq 0 ]]; then
        found=1
        # Extract current status (field 3) to check the transition.
        field_status="$(printf '%s' "$row" | awk -F' \\| ' '{print $3}')"
        if ! transition_allowed "$field_status" "$new_status"; then
          echo "set-status: transition '${field_status}' → '${new_status}' is not allowed" >&2
          exit 2
        fi
        # Preserve kind + summary; flip status + updated date.
        field_kind="$(printf '%s' "$row" | awk -F' \\| ' '{print $2}')"
        field_summary="$(printf '%s' "$row" | awk -F' \\| ' '{print $4}')"
        local today
        today="$(date +%Y-%m-%d)"
        new_rows+=("${field_path} | ${field_kind} | ${new_status} | ${field_summary} | ${today}")
      else
        new_rows+=("$row")
      fi
    done <<<"$rows"
  fi
  if [[ "$found" -eq 0 ]]; then
    echo "set-status: path '${target}' is not in the index" >&2
    exit 3
  fi
  local file tmp sorted
  file="${root}/docs/README.md"
  tmp="${file}.tmp.$$"
  sorted="$(printf '%s\n' "${new_rows[@]}" | LC_ALL=C sort)"
  {
    seed_header
    local r
    while IFS= read -r r; do
      [[ -z "$r" ]] && continue
      printf '| %s |\n' "$r"
    done <<<"$sorted"
  } > "$tmp"
  mv -f "$tmp" "$file"
  return 0
}

# Extract the "topic" of a path for collapse-grouping. Strips the
# `docs/plans/YYYY-MM-DD-` date prefix and the `-design/`/`-plan/`/`.md suffix
# so folders on the same topic across dates group together. For non-plan
# paths, returns the path as-is (they never form collapse groups — only
# implemented/expired design+plan rows are collapse candidates).
topic_of_path() {
  local p="$1"
  # Strip docs/plans/YYYY-MM-DD- prefix if present.
  local stripped="${p#docs/plans/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-}"
  # If the prefix didn't match, stripped == p; fall back to the bare basename.
  if [[ "$stripped" == "$p" ]]; then
    stripped="${p##*/}"
  fi
  # Strip -design/ or -plan/ suffix (with or without trailing slash).
  stripped="${stripped%-design}"
  stripped="${stripped%-plan}"
  stripped="${stripped%/}"
  printf '%s' "$stripped"
}

# Scan the filesystem for design/plan/retro artifacts and emit one
# "<path>\t<kind>\t<default_status>" row per artifact. Default status is wip
# for design/plan, active for retro. docs/writing-skills/ (if present) is
# seeded as kind=retro status=reference. Output is NOT sorted — caller sorts.
scan_folders() {
  local root="$1"
  local d f
  # design folders
  for d in "${root}/docs/plans/"*-design/; do
    [[ -d "$d" ]] || continue
    printf '%s\t%s\t%s\n' "${d#${root}/}" "design" "wip"
  done
  # plan folders
  for d in "${root}/docs/plans/"*-plan/; do
    [[ -d "$d" ]] || continue
    printf '%s\t%s\t%s\n' "${d#${root}/}" "plan" "wip"
  done
  # retro files (one row per retro-*.md file)
  for f in "${root}/docs/retros/"retro-*.md; do
    [[ -f "$f" ]] || continue
    printf '%s\t%s\t%s\n' "${f#${root}/}" "retro" "active"
  done
  # docs/writing-skills/ seeded as kind=retro status=reference
  if [[ -d "${root}/docs/writing-skills" ]]; then
    printf '%s\t%s\t%s\n' "docs/writing-skills/" "retro" "reference"
  fi
}

# Read the existing docs/README.md and emit "<path>\\t<status>\\t<summary>" lines
# for every row whose path still appears in the scanned set. Used by
# cmd_rebuild to preserve known statuses (and summaries) across rebuilds.
# Tab-separated because statuses themselves contain ":" (implemented:sha,
# superseded-by:path, expired:reason) and summaries may contain " | " — tab
# is unambiguous.
existing_status_map() {
  local root="$1"
  parse_rows "$root" | while IFS= read -r row; do
    [[ -z "$row" ]] && continue
    local p s sum
    p="$(printf '%s' "$row" | awk -F' \\| ' '{print $1}')"
    s="$(printf '%s' "$row" | awk -F' \\| ' '{print $3}')"
    sum="$(printf '%s' "$row" | awk -F' \\| ' '{print $4}')"
    printf '%s\t%s\t%s\n' "$p" "$s" "$sum"
  done
}

# Apply the 60-line collapse rule to the rows piped on stdin. Each input line
# is "<path>\t<kind>\t<status>\t<summary>\t<updated>" (5 tab-separated fields).
# Output is the same format, possibly with some implemented/expired groups
# replaced by a single summary line, and (if still > 60) expired entries
# dropped entirely. active/wip/superseded rows are never collapsed or dropped.
collapse_rows() {
  local rows=()
  local row
  while IFS= read -r row; do
    [[ -z "$row" ]] && continue
    rows+=("$row")
  done
  local total=${#rows[@]}
  if [[ "$total" -le 60 ]]; then
    if [[ "$total" -gt 0 ]]; then
      printf '%s\n' "${rows[@]}"
    fi
    return 0
  fi
  # Stage 1: collapse groups of >= 3 implemented/expired rows sharing a topic
  # prefix into a single summary line.
  local collapse_candidates=()
  local kept=()
  for row in "${rows[@]}"; do
    local s cat
    s="$(printf '%s' "$row" | awk -F'\t' '{print $3}')"
    cat="$(status_category "$s")"
    if [[ "$cat" == "implemented" || "$cat" == "expired" ]]; then
      collapse_candidates+=("$row")
    else
      kept+=("$row")
    fi
  done
  # Group collapse_candidates by (topic, cat). Bash 3.2 has no associative
  # arrays, so emit "topic\tcat\tpath\tkind" lines to a temp file and let
  # awk aggregate.
  local groups_file keys_file
  groups_file="$(mktemp)"
  keys_file="$(mktemp)"
  for row in "${collapse_candidates[@]}"; do
    local p s cat topic k
    p="$(printf '%s' "$row" | awk -F'\t' '{print $1}')"
    k="$(printf '%s' "$row" | awk -F'\t' '{print $2}')"
    s="$(printf '%s' "$row" | awk -F'\t' '{print $3}')"
    cat="$(status_category "$s")"
    topic="$(topic_of_path "$p")"
    printf '%s\t%s\t%s\t%s\n' "$topic" "$cat" "$p" "$k" >> "$groups_file"
  done
  # For each (topic, cat) with count >= 3, emit one summary line in the same
  # 5-field tab format and write the key to keys_file for the removal pass.
  local summary_file
  summary_file="$(mktemp)"
  awk -F'\t' '
    {
      key = $1 "|" $2
      count[key]++
      if (!(key in first_path)) { first_path[key] = $3; first_kind[key] = $4 }
    }
    END {
      for (key in count) {
        if (count[key] >= 3) {
          split(key, a, "|")
          printf "%s\t%s\t%s\t%s\t%d\n", a[1], a[2], first_path[key], first_kind[key], count[key]
          print key
        }
      }
    }
  ' "$groups_file" > "$keys_file.raw"
  # Split keys_file.raw: lines with 5 fields are summary specs, lines with 1
  # field (topic|cat) are collapsed-group keys.
  local today
  today="$(date +%Y-%m-%d)"
  while IFS= read -r gline; do
    [[ -z "$gline" ]] && continue
    local nf
    nf=$(printf '%s' "$gline" | awk -F'\t' '{print NF}')
    if [[ "$nf" -eq 1 ]]; then
      printf '%s\n' "$gline" >> "$keys_file"
    elif [[ "$nf" -ge 5 ]]; then
      local t c first_path kind cnt
      t="$(printf '%s' "$gline" | awk -F'\t' '{print $1}')"
      c="$(printf '%s' "$gline" | awk -F'\t' '{print $2}')"
      first_path="$(printf '%s' "$gline" | awk -F'\t' '{print $3}')"
      kind="$(printf '%s' "$gline" | awk -F'\t' '{print $4}')"
      cnt="$(printf '%s' "$gline" | awk -F'\t' '{print $5}')"
      printf '%s\t%s\t%s\t%s\t%s\n' \
        "docs/plans/(collapsed-${t})" \
        "${kind}" \
        "${c}" \
        "... and ${cnt} prior ${c} entries (topic: ${t}) - see git history" \
        "${today}" >> "$summary_file"
    fi
  done < "$keys_file.raw"
  rm -f "$groups_file" "$keys_file.raw"
  # Walk collapse_candidates; keep members of non-collapsed groups, drop
  # members of collapsed groups.
  for row in "${collapse_candidates[@]}"; do
    local p s cat topic key
    p="$(printf '%s' "$row" | awk -F'\t' '{print $1}')"
    s="$(printf '%s' "$row" | awk -F'\t' '{print $3}')"
    cat="$(status_category "$s")"
    topic="$(topic_of_path "$p")"
    key="${topic}|${cat}"
    if grep -qxF -- "$key" "$keys_file" 2>/dev/null; then
      continue
    fi
    kept+=("$row")
  done
  # Append the collapse summary rows.
  if [[ -s "$summary_file" ]]; then
    while IFS= read -r srow; do
      [[ -z "$srow" ]] && continue
      kept+=("$srow")
    done < "$summary_file"
  fi
  rm -f "$keys_file" "$summary_file"
  # Stage 2: if still > 60, drop expired entries entirely.
  if [[ "${#kept[@]}" -le 60 ]]; then
    if [[ "${#kept[@]}" -gt 0 ]]; then
      printf '%s\n' "${kept[@]}"
    fi
    return 0
  fi
  local final=()
  for row in "${kept[@]}"; do
    local s cat
    s="$(printf '%s' "$row" | awk -F'\t' '{print $3}')"
    cat="$(status_category "$s")"
    if [[ "$cat" == "expired" ]]; then
      continue
    fi
    final+=("$row")
  done
  if [[ "${#final[@]}" -gt 0 ]]; then
    printf '%s\n' "${final[@]}"
  fi
}

cmd_rebuild() {
  local root file tmp
  root="$(repo_root)"
  file="${root}/docs/README.md"
  tmp="${file}.tmp.$$"
  mkdir -p "${root}/docs"
  # Scan filesystem.
  local scanned
  scanned="$(scan_folders "$root")"
  # Build a path -> "status<TAB>summary" map from the existing index (if any).
  local status_map=""
  status_map="$(existing_status_map "$root")"
  # Merge: for each scanned row, use the existing status+summary if the path
  # is known, otherwise the default status from scan_folders and empty summary.
  local merged=()
  local line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local p k default_status existing final_status final_summary
    p="$(printf '%s' "$line" | awk -F'\t' '{print $1}')"
    k="$(printf '%s' "$line" | awk -F'\t' '{print $2}')"
    default_status="$(printf '%s' "$line" | awk -F'\t' '{print $3}')"
    existing=""
    if [[ -n "$status_map" ]]; then
      # status_map is "<path>\t<status>\t<summary>" per line; match on path
      # (field 1) and emit "status\tsummary" (fields 2-3).
      existing="$(printf '%s\n' "$status_map" | awk -F'\t' -v path="$p" '$1 == path { print $2 "\t" $3; exit }')"
    fi
    if [[ -n "$existing" ]]; then
      # existing is "status\tsummary" - split on the first tab.
      final_status="${existing%%$'\t'*}"
      local rest="${existing#*$'\t'}"
      if [[ "$rest" == "$existing" ]]; then
        final_summary=""
      else
        final_summary="$rest"
      fi
    else
      final_status="$default_status"
      final_summary=""
    fi
    local today
    today="$(date +%Y-%m-%d)"
    merged+=("${p}"$'\t'"${k}"$'\t'"${final_status}"$'\t'"${final_summary}"$'\t'"${today}")
  done <<<"$scanned"
  # Collapse if needed (only fires above 60 rows).
  local collapsed=""
  if [[ "${#merged[@]}" -eq 0 ]]; then
    : # nothing scanned — leave collapsed empty
  elif [[ "${#merged[@]}" -gt 60 ]]; then
    local collapse_in=""
    for line in "${merged[@]}"; do
      collapse_in+="${line}"$'\n'
    done
    collapsed="$(printf '%s' "$collapse_in" | collapse_rows)"
  else
    for line in "${merged[@]}"; do
      collapsed+="${line}"$'\n'
    done
  fi
  # Sort by path lexicographically and write.
  local sorted
  sorted="$(printf '%s\n' "$collapsed" | awk -F'\t' 'NF >= 5 { print }' | LC_ALL=C sort)"
  local count=0
  {
    seed_header
    local r
    while IFS= read -r r; do
      [[ -z "$r" ]] && continue
      local p k s sum up
      p="$(printf '%s' "$r" | awk -F'\t' '{print $1}')"
      k="$(printf '%s' "$r" | awk -F'\t' '{print $2}')"
      s="$(printf '%s' "$r" | awk -F'\t' '{print $3}')"
      sum="$(printf '%s' "$r" | awk -F'\t' '{print $4}')"
      up="$(printf '%s' "$r" | awk -F'\t' '{print $5}')"
      printf '| %s | %s | %s | %s | %s |\n' "$p" "$k" "$s" "$sum" "$up"
      count=$((count + 1))
    done <<<"$sorted"
  } > "$tmp"
  mv -f "$tmp" "$file"
  echo "rebuild: ${count} rows" >&2
  return 0
}
SUBCOMMAND="${1:-}"
if [[ -z "$SUBCOMMAND" ]]; then
  usage
  exit 2
fi

shift || true

case "$SUBCOMMAND" in
  list)        cmd_list "$@" ;;
  show)        cmd_show "$@" ;;
  upsert)      cmd_upsert "$@" ;;
  set-status)  cmd_set_status "$@" ;;
  rebuild)     cmd_rebuild "$@" ;;
  *)           usage; exit 2 ;;
esac
