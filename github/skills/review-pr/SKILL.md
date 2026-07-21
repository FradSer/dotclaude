---
name: review-pr
allowed-tools: Task, Bash(gh:*), Bash(git:*), Monitor, PushNotification, TaskStop, Skill, AskUserQuestion, Read, Edit, Write
description: Reviews a pull request with the built-in /review skill, then persists a Monitor watch over CI results and incoming reviewer comments, triages each comment through an independent skeptical agent, applies only verified fixes, and commits+pushes via /git:commit-and-push until CI passes and no comments remain to adopt. Use this skill when the user asks to "review a PR", "monitor PR review comments", "address reviewer feedback on #123", or "watch CI on a pull request".
argument-hint: <PR number or URL> [--auto-merge]
user-invocable: true
---

# Review a Pull Request

Run a baseline review with the built-in `/review`, then keep a persistent watch over CI and new reviewer comments until the PR settles.

## Context

- PR argument: `$ARGUMENTS`
- PR metadata: !`gh pr view "$ARGUMENTS" --json number,title,headRepository,headRepositoryOwner,additions,deletions,headRefName 2>/dev/null || printf 'set %s to a PR number or URL\n' "$ARGUMENTS"`
- Remote: !`git remote -v 2>/dev/null | head -2`
- Auth: !`gh auth status 2>&1 | head -3`

## Phase 1: Baseline Review and Sizing

**Goal**: Run the initial review, resolve the repo, and pick a poll interval sized to the PR.

**Actions**:
1. Parse the PR number or URL from `$ARGUMENTS`. If absent, list open PRs with `gh pr list` and ask the user which to review. **Normalize `PR` to the bare number** before any `gh api` REST call: `gh pr *` commands accept a URL, but `gh api repos/$REPO/issues/$PR/...` interpolates `$PR` into the URL path and breaks on a full URL — run `PR=$(gh pr view "$ARGUMENTS" --json number -q .number)` (the Context block already fetches `--json number`) and use `$PR` as the number everywhere downstream. **Parse `--auto-merge` from `$ARGUMENTS` and strip it before resolving the PR number** — it is a closeout opt-in (see Phase 5), not part of the PR identifier; treat its absence as the default (explicit `AskUserQuestion` merge).
2. Invoke `Skill("review", "<PR#>")` once for the baseline review. Treat its findings as the **first `[comment]` batch** — feed them straight into the Phase 3 triage flow before launching the Monitor. Do not act on them inline; the main context is biased (it likely authored the PR) and the same skeptical gatekeeping must apply to the baseline as to live comments.
3. Resolve `REPO=<owner>/<repo>` from the PR metadata above (fallback: `git remote get-url origin` parsed into `owner/repo`).
4. Read PR size from `additions+deletions` and pick `INTERVAL` (seconds) from the size table in `references/review-loop.md`: 180 / 300 / 480 for small / medium / large; floor 60s, cap 7200s (~2h).

## Phase 2: Launch the Persistent Monitor

**Goal**: One background watch streaming CI + comment events across turns.

**Action**: Launch a single `Monitor` with `persistent: true` running `${CLAUDE_PLUGIN_ROOT}/skills/review-pr/scripts/review-loop.sh`. The bare path `scripts/review-loop.sh` does NOT resolve — the skill runs in the PR's repository cwd, not the plugin dir, so the script must be addressed by its absolute plugin path. Pass `PR`, `REPO`, and `INTERVAL` as env vars (the script also accepts `--pr`/`--repo`/`--interval`). Use a specific `description` like `"CI + new comments on PR #<n> (<m> poll)"`. Do NOT run a foreground `while` loop. The script is documented in `references/review-loop.md`.

**CRITICAL: Do NOT skip the watch based on a launch-time snapshot.** "This repo has no CI workflow, so the watch would spin idly" is a **false** inference and not a valid reason to skip: CI is only one of the two things watched. Third-party auto-review services (GitHub Copilot code review, CodeRabbit, Greptile, Codex, Sourcery, and similar), org-level bots, and human reviewers post comments on no fixed schedule and are invisible in a launch-time snapshot — a repo with zero workflows can still accumulate a full review thread minutes after the PR opens. An empty `.github/workflows/` proves nothing about who will comment.

The only valid skip is an explicit user opt-out ("just baseline review, don't watch"). If CI and reviewers both appear absent AND the user still wants coverage, launch the watch anyway; it costs nothing and emits nothing until something changes.

## Phase 3: React to Each Monitor Event

**Goal**: Fix what is actionable, reject the noise, escalate the ambiguous. Full rules, prompt template, verdict format, and reply/hide/resolve lifecycle in `references/review-loop.md`.

