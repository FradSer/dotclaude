---
name: commit-and-push
description: Creates atomic conventional git commits using git-agent and pushes to the remote repository. This skill should be used when the user asks to "commit and push", "push my changes", or wants to commit staged changes following conventional commits and immediately push to the remote branch.
user-invocable: true
allowed-tools: ["Bash(git-agent:*)", "Bash(git:*)", "Read", "Write", "Glob", "AskUserQuestion", "Skill", "Task"]
model: haiku
---

## Workflow Execution

**Launch a general-purpose agent** that executes all 2 phases in a single task.

**Prompt template**:
```
Execute the commit-and-push workflow (2 phases).

## Phase 1: Create Commits
**Goal**: Create all commits using git-agent
**Actions**:
1. Load `git:commit` skill using the Skill tool
2. Execute commit workflow (git-agent handles staging, message generation, and atomic splitting)

## Phase 2: Push to Remote
**Goal**: Push commits to the remote repository
**Actions**:
1. Once all commits are created, push the current branch to the remote repository
2. Use `git push` (add `-u origin <branch>` if upstream is not set)

If no commits created, report "No commits to push" and exit.
```

**Execute**: Launch a general-purpose agent using the prompt template above
