---
name: start-feature
allowed-tools: ["Bash(git:*)"]
description: Starts working on a new feature branch using git-flow. This skill should be used when the user asks to "start a feature", "create feature branch", "begin new feature", "git flow feature start", or wants to start a new feature.
model: haiku
argument-hint: <feature-name>
user-invocable: true
disable-model-invocation: true
---

## Workflow Execution

**Launch a general-purpose agent** that executes all phases in a single task.

**Prompt template**:
```
Execute the start-feature workflow.

## Pre-operation Checks
Verify working tree is clean per `${CLAUDE_PLUGIN_ROOT}/references/invariants.md`.

## Phase 1: Start Feature
**Goal**: Create feature branch using git-flow-next CLI.
1. Run `git flow feature start $ARGUMENTS`
2. Push the branch to origin: `git push -u origin feature/$ARGUMENTS`
```

**Execute**: Launch a general-purpose agent using the prompt template above
