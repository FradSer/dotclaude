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

```bash
gh pr comment "$PR" --repo "$REPO" --body-file - <<'EOF'
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
```

`--body-file -` reads the heredoc from stdin, so multi-line bodies (and the user's actual
commit/review data pasted into the placeholders) work without shell-escaping pain. Replace
the placeholders with the real data gathered during Phases 1–4 before running.

If you already posted a summary comment earlier in the cycle, edit it in place rather than
posting a duplicate:

```bash
gh pr comment "$PR" --repo "$REPO" --edit-last --body-file - <<'EOF'
...same template, updated...
EOF
```

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
<one-line summary: N comments triaged, M adopted, K rejected; all CI green.>

## Verification
- <test commands run and their results>
- <manual checks performed>
EOF
```

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
units, not commit-by-commit), then a one-line **Review cycle** pointer to the summary
comment, then **Verification** (real commands + results, not claims). Keep it scannable —
headings and bullets, not prose walls.

## Merge decision

After the title/body are rewritten, the PR is a clean, self-contained record of the change.
The last step is to ask the user — via `AskUserQuestion` — whether to merge. **Merging is
hard to reverse and outward-facing**, so it requires an explicit user choice every time;
never auto-merge, and never merge past open `escalate` comments without surfacing them.

Ask one question, four mutually exclusive options:

- **Create a merge commit** (default — listed first)
- **Squash and merge**
- **Rebase and merge**
- **Don't merge**

If unresolved `escalate` comments remain on the PR, include the count in the question text
(e.g. "Note: 2 escalated comments are still open for your decision") so the user merges
with eyes open. The user may still choose to merge — that is their call, not the skill's.

On a merge choice, run the matching `gh pr merge`:

```bash
# Merge commit (default)
gh pr merge "$PR" --repo "$REPO" --merge

# Squash — pass --subject to avoid an interactive editor prompt; use the PR title.
gh pr merge "$PR" --repo "$REPO" --squash --subject "<PR title>"

# Rebase
gh pr merge "$PR" --repo "$REPO" --rebase
```

Never add `--auto` — that delegates the merge to CI status and silently merges without the
user's explicit confirmation, which defeats the AskUserQuestion gate. If the merge command
fails (branch protection, required reviews, stale base), surface the error to the user; do
not retry with different flags or force-push.

On "Don't merge": skip the merge entirely and fall through to `TaskStop`. The PR is already
in a clean, merge-ready state for the user to merge later by hand.

## Order and idempotency

1. Hide + resolve the fully-addressed comments (Phase 3 closeout) **first** — the summary
   comment should land on a clean PR. Re-sweep if a final CI push landed after the last
   closeout pass.
2. Post the summary comment.
3. Rewrite the title/body.
4. Ask the user via `AskUserQuestion` whether to merge; on a merge choice, run
   `gh pr merge` with the selected strategy.
5. `TaskStop` the Monitor.

Steps 1–3 are idempotent: re-running `gh pr edit` with the same title/body is a no-op, and
`gh pr comment --edit-last` updates rather than duplicates. Step 4 (the merge) is NOT
idempotent — only run it once, after the user's explicit choice. If the user interrupts and
you resume, skip steps already completed rather than re-posting; if the user already chose
"don't merge" or the merge already succeeded, do not ask again.

## Do not

- Do not post the summary while comments are still open or CI is still red — it would claim
  a merge-ready state that is not true.
- Do not rewrite the title/body to claim something the diff does not deliver.
- Do not include the closeout summary inside the PR body AND as a comment — the body
  describes the change; the comment records the review cycle. They are different records.
- Do not write the summary in the AI's voice or sign it as AI-generated; the user asked for
  it in their name.
- Do not auto-merge or use `gh pr merge --auto` — the merge requires an explicit
  `AskUserQuestion` choice every time. Never merge past open `escalate` comments without
  surfacing them in the question.
