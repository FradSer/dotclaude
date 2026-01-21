# Basic Commit Examples

Common conventional commit message examples.

## Feature

```
feat(auth): add google oauth login flow

- Add Google OAuth 2.0 configuration and client setup
- Implement backend callback endpoint `/auth/google/callback`
- Create OAuth button component in login UI
- Update user session management to support OAuth tokens

Provides a new authentication option that improves cross-platform
sign-in experience.

Closes #42
```

## Bug Fix

```
fix(api): handle null response in user endpoint

- Add null check before accessing user.data property
- Return 404 status code instead of 500 for missing users
- Add error logging for null user data cases

Prevents server crashes when user data is missing from the database.

Fixes #89
```

## Documentation

```
docs(api): update authentication guide

- Add OAuth 2.0 flow diagrams
- Update code examples to use current SDK version
- Fix outdated endpoint URLs

Improves clarity for developers integrating with the authentication API.
```

## Refactor

```
refactor(auth): extract token validation logic

- Create new TokenValidationService class
- Move JWT validation logic from AuthController to service
- Update AuthController to use new service

Improves testability and reduces coupling. No functional changes.
```

## Performance

```
perf(db): optimize user query with index

- Add composite index on (email, status) columns
- Update user lookup query to utilize new index

Reduces query time from 500ms to 50ms.
```

## Simple Commit

```
feat(lang): add polish language support

- Add Polish translation files (pl.json)
- Update language selector dropdown to include Polish

Expands accessibility for Polish-speaking users.
```
