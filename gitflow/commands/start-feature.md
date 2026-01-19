---
allowed-tools: Bash(git:*), Read, Skill
description: Start new feature branch
model: haiku
argument-hint: [feature-name]
---

## Your Task

1. **Load the `gitflow-workflow` skill** using the `Skill` tool to access GitFlow workflow capabilities.
2. Gather context: current branch, existing feature branches, git status.
3. Create or resume `feature/$ARGUMENTS` branch from develop.
4. Push the branch to origin if newly created.
