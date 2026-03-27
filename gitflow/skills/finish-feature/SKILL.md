---
name: finish-feature
allowed-tools: ["Bash(git-agent:*)", "Bash(git:*)", "Read", "Write"]
description: Finalizes and merges a feature branch into develop using git-flow. This skill should be used when the user asks to "finish a feature", "merge feature branch", "complete feature", "git flow feature finish", or wants to finalize a feature branch.
model: haiku
argument-hint: [feature-name]
user-invocable: true
disable-model-invocation: true
---

## Workflow Execution

**Launch a general-purpose agent** that executes all 4 phases in a single task.

**Prompt template**:
```
Execute the finish-feature workflow (4 phases).

## Pre-operation Checks
Verify working tree is clean and current branch matches `feature/*` per `${CLAUDE_PLUGIN_ROOT}/references/invariants.md`.

## Phase 1: Identify Feature
**Goal**: Determine feature name from current branch or argument.
1. If `$ARGUMENTS` provided, use it as feature name
2. Otherwise, extract from current branch: `git branch --show-current` (strip `feature/` prefix)

## Phase 2: Pre-finish Checks
**Goal**: Run tests before finishing.
1. Identify test commands (check package.json, Makefile, etc.)
2. Run tests if available; exit if tests fail

## Phase 3: Update Changelog
**Goal**: Document changes in CHANGELOG.md.
1. Ensure changes are in `[Unreleased]` section per `${CLAUDE_PLUGIN_ROOT}/examples/changelog.md`
2. Stage CHANGELOG.md: `git add CHANGELOG.md`
3. Determine the correct Claude model name for co-author attribution
   - Valid models: Claude Sonnet 4.6, Claude Opus 4.6, Claude Haiku 4.5
4. Commit with git-agent: `git-agent commit --no-stage --intent "update changelog for feature $FEATURE_NAME" --co-author "Claude <Model> <Version> <noreply@anthropic.com>"`
5. On auth error (401), retry with `--free`
6. **Fallback** (git-agent unavailable): `git commit -m "chore: update changelog for feature $FEATURE_NAME"` with conventional format and `Co-Authored-By` footer

## Phase 4: Finish Feature
**Goal**: Complete feature using git-flow-next CLI.
1. Run `git flow feature finish $FEATURE_NAME`
2. Verify current branch: `git branch --show-current` (should be on develop)
3. Push develop: `git push origin develop`
```

**Execute**: Launch a general-purpose agent using the prompt template above
