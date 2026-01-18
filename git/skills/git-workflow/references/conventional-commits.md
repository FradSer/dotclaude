# Conventional Commits Specification

Complete reference for the Conventional Commits specification v1.0.0 with practical examples and patterns.

## Format Specification

```
<type>(<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

### Required: Type and Subject

Every commit message MUST have a type and subject. Scope, body, and footer are optional but recommended for non-trivial changes.

## Commit Types

### feat: New Features

Use `feat:` for new functionality or capabilities added to the system.

**When to use:**
- Adding new user-facing features
- Introducing new API endpoints
- Creating new components or modules
- Implementing new business logic
- Adding new configuration options

**Examples:**

```
feat(auth): add two-factor authentication

- Implement TOTP-based 2FA
- Add QR code generation for authenticator apps
- Create verification endpoint /auth/2fa/verify

Enhances account security by requiring second factor.

Closes #234
```

```
feat(api): add pagination to user list endpoint

Add limit and offset query parameters to /api/users
endpoint. Returns total count in response headers.

Closes #156
```

```
feat: add dark mode support

- Create theme toggle component
- Add CSS variables for light/dark themes
- Persist theme preference in localStorage
- Update all components to respect theme

Closes #89
```

### fix: Bug Fixes

Use `fix:` for correcting incorrect behavior or resolving bugs.

**When to use:**
- Fixing crashes or errors
- Resolving incorrect calculations or logic
- Correcting UI rendering issues
- Addressing security vulnerabilities
- Fixing memory leaks or performance problems

**Examples:**

```
fix(api): handle null payload in session refresh

- Validate payload exists before accessing properties
- Return 400 Bad Request instead of 500 error
- Add test case for null payload scenario

Prevents server crash when expired tokens are refreshed.

Fixes #412
```

```
fix(ui): resolve button alignment in mobile view

Buttons were misaligned on screens < 768px width due to
missing flex container. Add flex display and center alignment.

Fixes #378
```

```
fix: prevent memory leak in event listeners

Remove event listeners in cleanup function. Previously
listeners were added but never removed, causing memory to
grow unbounded.

Fixes #523
```

### chore: Maintenance Tasks

Use `chore:` for maintenance tasks that don't modify source or test files.

**When to use:**
- Updating dependencies
- Configuring build tools
- Updating .gitignore
- Cleaning up unused files
- Updating documentation build scripts

**Examples:**

```
chore: update dependencies to latest versions

- Update React from 17.0.2 to 18.2.0
- Update webpack from 5.70.0 to 5.75.0
- Update testing-library packages

All tests passing. No breaking changes.
```

```
chore(deps): bump lodash from 4.17.19 to 4.17.21

Security update addressing CVE-2021-23337.
```

```
chore: remove deprecated feature flags

Clean up feature flags that are now permanently enabled
in production.
```

### docs: Documentation

Use `docs:` for documentation-only changes.

**When to use:**
- Updating README files
- Adding code comments
- Improving API documentation
- Creating usage examples
- Fixing typos in documentation

**Examples:**

```
docs: add oauth setup guide to README

Document OAuth 2.0 configuration steps including:
- Google Cloud Console setup
- Environment variable configuration
- Callback URL registration

Closes #445
```

```
docs(api): add examples to authentication endpoints

Add curl examples for login, logout, and token refresh
endpoints.
```

```
docs: fix typos in installation guide
```

### refactor: Code Restructuring

Use `refactor:` for code changes that neither fix bugs nor add features.

**When to use:**
- Extracting functions or classes
- Renaming variables or functions
- Reorganizing file structure
- Improving code organization
- Simplifying complex logic

**Examples:**

```
refactor(db): extract query builder to separate module

Move query building logic from controllers to dedicated
QueryBuilder class. No behavior changes.
```

```
refactor: simplify authentication middleware

Replace nested if/else with early returns. Improves
readability without changing functionality.
```

```
refactor(api): rename getUserData to fetchUserProfile

Rename for clarity. Update all references throughout
codebase.
```

### test: Testing

Use `test:` for adding or updating tests.

**When to use:**
- Adding new test cases
- Fixing failing tests
- Improving test coverage
- Refactoring test code
- Adding integration or E2E tests

**Examples:**

```
test(auth): add tests for password reset flow

Add integration tests covering:
- Request reset email
- Token validation
- Password update
- Expired token handling

