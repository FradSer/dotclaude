# Requirements

## Worktree and TDD Workflow

- Use the EnterWorktree/ExitWorktree tools for isolated development and follow the protected PR workflow.
- Apply a TDD cycle (red → green → refactor) with appropriate sub-agent support.
- Reference resolved issues in commits and PR descriptions using auto-closing keywords. Be aware that auto-closing keywords **only work when merged into the default branch**. If targeting a non-default branch, the issue must be closed manually.
- Delegate PR creation to `/github:create-pr` — it is the plugin's only PR-creating path, and the only one that reaches the `/github:review-pr` loop.

## Commit Message Standards

See `references/commit-standards.md` for the full commit message standards.

## Protected PR Workflow

- No direct pushes to main/develop branches
- All changes must go through PR + review + CI
- Every PR enters the `/github:review-pr` loop after creation — review, fix what is verified, commit+push, wait for the next review round — until CI is green and every comment is triaged
- Use worktrees to isolate development work
- Clean up worktrees after successful merge
