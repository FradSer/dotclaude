# Atomic Commits

Comprehensive guide to creating atomic commits that represent single, complete, logical units of work.

## What Are Atomic Commits?

Atomic commits are self-contained changes that:

1. **Represent one logical unit of work** - Single purpose or goal
2. **Are independently revertible** - Can be undone without breaking functionality
3. **Build and pass tests** - System works correctly after applying commit
4. **Are complete** - Include all necessary changes for that unit

**Atomic** means indivisible - the commit cannot be meaningfully split into smaller commits without losing coherence.

## Why Atomic Commits Matter

### Code Review Benefits

**Easier to review:**
- Reviewers focus on one change at a time
- Clear intent and scope
- Faster review cycles

**Example - Non-atomic (hard to review):**
```
feat: add user dashboard and fix auth bug and update deps

Changes:
- 43 files changed
- New dashboard component
- Auth middleware fix
- Package updates
- Refactored database queries
```

**Reviewer thinks:** "Where do I even start? What's related to what?"

**Example - Atomic (easy to review):**

Commit 1:
```
fix(auth): handle expired token edge case

Changes: 2 files
- auth-middleware.js
- auth.test.js
```

Commit 2:
```
feat(dashboard): add user statistics dashboard

Changes: 8 files
- All dashboard-related components
- Dashboard tests
```

Commit 3:
```
chore: update react and testing libraries

Changes: 2 files
- package.json
- package-lock.json
```

Each commit is focused and reviewable in isolation.

### Debugging Benefits

**Easier to bisect:**
- `git bisect` finds bug-introducing commit faster
- Smaller commit = easier to understand what broke
- Clear which change caused the issue

**Easier to revert:**
- Revert one specific change without affecting others
- No untangling of mixed concerns
- Less risk when reverting

**Example scenario:**

New feature introduced a bug. With atomic commits:

```bash
git log --oneline
a1b2c3d feat(dashboard): add statistics charts
e4f5g6h feat(dashboard): add data export button
i7j8k9l fix(auth): handle expired tokens
m0n1o2p feat(api): add pagination

# Bug is in charts. Revert just that commit:
git revert a1b2c3d

# Export button still works!
```

Without atomic commits:
```bash
git log --online
a1b2c3d feat: add dashboard with charts and export and fix auth

# To revert charts, must revert everything including auth fix
# Or manually cherry-pick changes (error-prone)
```

### Collaboration Benefits

**Better git history:**
- Tells a clear story
- Easy to understand project evolution
- Meaningful `git log` output

**Better merges:**
- Smaller commits = fewer conflicts
- Conflicts are easier to resolve
- Can merge partial work

**Better cherry-picking:**
- Pick specific features for backporting
- Port bug fixes to release branches
- Include/exclude specific changes cleanly

## Identifying Atomic Units

### Questions to Ask

**Is this commit atomic?**

✅ **YES if:**
- Can be reverted independently
- Has a single, clear purpose
- All changes serve the same goal
- Passes tests when applied alone
- Commit message describes it in one sentence

❌ **NO if:**
- Mixes unrelated changes
- Has multiple "and" statements in message
- Could be split into smaller logical pieces
- Partial implementation of a feature
- Includes unrelated refactoring

### Common Atomic Units

**Feature implementation:**
- One user-facing capability
- Includes tests for that feature
- Includes documentation for that feature
- Complete and functional

**Bug fix:**
- Fixes one specific bug
- Includes test preventing regression
- Doesn't include unrelated fixes

**Refactoring:**
- One refactoring pattern applied
- No behavior changes
- All related changes included

**Configuration change:**
- One configuration purpose
- All necessary config updates
- Documentation of new settings

**Dependency update:**
- One update purpose (security, feature, etc.)
- Related dependency updates together
- Breaking changes handled

## Splitting Commits

### When to Split

Split commits when they contain multiple logical units:

**Multiple bug fixes:**
```
❌ Bad: "fix auth and api bugs"

✅ Good:
- "fix(auth): handle null user session"
- "fix(api): validate request payload"
```

