#!/usr/bin/env bash
# review-loop.sh — persistent CI + PR-comment watch for /github:review-pr.
#
# Emits one tagged stdout line per new event (consumed by the Monitor tool as
# per-turn notifications). Designed to run under `Monitor(persistent: true)`.
#
# Output format:
#   [ci] <name>: <bucket>                  — CI check reaching a terminal bucket
#   [comment] issue  node=<id> id=<n> @<user>: <body>       — new issue-level comment
#   [comment] inline node=<id> id=<n> @<user> <path>:<line>: <body>  — new inline review comment
#   [comment] review node=<id> id=<n> @<user> [<STATE>]: <body>      — new review summary
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
INTERVAL="${INTERVAL:-}"

while [ $# -gt 0 ]; do
  case "$1" in
    # Flags fill in only when the env var is unset, so env vars keep precedence
    # over flags (as the header above documents). Guard `$# -ge 2` BEFORE
    # touching `$2` — under `set -u` an absent `$2` would crash the watch, and
    # `shift 2` with too few args would spin forever. A flag missing its value
    # errors out cleanly instead.
    --pr)        if [ $# -ge 2 ]; then [ -z "${PR:-}" ] && PR="$2"; shift 2; else echo "review-loop.sh: $1 requires a value" >&2; exit 2; fi ;;
    --repo)      if [ $# -ge 2 ]; then [ -z "${REPO:-}" ] && REPO="$2"; shift 2; else echo "review-loop.sh: $1 requires a value" >&2; exit 2; fi ;;
    --interval)  if [ $# -ge 2 ]; then [ -z "${INTERVAL:-}" ] && INTERVAL="$2"; shift 2; else echo "review-loop.sh: $1 requires a value" >&2; exit 2; fi ;;
    -h|--help)
      sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

# Apply the INTERVAL default AFTER flag parsing — initializing it to 300 above
# the loop would make `[ -z "$INTERVAL" ]` false and silently ignore --interval.
INTERVAL="${INTERVAL:-300}"

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
seen_comments=" "

# CI dedup: track the last-seen bucket per check name so a regression
# (fail→pass→fail after a fix push) re-emits. A plain append-only `seen_ci` set
# would suppress the recurring fail because name=bucket was already recorded from
# the first failure — breaking the loop's job of re-surfacing failures after fix
# pushes. Only suppress when the bucket is UNCHANGED from the last poll.
#
# `last_ci` holds one `name=bucket` entry per line (newline-delimited). Newlines
# never appear in GitHub check names (which routinely contain spaces, e.g.
# `test (git)`), so a line is a whole name=bucket pair — a space-delimited scheme
# would split `test (git)=pass` into junk tokens. Plain string, not `declare -A`:
# macOS /bin/bash is 3.2 and has no associative arrays.
last_ci=$'\n'

# Replace any existing entry for `name` with `name=bucket` (or append if new),
# so only the latest bucket per check is remembered. `case ${name}=$bucket` is
# unquoted so `*` globs; lines are newline-delimited so the match is whole-entry.
set_ci_bucket() {  # args: name  bucket
  local name="$1" bucket="$2" line tmp=$'\n'
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    case "$line" in ${name}=*) ;; *) tmp="$tmp$line"$'\n' ;; esac
  done <<<"$last_ci"
  last_ci="${tmp}${name}=${bucket}"$'\n'
}

emit_comment() {  # args: id  line
  [ -z "${1:-}" ] && return
  case "$seen_comments" in
    *" $1 "*) ;;
    *) echo "$2"; seen_comments="$seen_comments$1 " ;;
  esac
}

while true; do
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  # --- CI: emit each check whose bucket changed since the last poll (pass/fail/cancel/skip).
  # Only suppress when the bucket is UNCHANGED from last poll, so a regression
  # (fail→pass→fail) re-emits the recurring failure rather than silently dropping it.
  checks=$(gh pr checks "$PR" --repo "$REPO" --json name,bucket 2>/dev/null || true)
  if [ -n "$checks" ]; then
    while IFS=$'\t' read -r name bucket; do
      [ -z "$name" ] && continue
      # Suppress only when an exact `name=bucket` line is already present (bucket
      # UNCHANGED from last poll); a changed bucket — including a regression back
      # to a previously-seen bucket — re-emits. Newline boundaries let names
      # containing spaces (e.g. `test (git)`) match as a whole entry.
      case "$last_ci" in *$'\n'"${name}=${bucket}"$'\n'*) continue ;; esac
      echo "[ci] $name: $bucket"
      set_ci_bucket "$name" "$bucket"
    done < <(jq -r '.[] | select(.bucket!="pending") | "\(.name)\t\(.bucket)"' <<<"$checks" 2>/dev/null)
  fi

  # Only advance `since` when the comment-fetching API calls all succeeded.
  # If a transient failure (rate limit, network) dropped a call, reusing the
  # old `since` next poll re-fetches that window — `seen_comments` dedups any
  # repeats, so no comment is permanently missed. Failing forward to `now`
  # would silently drop every comment posted during the failed window.
  api_ok=true

  # --- Issue-level comments (?since= is inclusive; dedup by node_id).
  # `--paginate` walks every page: poll 1 seeds `since` to the PR creation time,
  # so the whole comment history is in scope and a PR with >30 comments (GitHub's
  # default page size) would otherwise have its tail silently dropped before
  # `since` advances to `now`. node_id dedup handles repeats across polls.
  # node=<id> (GraphQL node_id, for hide/resolve) and id=<n> (REST numeric id,
  # for the /comments/<id>/replies endpoint) are both carried on the emitted
  # line so the closeout steps can key on either without a second API fetch.
  if issue_comments=$(gh api --paginate "repos/$REPO/issues/$PR/comments?since=$since" \
      --jq '.[] | "\(.node_id)\t[comment] issue node=\(.node_id) id=\(.id) @\(.user.login): \(.body | gsub("\n";" "))"' 2>/dev/null); then
    while IFS=$'\t' read -r id line; do
      emit_comment "$id" "$line"
    done <<<"$issue_comments"
  else
    api_ok=false
  fi

  # --- Inline review comments.
  if inline_comments=$(gh api --paginate "repos/$REPO/pulls/$PR/comments?since=$since" \
      --jq '.[] | "\(.node_id)\t[comment] inline node=\(.node_id) id=\(.id) @\(.user.login) \(.path):\(.line // .original_line): \(.body | gsub("\n";" "))"' 2>/dev/null); then
    while IFS=$'\t' read -r id line; do
      emit_comment "$id" "$line"
    done <<<"$inline_comments"
  else
    api_ok=false
  fi

  # --- Review summaries. Fetch all non-PENDING and dedup by node_id client-side,
  # which avoids the fragile `submitted_at > since` string compare (that dropped
  # reviews posted in the launch second). `--paginate` walks every page (GitHub's
  # default page size is 30) so a long-lived PR with >30 reviews doesn't silently
  # drop the tail; node_id dedup handles the repeats across polls.
  if review_summaries=$(gh api --paginate "repos/$REPO/pulls/$PR/reviews" \
      --jq '.[] | select(.state != "PENDING") | "\(.node_id)\t[comment] review node=\(.node_id) id=\(.id) @\(.user.login) [\(.state)]: \(.body | gsub("\n";" "))"' 2>/dev/null); then
    while IFS=$'\t' read -r id line; do
      emit_comment "$id" "$line"
    done <<<"$review_summaries"
  else
    api_ok=false
  fi

  [ "$api_ok" = true ] && since=$now
  sleep "$INTERVAL"
done
