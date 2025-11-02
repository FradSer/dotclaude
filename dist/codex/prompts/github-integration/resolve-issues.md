# Resolve Issues

**Summary:** Resolve GitHub issues using isolated worktrees and TDD

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
- **Use atomic commits for logical units of work**: Each commit should represent one complete, cohesive change.
- Title: entirely lowercase, <50 chars, imperative mood (e.g., "add", "fix", "update"), conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
- Body: blank line after title, ≤72 chars per line, normal capitalization and punctuation. Describe what changed and why, not how.
- Footer (optional): Reference issues/PRs (Closes #123, Fixes #456, Linked to PR #789). Use BREAKING CHANGE: prefix for breaking changes.

### Examples

```
feat(auth): add google oauth login flow

- introduce Google OAuth 2.0 for user sign-in
- add backend callback endpoint `/auth/google/callback`
- update login UI with Google button and loading state

Add a new authentication option improving cross-platform sign-in.

Closes #42. Linked to #38 and PR #45
```

```
fix(api): handle null payload in session refresh

- validate payload before accessing `user.id`
- return proper 400 response instead of 500
- add regression test for null input

Prevents session refresh crash when token expires.

Fixes #105
```

```
feat(auth): migrate to oauth 2.0

- replace basic auth with OAuth 2.0 flow
- update authentication middleware
- add token refresh endpoint

BREAKING CHANGE: Authentication API now requires OAuth 2.0 tokens. Basic auth is no longer supported.

Closes #120. Linked to #115 and PR #122
```

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