- `[ci] <name>: fail|cancel` → fetch logs (`gh run view <run-id> --log-failed`), apply the fix, commit+push via `Skill("git:commit-and-push")`. The push triggers a fresh CI run the same Monitor re-emits. **CRITICAL: stop and report (do NOT auto-fix) for auth/permission, missing-secret, flaky, or infrastructure failures.**
- `[comment]` batch → **CRITICAL: spawn an independent review-triage Task agent with clean context.** Apply ONLY the `fix` verdicts; reject/escalate the rest. **CRITICAL: reply by comment type** — inline review comment → `gh api repos/$REPO/pulls/$PR/comments/<id>/replies`; issue-level comment → `gh pr comment` (no reply endpoint); review summary → skip reply. Use the `id=<n>`/`node=<id>` tokens from each emitted line. Commit+push all `fix` changes in one round; then hide each fully-addressed comment (`fix` pushed or `reject` replied) as `OUTDATED` via `minimizeComment` and resolve its thread via `resolveReviewThread` (inline only). Leave `escalate` comments open. Send a `PushNotification` per `escalate`.
- `[comment]` ambiguous (design disagreement, scope change, unclear intent) → `PushNotification` and report; do not guess, reply, hide, or resolve.

**CRITICAL mindset**: Comments are mostly from other agents (linters, code-review bots) and human reviewers — suggestions to *consider*, not orders. Default to skepticism; verify each claim against the diff and adopt only what is demonstrably correct and safe. Rejecting a comment is the normal outcome for noise and false positives.

## Phase 4: Stop Conditions

Stop the Monitor with `TaskStop` when EITHER holds — full conditions in `references/review-loop.md`:
- **Normal stop (all three)**: every `[ci]` check terminal + passing; every comment reflected on with resolved ones hidden + threads resolved (only `escalate` items remain visible); user signals done.
- **Hard cap (overrides the above)**: ~2h wall-clock reached OR user explicitly opts out — surface the unsettled state first (which of CI/comments is still open), then stop. Do NOT keep polling because CI is red or comments remain; the cap exists so a stuck PR cannot hold the watch open forever.

**CRITICAL: a temporarily empty comment queue is NOT a stop signal** — other agents may post more comments later.

## Phase 5: Closeout — Summary, Body Rewrite, and Merge

**Goal**: Once Phase 4 holds, post a merge-readiness summary comment (user's first-person voice), rewrite the PR title/body to link to it, then ask the user whether to merge. Full templates and ordered steps in `references/closeout.md`.

**CRITICAL constraints (hold even when detail is delegated to L3)**:
1. Capture the summary comment URL from `gh pr comment` stdout (`SUMMARY_URL=$(gh pr comment …)`).
2. The Review-cycle line in the rewritten body MUST contain that literal URL — a count with no link is not a pointer, and the quoted heredoc will not expand `$SUMMARY_URL`, so paste it.
3. Steps are ordered — the body needs the comment URL, so summary first, body second.
4. Do not sign the summary as AI-generated; body describes the change, comment records the review cycle — keep them distinct.
5. Do not post summary / rewrite body / ask to merge while CI is red or comments remain open; never auto-merge past open `escalate` items.
6. Merge only after an explicit `AskUserQuestion` choice (merge [Recommended]/squash/rebase/don't); never `--auto`. **`--auto-merge` opt-in**: when the flag was parsed in Phase 1, skip the `AskUserQuestion` and auto-merge with `gh pr merge --merge` (NOT `--auto`) once CI is green AND every non-escalate comment is triaged — see `references/closeout.md` (Merge decision → Auto-merge branch). If any `escalate` comment remains open, the opt-in is suspended: fall back to the explicit `AskUserQuestion` and surface the escalate items in the question text. Auto-merge is a single-shot choice for this PR; it does not re-arm after a failure or an interrupt.
7. Never force long-lived branch updates; `--delete-branch` only when stack-safe AND in the main worktree.

`TaskStop` the Monitor after closeout completes.

## References

- **Review Loop**: `references/review-loop.md` - Monitor script, size→INTERVAL table, triage agent prompt, verdict format, lifecycle/stop conditions
- **Closeout**: `references/closeout.md` - Summary comment, body rewrite, merge decision, post-merge hygiene constraints
- **Commit Standards**: `references/commit-standards.md` - Commit message format for the /git:commit-and-push rounds
- **Repository Templates**: `references/repository-templates.md` - Contributing guidelines conformance for fixes
- **Examples**: `references/examples.md` - Commit message examples
