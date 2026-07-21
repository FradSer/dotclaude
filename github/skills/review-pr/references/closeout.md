# Closeout: Summary, Body Rewrite, and Merge

Once the PR is merge-ready (all `[ci]` checks terminal and passing, every comment either
fixed, rejected-with-reply, or escalated-and-decided, and resolved comments hidden + their
threads resolved), write a summary of the work **as the user**, refresh the PR metadata
so the PR itself — not scattered review comments — becomes the record of what changed and why,
then ask the user whether to merge.

Do this exactly once, at the end, after the Phase 4 stop conditions hold. The merge step is
the last action before `TaskStop`.

## What the summary must cover

The user asked for two things in the closeout comment. Both are required:

1. **What was changed** — the substantive code/config changes across the review cycle
   (each `fix` round, summarized by commit). Not a git-log dump: group related commits and
   say what each group accomplished and why.
2. **What review surfaced and what was done about it** — for each comment batch, the
   outcome: adopted (with the fix), rejected (with the one-line reason), or escalated
   (and how it was resolved). This is the audit trail a reader needs to trust the merge.

Write it in the user's voice and first person ("I changed…", "Review flagged…, I fixed…").
No emojis, no marketing tone. Terse but complete.

## Write the summary comment

The body opens with the marker `<!-- review-pr:summary -->`. GitHub renders HTML comments as
nothing, and it makes the summary findable later without guessing which comment it was.

`gh pr comment` prints the new comment's URL on stdout — capture it. The PR body's Review-cycle
line links to that URL, which is why the comment must be posted *before* the body is rewritten.

```bash
SUMMARY_URL=$(gh pr comment "$PR" --repo "$REPO" --body-file - <<'EOF'
<!-- review-pr:summary -->
Summary of the review cycle on this PR.

## Changes made
- <group 1: what changed and why, in one or two lines>
- <group 2: ...>

## Review findings and resolution
- <Adopted> @<reviewer> on <path>:<line> — <what the comment was> → fixed in <sha>.
- <Rejected> @<reviewer> on <path>:<line> — <comment> → declined: <one-line reason>.
- <Escalated> @<reviewer> — <comment> → resolved by <decision>.

All CI checks are green and no comments remain worth adopting. This PR is ready to merge.
EOF
)
```

`--body-file -` reads the heredoc from stdin, so multi-line bodies (and the user's actual
commit/review data pasted into the placeholders) work without shell-escaping pain. Replace
the placeholders with the real data gathered during Phases 1–4 before running.

### Updating an existing summary

If a summary was already posted (a resumed session, a re-run after an interrupt), edit that
comment in place rather than posting a duplicate. Do NOT use `gh pr comment --edit-last`: it
edits your *most recent* comment on the PR, which may be a Phase 3 reject reply rather than
the summary, and overwrites it. Look the summary up by its marker and patch that exact id:

```bash
# `--paginate` runs the jq filter per page, so `.[] | select(...)` sees every page.
SUMMARY_ID=$(gh api --paginate "repos/$REPO/issues/$PR/comments" \
  --jq '.[] | select(.body | startswith("<!-- review-pr:summary -->")) | .id' | head -1)

# An empty SUMMARY_ID means no summary exists yet — post one with the block above instead.
SUMMARY_URL=$(gh api --method PATCH "repos/$REPO/issues/comments/$SUMMARY_ID" \
  -F body=@- --jq .html_url <<'EOF'
<!-- review-pr:summary -->
...same template, updated...
EOF
)
```

`-F body=@-` sends stdin verbatim as a string: the `@` prefix short-circuits gh's type coercion
and its `{owner}`/`{repo}`/`{branch}` placeholder expansion, so markdown passes through intact.

## Rewrite the PR title and body

The original PR title/body were written before the review cycle; by closeout the change may
have shifted scope, merged batches, or dropped approaches. Rewrite both so the PR page reads
as an accurate, self-contained description of what is actually being merged.

```bash
# Body is always rewritten. Title is rewritten ONLY if the current one no longer matches
# the merged change (see Title guidance below); drop --title when the title is already
# accurate.
gh pr edit "$PR" --repo "$REPO" \
  --title "<imperative, lowercase, conventional-commits if the repo uses them>" \
  --body-file - <<'EOF'
## What
<one-paragraph statement of what this PR changes>

## Why
<the problem or motivation; link issues if any>

## Changes
- <logical change 1>
- <logical change 2>

## Review cycle
<N> comments triaged over <R> rounds, <M> adopted, <K> rejected; all CI green.
Full breakdown: <paste $SUMMARY_URL here, e.g. https://github.com/owner/repo/pull/4#issuecomment-4930992385>

## Verification
- <test commands run and their results>
- <manual checks performed>
EOF
```

**The Review-cycle line MUST carry the summary comment's URL.** A count with no link is not a
pointer — the whole point is that a reader landing on the PR can reach the audit trail in one
click. The heredoc is quoted (`<<'EOF'`), so `$SUMMARY_URL` will NOT expand inside it: read the
URL that the previous command printed and paste it as a literal. Do not switch to an unquoted
heredoc to interpolate it — PR bodies contain backticks and `$` in code references, and an
unquoted heredoc would run them as command substitution.

