# Requirements

## Worktree and TDD Workflow

- Use the EnterWorktree/ExitWorktree tools for isolated development and follow the protected PR workflow.
- Apply a TDD cycle (red → green → refactor) with appropriate sub-agent support.
- Reference resolved issues in commits and PR descriptions using auto-closing keywords. Be aware that auto-closing keywords **only work when merged into the default branch**. If targeting a non-default branch, the issue must be closed manually.

## Commit Message Standards

- **Use atomic commits for logical units of work**: Each commit should represent one complete, cohesive change.
- Title: entirely lowercase, <50 chars, imperative mood (e.g., "add", "fix", "update"), conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
  - Scope (optional): lowercase noun, 1-2 words. Must match existing scopes in git history.
- Body: blank line after title, ≤72 chars per line, must start with uppercase letter, standard capitalization and punctuation. Describe what changed and why, not how.
- Footer (optional): Must start with uppercase letter, standard capitalization. Reference issues/PRs (Closes #123, Fixes #456, Linked to PR #789). Use BREAKING CHANGE: prefix for breaking changes.

## Protected PR Workflow

- No direct pushes to main/develop branches
- All changes must go through PR + review + CI
- Use worktrees to isolate development work
- Clean up worktrees after successful merge
