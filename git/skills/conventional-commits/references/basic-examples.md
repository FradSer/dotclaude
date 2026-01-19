# Basic Commit Examples

Common conventional commit message examples for typical scenarios.

## Single Feature Commit

```
feat(auth): add google oauth login flow

- Add Google OAuth 2.0 configuration and client setup
- Implement backend callback endpoint `/auth/google/callback`
- Create OAuth button component in login UI
- Add loading state handling during authentication
- Update user session management to support OAuth tokens

Provides a new authentication option that improves cross-platform
sign-in experience and reduces password-related support requests.

Closes #42
```

## Bug Fix

```
fix(api): handle null response in user endpoint

- Add null check before accessing user.data property
- Return 404 status code instead of 500 for missing users
- Add error logging for null user data cases
- Update response type definitions to include null

Prevents server crashes when user data is missing from the database.

Fixes #89
```

## Bug Fix with Tests

```
fix(payments): prevent duplicate charge processing

- Add transaction ID validation before processing
- Implement idempotency key checking using Redis cache
- Add mutex lock for concurrent payment requests
- Update payment service to reject duplicate transactions
- Create regression tests covering rapid double-click scenarios
- Add test cases for concurrent API requests

Prevents users from being charged multiple times for the same
transaction when they click submit repeatedly or make concurrent
requests.

Fixes #234
```

## Documentation Update

```
docs: correct spelling in changelog

Fix typo in main documentation file.
```

```
docs(api): update authentication guide

- Add OAuth 2.0 flow diagrams with sequence illustrations
- Update code examples to use current SDK version
- Fix outdated endpoint URLs to match production
- Add troubleshooting section for common auth errors

Improves clarity for developers integrating with the authentication
API and reduces support requests.
```

## Refactoring

```
refactor(auth): extract token validation logic

- Create new TokenValidationService class
- Move JWT validation logic from AuthController to TokenValidationService
- Extract token expiry checking into separate method
- Update AuthController to use new service
- Add unit tests for TokenValidationService

Improves testability and reduces coupling between auth and user
modules. No functional changes to authentication behavior.
```

## Performance Improvement

```
perf(db): optimize user query with index

- Add composite index on (email, status) columns in users table
- Update user lookup query to utilize new index
- Add query planner hints for email-based searches
- Remove redundant index on email column only

Reduces user lookup query time from 500ms to 50ms, significantly
improving login and profile page load times.
```

## Commit with Scope

```
feat(lang): add polish language support

Add Polish translation files and update language selector.
```

## Multiple Logical Changes

When making several unrelated changes, create separate commits:

**Commit 1:**
```
fix(api): handle null response in user endpoint

- Add null check before accessing user.data property
- Return 404 status code instead of 500 for missing users
- Update error response format for consistency

Prevents server crashes when user data is missing.

Fixes #89
```

**Commit 2:**
```
docs: update api endpoint documentation

- Add missing authentication requirements to all endpoints
- Fix incorrect response format examples
- Update status code documentation
- Add rate limiting information

Reduces confusion for API consumers and support requests.
```

**Commit 3:**
```
refactor(ui): extract form validation logic

- Create new utils/validation.ts module
- Move email, password, and phone validation functions to utils
- Remove duplicate validation code from three form components
- Update components to import shared validators

Improves code maintainability and enables easier testing of
validation logic.
```
