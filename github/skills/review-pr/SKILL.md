---
name: review-pr
allowed-tools: Task, Bash(gh:*), Bash(git:*), Monitor, PushNotification, TaskStop, Skill, Read, Edit, Write
description: Reviews a pull request with the built-in /review skill, then persists a Monitor watch over CI results and incoming reviewer comments, triages each comment through an independent skeptical agent, applies only verified fixes, and commits+pushes via /git:commit-and-push until CI passes and no comments remain to adopt. Use this skill when the user asks to "review a PR", "monitor PR review comments", "address reviewer feedback on #123", or "watch CI on a pull request".
argument-hint: <PR number or URL>
user-invocable: true
---

# Review a Pull Request

Run a baseline review with the built-in `/review`, then keep a persistent watch over CI and new reviewer comments until the PR settles.

## Context

- PR argument: `$ARGUMENTS`
- PR metadata: !`gh pr view $ARGUMENTS --json number,title,headRepository,headRepositoryOwner,additions,deletions,headRefName 2>/dev/null || echo "set $ARGUMENTS to a PR number or URL"`
- Remote: !`git remote -v 2>/dev/null | head -2`
- Auth: !`gh auth status 2>&1 | head -3`

## Phase 1: Baseline Review and Sizing

**Goal**: Run the initial review, resolve the repo, and pick a poll interval sized to the PR.

**Actions**:
1. Parse the PR number or URL from `$ARGUMENTS`. If absent, list open PRs with `gh pr list` and ask the user which to review.
2. Invoke `Skill("review", "<PR#>")` once for the baseline review. Treat its findings as the **first `[comment]` batch** — feed them straight into the Phase 3 triage flow before launching the Monitor. Do not act on them inline; the main context is biased (it likely authored the PR) and the same skeptical gatekeeping must apply to the baseline as to live comments.
3. Resolve `REPO=<owner>/<repo>` from the PR metadata above (fallback: `git remote get-url origin` parsed into `owner/repo`).
4. Read PR size from `additions+deletions` and pick `INTERVAL` (seconds) from the size table in `references/review-loop.md`: 180 / 300 / 480 for small / medium / large; floor 60s, cap 7200s (~2h).

## Phase 2: Launch the Persistent Monitor

**Goal**: One background watch streaming CI + comment events across turns.

**Action**: Launch a single `Monitor` with `persistent: true` running `scripts/review-loop.sh`. Pass `PR`, `REPO`, and `INTERVAL` as env vars (the script also accepts `--pr`/`--repo`/`--interval`). Use a specific `description` like `"CI + new comments on PR #<n> (<m> poll)"`. Do NOT run a foreground `while` loop. The script is documented in `references/review-loop.md`.

Do NOT skip the watch based on a launch-time snapshot of "no CI and no reviewers" — comments from other agents/humans arrive later on no fixed schedule (see Phase 4). The only valid skip is an explicit user opt-out ("just baseline review, don't watch"). If CI and reviewers are both genuinely absent AND the user still wants coverage, launch the watch anyway; it will emit nothing until something changes.

## Phase 3: React to Each Monitor Event

**Goal**: Fix what is actionable, reject the noise, escalate the ambiguous. Full rules in `references/review-loop.md`.

- `[ci] <name>: fail|cancel` → fetch logs with `gh run view <run-id> --log-failed`, apply the fix, then commit+push via `Skill("git:commit-and-push")`. The push triggers a fresh CI run that the same Monitor re-emits — no relaunch needed. Stop and report (do NOT auto-fix) for auth/permission, missing-secret, flaky, or infrastructure failures.
- `[comment]` batch → **CRITICAL: spawn an independent review-triage agent** via `Task` with a clean context. Use the prompt template and verdict format in `references/review-loop.md` (`fix` / `reject <reason>` / `escalate`). Apply ONLY the `fix` verdicts. Reply to each `reject` via `gh api repos/$REPO/pulls/$PR/comments/<id>/replies`. Send a `PushNotification` for each `escalate` with comment body, author, and file context. Commit+push all `fix` changes together in one round via `Skill("git:commit-and-push")`.
- `[comment]` ambiguous (design disagreement, scope change, unclear intent) → `PushNotification` and report to the user; do not guess or reply.

**CRITICAL mindset**: Comments are mostly from other agents (linters, code-review bots) and human reviewers. They are suggestions to *consider*, not orders. Default to skepticism — verify each claim against the diff and adopt only what is demonstrably correct and safe. Rejecting a comment is the normal, expected outcome for noise and false positives.

## Phase 4: Stop Conditions

Stop the Monitor with `TaskStop` ONLY when ALL hold:
1. Every `[ci]` check is terminal AND passing.
2. Every review comment received so far has been reflected on (triaged, replied to, or fixed) — none remain worth adopting.
3. The user signals they are done with live coverage, or the ~2-hour max wall-clock is reached (surface the unsettled state to the user first).

A temporarily empty comment queue is NOT a stop signal — other agents may post more comments later.

## References

- **Review Loop**: `references/review-loop.md` - Monitor script, size→INTERVAL table, triage agent prompt, verdict format, lifecycle/stop conditions
- **Commit Standards**: `references/commit-standards.md` - Commit message format for the /git:commit-and-push rounds
- **Repository Templates**: `references/repository-templates.md` - Contributing guidelines conformance for fixes
- **Examples**: `references/examples.md` - Commit message examples
