---
name: update-gitignore
description: Creates or updates a .gitignore file using the Toptal gitignore API with OS and language detection. Use when initializing a new project, adding new technologies to an existing project, or updating ignore rules for OS-specific files.
user-invocable: true
argument-hint: [additional-technologies]
allowed-tools: ["Bash(curl:*)", "Bash(uname:*)", "Bash(git:*)", "Read", "Write", "Edit", "Glob", "AskUserQuestion", "Task"]
model: haiku
context: fork
---

## Workflow Execution

**Launch a general-purpose agent** that executes all 3 phases in a single task.

**Prompt template**:
```
Execute the complete update-gitignore workflow (3 phases).

## Phase 1: Technology Detection
**Goal**: Identify operating systems and technologies to include in .gitignore

**Actions**:
1. Detect operating systems and technologies from context
2. Combine detected platforms with $ARGUMENTS into the generator request (e.g. `<os>,<language>,<tool>`)

## Phase 2: Generate or Update .gitignore
**Goal**: Create or update .gitignore file using Toptal API

**Actions**:
1. Generate or update `.gitignore` using the Toptal API
2. Preserve existing custom sections when updating `.gitignore`
3. Retain all custom rules from existing file

## Phase 3: Confirmation
**Goal**: Present changes for user review

**Actions**:
1. Show the repository changes (diff) to confirm the update
2. Present the resulting diff for user confirmation
```

**Execute**: Launch a general-purpose agent using the prompt template above
