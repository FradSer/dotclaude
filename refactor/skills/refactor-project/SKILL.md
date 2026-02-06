---
name: refactor-project
description: This skill should be used when the user asks for project-wide refactoring, cross-file simplification, consistency standardization across the codebase, duplication reduction, or invokes `/refactor-project`.
argument-hint: (no arguments needed)
allowed-tools: ["Task", "Read", "Bash(git:*)", "Grep", "Glob"]
user-invocable: true
---

# Refactor Project Command

Execute automated project-wide refactoring using `refactor:code-simplifier` agent with cross-file optimization focus.

## Pre-operation Checks
**Goal**: Ensure project-wide execution is explicit and reproducible.

**Actions**:
1. Run `git rev-parse --is-inside-work-tree`; if false, inform user that project-wide mode requires a git workspace
2. Record current revision with `git rev-parse --short HEAD` and include it in final summary for rollback context
3. Ignore command arguments and proceed with full-project discovery

## Phase 1: Analyze Project Scope
**Goal**: Discover all code files and display scope summary.

**Actions**:
1. Find all code files using Glob patterns for common extensions
2. Filter out `node_modules/`, `.git/`, `dist/`, `build/`, `vendor/`, `.venv/`
3. Group files by language/extension and identify primary source directories
4. Display scope summary (file count, languages, directories) then proceed automatically

See `references/scope-analysis.md` for exclusion patterns and edge cases.

## Phase 2: Launch Refactoring Agent
**Goal**: Execute `refactor:code-simplifier` agent with project-wide scope and cross-file focus.

**Actions**:
1. Launch `refactor:code-simplifier` agent with all discovered code files
2. Pass cross-file optimization emphasis: duplication reduction, consistent patterns
3. Pass aggressive mode flag for legacy code removal
4. Agent auto-loads `refactor:best-practices` skill and applies language-specific patterns

See `references/agent-configuration.md` for detailed Task parameters.

## Phase 3: Summary
**Goal**: Report comprehensive summary of project-wide changes.

**Actions**:
1. Report total files refactored (count and percentage of project)
2. List changes categorized by improvement type and cross-file improvements made
3. List best practices applied and legacy code removed
4. Suggest test suite to run and recommend reviewing changes in logical groups
5. Provide safer rollback command tied to recorded baseline (for example: `git restore --worktree --staged .`)

See `references/output-requirements.md` for detailed summary format.

## Requirements

- Execute immediately after displaying scope (no confirmation needed)
- Refactor entire project across all discovered code files
- Prioritize cross-file duplication reduction and consistent patterns
- Preserve behavior and public interfaces unless user explicitly requests a behavior change
