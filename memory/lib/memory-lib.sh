#!/bin/bash
#
# lib/memory-lib.sh — shared helpers for the memory plugin.
#
# Sourced by hooks/consolidate-stop.sh and the four skills. Provides:
#   - escape_path, tier_a_dir, tier_b_dir, project_stamp, repo_root
#   - read_frontmatter_field (one field), read_visibility (classify.sh glue)
#
# Single source of truth for the path-escape convention. Claude Code encodes a
# project's absolute path as a folder name by replacing every '/' with '-'.
# Space handling is inconsistent across Claude Code versions ('Home Lab' ->
# '-Home-Lab' but 'Work Research' keeps the space), so tier_a_dir probes both
# forms and returns whichever project folder actually exists.
#
# This is the same convention reflect-skills-from-memory uses:
#   MEM="$HOME/.claude/projects/$(pwd | sed 's/\//-/g')/memory"

# --- repo_root ---------------------------------------------------------------
# Resolve the consuming project's root. Mirrors superpowers/lib/utils.sh
# repo_root() so Tier B paths land in the right project, not the plugin's own
# repo when developing the plugin by hand.
repo_root() {
  if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    printf '%s' "$CLAUDE_PROJECT_DIR"
    return 0
  fi
  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
  if [[ -n "$git_root" ]]; then
    printf '%s' "$git_root"
    return 0
  fi
  printf '%s' "${PWD:-}"
}

# --- escape_path -------------------------------------------------------------
# Escape an absolute path the way Claude Code names project folders: '/' -> '-'.
escape_path() {
  printf '%s' "$1" | sed 's|/|-|g'
}

# --- tier_a_dir --------------------------------------------------------------
# Print the Tier A memory dir for <cwd>, or empty if none exists.
# Probes two space-handling forms (space->'-' and space-kept) since Claude
# Code's own folder naming is inconsistent across versions.
tier_a_dir() {
  local cwd="$1"
  local projects_root="$HOME/.claude/projects"
  local sp2dash sp_keep
  sp2dash=$(printf '%s' "$cwd" | sed 's|/|-|g; s| |-|g')
  sp_keep=$(escape_path "$cwd")
  for cand in "$sp2dash" "$sp_keep"; do
    if [[ -d "$projects_root/$cand/memory" ]]; then
      printf '%s' "$projects_root/$cand/memory"
      return 0
    fi
  done
  return 0
}

# --- tier_b_dir --------------------------------------------------------------
# Print the Tier B memory dir for <repo-root>, or empty if it doesn't exist.
tier_b_dir() {
  local root="$1"
  local d="$root/docs/memory"
  if [[ -d "$d" ]]; then
    printf '%s' "$d"
    return 0
  fi
  return 0
}

# --- project_stamp -----------------------------------------------------------
# Print the per-project debounce stamp path for <cwd>.
# --- project_stamp -----------------------------------------------------------
# Print the per-project debounce stamp path for <cwd>. The hash is normalized
# to the first 16 hex chars on BOTH macOS (md5) and Linux (shasum) so the stamp
# filename is stable across platforms — without this, md5 -q returns 32 chars
# while shasum returned 16, and the same project's debounce window reset on
# platform switch.
project_stamp() {
  local cwd="$1"
  local hash
  hash=$(printf '%s' "$cwd" | md5 -q 2>/dev/null | cut -c1-16 || printf '%s' "$cwd" | shasum 2>/dev/null | cut -c1-16)
  printf '%s' "$HOME/.claude/.last-consolidation-${hash}"
}

# --- read_frontmatter_field --------------------------------------------------
# Print the value of <field> from <file>'s YAML frontmatter, or empty.
# Handles BOTH schemas this plugin touches:
#   - Tier B flat keys: `category: convention`, `summary: ...`, `visibility: public`
#   - Tier A nested `metadata:` block: a `metadata.type` request resolves to the
#     `type:` line nested under `metadata:` (real Tier A files use
#     `metadata:\n  node_type: memory\n  type: project`, not flat `metadata.type:`).
# A dotted field (`metadata.type`) walks into the named block; a bare field
# (`visibility`) reads the top-level key. Only reads the first match.
read_frontmatter_field() {
  local file="$1" field="$2"
  [[ -f "$file" ]] || return 0
  # Split on the first dot: PARENT="metadata", LEAF="type".
  local parent="" leaf="$field"
  if [[ "$field" == *.* ]]; then
    parent="${field%%.*}"
    leaf="${field#*.}"
  fi
  if [[ -n "$parent" ]]; then
    # Nested-block path: read <leaf:> from under the <parent>: block.
    awk -v parent="$parent" -v leaf="$leaf" '
      /^---[[:space:]]*$/ { in_fm = !in_fm; next }
      !in_fm { next }
      { if (in_block && $0 ~ /^[^[:space:]]/) in_block = 0 }
      in_block && $0 ~ ("^[[:space:]]+" leaf ":") {
        sub("^[[:space:]]+" leaf ":[[:space:]]*", ""); print; exit
      }
      $0 ~ ("^" parent ":") { in_block = 1 }
    ' "$file" 2>/dev/null
  else
    # Flat-key path: read the top-level <leaf>: line.
    awk -v leaf="$leaf" '
      /^---[[:space:]]*$/ { in_fm = !in_fm; next }
      in_fm && $0 ~ ("^" leaf ":") { sub("^" leaf ":[[:space:]]*", ""); print; exit }
    ' "$file" 2>/dev/null
  fi
}

# --- resolve_cwd -------------------------------------------------------------
# Print the session's project cwd from CLAUDE_PROJECT_DIR, falling back to the
# `cwd` field of a Stop-hook stdin JSON payload passed on fd 0.
# Never blocks: reads stdin only if the env var is unset, and only once.
resolve_cwd() {
  if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    printf '%s' "$CLAUDE_PROJECT_DIR"
    return 0
  fi
  local stdin_json
  stdin_json=$(cat 2>/dev/null || printf '')
  if [[ -n "$stdin_json" ]]; then
    printf '%s' "$stdin_json" | python3 -c "import json,sys;print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null || true
  fi
}
