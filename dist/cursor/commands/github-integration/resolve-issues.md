---
description: Resolve GitHub issues using isolated worktrees and TDD
trigger: /resolve-issues
---

## Context

- Current git status: `git status`
- Current branch: `git branch --show-current`
- Existing worktrees: `git worktree list`
- Open issues: `gh issue list --state open --limit 10`
- GitHub authentication: `gh auth status`

## Requirements

- Use isolated worktrees for development and follow the protected PR workflow.
- Apply a TDD cycle (red → green → refactor) with appropriate sub-agent support.
- Reference resolved issues in commits and PR descriptions using auto-closing keywords.
- Commit message title must be entirely lowercase
- Title must be less than 50 characters
- Commit message body must use normal text formatting (proper capitalization and punctuation)
- Follow conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
- Use atomic commits for logical units of work

## Your Task

1. Inspect the repository context, select a target issue, and decide whether to create a new worktree or resume an existing one.
2. Set up the worktree environment, implement the fix using TDD with specialized review agents, and ensure quality checks pass.
3. Create the pull request, link the issue, and clean up the worktree after merge, documenting all results to the user.

### Recommended Workflow

- **Issue Selection**: Evaluate open issues and prioritize the next actionable item.
- **Worktree Setup**: Create or reuse an isolated worktree with a descriptive branch name (e.g. `fix/456-auth-redirect`).
- **TDD Implementation**: Plan with @tech-lead-reviewer, write failing tests, implement fixes, and refactor with @code-simplifier while keeping tests green.
- **Quality Validation**: Run project-specific lint, test, and build commands before PR creation.
- **PR Creation & Cleanup**: Push the branch, raise a PR with auto-closing keywords, and remove the worktree after merge.