Increases auth coverage to 95%.
```

```
test: fix flaky date formatting tests

Tests were failing intermittently due to timezone
assumptions. Mock Date.now() for deterministic results.
```

```
test(api): add missing error case tests

Add test cases for 400, 404, and 500 responses.
```

### perf: Performance Improvements

Use `perf:` for changes that improve performance.

**When to use:**
- Optimizing algorithms
- Reducing memory usage
- Caching improvements
- Database query optimization
- Bundle size reduction

**Examples:**

```
perf(api): add Redis caching for user profiles

Cache frequently-accessed user profiles in Redis with
5-minute TTL. Reduces database queries by ~80%.

Closes #567
```

```
perf: lazy load images below the fold

Implement intersection observer for image loading.
Reduces initial page load time by 40%.
```

```
perf(db): add index on user_id column

Query time reduced from 2.3s to 45ms for user lookups.
```

### style: Code Formatting

Use `style:` for formatting changes that don't affect code meaning.

**When to use:**
- Fixing indentation
- Removing trailing whitespace
- Adding missing semicolons
- Running code formatters (Prettier, Black)
- Organizing imports

**Examples:**

```
style: format code with Prettier

Apply Prettier formatting to all JavaScript files.
No functional changes.
```

```
style: fix indentation in config files

Standardize indentation to 2 spaces.
```

```
style(api): organize imports alphabetically
```

### ci: CI/CD Changes

Use `ci:` for continuous integration and deployment changes.

**When to use:**
- Updating CI configuration
- Modifying GitHub Actions workflows
- Changing deployment scripts
- Updating Docker configurations
- Modifying pipeline stages

**Examples:**

```
ci: add automated security scanning

Add Snyk security scanning to GitHub Actions workflow.
Runs on all pull requests and main branch commits.
```

```
ci: cache npm dependencies in workflow

Reduces CI build time from 8min to 3min.
```

```
ci(docker): optimize image build caching

Use multi-stage builds and layer caching to reduce
image build time.
```

### build: Build System Changes

Use `build:` for changes to build system or external dependencies.

**When to use:**
- Updating webpack configuration
- Modifying Rollup or Vite config
- Changing build scripts
- Updating package.json scripts
- Modifying bundler settings

**Examples:**

```
build: enable tree shaking in production

Configure webpack to eliminate dead code. Reduces
bundle size by 23%.
```

```
build: add source maps for production builds

Enable source maps in production for better error
tracking.
```

```
build(webpack): split vendor bundle

Separate vendor code into separate bundle for better
caching.
```

### revert: Reverting Commits

Use `revert:` when reverting a previous commit.

**Format:**
```
revert: <reverted commit subject>

This reverts commit <hash>.

<reason for revert>
```

**Example:**

```
revert: feat(auth): add two-factor authentication

This reverts commit a1b2c3d4e5f6.

Reverting due to critical bug in production causing
login failures. Will reimplement after fixing issue.

Refs #678
```

## Scope Conventions

Scope identifies the affected component or area. Use consistent scope names across the project.

### Common Scopes

**By Feature/Module:**
- `auth` - Authentication and authorization
- `api` - API endpoints and services
- `ui` - User interface components
- `db` - Database layer
- `cli` - Command-line interface
- `docs` - Documentation

**By Component:**
- `header` - Header component
- `sidebar` - Sidebar component
- `dashboard` - Dashboard page
- `profile` - User profile feature

**By Package (monorepo):**
- `@company/ui` - UI package
- `@company/api` - API package
- `@company/shared` - Shared utilities

### Scope Best Practices

1. **Be consistent:** Use same scope names throughout project
2. **Be specific:** Prefer `auth` over `authentication`
3. **Check history:** Use `git log --oneline` to see existing scopes
4. **Document scopes:** List valid scopes in CONTRIBUTING.md
5. **One or two words:** Keep scopes concise
6. **Use existing scopes:** Don't create new scopes unnecessarily

**Examples:**

```
feat(auth): add oauth support
fix(api): handle timeout errors
refactor(ui): simplify header component
test(db): add migration tests
docs(cli): update command reference
```

## Subject Line Rules

### Format Requirements

**MUST:**
- Be entirely lowercase
- Be under 50 characters (hard limit: 72)
- Use imperative mood ("add" not "added" or "adds")
- Not end with a period

**SHOULD:**
- Start with a verb
- Be specific and descriptive
- Focus on what changed, not how

### Imperative Mood

Write as if giving a command:

✅ **Correct:**
- `add oauth support`
- `fix memory leak`
- `update dependencies`
- `remove deprecated methods`

❌ **Incorrect:**
- `added oauth support` (past tense)
- `adds oauth support` (third person)
- `adding oauth support` (gerund)
- `oauth support` (no verb)

### Length Guidelines

**Optimal: Under 50 characters**
```
✅ feat(auth): add oauth 2.0 support (35 chars)
✅ fix(api): handle null in user response (40 chars)
✅ refactor: extract validation logic (36 chars)
```

**Acceptable: 50-72 characters**
```
⚠️ feat(payments): integrate stripe checkout for subscriptions (63 chars)
```

**Too long: Over 72 characters**
```
❌ feat(payments): integrate stripe checkout for subscription payments with webhook support (89 chars)
```

**Fix:** Move details to body
```
✅ feat(payments): integrate stripe checkout

