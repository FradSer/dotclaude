---
name: finish-feature
allowed-tools: Bash(git:*), Read, Skill
description: Complete and merge feature branch
model: haiku
argument-hint: [feature-name]
user-invocable: true
---

## Your Task

1. **Load the `gitflow-workflow` skill** using the `Skill` tool to access GitFlow workflow capabilities.
2. Gather context: current branch, git status, recent commits.
3. Normalize the provided feature name from `$ARGUMENTS` to `$FEATURE_NAME`:
   - Strip a leading `feature/` prefix if present
   - Convert to kebab-case (lowercase, hyphens)
4. Validate branch follows `feature/*` convention and working tree is clean.
5. Run tests if available and resolve any failures.
6. Identify target integration branch for the active workflow (often `develop`).
7. Merge into the integration branch (often with `--no-ff`), then delete `feature/$FEATURE_NAME` locally and remotely when appropriate.
