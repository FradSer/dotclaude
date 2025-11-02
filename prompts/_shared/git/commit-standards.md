- **Use atomic commits for logical units of work**: Each commit should represent one complete, cohesive change.
- Title: entirely lowercase, <50 chars, imperative mood (e.g., "add", "fix", "update"), conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
- Body: blank line after title, ≤72 chars per line, standard capitalization (may start with uppercase) and punctuation. Describe what changed and why, not how.
- Footer (optional): Standard capitalization (may start with uppercase). Reference issues/PRs (Closes #123, Fixes #456, Linked to PR #789). Use BREAKING CHANGE: prefix for breaking changes.

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