Add Stripe checkout for subscription payments including
webhook support for payment events.
```

### Subject Examples

**Good subjects:**
```
feat(auth): add two-factor authentication
fix(api): prevent race condition in cache
refactor(db): simplify connection pooling
perf(ui): lazy load dashboard widgets
docs: add deployment instructions
test(auth): cover edge cases in login
chore: update node to version 18
```

**Bad subjects:**
```
❌ feat(auth): Added two-factor authentication (past tense)
❌ fix(api): Fixed a bug (too vague)
❌ Update dependencies. (capitalized, has period)
❌ refactor(db): We extracted the connection pool logic and simplified it (too long, wrong perspective)
❌ new feature (no type prefix, vague)
```

## Body Format

### Structure

- **Blank line** after subject (required)
- **Maximum 72 characters per line** (wrap longer lines)
- **Start with uppercase letter**
- **Use standard capitalization and punctuation**
- **Focus on "what" and "why", not "how"**

### What to Include

**DO explain:**
- What changed
- Why the change was necessary
- What problem it solves
- Side effects or impacts
- Alternatives considered (if relevant)

**DON'T explain:**
- How the code works (that's what code comments are for)
- Implementation details (visible in diff)

### Formatting

**Use bullet points for multiple changes:**
```
feat(auth): add oauth 2.0 support

- Implement authorization code flow
- Add callback endpoint /auth/oauth/callback
- Store tokens in encrypted session storage
- Add token refresh mechanism

Enables users to sign in with Google, GitHub, and Microsoft
accounts without creating separate credentials.
```

**Or paragraphs for narrative:**
```
fix(api): resolve database connection leak

Database connections were not being properly released back
to the pool after failed queries. This caused the pool to
exhaust under high load, resulting in timeout errors.

Add finally block to ensure connections always return to
pool, even when errors occur.
```

### Body Examples

**Feature with context:**
```
feat(search): add full-text search

Implement PostgreSQL full-text search for product names
and descriptions. Creates tsvector index for fast queries.

Improves search performance from 2.5s to 80ms average.
Enables users to find products more effectively.

Closes #234
```

**Bug fix with explanation:**
```
fix(payments): prevent duplicate charge processing

Race condition existed when user clicked "Pay" multiple
times rapidly. Added idempotency key using transaction ID
to ensure charges are processed exactly once.

Fixes #567
```

**Refactoring with rationale:**
```
refactor(api): extract middleware to separate files

Middleware functions were defined inline in server.js,
making it difficult to test and reuse. Extract to
middleware/ directory with one file per middleware.

Improves testability and reduces server.js from 800 to
200 lines.
```

## Footer Format

### Issue References

**Closing issues:**
```
Closes #123
Fixes #234
Resolves #345
```

**Multiple issues:**
```
Closes #123, #234, #345
```

or
```
Closes #123
Closes #234
Closes #345
```

**Referencing without closing:**
```
Refs #123
Related to #234
See also #345
```

**Pull requests:**
```
Linked to PR #456
```

**Combined:**
```
Closes #123. Linked to #234 and PR #456
```

### Breaking Changes

**Format:**
```
BREAKING CHANGE: <description of breaking change>
```

**Always include:**
- What broke
- Why it broke
- Migration path for users

**Examples:**

```
feat(api): migrate to oauth 2.0

- Replace basic auth with OAuth 2.0
- Remove /auth/login endpoint
- Add /auth/oauth/authorize endpoint

