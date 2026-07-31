#!/bin/bash
#
# lib/classify.sh — public/private/redacted visibility for memory files.
#
# Both tiers carry an optional `visibility` frontmatter field:
#   private  — default on Tier A. Stays in the private harness memory; never
#              synced or published.
#   public   — default on Tier B (it's already git-tracked). Eligible for
#              bidirectional sync.
#   redacted — a secret-bearing file (passwords, tokens, keys). Never synced,
#              never published, regardless of the visibility field's value.
#
# Secrets are auto-detected: if the filename or body matches the denylist
# below, the file is treated as redacted even without an explicit field. This
# guards files like frad-nas-kicad-password.md or substore-openclash-secrets.md
# from ever leaking Tier A -> Tier B.

# shellcheck source=memory-lib.sh
# (callers source memory-lib.sh first so read_frontmatter_field is available)

# Secret denylist — one pattern per line, so iteration does not depend on
# word-splitting (which differs between bash and zsh). Substring match against
# the filename, case-insensitive.
SECRET_PATTERNS="password
secret
token
apikey
api-key
privatekey
private-key
credential"

# is_secret_filename <file> — 0 if the filename matches the secret denylist.
is_secret_filename() {
  local base lower pat
  base=$(basename "$1" .md)
  lower=$(printf '%s' "$base" | tr '[:upper:]' '[:lower:]')
  # SECRET_PATTERNS is newline-separated, so `read -r pat` walks one pattern per
  # iteration — portable across bash and zsh (no word-splitting dependency).
  while IFS= read -r pat; do
    [[ -z "$pat" ]] && continue
    case "$lower" in
      *"$pat"*) return 0 ;;
    esac
  done <<<"$SECRET_PATTERNS"
  return 1
}

# is_secret_body <file> — 0 if the body contains a literal redaction marker
# line ('REDACTED' / 'SECRET') or a key=value secret shape. Conservative:
# only matches explicit markers, not every occurrence of the word "token".
is_secret_body() {
  [[ -f "$1" ]] || return 1
  grep -qiE '^(REDACTED|SECRET:|<!-- secret)' "$1" 2>/dev/null
}

# read_visibility <file> — print the file's visibility: public|private|redacted.
# Redacted wins over the explicit field when the filename/body is secret-bearing.
read_visibility() {
  local file="$1"
  if is_secret_filename "$file" || is_secret_body "$file"; then
    printf 'redacted'
    return 0
  fi
  local vis
  vis=$(read_frontmatter_field "$file" visibility)
  case "$vis" in
    public) printf 'public' ;;
    redacted) printf 'redacted' ;;
    *) printf 'private' ;;
  esac
}

# is_syncable <file> — 0 iff the file may be synced/published (public only).
# redacted and private are never syncable.
is_syncable() {
  [[ "$(read_visibility "$1")" == "public" ]]
}

# set_visibility <file> <public|private|redacted> — write/update the visibility
# field in <file>'s frontmatter. Creates the field if absent. Idempotent.
set_visibility() {
  local file="$1" val="$2"
  [[ -f "$file" ]] || return 1
  # Ensure a frontmatter block exists with a '---' opener; if not, prepend one.
  # `--` terminates option parsing so BSD grep does not read '---' as a long option.
  if ! head -1 "$file" 2>/dev/null | grep -qx -- '---'; then
    local tmp
    tmp=$(mktemp)
    printf -- '---\nvisibility: %s\n---\n\n' "$val" > "$tmp"
    cat "$file" >> "$tmp"
    mv "$tmp" "$file"
    return 0
  fi
  # Replace or insert the visibility line within the existing frontmatter.
  if grep -q '^visibility:' "$file"; then
    # BSD/GNU sed -i compatible: write to tmp and mv.
    local tmp
    tmp=$(mktemp)
    awk -v v="$val" '
      /^---[[:space:]]*$/ { in_fm = !in_fm; print; next }
      in_fm && /^visibility:/ { print "visibility: " v; next }
      { print }
    ' "$file" > "$tmp" && mv "$tmp" "$file"
  else
    # Insert visibility: as the first frontmatter key (after the opening ---).
    local tmp
    tmp=$(mktemp)
    awk -v v="$val" '
      NR==1 && /^---[[:space:]]*$/ { print; print "visibility: " v; next }
      { print }
    ' "$file" > "$tmp" && mv "$tmp" "$file"
  fi
}
