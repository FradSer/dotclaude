# Requirements

## Worktree and TDD Workflow

- Use the EnterWorktree/ExitWorktree tools for isolated development and follow the protected PR workflow.
- Apply a TDD cycle (red → green → refactor) with appropriate sub-agent support.
- Reference resolved issues in commits and PR descriptions using auto-closing keywords. Be aware that auto-closing keywords **only work when merged into the default branch**. If targeting a non-default branch, the issue must be closed manually.

## Commit Message Standards

See `references/commit-standards.md` for the full commit message standards.

## Protected PR Workflow

- No direct pushes to main/develop branches
- All changes must go through PR + review + CI
- Use worktrees to isolate development work
- Clean up worktrees after successful merge
