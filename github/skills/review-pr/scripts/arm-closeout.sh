#!/usr/bin/env bash
# arm-closeout.sh — arm the /github:review-pr closeout state for a PR.
#
# Writes .git/review-pr-closeout.json (resolved via `git rev-parse --git-dir`,
# so the script works from any cwd inside the repo). While that file exists,
# the plugin's Stop hook (hooks/closeout-stop.sh) blocks turn-end until the
# merge decision is resolved.
#
# Usage:
#   bash arm-closeout.sh <PR>                # explicit AskUserQuestion closeout
#   bash arm-closeout.sh <PR> --auto-merge   # --auto-merge opt-in closeout

set -u

PR="${1:-}"
MODE="ask"
[ "${2:-}" = "--auto-merge" ] && MODE="auto"

# PR is a bare number (the skill normalizes it before arming); anything else
# would write invalid JSON that the hook cannot parse and the clear script can
# never remove — reject it outright.
[[ "$PR" =~ ^[0-9]+$ ]] || { echo "arm-closeout.sh: usage: arm-closeout.sh <PR> [--auto-merge] (PR must be a number)" >&2; exit 2; }

GITDIR=$(git rev-parse --git-dir 2>/dev/null) || { echo "arm-closeout.sh: not a git repository" >&2; exit 1; }
case "$GITDIR" in
  /*) ;;
  *)  GITDIR="$PWD/$GITDIR" ;;
esac

jq -n --arg pr "$PR" --arg mode "$MODE" '{pr:$pr,mode:$mode}' \
  > "$GITDIR/review-pr-closeout.json" || { echo "arm-closeout.sh: cannot write state file" >&2; exit 1; }
echo "closeout armed for PR #$PR (mode: $MODE)"
