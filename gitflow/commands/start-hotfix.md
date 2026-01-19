---
allowed-tools: Bash(git:*), Read, Write, Skill
description: Start new hotfix branch
model: haiku
argument-hint: [hotfix-name]
---

## Your Task

1. **Load the `gitflow-workflow` skill** using the `Skill` tool to access GitFlow workflow capabilities.
2. Gather context: current branch, existing hotfix branches, latest tag, version files.
3. Create or resume `hotfix/$ARGUMENTS` branch from main.
4. Increment patch version and update version files.
5. Push the branch to origin if newly created.
