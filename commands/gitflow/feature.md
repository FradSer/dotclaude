# Git Flow Features

Commands for managing feature branches following GitHub best practices.

## AI Instructions for Feature Development

### Starting a new feature
1. **Ensure repository is up-to-date**:
   ```bash
   git status
   git fetch origin
   git checkout develop
   git pull origin develop
   git status
   ```

2. **Start feature with descriptive name**:
   ```bash
   git flow feature start FEATURE_NAME
   ```
   Use kebab-case naming: `user-authentication`, `payment-integration`

3. **Immediately push to remote for backup**:
   ```bash
   git flow feature publish FEATURE_NAME
   ```

### Working on a feature
1. **Make incremental commits with clear messages**:
   ```bash
   git add .
   git commit -m "feat: add user login validation"
   git push origin feature/FEATURE_NAME
   ```
   
   **Commit Requirements:**
   - Commit message title must be entirely lowercase
   - Title must be less than 50 characters
   - Follow conventional commits format (feat:, fix:, chore:, etc.)
   - Use atomic commits for logical units of work

2. **Regularly sync with develop** (for long-running features):
   ```bash
   git checkout develop
   git pull origin develop
   git checkout feature/FEATURE_NAME
   git merge develop
   ```

### Finishing a feature
1. **Ensure feature is complete and tested**:
   ```bash
   git status
   # Run tests here
   npm test  # or appropriate test command
   ```

2. **Ensure latest changes before finishing**:
   ```bash
   git fetch origin
   git checkout develop
   git pull origin develop
   git checkout feature/FEATURE_NAME
   git merge develop
   ```

3. **Finish the feature**:
   ```bash
   git flow feature finish FEATURE_NAME
   ```

4. **Push updated develop branch**:
   ```bash
   git push origin develop
   ```

## Alternative: GitHub Pull Request Workflow
For better code review and CI/CD integration:

1. **Create PR instead of direct finish**:
   ```bash
   # Don't use git flow feature finish
   # Instead, create PR on GitHub from feature/FEATURE_NAME to develop
   ```

2. **Use GitHub CLI** (if available):
   ```bash
   gh pr create --title "feat: FEATURE_NAME" --body "Description of changes" --base develop
   ```

## Collaboration Commands

### Track existing feature
```bash
git flow feature track FEATURE_NAME
```

### Pull latest changes
```bash
git flow feature pull origin FEATURE_NAME
```

## Best Practices
- **Commit Requirements:**
  - Commit message title must be entirely lowercase
  - Title must be less than 50 characters
  - Follow conventional commits format (feat:, fix:, chore:, etc.)
  - Use atomic commits for logical units of work
- Keep features small and focused (< 500 lines of code)
- Write tests before finishing features
- Use descriptive branch names that explain the feature
- Delete remote feature branches after merging to keep repository clean

## Error Handling
- If merge conflicts occur during sync, resolve them before proceeding
- If feature finish fails, check for uncommitted changes
- Use `git flow feature delete FEATURE_NAME` to remove unwanted features