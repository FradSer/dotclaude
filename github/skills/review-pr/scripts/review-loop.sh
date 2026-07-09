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

# INTERVAL sanity: must be a positive integer; never faster than once per
# minute (GitHub + token cost). A non-integer would make the `-lt` test fail
# and `sleep` return non-zero, spinning the loop without sleeping and flooding
# the API — so fall back to the default instead.
if ! [[ "$INTERVAL" =~ ^[0-9]+$ ]]; then
  INTERVAL=300
elif [ "$INTERVAL" -lt 60 ]; then
  INTERVAL=60
fi

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

  # Only advance `since` when the comment-fetching API calls all succeeded.
  # If a transient failure (rate limit, network) dropped a call, reusing the
  # old `since` next poll re-fetches that window — `seen_comments` dedups any
  # repeats, so no comment is permanently missed. Failing forward to `now`
  # would silently drop every comment posted during the failed window.
  api_ok=true

  # --- Issue-level comments (?since= is inclusive; dedup by node_id).
  # node=<id> is carried on the emitted line so hide/resolve can key on it.
  if issue_comments=$(gh api "repos/$REPO/issues/$PR/comments?since=$since" \
      --jq '.[] | "\(.node_id)\t[comment] issue node=\(.node_id) @\(.user.login): \(.body | gsub("\n";" "))"' 2>/dev/null); then
    while IFS=$'\t' read -r id line; do
      emit_comment "$id" "$line"
    done <<<"$issue_comments"
  else
    api_ok=false
  fi

  # --- Inline review comments.
  if inline_comments=$(gh api "repos/$REPO/pulls/$PR/comments?since=$since" \
      --jq '.[] | "\(.node_id)\t[comment] inline node=\(.node_id) @\(.user.login) \(.path):\(.line // .original_line): \(.body | gsub("\n";" "))"' 2>/dev/null); then
    while IFS=$'\t' read -r id line; do
      emit_comment "$id" "$line"
    done <<<"$inline_comments"
  else
    api_ok=false
  fi

  # --- Review summaries. Fetch all non-PENDING and dedup by node_id client-side,
  # which avoids the fragile `submitted_at > since` string compare (that dropped
  # reviews posted in the launch second).
  if review_summaries=$(gh api "repos/$REPO/pulls/$PR/reviews" \
      --jq '.[] | select(.state != "PENDING") | "\(.node_id)\t[comment] review node=\(.node_id) @\(.user.login) [\(.state)]: \(.body | gsub("\n";" "))"' 2>/dev/null); then
    while IFS=$'\t' read -r id line; do
      emit_comment "$id" "$line"
    done <<<"$review_summaries"
  else
    api_ok=false
  fi

  [ "$api_ok" = true ] && since=$now
  sleep "$INTERVAL"
done
