#!/usr/bin/env bash
# clear-closeout.sh — clear the /github:review-pr closeout state for a PR.
#
# Removes .git/review-pr-closeout.json only when it was armed for $PR, so an
# interrupted closeout for one PR never deletes a pending one for another.
# No-op (exit 0) when the state is absent or belongs to a different PR.
#
# Usage:
#   bash clear-closeout.sh <PR>

set -u

PR="${1:-}"
[[ "$PR" =~ ^[0-9]+$ ]] || { echo "clear-closeout.sh: usage: clear-closeout.sh <PR> (PR must be a number)" >&2; exit 2; }

GITDIR=$(git rev-parse --git-dir 2>/dev/null) || exit 0
case "$GITDIR" in
  /*) ;;
  *)  GITDIR="$PWD/$GITDIR" ;;
esac

STATE="$GITDIR/review-pr-closeout.json"
[ -f "$STATE" ] || exit 0
[ "$(jq -r '.pr // empty' "$STATE" 2>/dev/null)" = "$PR" ] || exit 0
rm -f "$STATE"
