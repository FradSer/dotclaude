---
name: resolve-issues
allowed-tools: Bash(gh:*), Bash(git:*), Bash(cd:*), Bash(mkdir:*), Task
description: Resolve GitHub issues using isolated worktrees and TDD
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
3. Create new worktree with descriptive branch name (see `references/workflow-details.md` for naming)
4. Navigate to worktree directory for isolated development
5. Verify issue acceptance criteria and dependencies

## Phase 2: TDD Implementation

**Goal**: Implement fix using test-driven development with agent collaboration.

**Actions**:
1. Plan implementation with @tech-lead-reviewer for architectural assessment
2. Write failing tests that verify issue is resolved (RED phase)
3. Implement minimal code to make tests pass (GREEN phase)
4. Refactor with @code-simplifier while keeping tests green (REFACTOR phase)
5. Run quality validation commands (see `references/workflow-details.md` for project-specific checks)

## Phase 3: PR Creation and Cleanup

**Goal**: Create pull request, link issue, and clean up worktree after merge.

**Actions**:
1. Push branch to remote with `git push -u origin <branch-name>`
2. Create PR using `gh pr create` with auto-closing keywords (e.g., "Closes #456")
3. Report PR URL and status to user
4. After successful merge: remove worktree and delete local branch
5. Document resolution and any follow-up tasks

## References

- **Requirements**: `references/requirements.md` - Worktree setup, TDD, and commit standards
- **Workflow Details**: `references/workflow-details.md` - Issue selection, TDD cycle, agent collaboration
- **Examples**: `references/examples.md` - Commit message examples
