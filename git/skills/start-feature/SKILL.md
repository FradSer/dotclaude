---
name: start-feature
allowed-tools: ["Bash(git:*)"]
description: Starts working on a new feature branch using git-flow. This skill should be used when the user asks to "start a feature", "create feature branch", "begin new feature", "git flow feature start", or wants to start a new feature. Accepts either a branch name or a natural-language description.
model: haiku
argument-hint: <feature-name-or-description>
user-invocable: true
disable-model-invocation: true
---

## Workflow Execution

**Launch a general-purpose agent** that executes all phases in a single task.

**Prompt template**:
```
Execute the start-feature workflow.

`$ARGUMENTS` is either a ready-made branch name OR a natural-language description
of the feature (e.g. "add dark mode toggle to settings"). Phase 0 resolves it to
a concrete branch name.

CRITICAL: Verify working tree is clean (`git status --porcelain` is empty) before starting. Abort if dirty. See `${CLAUDE_PLUGIN_ROOT}/references/invariants.md` for details.

## Phase 0: Resolve Branch Name
**Goal**: Turn `$ARGUMENTS` into a concrete branch name `NAME`.
1. If `$ARGUMENTS` is already a slug (lowercase, hyphen-separated, no spaces), use it directly as `NAME`.
2. Otherwise, derive a concise kebab-case `NAME` from the description: lowercase, words joined by hyphens, drop filler words, keep it under ~5 words (e.g. "add dark mode toggle to settings" -> `dark-mode-toggle`).
3. Report the resolved name: "Resolved feature branch: feature/<NAME> (from: $ARGUMENTS)."

## Phase 1: Start Feature
**Goal**: Create feature branch using git-flow-next CLI. Use `NAME` from Phase 0.
1. Run `git flow feature start <NAME>`
2. Push the branch to origin: `git push -u origin feature/<NAME>`
```

**Execute**: Launch a general-purpose agent using the prompt template above
