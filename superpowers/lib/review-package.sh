#!/usr/bin/env bash
# lib/review-package.sh — generate a review package (commit list, stat
# summary, net diff with extended context) written to a file the
# superpowers-evaluator reads in one call, so the diff never has to be pasted
# through the coordinator's context.
#
# Adapted from upstream obra/superpowers skills/subagent-driven-development/
# scripts/review-package (v6.1.1), re-pathed to the local docs/plans/ tree.
#
# Usage: review-package.sh BASE HEAD [PLAN_DIR] [OUTFILE]
#   BASE     git ref for the diff base (e.g. HEAD~1 or a commit sha)
#   HEAD     git ref for the diff head
#   PLAN_DIR optional plan directory; default <repo-root>/docs/plans/<auto>
#            (resolved from git toplevel if PLAN_DIR is omitted — caller must
#            pass PLAN_DIR when running outside a plan context)
#   OUTFILE  optional; default <PLAN_DIR>/_reviews/review-<base7>..<head7>.diff
#
# Exit codes:
#   0  wrote review package
#   2  bad usage / bad git ref
#
# The per-range filename means a re-review after fixes gets a distinct fresh
# file rather than overwriting the prior package.
set -euo pipefail

if [ $# -lt 2 ] || [ $# -gt 4 ]; then
  echo "usage: review-package.sh BASE HEAD [PLAN_DIR] [OUTFILE]" >&2
  exit 2
fi

base=$1
head=$2

git rev-parse --verify --quiet "$base" >/dev/null || { echo "bad BASE: $base" >&2; exit 2; }
git rev-parse --verify --quiet "$head" >/dev/null || { echo "bad HEAD: $head" >&2; exit 2; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=utils.sh
. "${SCRIPT_DIR}/utils.sh"

base7=$(git rev-parse --short "$base")
head7=$(git rev-parse --short "$head")

if [ $# -ge 4 ]; then
  out=$4
elif [ $# -eq 3 ]; then
  plan_dir=$3
  out="${plan_dir}/_reviews/review-${base7}..${head7}.diff"
else
  root=$(repo_root)
  out="${root}/docs/plans/_reviews/review-${base7}..${head7}.diff"
fi

mkdir -p "$(dirname "$out")"

{
  echo "# Review package: ${base}..${head}"
  echo
  echo "## Commits"
  git log --oneline "${base}..${head}"
  echo
  echo "## Files changed"
  git diff --stat "${base}..${head}"
  echo
  echo "## Diff"
  git diff -U10 "${base}..${head}"
} > "$out"

commits=$(git rev-list --count "${base}..${head}")
echo "wrote ${out}: ${commits} commit(s), $(wc -c < "$out" | tr -d ' ') bytes"
