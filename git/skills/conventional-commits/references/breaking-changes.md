# Breaking Changes Examples

Examples of how to indicate breaking changes in conventional commits.

## Using `!` in Title

The simplest way to indicate a breaking change:

```
feat(api)!: migrate to oauth 2.0

Replace basic auth with OAuth 2.0 flow.
Update authentication middleware.
Add token refresh endpoint.
```

## Using BREAKING CHANGE Footer

When you need more detailed explanation:

```
feat(api): migrate to oauth 2.0

Replace basic auth with OAuth 2.0 flow.
Update authentication middleware.
Add token refresh endpoint.

BREAKING CHANGE: Authentication API now requires OAuth 2.0 tokens.
Basic auth is no longer supported. All clients must migrate to
OAuth 2.0 flow.

Closes #120
```

## Using Both `!` and Footer

You can use both for maximum clarity:

```
feat(api)!: migrate to oauth 2.0

Replace basic auth with OAuth 2.0 flow.

BREAKING CHANGE: Authentication API now requires OAuth 2.0 tokens.
Basic auth is no longer supported.

Closes #120. Linked to #115 and PR #122
```

## Notes

- `!` in title is sufficient for breaking changes
- `BREAKING CHANGE:` footer provides space for detailed explanation
- Both can be used together for maximum clarity
- Breaking changes correlate with MAJOR version in SemVer