### Title guidance

Rewrite the title only when the current one no longer matches the merged change (scope
drifted, the feature was renamed, the original was a WIP stub). If the title is already
accurate, leave it — **drop the `--title` flag from the command above and just rewrite the
body**; do not churn the title for style. When rewriting:
- Imperative mood, lowercase, under ~70 chars.
- Match the repo's conventions (conventional-commits prefix like `feat(scope):` if the
  repo's history uses it; plain imperative otherwise).
- The PR title does not need the commit-message body rules — it is a UI title, not a commit.

### Body guidance

The body is the durable record. Lead with **What** and **Why** (a reviewer who never read
the comments should understand the PR from the body alone), then **Changes** (the logical
units, not commit-by-commit), then a one-line **Review cycle** pointer *linking to the summary
comment*, then **Verification** (real commands + results, not claims). Keep it scannable —
headings and bullets, not prose walls.

The pointer is what makes the pair work: the body stays short and describes the merged change,
the linked comment holds the full comment-by-comment audit trail, and neither repeats the other.

## Merge decision

After the title/body are rewritten, the PR is a clean, self-contained record of the change.
The last step is to ask the user — via `AskUserQuestion` — whether to merge. **Merging is
hard to reverse and outward-facing**, so it requires an explicit user choice every time;
never auto-merge, and never merge past open `escalate` comments without surfacing them.

Ask one question, four mutually exclusive options:

- **Create a merge commit** (Recommended — listed first; the default merge strategy)
- **Squash and merge**
- **Rebase and merge**
- **Don't merge**

If unresolved `escalate` comments remain on the PR, include the count in the question text
(e.g. "Note: 2 escalated comments are still open for your decision") so the user merges
with eyes open. The user may still choose to merge — that is their call, not the skill's.

On a merge choice, run the matching `gh pr merge` (`--merge` / `--squash --subject "<title>"` /
`--rebase`). Never `--auto`.

## Auto-merge branch (`--auto-merge` opt-in)

When `--auto-merge` was parsed in Phase 1, the closeout swaps the `AskUserQuestion` step for
an automatic merge — but only under the same stop conditions that gate the question. The flag
is an opt-out from the *prompt*, not from the *readiness gate*.

**Pre-merge gate (ALL must hold, same as the explicit-choice path):**
1. Every `[ci]` check is terminal AND passing.
2. Every non-escalate comment is reflected on: `fix` pushed, `reject` replied, resolved ones
   hidden + threads resolved. Only `escalate` items may remain visible.
3. No open `escalate` comments. ← this is the hard switch

**If any `escalate` comment is still open, the auto-merge opt-in is suspended for this closeout.**
Fall back to the explicit `AskUserQuestion` (four options, merge listed first as Recommended)
and include the escalate count in the question text. Do not merge past escalate items just
because the flag was set — escalate means "needs human judgment", and auto-merging past it
is exactly the over-reach the explicit-choice rule exists to prevent. The user may still pick
merge from the question; that is their call.

**If the gate holds (CI green, zero open escalate), execute:**
1. Send a `PushNotification` that the PR is about to auto-merge — merge is hard to reverse and
   outward-facing, so warn the user before it lands (they may still interrupt to stop it).
   One line: e.g. "PR #<n>: CI green, no open comments — auto-merging with a merge commit."
2. Run `gh pr merge "$PR" --repo "$REPO" --merge` (add `--delete-branch` only when stack-safe
   AND in the main worktree, same rule as the explicit path). Never `--auto`.

**Single-shot.** Auto-merge is a one-shot choice for this PR. If the merge fails (branch
protection, required reviews, stale base), surface the error and stop — do not retry with
different flags, do not force-push, and do not re-arm auto-merge; the user decides next. If
the user interrupts and you resume, and the gate no longer holds (a new comment arrived, CI
re-ran red), do not auto-merge — re-check the gate, and if escalate items now exist, fall
back to the explicit question.

**On a successful auto-merge**, proceed to "After a successful merge" hygiene exactly as the
explicit-choice path would. `TaskStop` the Monitor.

`--delete-branch` removes **both** remote and local head — safe only in the main worktree when
no open PR still bases on that head. In a linked worktree (`/github:resolve-issues`), omit it:
delete the remote head separately if stack-safe, leave the local branch for `ExitWorktree`.

If merge fails (branch protection, required reviews, stale base), surface the error; do not
retry with different flags or force-push.

On "Don't merge": skip merge and post-merge hygiene; fall through to `TaskStop`.

## After a successful merge

Usual hygiene — no ritual script:

1. Ensure remote head is gone when stack-safe (and local head in the main worktree).
2. `fetch --prune`, then fast-forward local `main` and `develop` when present on origin,
   plus the PR's `baseRefName` if it is neither. Never force long-lived branches.
3. Drop other locals already merged into those; `worktree prune` as needed.

**Linked worktree**: fetch only — do not switch onto `main`/`develop` or delete the issue head.

