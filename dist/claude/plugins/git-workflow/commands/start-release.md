---
allowed-tools: Task, Bash
description: Start new release or continue existing release development
model: claude-haiku-4-5-20251001
---

## Context

- Current branch: !`git branch --show-current`
- Existing release branches: !`git branch --list 'release/*' | sed 's/^..//'`
- Latest tag: !`git tag --list --sort=-creatordate | head -1`
- Conventional commit scan: !`git log $(git describe --tags --abbrev=0 2>/dev/null || echo)..develop --oneline --grep="feat\|fix\|BREAKING" 2>/dev/null || git log develop --oneline --grep="feat\|fix\|BREAKING"`
- Current version: Inspect project configuration files

## Requirements

- Release branches must use the `release/` prefix and reflect the target semantic version.
- Determine the semantic version bump using conventional commit history (breaking → major, feat → minor, fix → patch).
- Update version metadata (package manifests, changelog) and publish the branch to origin.
- Commit message title must be entirely lowercase
- Title must be less than 50 characters
- Commit message body must use normal text formatting (proper capitalization and punctuation)
- Follow conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
- Use atomic commits for logical units of work

## Your Task

**IMPORTANT: You MUST use the Task tool to complete ALL tasks.**

1. Decide whether to create a new `release/<version>` branch from `develop` or resume an existing release branch.
2. Calculate the next semantic version based on commit history and update version files accordingly.
3. Switch to the release branch, push it to origin if newly created, and prepare it for stabilization work.
