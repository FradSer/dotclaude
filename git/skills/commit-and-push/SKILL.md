---
name: commit-and-push
description: Creates clean conventional git commits using standard git and pushes changes to the remote repository. Use when the user asks to "commit and push", "push changes", or complete a commit followed by git push.
user-invocable: true
argument-hint: "[optional commit message or instructions]"
allowed-tools: ["Bash(git:*)"]
---

# Commit and Push Skill (Standard Git)

Create clean, atomic Conventional Commits using standard `git` commands and push them to origin.

## Workflow

1. **Inspect status and diff**:
   ```bash
   git status --porcelain
   git diff --staged
   git diff
   ```
2. **Stage files**:
   ```bash
   git add <file1> <file2> ...
   ```
3. **Commit**:
   Formulate a Conventional Commit message and commit:
   ```bash
   git commit -m "<type>(<scope>): <summary>"
   ```
4. **Push**:
   Detect current branch and push:
   ```bash
   BRANCH=$(git branch --show-current)
   git push origin "$BRANCH"
   ```
   If pushing a new branch for the first time, append `-u`:
   ```bash
   git push -u origin "$BRANCH"
   ```
