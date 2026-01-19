# Breaking Changes Examples

Examples of how to indicate breaking changes in conventional commits.

## Using "!" in Title

The simplest way to indicate a breaking change:

```
feat(api)!: migrate to oauth 2.0

- Remove basic authentication support
- Add OAuth 2.0 client credentials flow
- Update authentication middleware to validate OAuth tokens
- Add token refresh endpoint `/auth/refresh`
- Update all existing endpoints to require OAuth tokens

Improves security and enables single sign-on capabilities.
All clients must migrate to OAuth 2.0 as basic auth is no longer
supported.
```

## Using BREAKING CHANGE Footer

When you need more detailed explanation:

```
feat(api): migrate to oauth 2.0

- Remove basic authentication support from all endpoints
- Add OAuth 2.0 client credentials flow
- Update authentication middleware to validate OAuth tokens
- Add token refresh endpoint `/auth/refresh`
- Update API documentation with OAuth migration guide

Improves security posture and enables single sign-on capabilities
for enterprise customers.

BREAKING CHANGE: Authentication API now requires OAuth 2.0 tokens.
Basic auth is no longer supported. All clients must migrate to
OAuth 2.0 flow. See migration guide at /docs/oauth-migration.

Closes #120
```

## Using Both "!" and Footer

You can use both for maximum clarity:

```
feat(api)!: migrate to oauth 2.0

- Remove basic authentication support from all endpoints
- Add OAuth 2.0 client credentials flow
- Update authentication middleware to validate OAuth tokens
- Add token refresh endpoint `/auth/refresh`
- Create OAuth client management interface

Improves security and enables enterprise SSO integration.

BREAKING CHANGE: Authentication API now requires OAuth 2.0 tokens.
Basic auth is no longer supported. Migration guide available at
/docs/oauth-migration. Clients have 30 days to migrate before
basic auth endpoints are removed.

Closes #120
Refs: #115, #122
```

## Notes

- "!" in title is sufficient for breaking changes
- `BREAKING CHANGE:` footer provides space for detailed explanation
- Both can be used together for maximum clarity
- Breaking changes correlate with MAJOR version in SemVer
