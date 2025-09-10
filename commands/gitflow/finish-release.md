# Finish Release

Complete and merge current release development.

## Overview

Finishes a release branch by:
- Merging release back into main
- Creating version tag
- Back-merging into develop
- Removing release branch

## Prerequisites
- On release branch (`release/*`)
- All changes committed
- Tests passing

## Usage

```bash
git flow release finish [version]
git push origin --tags
git push origin main develop
gh release create v[version] --title "Release [version]" --latest
```

## What It Does

1. Validates current branch is a release branch
2. Updates version files and changelog
3. Merges to main and creates tag
4. Back-merges to develop
5. Pushes changes and creates GitHub release


## Error Handling
- **Not on release branch**: Use start-release first
- **Uncommitted changes**: Commit or stash changes
- **Merge conflicts**: Resolve conflicts manually
- **Failed tests**: Fix tests before proceeding
- **Git flow fails**: Use manual recovery process

## Manual Recovery

If `git flow release finish` fails:

```bash
# Merge to main and tag
git checkout main
git merge --no-ff release/[version]
git tag v[version]

# Back-merge to develop
git checkout develop
git merge --no-ff release/[version]

# Clean up
git branch -d release/[version]
git push origin --tags
git push origin main develop
gh release create v[version] --title "Release [version]" --latest
```

## Best Practices
- Run tests before finishing
- Use conventional commit messages
- Keep releases focused
- Coordinate with team