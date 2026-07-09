# Review Loop: Monitor, Triage, Auto-Fix

Monitoring uses the **Monitor tool** — a single persistent background watch that emits
one tagged stdout line per new event for BOTH CI checks and PR comments. Each line
arrives as a notification across turns, so react to events instead of blocking on a
manual `while true` loop.

## Poll interval by PR size

Review comments on a PR typically come from **other agents** (automated linters, code-review
bots) and human reviewers. They arrive on no fixed schedule, so pick a poll interval matched
to the PR's size and pass it as `INTERVAL` (in seconds) to the script below.

| PR size | Lines changed (additions+deletions) | INTERVAL |
|---|---|---|
| Small | < 200 | 180 (3 min) |
| Medium | 200–1000 | 300 (5 min, recommended default) |
| Large | > 1000 | 480 (8 min) |

- Never poll faster than once per minute.
- Cap the total watch at ~2 hours (7200 s). After that, surface to the user that the PR is
  still unsettled rather than polling indefinitely.

Read size via `gh pr view <PR> --repo <REPO> --json additions,deletions` and pick the row.

## One Monitor for CI and Comments

Launch one Monitor with `persistent: true` (PR reviews arrive on no fixed schedule).
The command below emits:

- `[ci] <name>: <bucket>` once per check reaching a terminal bucket (pass/fail/cancel/skipping)
- `[comment] issue node=<id> id=<n> @<user>: <body>` for new issue-level comments
- `[comment] inline node=<id> id=<n> @<user> <path>:<line>: <body>` for new inline review comments
- `[comment] review node=<id> id=<n> @<user> [<STATE>]: <body>` for new review summaries (approve / request-changes / comment)

Every `[comment]` line carries two IDs so the closeout steps never need a second API fetch:
- `node=<id>` — the comment's GraphQL `node_id`, used by `minimizeComment` (hide) and to match
  review threads for `resolveReviewThread`.
- `id=<n>` — the REST numeric id, used by the `/pulls/$PR/comments/<id>/replies` endpoint to
  reply to accepted/rejected inline comments. (For review summaries, `id` is the review's id,
  not a comment id — it does not feed the replies endpoint.)

The script lives at `scripts/review-loop.sh` (executable, `#!/usr/bin/env bash`).
Run it via the Monitor tool — it reads `PR`, `REPO`, and `INTERVAL` from env
(or `--pr`/`--repo`/`--interval` flags) and emits the tagged lines above.

```bash
# From the skill, launch under a persistent Monitor:
PR=<pr-number> REPO=<owner>/<repo> INTERVAL=<sec> \
  bash ${CLAUDE_PLUGIN_ROOT}/skills/review-pr/scripts/review-loop.sh
```

Behavior notes:
- `since` is seeded to the PR's **creation time** (not launch time), so comments posted
  before the skill started are surfaced on poll 1. It advances to `now` after each poll.
- Comments dedup client-side by `node_id` (GitHub's `?since=` is inclusive, so a comment
  posted in the boundary second could otherwise re-emit).
- Reviews are fetched without a `submitted_at` filter and deduped by `node_id` — the old
  client-side `submitted_at > since` string compare dropped reviews posted in the launch
  second.
- `|| true` / `2>/dev/null` on every API call keeps one transient failure from killing
  the watch; `INTERVAL` is floored at 60s.

Run via the Monitor tool with `persistent: true` and a specific `description`
(e.g. `"CI + new comments on PR #<n> (5m poll)"`). Stop it with TaskStop when done — never
leave it running once the PR is settled.

## You do not have to adopt review comments

**CRITICAL**: Comments arriving on the PR are mostly from **other agents** and human
reviewers, not from you. They are suggestions to *consider*, not orders to apply. Default
to skepticism: verify each claim against the diff, and adopt only the comments that are
demonstrably correct and safe. Rejecting a comment (with a one-line reason) is the correct
and expected outcome for noise, false positives, or context misunderstandings.

The watch ends only when **every** comment received so far has been reflected on (triaged,
replied to, or fixed) and none remain worth adopting — not merely when the comment queue is
temporarily empty. Other agents may post more comments later.

## Reacting to Events

Each emitted line is a notification. The Monitor keeps running while you act, so apply
fixes, push, and let the same watch re-emit the resulting CI lines.

### `[ci]` failure

```bash
gh run view <run-id> --log-failed          # failed step logs
gh run list --branch <branch> --json status,conclusion,name,databaseId
```

