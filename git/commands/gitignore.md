---
allowed-tools: Task, Bash(curl:*), Bash(uname:*), Bash(git:*), Read, Write, Edit, Glob
description: Create or update .gitignore file
model: haiku
argument-hint: [additional-technologies]
---

## Context

- Project guidelines: @CLAUDE.md
- Operating system: !`uname -s`
- Existing .gitignore status: !`test -f .gitignore && echo ".gitignore found" || echo ".gitignore not found"`
- Project files: Analyze repository structure to detect technologies
- Available templates: !`curl -sL https://www.toptal.com/developers/gitignore/api/list`

## Requirements

- Combine detected platforms and `$ARGUMENTS` into the generator request (e.g. `macos,node,docker`).
- Preserve existing custom sections when updating `.gitignore`.
- Present the resulting diff for confirmation.

## Your Task

**IMPORTANT: You MUST use the Task tool to complete ALL tasks.**

1. Detect operating systems and technologies from context plus `$ARGUMENTS`.
2. Generate or update `.gitignore` using the Toptal API while retaining custom rules.
3. Show the repository changes to confirm the update.

### Usage Examples

- `/gitignore` — Auto-detect and create `.gitignore`.
- `/gitignore react typescript` — Add React and TypeScript to detected technologies.
