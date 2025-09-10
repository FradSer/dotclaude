# Finish Feature

Complete and merge current feature development.

## Overview

Merges feature branch to develop and deletes feature branch.

## Prerequisites
- On feature branch (`feature/*`)
- All changes committed
- Tests passing

## Usage

```bash
git flow feature finish [feature-name]
git push origin develop
```

## What It Does

1. Validates current branch is a feature branch
2. Merges to develop and deletes feature branch
3. Pushes develop to origin

## Error Handling
- **Not on feature branch**: Use start-feature first
- **Uncommitted changes**: Commit or stash changes
- **Merge conflicts**: Resolve conflicts manually

## Best Practices
- Run tests before finishing
- Use conventional commits
- Keep features small (< 500 lines)
- Review changes before finishing
