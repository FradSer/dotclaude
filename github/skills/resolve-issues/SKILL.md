---
name: resolve-issues
allowed-tools: Bash(gh:*), Bash(git:*), EnterWorktree, ExitWorktree, Task, Skill
description: Resolves GitHub issues using isolated worktrees and test-driven development, then delegates PR creation to /github:create-pr so the quality gate and the /github:review-pr loop always run. This skill should be used when the user asks to "resolve an issue", "fix issue #123", or needs to implement a solution for a specific GitHub ticket using a structured workflow.
argument-hint: [issue number or description]
user-invocable: true
---

# Resolve GitHub Issues

Execute issue resolution workflow using isolated worktrees, TDD methodology, and agent collaboration.

## Context

- Current git status: !`git status`
- Current branch: !`git branch --show-current`
- Existing worktrees: !`git worktree list`
- Open issues: !`gh issue list --state open --limit 10`
- GitHub authentication: !`gh auth status`

## Requirements Summary

Use isolated worktrees to avoid disrupting main development. Follow TDD cycle (red → green → refactor) with agent support. Reference issues in commits using auto-closing keywords. See `references/requirements.md` for protected PR workflow and commit standards.

## Phase 1: Issue Selection and Worktree Setup

**Goal**: Select target issue and prepare isolated development environment.

**Actions**:
1. Review open issues from context and select based on priority and `$ARGUMENTS`
2. Check existing worktrees to determine if reuse is possible
3. Use the EnterWorktree tool with a descriptive name (e.g., `fix-456-auth-redirect`) to create an isolated session
4. Rename the auto-generated branch to match conventions: run `git branch -m <type>/<issue>-<description>` (see `references/workflow-details.md` for naming)
5. Verify issue acceptance criteria and dependencies

## Phase 2: TDD Implementation

**Goal**: Implement fix using test-driven development with agent collaboration.

**Actions**:
1. Plan implementation approach and assess architectural impact
2. Write failing tests that verify issue is resolved (RED phase)
3. Implement minimal code to make tests pass (GREEN phase)
4. Refactor while keeping tests green (REFACTOR phase)
5. Run quality validation commands to keep the TDD cycle honest (see `references/workflow-details.md` for project-specific checks). `/github:create-pr` re-runs the full gate in Phase 3 and is the authoritative pre-PR check.

## Phase 3: PR Creation and Cleanup

**Goal**: Hand PR creation to `/github:create-pr` so the quality gate and the review loop run. Cleanup happens only after the merge, which may be many turns later.

**Actions**:
1. Push branch to remote with `git push -u origin <branch-name>`
2. **CRITICAL: Do NOT call `gh pr create` here.** Invoke `Skill("github:create-pr", "<issue reference>")` — e.g. `Skill("github:create-pr", "Closes #456")`. This is the plugin's only PR-creating path: it owns the quality/security gate, the auto-closing-keyword linkage, the non-default-branch warning, and the mandatory `/github:review-pr` handoff (review → fix → commit+push → wait for review, until CI is green and every comment is triaged). Creating the PR directly skips all of it.
   - Append `--draft` to the arguments if the fix requires further feedback before review
   - Append `--no-monitor` only when the user explicitly opts out of the review loop
3. **This skill does not resume here.** `/github:create-pr` reports the PR URL, and `/github:review-pr` then owns the PR for the rest of its life: a persistent Monitor spanning turns, the triage/fix/push rounds, and the merge decision it asks the user to make. Do NOT wait inline, do NOT re-report the URL, and do NOT run Phase 4 speculatively.

## Phase 4: Post-Merge Cleanup (later turn)

**Trigger**: The PR from Phase 3 has actually merged — normally a later turn, after `/github:review-pr` completed its merge decision. Verify with `gh pr view <PR#> --json state -q .state` returning `MERGED`; never assume.

**Actions**:
1. **CRITICAL: confirm the session is still in the issue worktree and still on the issue branch** (`git branch --show-current`) before removing anything. `/github:review-pr` runs a post-merge base-branch sync; if it ever left this worktree checked out on the base branch (`main`/`develop`) rather than the issue branch, `ExitWorktree action:"remove"` would delete the **base** branch. Stop and report instead of removing.
2. Use the ExitWorktree tool with action "remove" to clean up worktree and branch
   - If uncommitted changes exist, ExitWorktree refuses; confirm with the user before setting `discard_changes: true`
3. Document resolution and any follow-up tasks

## References

- **Requirements**: `references/requirements.md` - Worktree setup, TDD, and commit standards
- **Workflow Details**: `references/workflow-details.md` - Issue selection, TDD cycle, agent collaboration
- **Examples**: `references/examples.md` - Commit message examples
