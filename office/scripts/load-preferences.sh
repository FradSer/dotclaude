#!/usr/bin/env bash
# load-preferences.sh — merge four-tier office.*.json preferences
#
# Reads up to four preference files, deep-merges them in precedence order, and
# prints the merged JSON object to stdout.
#
# CRITICAL: These are the office plugin's own preference files, following the
# official .claude/plugin-name.local.* convention with .json carriers. They are
# NOT Claude Code's settings.json and do NOT participate in the harness
# four-layer settings merge. The merge below is implemented by this script.
#
# Precedence (highest to lowest — .local overrides shared, project overrides global):
#   1. ./.claude/office.local.json        (project, personal/gitignored)
#   2. ./.claude/office.json              (project, shared/committed)
#   3. ~/.claude/office.local.json        (global, personal)
#   4. ~/.claude/office.json              (global, shared)
#
# Merge semantics (applied low->high, each layer overlays the prior):
#   object x object -> recursive deep merge
#   array   x array -> concatenate + dedupe (plain strings by identity;
#                       objects in .pattern_caps deduped by .id keeping higher layer;
#                       objects in .dead_metaphors.entries deduped by .word keeping higher layer)
#   scalar  x scalar -> higher layer wins when non-null
#   null in higher layer -> keep lower layer value (inherit)
#
# Output: single merged JSON object on stdout. On any error (missing jq,
# missing/invalid files), fails open to '{}' so the tropes skill still runs
# with default rules.
#
# Env overrides (for testing), each may be set to a path or empty:
#   OFFICE_PROJECT_LOCAL   default ./.claude/office.local.json
#   OFFICE_PROJECT_SHARED  default ./.claude/office.json
#   OFFICE_GLOBAL_LOCAL    default ~/.claude/office.local.json
#   OFFICE_GLOBAL_SHARED   default ~/.claude/office.json

set -u

PROJECT_LOCAL="${OFFICE_PROJECT_LOCAL:-./.claude/office.local.json}"
PROJECT_SHARED="${OFFICE_PROJECT_SHARED:-./.claude/office.json}"
GLOBAL_LOCAL="${OFFICE_GLOBAL_LOCAL:-$HOME/.claude/office.local.json}"
GLOBAL_SHARED="${OFFICE_GLOBAL_SHARED:-$HOME/.claude/office.json}"

# Fail open if jq is unavailable — tropes falls back to default rules.
if ! command -v jq >/dev/null 2>&1; then
  echo "office.local.json: jq not found, using defaults" >&2
  echo '{}'
  exit 0
fi

# v0.5.x -> v0.6.0 upgrade guard: preferences moved from office.local.md (YAML
# frontmatter + markdown body) to office.*.json. Warn (not fail) when an old
# .md file exists alongside a missing .json, so upgraders don't silently lose
# their preferences. The script still fails open to '{}' (defaults) either way.
warn_legacy_md() {  # args: md_path  json_path  label
  [ -f "$1" ] || return 0
  [ -f "$2" ] && return 0
  echo "office: legacy $1 exists but no $2 — preferences were not loaded." >&2
  echo "office: migrate $1 (v0.5.x .md) to $2 (v0.6.0 .json); see references/preferences-schema.md." >&2
}
warn_legacy_md "$HOME/.claude/office.local.md" "$GLOBAL_LOCAL" "global local"
warn_legacy_md "$HOME/.claude/office.md"       "$GLOBAL_SHARED" "global shared"
warn_legacy_md "./.claude/office.local.md"     "$PROJECT_LOCAL" "project local"
warn_legacy_md "./.claude/office.md"           "$PROJECT_SHARED" "project shared"

# Read a file as JSON, or emit '{}' if missing/invalid (warn on invalid).
read_json() {
  local file="$1"
  if [ ! -f "$file" ]; then
    return 0  # missing file = empty input, not an error
  fi
  if ! jq -e . "$file" >/dev/null 2>&1; then
    echo "office.*.json: invalid JSON in $file, ignoring" >&2
    printf '{}'
    return 0
  fi
  jq -c . "$file"
}

# Deep merge program. `merge(a;b)` recursively combines two values:
# - both objects: merge key-by-key (b's null keeps a's value)
# - both arrays: concatenate then dedup via `dedup`
# - otherwise: b wins (unless b is null, then a wins)
#
# `dedup` handles three array shapes:
# - objects with .id (pattern_caps): group by .id, keep last (higher layer wins)
# - objects with .word (dead_metaphors.entries): group by .word, keep last
# - anything else (strings): unique
MERGE_PROG='
def dedup:
  if length == 0 then .
  elif (.[0] | type) == "object" and (.[0] | has("id")) then
    group_by(.id) | map(.[-1])
  elif (.[0] | type) == "object" and (.[0] | has("word")) then
    group_by(.word) | map(.[-1])
  else
    unique
  end;

def merge(a;b):
  if (a | type) == "object" and (b | type) == "object" then
    reduce (a,b | keys | unique[]) as $k
      ({}; .[$k] = merge(a[$k]; b[$k]))
  elif (a | type) == "array" and (b | type) == "array" then
    (a + b) | dedup
  elif b == null then a
  else b
  end;

merge($a; $b)
'

# Fold-merge in precedence order: lowest first, each higher layer overlays.
acc='{}'
for f in "$GLOBAL_SHARED" "$GLOBAL_LOCAL" "$PROJECT_SHARED" "$PROJECT_LOCAL"; do
  layer="$(read_json "$f")"
  [ -z "$layer" ] && layer='{}'
  acc="$(jq -n --argjson a "$acc" --argjson b "$layer" "$MERGE_PROG")"
done

printf '%s\n' "$acc"
