---
allowed-tools: Bash(curl:*), Bash(uname:*), Bash(git:*), Read, Write, Edit, Glob
description: Create or update .gitignore file
argument-hint: [additional-technologies]
---

## Context

- Operating system: !`uname -s`
- Existing .gitignore: !`cat .gitignore 2>/dev/null || echo "(none)"`
- Project files: !`ls -la`

## Your task

Create or update `.gitignore` using Toptal gitignore templates.

1. Detect OS and technologies from project structure plus `$ARGUMENTS`
2. Fetch template from `https://www.toptal.com/developers/gitignore/api/<platforms>`
3. Preserve existing custom sections when updating
4. Show diff for confirmation before applying

Examples:
- `/gitignore` — Auto-detect and create
- `/gitignore react typescript` — Add specific technologies
