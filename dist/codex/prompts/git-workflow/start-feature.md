# Start Feature

**Summary:** Start new feature or continue existing feature development

---

## Context

- Current branch: `git branch --show-current`
- Existing feature branches: List all feature branches
- Git status: `git status --porcelain`

## Your task

Start or continue feature development with description: $ARGUMENTS

**Actions to take:**
1. If no feature branches exist: Create new feature branch from develop
2. If one feature branch exists: Switch to existing feature branch
3. If multiple feature branches exist: Show options and let user choose
4. Use kebab-case naming for branch names
5. Publish new feature branch to remote for collaboration
6. Ensure working directory is clean before switching branches

**Required Commit Standards:**
- Commit message title must be entirely lowercase
- Title must be less than 50 characters
- Follow conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
- Use atomic commits for logical units of work
