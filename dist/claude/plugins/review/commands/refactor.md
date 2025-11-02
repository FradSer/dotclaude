---
allowed-tools: Bash(git:*), Read, Edit, MultiEdit, Glob, Grep, Task
description: Systematic code refactoring to improve quality while preserving functionality
argument-hint: [files-or-directories]
---

## Context

- Current git status: !`git status`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -5`
- Complexity indicators: Identify functions >20 lines, nested conditionals, and duplicated logic
- Project snapshot: !`find . -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.java" -o -name "*.go" | head -20`

## Requirements

- Preserve existing behaviour—tests should only be run, not altered.
- Apply SOLID and Clean Code principles to reduce complexity and duplication.
- Strengthen typing, error handling, and naming conventions.
- Stage and commit refactors atomically, pushing updates after validation.
- **Use atomic commits for logical units of work**: Each commit should represent one complete, cohesive change.
- Title: entirely lowercase, <50 chars, imperative mood (e.g., "add", "fix", "update"), conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
- Body: blank line after title, ≤72 chars per line, must start with uppercase letter, standard capitalization and punctuation. Describe what changed and why, not how.
- Footer (optional): Must start with uppercase letter, standard capitalization. Reference issues/PRs (Closes #123, Fixes #456, Linked to PR #789). Use BREAKING CHANGE: prefix for breaking changes.

### Examples

```
feat(auth): add google oauth login flow

- Introduce Google OAuth 2.0 for user sign-in
- Add backend callback endpoint `/auth/google/callback`
- Update login UI with Google button and loading state

Add a new authentication option improving cross-platform
sign-in.

Closes #42. Linked to #38 and PR #45
```

```
fix(api): handle null payload in session refresh

- Validate payload before accessing `user.id`
- Return proper 400 response instead of 500
- Add regression test for null input

Prevents session refresh crash when token expires.

Fixes #105
```

```
feat(auth): migrate to oauth 2.0

- Replace basic auth with OAuth 2.0 flow
- Update authentication middleware
- Add token refresh endpoint

BREAKING CHANGE: Authentication API now requires OAuth 2.0 tokens. Basic auth is no longer supported.

Closes #120. Linked to #115 and PR #122
```

## Your Task

**IMPORTANT: You MUST use the Task tool to complete ALL tasks.**

1. Analyse the codebase (or `$ARGUMENTS` scope) to pinpoint high-impact refactor targets using **@code-simplifier** — optimization and complexity reduction — for guidance.
2. Execute refactoring steps iteratively—eliminate duplication, simplify control flow, modernise syntax, and reinforce typing and error handling.
3. Validate with existing tests, run lint/build checks, and produce atomic commits before summarising improvements and remaining risks.

### Refactoring Workflow

- **Assessment**: Inspect branch status, catalogue complexity hot spots, and search for existing patterns to align with project conventions.
- **Planning**: Prioritise improvements by readability, maintainability, and performance impact; map steps into Task tool actions.
- **Execution**: Apply DRY, introduce guard clauses, extract helpers, adopt idiomatic constructs, and ensure descriptive names.
- **Validation & Delivery**: Re-run tests, lint, and builds; ensure a clean working directory; stage and commit each logical unit; push results and report the refactor summary.