BREAKING CHANGE: Authentication now requires OAuth 2.0
tokens. The /auth/login endpoint accepting username and
password has been removed. Clients must migrate to OAuth
2.0 authorization code flow. See migration guide:
https://docs.example.com/auth-migration

Closes #890
```

```
refactor(api)!: rename user endpoints

- Rename /users/profile to /users/me
- Rename /users/:id/data to /users/:id/profile

BREAKING CHANGE: User API endpoints have been renamed for
consistency. Update client code to use new endpoints:
  - /users/profile → /users/me
  - /users/:id/data → /users/:id/profile

Closes #456
```

### Breaking Change Indicators

**In subject line (optional but recommended):**
```
feat(api)!: migrate to oauth 2.0
```

The `!` after scope indicates breaking change.

**In footer (required):**
```
BREAKING CHANGE: description
```

Must include `BREAKING CHANGE:` in footer for automated changelog generation.

## Complete Examples

### Simple Feature

```
feat(ui): add loading spinner to button

Display spinner inside button during async operations.
Prevents duplicate submissions.
```

### Complex Feature

```
feat(payments): integrate stripe checkout

- Add Stripe checkout component
- Implement webhook handlers for payment events
- Store payment methods in user profile
- Add subscription management UI
- Send email confirmations for successful payments

Enables users to purchase premium subscriptions through
Stripe. Webhooks ensure payment state stays synchronized
even if user closes browser during checkout.

Closes #123. Linked to #118, #119, and PR #125
```

### Bug Fix with Context

```
fix(auth): resolve token expiration race condition

Token refresh was called simultaneously by multiple
requests, resulting in invalid tokens and logout. Add
mutex lock to ensure refresh happens only once, with
other requests waiting for completion.

Fixes #456
```

### Breaking Change

```
feat(api)!: redesign error response format

- Standardize error responses across all endpoints
- Include error codes for programmatic handling
- Add field-level validation errors
- Remove legacy error format

BREAKING CHANGE: Error responses now use new format:
  {
    "error": {
      "code": "VALIDATION_ERROR",
      "message": "Invalid input",
      "fields": {
        "email": "Invalid email format"
      }
    }
  }

Old format returned plain strings. Update error handling
code to parse new format. See migration guide:
https://docs.example.com/api-errors-migration

Closes #789
```

### Revert

```
revert: feat(payments): integrate stripe checkout

This reverts commit a1b2c3d4e5f6.

Reverting due to webhook processing bug causing duplicate
charges in production. Will fix and re-deploy after
thorough testing.

Refs #890
```

### Chore with Security Update

```
chore(deps): update dependencies for security patches

- Update lodash 4.17.19 → 4.17.21 (CVE-2021-23337)
- Update minimist 1.2.5 → 1.2.6 (CVE-2021-44906)
- Update express 4.17.1 → 4.18.2 (CVE-2022-24999)

All security vulnerabilities addressed. Tests passing.
```

## Validation Checklist

Before committing, verify:

- [ ] Type is valid (feat, fix, chore, docs, refactor, test, perf, style, ci, build)
- [ ] Scope matches existing conventions (check `git log`)
- [ ] Subject is entirely lowercase
- [ ] Subject under 50 characters (72 hard limit)
- [ ] Subject uses imperative mood
- [ ] Subject doesn't end with period
- [ ] Blank line between subject and body
- [ ] Body lines wrapped at 72 characters
- [ ] Body explains what and why, not how
- [ ] Footer references issues if applicable
- [ ] Breaking changes documented with BREAKING CHANGE: prefix
- [ ] Commit is atomic (single logical change)

## Tools and Automation

### Commitlint

Validate commits automatically:

```json
{
  "extends": ["@commitlint/config-conventional"]
}
```

### Commitizen

Interactive commit message builder:

```bash
npm install -g commitizen
cz
```

### Changelog Generation

Generate changelogs from commits:

```bash
npx conventional-changelog-cli -p angular -i CHANGELOG.md -s
```

### Pre-commit Hooks

Validate commit messages with Husky:

```json
{
  "husky": {
    "hooks": {
      "commit-msg": "commitlint -E HUSKY_GIT_PARAMS"
    }
  }
}
```

## References

- Conventional Commits Specification: https://www.conventionalcommits.org/
- Angular Commit Guidelines: https://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit
- Commitlint: https://commitlint.js.org/
- Commitizen: http://commitizen.github.io/cz-cli/
