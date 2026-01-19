---
allowed-tools: Bash(git:*), Read, Skill
description: Complete and merge feature branch
model: haiku
argument-hint: [feature-name]
---

## Your Task

1. **Load the `gitflow-workflow` skill** using the `Skill` tool to access GitFlow workflow capabilities.
2. Gather context: current branch, git status, recent commits.
3. Validate branch follows `feature/*` convention and working tree is clean.
4. Run tests if available and resolve any failures.
5. Merge to develop with `--no-ff`, delete branch locally and remotely.