**Feature + refactoring:**
```
❌ Bad: "add search feature and refactor database queries"

✅ Good:
- "refactor(db): extract query builder"
- "feat(search): add full-text search"
```

**Multiple features:**
```
❌ Bad: "add user profile and settings pages"

✅ Good:
- "feat(profile): add user profile page"
- "feat(settings): add settings page"
```

### How to Split

**Strategy 1: Split by file**

When changes to different files are independent:

```bash
# Stage and commit files separately
git add user-profile.tsx
git commit -m "feat(profile): add user profile page"

git add settings.tsx
git commit -m "feat(settings): add settings page"
```

**Strategy 2: Split by hunk**

When changes in same file are independent:

```bash
# Interactive staging
git add -p user-service.ts

# For each hunk, choose:
# y = stage this hunk
# n = don't stage this hunk
# s = split hunk into smaller pieces

git commit -m "fix(user): handle null email"

# Stage remaining changes
git add user-service.ts
git commit -m "feat(user): add email validation"
```

**Strategy 3: Split after the fact**

When you already made a large commit:

```bash
# Undo last commit, keep changes staged
git reset --soft HEAD~1

# Or undo and unstage
git reset HEAD~1

# Now stage and commit atomically
git add file1.js
git commit -m "fix: first logical change"

git add file2.js file3.js
git commit -m "feat: second logical change"
```

### Splitting Examples

**Example 1: Feature with refactoring**

```
# Files changed:
- auth-service.ts (refactored)
- login.tsx (new feature)
- login.test.tsx (new tests)

# Split into:

Commit 1:
git add auth-service.ts
git commit -m "refactor(auth): extract token validation"

Commit 2:
git add login.tsx login.test.tsx
git commit -m "feat(auth): add login page"
```

**Example 2: Multiple fixes in one file**

```javascript
// user-service.ts has 3 fixes:
// 1. Handle null email
// 2. Validate password length
// 3. Fix user ID type

# Use interactive staging:
git add -p user-service.ts

# Stage null email fix hunks
# Commit 1
git commit -m "fix(user): handle null email field"

# Stage password validation hunks
# Commit 2
git commit -m "fix(user): validate password length"

# Stage type fix hunks
# Commit 3
git commit -m "fix(user): correct user ID type annotation"
```

## Combining Commits

### When to Combine

Combine changes when they're part of the same logical unit:

**Feature + its tests:**
```
✅ Good: One commit with feature and tests

❌ Bad:
- Commit 1: "feat: add login"
- Commit 2: "test: add login tests"
```

**Change + corresponding documentation:**
```
✅ Good: One commit with code and docs

❌ Bad:
- Commit 1: "feat: add API endpoint"
- Commit 2: "docs: document API endpoint"
```

**Tightly coupled changes:**
```
✅ Good: One commit for model and migration

❌ Bad:
- Commit 1: "feat: add user table migration"
- Commit 2: "feat: add user model"
```

### How to Combine

**Strategy 1: Amend previous commit**

Add to the last commit (only if not pushed):

```bash
git add missing-file.ts
git commit --amend --no-edit

# Or update message:
git commit --amend -m "new message"
```

**Strategy 2: Squash during rebase**

Combine multiple commits:

```bash
git rebase -i HEAD~3

# In editor, change:
pick a1b2c3d feat: add login form
pick e4f5g6h test: add login tests
pick i7j8k9l docs: document login

# To:
pick a1b2c3d feat: add login form
squash e4f5g6h test: add login tests
squash i7j8k9l docs: document login

# Save and exit. Commits are combined.
```

**Strategy 3: Soft reset and recommit**

Start over with clean commits:

```bash
# Reset 3 commits but keep changes
git reset --soft HEAD~3

# Now make one commit
git commit -m "feat(auth): add login form with tests and docs"
```

### Combining Examples

**Example 1: Feature developed incrementally**

```
# During development:
git commit -m "feat: add login form WIP"
git commit -m "feat: add validation WIP"
git commit -m "feat: add submit handler"
git commit -m "test: add login tests"

# Before pushing, combine:
git rebase -i HEAD~4

pick a1b2c3d feat: add login form WIP
squash e4f5g6h feat: add validation WIP
squash i7j8k9l feat: add submit handler
squash m0n1o2p test: add login tests

# Result:
feat(auth): add login form

- Create login component with email/password fields
- Add validation for required fields
- Implement submit handler calling auth API
- Add comprehensive test coverage
```