| Failure Type | Signal | Action |
|---|---|---|
| Lint error | `eslint`, `ruff`, `biome` non-zero | Run formatter/linter, commit, push |
| Type error | `tsc`, `mypy` non-zero | Read error, apply type fix, push |
| Test failure | `jest`, `pytest` output `FAIL` | Fix code or update test, push |
| Build error | `npm run build`, `cargo build` fails | Fix import/config, push |
| Format drift | `prettier --check`, `black --check` fails | Run formatter, commit, push |

Stop and report (do NOT auto-fix) for: permission/auth (`403`, `401`, `token expired`),
missing secret (`secret not found`, `env var missing`), flaky test (passes on retry),
infrastructure (`timeout`, `OOM`, `runner unavailable`).

### `[comment]` batch — spawn independent triage agent

**CRITICAL: Never evaluate comments in the main conversation.** The main loop authored the PR and is biased — it will either defensively reject criticism or over-correct to please reviewers. Both failure modes are harmful. Instead, spawn an **independent review-triage agent** with a clean context.

**Why independent evaluation:**
- The PR author context rationalizes ("this is intentional") or capitulates ("the reviewer must be right")
- A fresh agent reads the diff and comment without sunk-cost bias
- The comments mostly come from **other agents** (linters, code-review bots) and human reviewers — they can be wrong, overzealous, or misunderstand context. Only ~40-60% of automated review comments are actually valid in practice
- The triage agent's job is to be a **skeptical gatekeeper**, not a fix applicator. Not adopting a comment is a normal, correct outcome.

**Triage agent prompt template:**

```
You are a skeptical code reviewer evaluating PR comments on behalf of the PR author.
You did NOT write this code. You have no attachment to it.

The comments below come from OTHER agents (automated linters, code-review bots) and
human reviewers. They are suggestions to CONSIDER, not orders to apply. Default to
skepticism — most automated review comments are noise, false positives, or context
misunderstandings. You do NOT have to adopt them.

Your job: for each comment below, independently verify whether it is correct and
worth applying. Rejecting a comment (with a one-line reason) is the expected outcome
for anything that is wrong, overzealous, or would harm the code.

Context:
- PR diff: <paste relevant diff sections via `git diff main...HEAD -- <files>`>
- Comments to evaluate: <paste all [comment] lines from this batch>

For EACH comment, return one of:
- `fix` — the claim is verified correct AND the suggested fix is safe to apply
- `reject <reason>` — the claim is wrong, overzealous, or the fix would be harmful
- `escalate` — design disagreement, scope change, or needs human judgment

Evaluation criteria (ALL must be true for `fix`):
1. Points to a specific file/line or names a concrete change
2. The claim is actually correct when you read the diff (verify it!)
3. The fix does not change behavior or API surface
4. The fix would not introduce worse problems than it solves
5. Consistent with the surrounding code style and project conventions

Common reasons to REJECT:
- Comment says "use const not let" but the variable IS reassigned
- Comment says "add a test" for internal implementation detail
- Comment says "remove this comment" but it explains non-obvious logic
- Comment enforces a style preference that conflicts with project conventions
- Comment misunderstands the code's purpose or context
- Comment is a generic linter false-positive (unused variable that IS used downstream)
- Comment is from an automated bot applying a generic rule that does not fit this code

Be terse. One line per comment, verdict first.
```

**Verdict format (one line per comment):**
```
<comment-id or file:line>: fix
<comment-id or file:line>: reject <one-line reason>
<comment-id or file:line>: escalate
```

**After the triage agent returns:**
1. Parse verdicts — apply ONLY `fix` verdicts
2. Reply to each `reject` comment explaining why it was declined
3. Send PushNotification for each `escalate` verdict with comment body + author + file context
4. Commit and push all `fix` changes together in one round
5. **Close out resolved comments** — for each comment that is now fully addressed (a `fix`
   that you applied and pushed, OR a `reject` you replied to with a reason), hide it as
   `OUTDATED` and resolve its thread. This keeps the PR review clean: only genuinely open
   comments stay visible. See "Closing out resolved comments" below for the exact commands.
   `escalate` comments stay open until the user decides.

Apply the validated fixes, commit and push them via the `/git:commit-and-push` skill (Skill tool), then acknowledge each. **The reply endpoint depends on comment type** — the `/pulls/$PR/comments/<id>/replies` endpoint ONLY accepts inline review-comment ids; using it for an issue-level comment or a review summary hits the wrong resource and fails:

