---
name: commit-and-push
description: Create atomic conventional git commit and push to remote
user-invocable: true
allowed-tools: ["Bash(git:*)", "Read", "Write", "Glob", "AskUserQuestion", "Skill"]
argument-hint: "[no arguments needed]"
model: haiku
version: 0.1.0
---

## Your Task

1. **Invoke the `/commit` command** to create all commits following conventional commits format.

2. **Push to Remote**:
   - Once all commits are created, push the current branch to the remote repository.
   - Use `git push` (add `-u origin <branch>` if upstream is not set).
