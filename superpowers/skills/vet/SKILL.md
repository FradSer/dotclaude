---
name: vet
description: This skill should be used when the user invokes /vet to manually surface the current session task and have Claude evaluate whether it is clear and complete.
user-invocable: true
allowed-tools: ["Bash(ls:*)", "Bash(cat:*)", "Read", "AskUserQuestion"]
---

# Vet Session Task

Surface the current session task and evaluate its clarity and completion status.

## Phase 1: Resolve Task State

**Goal**: Locate and read the session state file.

**Actions**:
1. Find the most recent `*.superpowers.json` file in `~/.claude/projects/$(echo "$PWD" | tr '/' '-')/` (use the file with the most recent modification time)
2. If no state file exists, report "No task is being tracked in this session" and stop
3. Read the file and extract `task`, `updated_at`, and `modified_files` (if present)
4. Display the tracked task clearly to the user

## Phase 2: Clarity Check

**Goal**: Determine whether the task has unambiguous completion criteria.

**Actions**:
1. Evaluate whether the task is specific enough to define a concrete delivery checklist
2. If the task is vague or ambiguous, use the `AskUserQuestion` tool to ask the user to clarify before proceeding
3. Do not continue to Phase 3 until the task is clear

## Phase 3: Completion Check

**Goal**: Assess whether the task is complete based on the conversation so far.

**Actions**:
1. If complete: confirm what was done and append `<verified>Fully Vetted.</verified>`
2. If incomplete: list what remains undone and identify the next step (do not mark verified)
3. If indeterminate (discussion or planning only): state that and skip verification