## Stacked / chained PRs (base branch is a shared dependency)

When several PRs depend on each other — PR-B's `--base` is PR-A's head branch, not
`main` — **the base branch is a load-bearing dependency**, not a scratch branch. A
chain breaks in a specific, silent way that is easy to miss:

- PR-A merges into `main` with `--delete-branch`. Its head branch is deleted.
- PR-B (and PR-C, …) had `--base = <PR-A head branch>`. When that branch is deleted,
  GitHub auto-retargets their base to `main`, **but their merge commits were created
  against the now-deleted branch and become dangling** — the content of PR-B/C lands
  on **nothing**, and `main` advances with only PR-A's changes. The PRs show `MERGED`
  on GitHub, which is the trap: the merge state lies. The only reliable check is
  `git branch -r --contains <head-sha>` against `origin/main` — if it says no, the
  content is not on `main` despite the MERGED badge.

**Two safe patterns for a stack:**

1. **All PRs base on `main` directly** (no inter-PR base). Land them in order; each
   merge advances `main` and the next PR's base is already current. Simplest; prefer
   this unless the intermediate state is genuinely unreviewable on its own.
2. **Keep the base branch alive until every downstream PR is merged.** Merge the
   stack top-down (or in dependency order); do not delete a head that open PRs still
   base on.

If you suspect a stack already broke (PRs MERGED but content absent from `main`):
open one repair PR off `origin/main` that cherry-picks each missing head commit, and
link the dangling PRs in the body. Verify the repair with `git branch -r --contains
<sha> origin/main` before merging.

**Don't pre-announce implementation-detail strings in docs a parallel agent will
write.** When a stack splits docs (PR-E) from the code that emits a string
(PR-B), the docs author will name the string from intuition — `manual-blocks-initial`
— instead of the real `manual-skips-initial`. The review bots catch it, but it costs
a round-trip. If a downstream PR documents a value another PR produces, put the
exact literal in the upstream agent's prompt and have it referenced verbatim, or
land docs after the code PR merges so the author can grep the real value.

## Order and idempotency

1. Hide + resolve the fully-addressed comments (Phase 3 closeout) **first** — the summary
   comment should land on a clean PR. Re-sweep if a final CI push landed after the last
   closeout pass.
2. Post the summary comment, capturing its URL.
3. Rewrite the title/body, linking the Review-cycle line to that URL.

Steps 2 and 3 are ordered, not merely sequential: the body needs a URL that does not exist
until the comment is posted. Never rewrite the body first and backfill the link later.

4. Merge step — depends on the opt-in:
   - **No flag (default)**: ask the user via `AskUserQuestion` (four options, merge listed
     first as Recommended); on a merge choice, run `gh pr merge` (add `--delete-branch` only
     when stack-safe and in the main worktree).
   - **`--auto-merge` opt-in**: if the pre-merge gate holds with zero open `escalate` items,
     send a `PushNotification` then run `gh pr merge --merge` directly (no question). If any
     `escalate` item is open, suspend auto-merge and fall back to the explicit question.
5. After a successful merge: head cleanup + sync `main`/`develop` (see above).
6. `TaskStop` the Monitor.

Steps 1–3 are idempotent: re-running `gh pr edit` with the same title/body is a no-op, and the
marker lookup patches the existing summary rather than duplicating it (which also recovers
`SUMMARY_URL` after an interrupt). Steps 4 and 5 are NOT idempotent — only run them once, after
the user's explicit merge choice (or, under `--auto-merge`, the gate holding). If the user
interrupts and you resume, skip steps already completed; if they chose "don't merge", or
merge + hygiene already ran, do not repeat. Under `--auto-merge`, if the gate no longer holds
on resume (new comment or CI re-ran red), do not auto-merge — re-check and fall back to the
explicit question if escalate items now exist.

## Do not

- Do not post the summary while comments are still open or CI is still red — it would claim
  a merge-ready state that is not true.
- Do not rewrite the title/body to claim something the diff does not deliver.
- Do not include the closeout summary inside the PR body AND as a comment — the body
  describes the change; the comment records the review cycle. They are different records.
- Do not ship a Review-cycle line without the summary comment's URL. Counts alone strand the
  audit trail somewhere in a long comment thread.
- Do not edit the summary with `gh pr comment --edit-last` — it targets whatever you commented
  last, not the summary. Find it by its `<!-- review-pr:summary -->` marker.
- Do not write the summary in the AI's voice or sign it as AI-generated; the user asked for
  it in their name.
- Do not merge without the user's explicit choice OR the `--auto-merge` opt-in — the merge
  requires an explicit `AskUserQuestion` choice every time, unless the user set `--auto-merge`
  AND the pre-merge gate holds with zero open `escalate` items. Never call
  `gh pr merge --auto` (GitHub's background auto-merge feature, which fires whenever it can and
  bypasses your own gate); under `--auto-merge` use `gh pr merge --merge` (a direct merge you
  execute only when the gate holds). Never merge past open `escalate` comments without
  surfacing them — under `--auto-merge`, that means falling back to the explicit question
  instead of merging.
