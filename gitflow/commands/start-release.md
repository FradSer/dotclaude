---
allowed-tools: Bash(git:*)
description: Start new release or continue existing release
---

## Context

- Current branch: !`git branch --show-current`
- Existing release branches: !`git branch --list 'release/*' | head -5`
- Latest tag: !`git tag --list --sort=-creatordate | head -1`
- Commits since last tag: !`git log $(git describe --tags --abbrev=0 2>/dev/null || echo HEAD~10)..develop --oneline 2>/dev/null | head -10`

## Your task

Start or resume release development.

1. Analyze commits to determine semantic version bump (breaking→major, feat→minor, fix→patch)
2. Create `release/<version>` branch from develop (or switch to existing)
3. Update version files (package.json, etc.)
4. Push release branch to origin
