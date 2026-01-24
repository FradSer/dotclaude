---
name: update-gitignore
description: Create or update .gitignore file
user-invocable: true
allowed-tools: ["Bash(curl:*)", "Bash(uname:*)", "Bash(git:*)", "Read", "Write", "Edit", "Glob"]
model: haiku
context: fork
argument-hint: [additional-technologies]
version: 0.1.0
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

1. Detect operating systems and technologies from context plus `$ARGUMENTS`.
2. Generate or update `.gitignore` using the Toptal API while retaining custom rules.
3. Show the repository changes to confirm the update.
