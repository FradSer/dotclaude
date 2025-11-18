---
description: Create atomic conventional git commit
tags:
  - git
---

# Commit

**Summary:** Create atomic conventional git commit

## Requirements

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

1. Analyze the pending changes to identify coherent logical units of work.
2. For each logical unit, stage only the relevant files and craft a conventional commit message.
3. Repeat the staging and committing process until every change is accounted for.
