# Finish Hotfix

Complete and merge current hotfix development.

## Overview

Finishes hotfix branch by:
- Merging hotfix back into main
- Creating version tag
- Back-merging into develop
- Removing hotfix branch

## Prerequisites
- On hotfix branch (`hotfix/*`)
- All changes committed
- Tests passing

## Usage

```bash
git flow hotfix finish [version]
git push origin main develop --tags
gh release create v[version] --title "Hotfix [version]" --latest
```

## What It Does

1. Validates current branch is a hotfix branch
2. Updates version files and changelog
3. Merges to both main and develop branches
4. Creates version tag and pushes changes
5. Creates GitHub release

## Error Handling
- **Not on hotfix branch**: Use start-hotfix first
- **Uncommitted changes**: Commit or stash changes
- **Merge conflicts**: Resolve conflicts manually

## Best Practices
- Run tests before finishing
- Use conventional commits
- Keep fixes critical and minimal
- Coordinate timing with team