**Example 2: Fix and its test**

```
# Made fix
git add user-service.ts
git commit -m "fix(user): handle null email"

# Realized test is part of same logical unit
git add user-service.test.ts
git commit --amend --no-edit

# Now one commit includes fix and test
```

## Multi-Commit Workflows

### Feature Branch with Atomic Commits

```
# Feature: Add user profile page

Commit 1: "feat(profile): add profile data model"
- User profile types
- API service methods
- Tests

Commit 2: "feat(profile): add profile view component"
- Profile display component
- Mock data for tests
- Component tests

Commit 3: "feat(profile): add profile edit functionality"
- Edit form
- Update API integration
- Validation
- Tests

Commit 4: "feat(profile): add profile picture upload"
- Upload component
- Image processing
- S3 integration
- Tests

Each commit builds on previous and is independently testable.
```

### Refactoring Series

```
# Refactoring: Extract services from controller

Commit 1: "refactor(api): extract user service"
- Create UserService class
- Move user logic from controller
- Update tests

Commit 2: "refactor(api): extract auth service"
- Create AuthService class
- Move auth logic from controller
- Update tests

Commit 3: "refactor(api): extract payment service"
- Create PaymentService class
- Move payment logic from controller
- Update tests

Commit 4: "refactor(api): remove empty controller methods"
- Clean up now-empty methods
- Update routing

Each service extraction is independent and complete.
```

### Bug Fix Series

```
# Multiple related bugs in authentication

Commit 1: "fix(auth): handle expired token refresh"
- Add expiration check
- Add refresh logic
- Add test

Commit 2: "fix(auth): prevent concurrent token refreshes"
- Add mutex lock
- Queue simultaneous requests
- Add test

Commit 3: "fix(auth): clear tokens on logout"
- Remove tokens from storage
- Invalidate on server
- Add test

Related bugs, but each fix is independent and revertible.
```

## Testing Atomicity

### Manual Tests

**Can you explain it in one sentence?**
```
✅ "This commit adds user profile editing"
❌ "This commit adds profile editing and fixes auth bugs and updates dependencies"
```

**Can you revert it independently?**
```bash
git revert <commit-hash>

# Check:
- Does system still work?
- Are other features unaffected?
- Can it be reverted without conflicts?
```

**Does it pass tests?**
```bash
git checkout <commit-hash>
npm test

# All tests should pass at this commit
```

**Is the commit message clear?**
```
✅ Clear: "fix(auth): handle null user session"
❌ Unclear: "fix: various fixes"
```

### Automated Tests

**Pre-commit hook:**
```bash
#!/bin/bash
# .git/hooks/pre-commit

# Run tests
npm test || exit 1

# Validate commit message
npx commitlint --edit $1 || exit 1
```

**CI pipeline:**
```yaml
# Run tests on every commit
name: Test Each Commit
on: [push]
jobs:
  test-commits:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
        with:
          fetch-depth: 0
      - name: Test each commit
        run: |
          for commit in $(git rev-list origin/main..HEAD); do
            git checkout $commit
            npm test || exit 1
          done
```

## Common Patterns

### Pattern 1: Test-Driven Development

```
Commit 1: "test(user): add test for email validation"
- Write failing test first

Commit 2: "feat(user): implement email validation"
- Implement feature to pass test

Both commits are atomic. Alternative: combine into one.
```

### Pattern 2: Preparatory Refactoring

```
Commit 1: "refactor(db): extract query builder"
- Makes next feature easier

Commit 2: "feat(api): add pagination using query builder"
- Builds on refactoring

Refactoring is separate, revertible commit.
```

### Pattern 3: Incremental Feature

```
Commit 1: "feat(search): add basic text search"
- Simple implementation first

Commit 2: "feat(search): add filter options"
- Enhancement

Commit 3: "feat(search): add sort options"
- Enhancement

Each commit adds complete, working functionality.
```

