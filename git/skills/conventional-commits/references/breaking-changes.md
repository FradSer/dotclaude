# Breaking Changes Examples

## Using "!" in Title

```
feat(api)!: migrate to oauth 2.0

- Remove basic authentication support
- Add OAuth 2.0 client credentials flow
- Update authentication middleware to validate OAuth tokens
- Add token refresh endpoint `/auth/refresh`

Improves security and enables single sign-on capabilities.
All clients must migrate to OAuth 2.0 as basic auth is no longer
supported.
```

## Using BREAKING CHANGE Footer

```
feat(api): migrate to oauth 2.0

- Remove basic authentication support from all endpoints
- Add OAuth 2.0 client credentials flow
- Update authentication middleware to validate OAuth tokens

Improves security posture and enables single sign-on capabilities.

BREAKING CHANGE: Authentication API now requires OAuth 2.0 tokens.
Basic auth is no longer supported. All clients must migrate to
OAuth 2.0 flow. See migration guide at /docs/oauth-migration.

Closes #120
```

## Using Both

```
feat(api)!: migrate to oauth 2.0

- Remove basic authentication support
- Add OAuth 2.0 client credentials flow
- Update authentication middleware

Improves security and enables enterprise SSO integration.

BREAKING CHANGE: Authentication API now requires OAuth 2.0 tokens.
Basic auth is no longer supported. Migration guide at /docs/oauth-migration.

Closes #120
Refs: #115, #122
```
