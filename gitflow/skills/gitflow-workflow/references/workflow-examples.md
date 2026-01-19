# GitFlow Workflow Examples

Complete workflow examples for different GitFlow scenarios.

## Feature Development Workflow

### Starting a Feature

```bash
# Start new feature branch
git flow feature start user-authentication

# This creates: feature/user-authentication from develop
# Automatically checks out the new branch
```

### Developing the Feature

```bash
# Make changes and commit using conventional format
git add .
git commit -m "feat(auth): add login form component"

git add .
git commit -m "feat(auth): implement authentication API endpoint"

# Update from develop if needed
git flow feature update
# or
git flow update
```

### Finishing a Feature

```bash
# Ensure all changes are committed
git status

# Run tests
npm test

# Finish and merge to develop
git flow feature finish user-authentication

# This will:
# 1. Merge feature/user-authentication to develop with --no-ff
# 2. Delete feature/user-authentication locally and remotely
# 3. Switch back to develop branch
```

## Hotfix Workflow

### Starting a Hotfix

```bash
# Start hotfix from main
git flow hotfix start critical-payment-bug

# This creates: hotfix/critical-payment-bug from main
# Automatically increments patch version (e.g., v1.2.3 → v1.2.4)
```

### Fixing the Issue

```bash
# Make the fix
git add .
git commit -m "fix(payment): resolve gateway timeout issue"

# Test the fix
npm test
```

### Finishing a Hotfix

```bash
# Finish hotfix
git flow hotfix finish critical-payment-bug

# This will:
# 1. Merge hotfix/critical-payment-bug to main
# 2. Create version tag (e.g., v1.2.4) on main
# 3. Merge hotfix/critical-payment-bug to develop
# 4. Delete hotfix branch locally and remotely
# 5. Switch back to develop
```

## Release Workflow

### Starting a Release

```bash
# Auto-determine version from commits
git flow release start

# Or specify version explicitly
git flow release start 1.2.0

# This creates: release/1.2.0 from develop
# Version calculated from conventional commits since last tag
```

### Release Stabilization

```bash
# On release branch, only bug fixes allowed
git add .
git commit -m "fix(ui): correct date formatting in release"

# Final testing
npm test
npm run build
```

### Finishing a Release

```bash
# Finish release
git flow release finish 1.2.0

# This will:
# 1. Merge release/1.2.0 to main with --no-ff
# 2. Create version tag (v1.2.0) on main
# 3. Merge main back to develop
# 4. Delete release branch locally and remotely
# 5. Switch back to develop
```

## Complete Feature-to-Release Cycle

### Step 1: Develop Features

```bash
# Feature 1
git flow feature start user-auth
# ... develop and commit ...
git flow feature finish user-auth

# Feature 2
git flow feature start payment-integration
# ... develop and commit ...
git flow feature finish payment-integration
```

### Step 2: Start Release

```bash
# All features merged to develop
git flow release start

# Version calculated: v1.2.0 (has feat: commits)
```

### Step 3: Stabilize Release

```bash
# Fix any bugs found during testing
git add .
git commit -m "fix(release): resolve payment gateway issue"

# Final verification
npm test
```

### Step 4: Finish Release

```bash
git flow release finish

# Creates v1.2.0 tag on main
# Merges to both main and develop
```

## Handling Merge Conflicts

### During Feature Finish

```bash
# Attempt to finish feature
git flow feature finish my-feature

# If conflicts occur:
# 1. Resolve conflicts manually
git add .
git commit -m "fix: resolve merge conflicts"

# 2. Continue the finish operation
git flow feature finish my-feature --continue
```

### During Release Finish

```bash
# Attempt to finish release
git flow release finish 1.2.0

# If conflicts occur:
# 1. Resolve conflicts
git add .
git commit -m "fix: resolve release merge conflicts"

# 2. Continue
git flow release finish 1.2.0 --continue

# Or abort if needed
git flow release finish 1.2.0 --abort
```

## Using Merge Strategies

### Rebase Strategy

```bash
# Finish feature with rebase (linear history)
git flow feature finish my-feature --rebase
```

### Squash Strategy

```bash
# Finish feature with squash (single commit)
git flow feature finish my-feature --squash
```

### Force No-Fast-Forward

```bash
# Always create merge commit
git flow feature finish my-feature --no-ff
```

## Version Calculation Examples

### Example 1: Minor Release

**Commits since v1.2.0:**
```
feat(auth): add oauth login
fix(api): handle null payload
docs: update readme
```

**Result:** `v1.3.0` (has `feat:` → minor bump)

### Example 2: Major Release

**Commits since v1.2.0:**
```
feat(api)!: migrate to oauth 2.0

BREAKING CHANGE: API requires OAuth 2.0 tokens
feat(auth): add google login
```

**Result:** `v2.0.0` (has `BREAKING CHANGE` → major bump)

### Example 3: Patch Release

**Commits since v1.2.0:**
```
fix(api): handle null payload
fix(ui): correct date formatting
chore: update dependencies
```

**Result:** `v1.2.1` (only `fix:` → patch bump)

## Branch Management

### List Active Branches

```bash
# List all feature branches
git flow feature list

# List all release branches
git flow release list

# List all hotfix branches
git flow hotfix list
```

### Update Branch from Parent

```bash
# Update current feature from develop
git flow update

# Update specific feature
git flow feature update my-feature
```

### Rename Branch

```bash
# Rename current branch
git flow rename better-feature-name

# Rename specific feature
git flow feature rename old-name new-name
```

### Delete Branch

```bash
# Delete specific feature
git flow feature delete old-feature

# Delete current branch
git flow delete
```

## Multi-Environment Workflow (GitLab Flow)

### Development Flow

```bash
# Feature development
git flow feature start new-feature
# ... develop ...
git flow feature finish new-feature  # merges to main
```

### Staging Deployment

```bash
# Update staging from main
git checkout staging
git merge main
git push origin staging
```

### Production Deployment

```bash
# Update production from staging
git checkout production
git merge staging
git push origin production
```

### Hotfix in Production

```bash
# Start hotfix from production
git flow hotfix start critical-fix

# Fix and finish
git flow hotfix finish critical-fix
# Merges to both production and main
```

## Best Practices

1. **Keep features small**: 2-3 days maximum
2. **Test before finish**: Always run tests before merging
3. **Use conventional commits**: Follow commit message format
4. **Update frequently**: Sync feature branches with develop regularly
5. **Clean merges**: Resolve conflicts before finishing
6. **Tag releases**: Always create version tags on main
7. **Document breaking changes**: Clearly mark in commits
