---
name: update-gitignore
description: Creates or updates a .gitignore file using git-agent AI generation. This skill should be used when the user asks to "update gitignore", "create gitignore", "add ignore rules", or needs to initialize ignore rules for a new project, add new technologies, or update OS-specific ignore patterns.
user-invocable: true
argument-hint: [additional-technologies]
allowed-tools: ["Bash(git-agent:*)", "Bash(git:*)", "Read", "Write", "Edit", "Glob", "AskUserQuestion", "Task"]
model: haiku
context: fork
---

## Workflow Execution

**Launch a general-purpose agent** that executes all 3 phases in a single task.

**Prompt template**:
```
Execute the complete update-gitignore workflow (3 phases).

## Phase 1: Preserve Custom Rules
**Goal**: Back up any existing custom .gitignore rules before regeneration

**Actions**:
1. If `.gitignore` exists, read it and identify custom sections/rules (lines not from a generator)
2. Save custom rules for re-addition after generation

## Phase 2: Generate .gitignore with git-agent
**Goal**: Create or update .gitignore file using git-agent

**Actions**:
1. Run `git-agent init --gitignore --force` to generate `.gitignore` via AI
2. On auth error (401 / missing key), retry with `--free` flag:
   `git-agent init --gitignore --force --free`
3. Re-add any custom rules preserved from Phase 1

## Phase 3: Confirmation
**Goal**: Present changes for user review

**Actions**:
1. Show the repository changes (diff) to confirm the update
2. Present the resulting diff for user confirmation
```

**Execute**: Launch a general-purpose agent using the prompt template above
