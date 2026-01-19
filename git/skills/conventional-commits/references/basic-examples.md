# Basic Commit Examples

Common conventional commit message examples for typical scenarios.

## Single Feature Commit

```
feat(auth): add google oauth login flow

- Introduce Google OAuth 2.0 for user sign-in
- Add backend callback endpoint `/auth/google/callback`
- Update login UI with Google button and loading state

Add a new authentication option improving cross-platform
sign-in.

Closes #42
```

## Bug Fix

```
fix(api): handle null response in user endpoint

- Add null check before accessing user.data
- Return 404 instead of 500 for missing users
- Add error logging

Prevents server crashes when user data is missing.

Fixes #89
```

## Bug Fix with Tests

```
fix(payments): prevent duplicate charge processing

- Add transaction ID validation
- Implement idempotency key checking
- Add mutex lock for payment processing
- Create regression tests for duplicate scenarios

Prevents users from being charged multiple times for
the same transaction when they click submit repeatedly.

Fixes #234
```

## Documentation Update

```
docs: correct spelling of CHANGELOG

Fix typo in main documentation file.
```

```
docs(api): update authentication guide

- Add OAuth 2.0 flow diagrams
- Update code examples
- Fix outdated endpoint URLs
```

## Refactoring

```
refactor(auth): extract token validation logic

- Move token validation to separate service
- Improve testability of authentication flow
- Reduce coupling between auth and user modules

No functional changes, only code organization improvements.
```

## Performance Improvement

```
perf(db): optimize user query with index

- Add composite index on (email, status) columns
- Reduce query time from 500ms to 50ms
- Update query planner hints

Improves user lookup performance significantly.
```

## Commit with Scope

```
feat(lang): add Polish language

Add Polish translation files and update language selector.
```

## Multiple Logical Changes

When making several unrelated changes, create separate commits:

**Commit 1:**
```
fix(api): handle null response in user endpoint

- Add null check before accessing user.data
- Return 404 instead of 500 for missing users

Fixes #89
```

**Commit 2:**
```
docs: update API endpoint documentation

- Add missing authentication requirements
- Fix incorrect response examples
```

**Commit 3:**
```
refactor(ui): extract form validation logic

- Move validation functions to utils
- Remove duplicate validation code

Improves code maintainability and test coverage.
```
