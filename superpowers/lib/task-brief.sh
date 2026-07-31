#!/usr/bin/env bash
# lib/task-brief.sh — extract one task's full text from a plan file into a
# file the implementer sub-agent reads in one call, so task text never has to
# be pasted through the coordinator's context.
#
# Adapted from upstream obra/superpowers skills/subagent-driven-development/
# scripts/task-brief (v6.1.1), renamed and re-pathed to the local docs/plans/
# tree (Claude Code-only fork — no .superpowers/sdd directory).
#
# Usage: task-brief.sh PLAN_FILE TASK_NUMBER [OUTFILE]
#   PLAN_FILE    path to _index.md or a task-NNN-*.md file
#   TASK_NUMBER  the NNN of the task to extract (e.g. 002)
#   OUTFILE      optional; default <plan-dir>/_briefs/task-<N>-brief.md
#
# Exit codes:
#   0  wrote brief
#   2  bad usage / no such plan file
#   3  task not found in plan file
#
# The default OUTFILE lands INSIDE the plan directory's _briefs/ subdir so it
# is co-located with the plan and cleaned up with it.
set -euo pipefail

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
  echo "usage: task-brief.sh PLAN_FILE TASK_NUMBER [OUTFILE]" >&2
  exit 2
fi

plan=$1
n=$2
[ -f "$plan" ] || { echo "no such plan file: $plan" >&2; exit 2; }

if [ $# -eq 3 ]; then
  out=$3
else
  plan_dir=$(cd "$(dirname "$plan")" && pwd)
  out="${plan_dir}/_briefs/task-${n}-brief.md"
fi

# Source the shared repo_root helper for consistency with other lib scripts.
# (Not used for the default path — the default is plan-dir-relative, which is
# what callers want — but kept available for callers who source this file.)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=utils.sh
. "${SCRIPT_DIR}/utils.sh" 2>/dev/null || true

mkdir -p "$(dirname "$out")"

# Extract a single task heading's body from the plan file.
# A task heading looks like "# Task NNN:" or "## Task NNN:" — matches the
# task-NNN-*.md filename convention and the _index.md "Task NNN" references.
awk -v n="$n" '
  /^```/ { infence = !infence }
  !infence && /^#+[ \t]+Task[ \t]+[0-9]+/ {
    intask = ($0 ~ ("^#+[ \t]+Task[ \t]+" n "([^0-9]|$)"))
  }
  intask { print }
' "$plan" > "$out"

if [ ! -s "$out" ]; then
  echo "task ${n} not found in ${plan} (no heading matching 'Task ${n}')" >&2
  exit 3
fi

echo "wrote ${out}: $(wc -l < "$out" | tr -d ' ') lines"
