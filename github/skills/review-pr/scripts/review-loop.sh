#!/usr/bin/env bash
# review-loop.sh — persistent CI + PR-comment watch for /github:review-pr.
#
# Emits one tagged stdout line per new event (consumed by the Monitor tool as
# per-turn notifications). Designed to run under `Monitor(persistent: true)`.
#
# Output format:
#   [ci] <name>: <bucket>                  — CI check reaching a terminal bucket
#   [comment] issue  @<user>: <body>       — new issue-level comment
#   [comment] inline @<user> <path>:<line>: <body>  — new inline review comment
#   [comment] review @<user> [<STATE>]: <body>      — new review summary
#
# Usage:
#   PR=<n> REPO=<owner>/<repo> INTERVAL=<sec> bash review-loop.sh
#   bash review-loop.sh --pr <n> --repo <owner>/<repo> [--interval <sec>]
#
# Env vars (PR / REPO / INTERVAL) take precedence over flags so the skill can
# pass them through Monitor's env.

set -u

PR="${PR:-}"
REPO="${REPO:-}"
INTERVAL="${INTERVAL:-300}"

while [ $# -gt 0 ]; do
  case "$1" in
    --pr)        PR="$2"; shift 2 ;;
    --repo)      REPO="$2"; shift 2 ;;
    --interval)  INTERVAL="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [ -z "$PR" ] || [ -z "$REPO" ]; then
  echo "review-loop.sh: --pr and --repo (or PR/REPO env) are required" >&2
  exit 2
fi

# INTERVAL sanity: never faster than once per minute (GitHub + token cost).
if [ "$INTERVAL" -lt 60 ] 2>/dev/null; then INTERVAL=60; fi

# Seed `since` to the PR's creation time (not launch time) so pre-existing
# comments posted before the skill started surface on poll 1. GitHub's ?since=
# is inclusive (>=); we advance it to `now` after each poll so only genuinely
# new comments are fetched next time.
since=$(gh pr view "$PR" --repo "$REPO" --json createdAt --jq '.createdAt' 2>/dev/null \
        || date -u +%Y-%m-%dT%H:%M:%SZ)

# Dedup sets, space-padded so `case *" $key "*` substring-match works.
seen_ci=" "
seen_comments=" "

emit_comment() {  # args: id  line
  [ -z "${1:-}" ] && return
  case "$seen_comments" in
    *" $1 "*) ;;
    *) echo "$2"; seen_comments="$seen_comments$1 " ;;
  esac
}

while true; do
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  # --- CI: emit each check that newly reached a terminal bucket (pass/fail/cancel/skip).
  checks=$(gh pr checks "$PR" --repo "$REPO" --json name,bucket 2>/dev/null || true)
  if [ -n "$checks" ]; then
    while IFS=$'\t' read -r name bucket; do
      [ -z "$name" ] && continue
      case "$seen_ci" in
        *" $name=$bucket "*) ;;
        *) echo "[ci] $name: $bucket"; seen_ci="$seen_ci$name=$bucket " ;;
      esac
    done < <(jq -r '.[] | select(.bucket!="pending") | "\(.name)\t\(.bucket)"' <<<"$checks" 2>/dev/null)
  fi

  # --- Issue-level comments (?since= is inclusive; dedup by node_id).
  while IFS=$'\t' read -r id line; do
    emit_comment "$id" "$line"
  done < <(gh api "repos/$REPO/issues/$PR/comments?since=$since" \
      --jq '.[] | "\(.node_id)\t[comment] issue @\(.user.login): \(.body | gsub("\n";" "))"' 2>/dev/null)

  # --- Inline review comments.
  while IFS=$'\t' read -r id line; do
    emit_comment "$id" "$line"
  done < <(gh api "repos/$REPO/pulls/$PR/comments?since=$since" \
      --jq '.[] | "\(.node_id)\t[comment] inline @\(.user.login) \(.path):\(.line // .original_line): \(.body | gsub("\n";" "))"' 2>/dev/null)

  # --- Review summaries. Fetch all non-PENDING and dedup by node_id client-side,
  # which avoids the fragile `submitted_at > since` string compare (that dropped
  # reviews posted in the launch second).
  while IFS=$'\t' read -r id line; do
    emit_comment "$id" "$line"
  done < <(gh api "repos/$REPO/pulls/$PR/reviews" \
      --jq '.[] | select(.state != "PENDING") | "\(.node_id)\t[comment] review @\(.user.login) [\(.state)]: \(.body | gsub("\n";" "))"' 2>/dev/null)

  since=$now
  sleep "$INTERVAL"
done