```bash
# Reply to an accepted/rejected INLINE review comment (id=<n> from the emitted line).
gh api repos/$REPO/pulls/$PR/comments/<comment-id>/replies -f body="Fixed in <commit-sha>."     # accepted
gh api repos/$REPO/pulls/$PR/comments/<comment-id>/replies -f body="<rejection reason>"        # rejected

# Reply to an ISSUE-LEVEL comment — there is no reply endpoint; post a new PR
# issue comment (the `id=<n>` from the emitted line can be referenced in the body
# but is not used in the URL).
gh pr comment "$PR" --repo "$REPO" --body="Re: <rejection reason or fix summary>"

# REVIEW SUMMARIES have no reply endpoint at all — skip the reply. If a summary
# raises a point worth addressing, reply to its inline sub-comments (handled as
# inline above) or post a single summary issue comment via `gh pr comment`.
```

### Closing out resolved comments

When a comment is fully addressed (fixed-and-pushed, or rejected with a reply), hide and
resolve it so the PR review only shows what is still open. Both use GraphQL via `gh api graphql`,
keyed on the comment's `node_id` (GitHub's `node_id`, NOT the REST numeric id).

**Minimize (hide) a comment** — works on issue-level AND inline review comments:

```bash
# $NODE_ID = the comment's node_id (from .node_id in the REST responses above)
gh api graphql -f query="mutation { minimizeComment(input: {subjectId: \"$NODE_ID\", classifier: OUTDATED}) { minimizedComment { isMinimized } } }"
```

**Resolve an inline review comment's thread** — inline comments only; issue-level comments
have no thread. Resolving requires the **thread node ID**, which is NOT the comment node_id.
Resolve only the thread containing each *top-level* inline comment you addressed (skip reply
comments — their thread is the parent's). Look up the thread IDs once per PR, then resolve:

```bash
# 1. Fetch every review thread with its node ID, line, path, and the first comment's
#    GraphQL `id` — which equals the REST `node_id` you just triaged on, so you can match
#    each thread to the comment node_ids from the [comment] batch. Loop on the cursor:
#    `first:100` alone would truncate at 100 threads (bot-heavy PRs can exceed that),
#    leaving addressed comments beyond the first page unresolvable.
threads=""
cursor=""
while :; do
  page=$(gh api graphql -f query='query($pr:Int!, $owner:String!, $name:String!, $c:String!) {
    repository(owner:$owner, name:$name) {
      pullRequest(number:$pr) {
        reviewThreads(first:100, after:$c) {
          nodes { id isResolved line path comments(first:1) { nodes { id fullDatabaseId } } }
          pageInfo { hasNextPage endCursor }
        }
      }
    }
  }' -F owner="${REPO%/*}" -F name="${REPO#*/}" -F pr="$PR" -F c="$cursor" 2>/dev/null || true)
  [ -z "$page" ] && break
  threads="$threads$(printf '%s' "$page" | jq -c '.data.repository.pullRequest.reviewThreads.nodes[]')"
  has_next=$(printf '%s' "$page" | jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.hasNextPage')
  [ "$has_next" = "true" ] && cursor=$(printf '%s' "$page" | jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.endCursor') || break
done
# `threads` now holds one JSON thread object per line; match by comments[0].id (== node_id).
# 2. For each thread whose first comment you fully addressed, resolve it:
gh api graphql -f query="mutation { resolveReviewThread(input: {threadId: \"$THREAD_ID\"}) { thread { isResolved } } }"
```

Order per comment: for inline comments, reply first, then resolve the thread, then minimize
the comment (minimize-after-resolve is fine; minimizing a comment does not resolve its thread).
For issue-level comments, reply then minimize (no thread to resolve). Do NOT hide or resolve
`escalate` comments — they stay open for the user.

### `[comment]` ambiguous — PushNotification and report

Ambiguous when ANY are true: questions a design decision; requests a scope change or new
feature; unclear intent; needs business context not in the diff; multiple valid readings.

Examples: "Why not use X instead of Y?", "This feels over-engineered",
"Can we also handle Z?", "I'm not sure this is the right approach".

For these: send a **PushNotification** (the user may have stepped away), report the comment
body + author + file context, and let the user decide. Do NOT reply to or guess at these.

## Lifecycle

- The Monitor runs across turns; you keep working and react as lines arrive.
- A pushed fix triggers a fresh CI run that the same Monitor re-emits — no need to relaunch it.
- A temporarily empty comment queue is NOT a stop signal — other agents may post more
  comments later. Keep the watch running.
- Stop with **TaskStop** ONLY when ALL hold:
  1. Every `[ci]` check is terminal AND passing.
  2. Every review comment received so far has been reflected on (triaged, replied to,
     or fixed) AND every fully-resolved one is hidden + its thread resolved. The only
     comments left visible on the PR are unresolved `escalate` items awaiting the user.
  3. The user signals they are done with live coverage, or the ~2-hour max wall-clock
     is reached (in which case surface the unsettled state to the user first).
- If the user wants ongoing review coverage, leave it persistent and stop on their signal.
