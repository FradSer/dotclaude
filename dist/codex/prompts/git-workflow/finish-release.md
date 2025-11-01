# Finish Release

**Summary:** Complete and merge current release development

---

## Context

- Current branch: `git branch --show-current`
- Existing release branches: `git branch --list 'release/*' | sed 's/^..//'`
- Git status: `git status --porcelain`
- Recent commits: `git log --oneline -5`
- Test commands available: Detect available testing frameworks for this project
- Current version: Check version information in project configuration files

## Your task

Complete and merge current release development

**Actions to take:**
1. Validate current branch is a release branch (`release/*`) and extract version from branch name
2. Ensure all changes are committed
3. Run tests if available before finishing
4. Update changelog if exists
5. Update all README files (README*.*, README.*.*, etc.) if they exist
6. Merge release branch to main with `--no-ff` (creates merge commit)
7. Create annotated tag on the merge commit in main using version from branch name (e.g., for `release/1.0.0` → `git tag -a v1.0.0 -m "Release 1.0.0"`)
8. Merge main back to develop with `--no-ff` to sync changes
9. Delete release branch locally and remotely
10. Push all changes (main, develop) and tags to origin
11. Create GitHub release using the tag created in step 7 (GitHub release MUST be based on the tagged commit)
12. Handle merge conflicts if they occur

**Manual recovery if workflow fails:**
- Checkout main: `git checkout main`
- Merge release to main: `git merge --no-ff release/x.x.x`
- Create tag on merge commit: `git tag -a vx.x.x -m "Release x.x.x"`
- Checkout develop: `git checkout develop`
- Merge main to develop: `git merge --no-ff main`
- Delete release branch: `git branch -d release/x.x.x && git push origin --delete release/x.x.x`
- Push all: `git push origin main develop --tags`
- Create GitHub release

**Required Commit Standards:**
- Commit message title must be entirely lowercase
- Title must be less than 50 characters
- Follow conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
- Use atomic commits for logical units of work