### Pattern 4: Fix and Prevent

```
Commit 1: "fix(api): handle timeout errors"
- Fix the immediate bug

Commit 2: "feat(api): add retry logic for failures"
- Prevent future occurrences

Fix is separate from prevention strategy.
```

## Anti-Patterns

### Anti-Pattern 1: The "WIP" Commit

```
❌ Bad:
git commit -m "WIP"
git commit -m "still working"
git commit -m "almost done"
git commit -m "done"

✅ Good:
# Work in progress locally
# Squash before pushing
git rebase -i HEAD~4
```

### Anti-Pattern 2: The "Kitchen Sink"

```
❌ Bad: One commit with:
- 3 new features
- 2 bug fixes
- Dependency updates
- Refactoring
- Documentation

✅ Good: 7 atomic commits, one per concern
```

### Anti-Pattern 3: The "Oops" Commits

```
❌ Bad:
Commit 1: "feat: add login"
Commit 2: "fix typo"
Commit 3: "forgot to add file"
Commit 4: "fix lint error"

✅ Good:
# Amend or squash fixes into original commit
git rebase -i HEAD~4
```

### Anti-Pattern 4: Partial Implementation

```
❌ Bad:
Commit 1: "feat: add login form (incomplete)"
# Missing validation, submit handler

✅ Good:
# Don't commit until feature is complete
# Or make smaller but complete features
Commit 1: "feat: add login form UI"
Commit 2: "feat: add login form validation"
Commit 3: "feat: add login form submission"
```

### Anti-Pattern 5: Mixed Concerns

```
❌ Bad:
"feat: add user dashboard and fix auth bug"

✅ Good:
Commit 1: "fix(auth): handle expired tokens"
Commit 2: "feat(dashboard): add user dashboard"
```

## Workflow Tips

### During Development

**Commit frequently locally:**
```bash
# Make small local commits as you work
git commit -m "WIP: add form validation"
git commit -m "WIP: add submit handler"
git commit -m "WIP: add tests"

# Clean up before pushing
git rebase -i origin/main
# Squash WIP commits into atomic commits
```

**Use feature branches:**
```bash
# Branch per feature
git checkout -b feature/user-profile

# Make atomic commits
# Clean up if needed
# Merge when done
```

### Before Pushing

**Review your commits:**
```bash
# See what you're about to push
git log origin/main..HEAD --oneline

# Review each commit
git show <commit-hash>

# Rebase if needed
git rebase -i origin/main
```

**Test each commit:**
```bash
# Checkout each commit and test
for commit in $(git rev-list origin/main..HEAD); do
  git checkout $commit
  npm test || echo "Failed at $commit"
done

# Return to branch
git checkout feature/user-profile
```

### During Code Review

**If requested to split commit:**
```bash
# Interactive rebase
git rebase -i HEAD~1

# Change "pick" to "edit"
edit a1b2c3d feat: large commit

# Unstage everything
git reset HEAD^

# Stage and commit atomically
git add file1.js
git commit -m "feat: first part"
git add file2.js
git commit -m "feat: second part"

# Continue rebase
git rebase --continue
```

**If requested to combine commits:**
```bash
git rebase -i HEAD~3

# Change commits to squash
pick a1b2c3d feat: first part
squash e4f5g6h feat: second part
squash i7j8k9l feat: third part
```

## Summary Checklist

Is this commit atomic?

- [ ] Has single, clear purpose
- [ ] Can be described in one sentence
- [ ] Can be reverted independently
- [ ] Builds successfully when applied alone
- [ ] Passes all tests when applied alone
- [ ] Doesn't mix unrelated concerns
- [ ] Includes all necessary changes (complete)
- [ ] Doesn't include unnecessary changes
- [ ] Commit message accurately describes change
- [ ] Follows conventional commits format

If all checkboxes are checked, the commit is atomic!

## References

- Pro Git Book: https://git-scm.com/book/en/v2
- Atomic Commits: https://www.freshconsulting.com/insights/blog/atomic-commits/
- Git Best Practices: https://sethrobertson.github.io/GitBestPractices/
