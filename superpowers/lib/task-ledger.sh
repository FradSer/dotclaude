#!/usr/bin/env bash
# lib/task-ledger.sh — durable per-task completion ledger for executing-plans.
#
# Records one JSON line per completed task to <plan-dir>/task-ledger.jsonl so
# a fresh coordinator (after context loss mid-batch, or a resumed /goal run)
# can check "was this task already verified done" from disk instead of from
# conversation memory. TaskList is the live status source; this ledger is the
# durable cross-restart backstop for the specific unit (task), mirroring
# upstream obra/superpowers subagent-driven-development's progress.md lesson:
# never re-dispatch an already-completed task — their observed most
# expensive failure mode.
#
# Usage:
#   task-ledger.sh append PLAN_DIR TASK_ID BATCH COMMIT_RANGE VERDICT
#   task-ledger.sh check  PLAN_DIR TASK_ID
#
# append: appends one NDJSON line to <PLAN_DIR>/task-ledger.jsonl.
#   BATCH         batch number this task ran in (e.g. "2")
#   COMMIT_RANGE  e.g. "abc1234..def5678" (the review-package BASE_SHA..HEAD range)
#   VERDICT       PASS | REWORK | PIVOT (the coordinator's processed verdict for this task)
#
# check: exits 0 and prints the most recent PASS ledger line for TASK_ID if
# one exists; exits 1 (silent, no stderr) if none is found. Call this before
# dispatching a task ID to skip re-dispatching already-verified work.
#
# Exit codes:
#   0  wrote (append) / found a PASS entry (check)
#   1  no PASS entry found (check only)
#   2  bad usage / missing jq / bad plan dir
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "usage: task-ledger.sh append PLAN_DIR TASK_ID BATCH COMMIT_RANGE VERDICT" >&2
  echo "       task-ledger.sh check  PLAN_DIR TASK_ID" >&2
  exit 2
fi

cmd=$1
shift

command -v jq >/dev/null 2>&1 || { echo "task-ledger.sh requires jq" >&2; exit 2; }

case "$cmd" in
  append)
    if [ $# -ne 5 ]; then
      echo "usage: task-ledger.sh append PLAN_DIR TASK_ID BATCH COMMIT_RANGE VERDICT" >&2
      exit 2
    fi
    plan_dir=$1
    task_id=$2
    batch=$3
    commit_range=$4
    verdict=$5
    [ -d "$plan_dir" ] || { echo "no such plan dir: $plan_dir" >&2; exit 2; }

    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    out="${plan_dir%/}/task-ledger.jsonl"
    jq -nc \
      --arg ts "$now" \
      --arg task_id "$task_id" \
      --arg batch "$batch" \
      --arg commit_range "$commit_range" \
      --arg verdict "$verdict" \
      '{ts: $ts, task_id: $task_id, batch: $batch, commit_range: $commit_range, verdict: $verdict}' \
      >> "$out"
    echo "appended task ${task_id} (verdict ${verdict}) to ${out}"
    ;;
  check)
    if [ $# -ne 2 ]; then
      echo "usage: task-ledger.sh check PLAN_DIR TASK_ID" >&2
      exit 2
    fi
    plan_dir=$1
    task_id=$2
    ledger="${plan_dir%/}/task-ledger.jsonl"
    [ -f "$ledger" ] || exit 1
    match=$(jq -c --arg id "$task_id" 'select(.task_id == $id and .verdict == "PASS")' "$ledger" | tail -n 1)
    if [ -n "$match" ]; then
      echo "$match"
      exit 0
    fi
    exit 1
    ;;
  *)
    echo "unknown subcommand: $cmd (expected append|check)" >&2
    exit 2
    ;;
esac
