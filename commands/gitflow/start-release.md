# Start Release

Start new release or continue existing release development.

## Overview

Creates release branch from develop or switches to existing release:
- No existing branches: Create new release with semantic version
- Branch exists: Switch to existing branch

## Usage

```bash
# Create new release
git flow release start [version]
git flow release publish [version]

# Continue existing release
git checkout release/[version]
```

## What It Does

1. Detects existing release branches
2. Creates new release from develop with semantic version:
   - `feat!`/`fix!` or BREAKING CHANGE → major bump
   - `feat:` commits → minor bump
   - `fix:` commits → patch bump
3. Updates version files and publishes branch

## Best Practices
- Use conventional commits for version detection
- Test thoroughly before finishing
- Coordinate timing with team
- Sync dependencies before finishing