# Start Feature

Start new feature or continue existing feature development.

## Overview

Creates feature branch from develop or switches to existing feature:
- No existing branches: Create new feature branch
- One branch: Switch to existing branch
- Multiple branches: Prompt for selection

## Usage

```bash
# Create new feature
git flow feature start [feature-name]

# Publish feature for collaboration
git flow feature publish [feature-name]

# Continue existing feature
git checkout feature/[feature-name]
git flow feature pull origin [feature-name]
```

## What It Does

1. Detects existing feature branches
2. Creates new feature from develop or switches to existing
3. Generates kebab-case names (e.g., `user-authentication`)
4. Publishes branch to remote if new

## Best Practices
- Keep features small (< 500 lines)
- Use conventional commits
- Regular atomic commits
- Write tests during development
