# Git commit conventions

## Atomic commits

**Use atomic commits for logical units of work**: each commit should represent a complete, cohesive change.

## Conventional Commits format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Title rules

- ALL LOWERCASE (no capitalization in description)
- <50 characters
- Imperative mood (e.g., "add" not "added")
- No period at end
- Add "!" before ":" for breaking changes (e.g., `feat!:`, `feat(api)!:`)

**Common types**: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `chore`, `build`, `ci`, `style`

## Body rules (mandatory)

- **Body is required** - all commits must include bullet points
- Blank line after title
- ≤72 chars/line
- **Bullet points**: use `- ` prefix, start with imperative verb (Add, Remove, Update, Fix)
- **Optional paragraphs**: context before bullets, explanation after bullets

## Footer (mandatory)

Blank line after body, then add these footers:

**Required:**
- **Co-Authored-By**: Always add this to attribute AI assistance. Use the appropriate format:
  - `Co-Authored-By: <Model Name> <noreply@anthropic.com>`

**Optional:**
- Issue references: `Closes #123`, `Fixes #456`
- Breaking changes: `BREAKING CHANGE: <description>`

## Examples

### Feature
```
feat(auth): add oauth login flow

- Add Google OAuth 2.0 integration
- Implement callback endpoint handler
- Update session management

Co-Authored-By: <Model Name> <noreply@anthropic.com>
```

### Bug fix
```
fix(api): handle null payload in session refresh

- Fix null payload handling in session refresh
- Return 400 response instead of 500
- Add regression test for null input

Co-Authored-By: <Model Name> <noreply@anthropic.com>

Fixes #105
```

### Breaking change
```
feat(auth)!: migrate to oauth 2.0

- Replace basic auth with OAuth 2.0 flow
- Update authentication middleware
- Add token refresh endpoint

BREAKING CHANGE: Authentication API now requires OAuth 2.0 tokens. Basic auth is no longer supported.

Co-Authored-By: <Model Name> <noreply@anthropic.com>

Closes #120
```
