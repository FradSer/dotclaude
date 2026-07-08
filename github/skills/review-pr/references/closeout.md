# Closeout: Summary Comment and PR Body Rewrite

Once the PR is merge-ready (all `[ci]` checks terminal and passing, every comment either
fixed, rejected-with-reply, or escalated-and-decided, and resolved comments hidden + their
threads resolved), write a summary of the work **as the user** and refresh the PR metadata
so the PR itself — not scattered review comments — becomes the record of what changed and why.

Do this exactly once, at the end, after the Phase 4 stop conditions hold. It is the last
action before `TaskStop`.

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
accurate, leave it — do not churn the title for style. When rewriting:
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

## Order and idempotency

1. Hide + resolve the fully-addressed comments (Phase 3 closeout) **first** — the summary
   comment should land on a clean PR.
2. Post the summary comment.
3. Rewrite the title/body.
4. `TaskStop` the Monitor.

These are idempotent: re-running `gh pr edit` with the same title/body is a no-op, and
`gh pr comment --edit-last` updates rather than duplicates. If the user interrupts and you
resume, skip steps already completed rather than re-posting.

## Do not

- Do not post the summary while comments are still open or CI is still red — it would claim
  a merge-ready state that is not true.
- Do not rewrite the title/body to claim something the diff does not deliver.
- Do not include the closeout summary inside the PR body AND as a comment — the body
  describes the change; the comment records the review cycle. They are different records.
- Do not write the summary in the AI's voice or sign it as AI-generated; the user asked for
  it in their name.
