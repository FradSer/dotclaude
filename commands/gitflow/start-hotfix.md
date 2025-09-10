# Start Hotfix

Start new hotfix or continue existing hotfix development.

## Overview

Creates hotfix branch from main or switches to existing hotfix:
- No existing branches: Create new hotfix with incremented patch version
- Branch exists: Switch to existing branch

## Usage

```bash
# Create new hotfix
git flow hotfix start [version]

# Continue existing hotfix
git checkout hotfix/[version]
```

## What It Does

1. Detects existing hotfix branches
2. Creates new hotfix from main with incremented patch version (1.2.3 → 1.2.4)
3. Updates version files (package.json, pyproject.toml)
4. Switches to existing hotfix if found

## Best Practices
- Focus on critical bug fixes only
- Use conventional commits (fix:, chore:)
- Test fixes thoroughly
- Keep changes minimal