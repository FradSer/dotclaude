---
name: commit
description: Creates clean, conventional git commits using standard git. Use when the user asks to "commit", "git commit", "create commit", or wants to commit staged or unstaged changes.
user-invocable: true
argument-hint: "[optional commit message or instructions]"
allowed-tools: ["Bash(git:*)"]
---

# Commit Skill (Standard Git)

Create clean, atomic Conventional Commits using standard `git` commands.

## Workflow

1. **Inspect status and diff**:
   ```bash
   git status --porcelain
   git diff --staged
   git diff
   ```
2. **Stage files**:
   Stage relevant modified or untracked files explicitly:
   ```bash
   git add <file1> <file2> ...
   ```
3. **Formulate Conventional Commit Message**:
   Follow the specification: `<type>(<optional scope>): <short description>`
   Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`.
4. **Commit**:
   Execute standard `git commit`:
   ```bash
   git commit -m "<type>(<scope>): <summary>"
   ```
   If a co-author trailer is required or requested, follow `../../references/coauthor-attribution.md`.
