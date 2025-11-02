# Finish Feature

**Summary:** Complete and merge current feature development

---

## Context

- Current branch: `git branch --show-current`
- Git status: `git status --porcelain`
- Recent commits: `git log --oneline -5`
- Test commands available: Detect available testing frameworks for this project

## Requirements

- Ensure all changes for feature `$ARGUMENTS` are committed before finishing.
- Run the relevant test suite and confirm all checks pass.
- Commit message title must be entirely lowercase
- Title must be less than 50 characters
- Commit message body must use normal text formatting (proper capitalization and punctuation)
- Follow conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
- Use atomic commits for logical units of work

## Your Task

1. Confirm the branch name follows the `feature/*` convention and the working tree is clean.
2. Execute the appropriate tests and resolve any failures before proceeding.
3. Merge the feature branch into `develop`, delete the feature branch locally and remotely, handle merge conflicts if they arise, and push the updated `develop` branch.
