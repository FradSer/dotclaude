# Git Flow Initialization

Initialize git-flow in an existing repository with GitHub best practices.

## AI Instructions

When initializing gitflow, follow these steps exactly:

1. **Ensure repository is up-to-date**:
   ```bash
   git status
   git fetch origin
   git pull origin $(git branch --show-current)
   git branch -a
   ```

2. **Initialize git-flow with version tag prefix**:
   ```bash
   git config gitflow.prefix.versiontag "v"
   git flow init -d
   ```

3. **Verify initialization**:
   ```bash
   git branch
   git flow version
   ```

4. **Push develop branch to origin**:
   ```bash
   git push -u origin develop
   ```

## What this accomplishes:
- Sets up git-flow configuration with GitHub-compatible naming
- Creates the develop branch from main/master
- Establishes branch naming conventions:
  - Production branch: `main` (or `master` if existing)
  - Development branch: `develop`
  - Feature prefix: `feature/`
  - Release prefix: `release/`
  - Hotfix prefix: `hotfix/`
  - Support prefix: `support/`
  - Version tag prefix: `v` (creates tags like v1.0.0, v1.2.1)

## Prerequisites
- Repository must be initialized with git
- Must have git-flow installed (`brew install git-flow-avh` on macOS)
- Should have main/master branch with initial commit

## Error handling
- If git-flow is already initialized, use `git flow init -f` to force re-initialization
- If develop branch exists, git-flow will use the existing branch