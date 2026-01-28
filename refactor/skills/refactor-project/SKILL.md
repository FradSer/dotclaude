---
name: refactor-project
description: Run project-wide refactoring with code-simplifier
argument-hint: (no arguments needed - refactors entire project)
allowed-tools: ["Task", "Read", "Write", "Bash(git:*)", "Grep", "Glob"]
user-invocable: true
---

# Refactor Project Command

## Core Principles

- **Fully automated**: Execute project-wide refactoring immediately without confirmation
- **Aggressive refactoring**: Apply thorough improvements across entire codebase
- **Self-discovery**: Agent discovers best practices from skills automatically
- **Cross-file focus**: Emphasize duplication reduction and consistent patterns
- **Git safety net**: Trust git to revert if needed, no preview confirmations

## Context

- This command is for project-wide refactoring across the entire codebase.
- This command executes immediately without preview or confirmation.
- Use git to revert if any issues arise.

## Phase 1: Analyze Project Scope

**Goal**: Perform a quick analysis to determine the full project refactoring scope.

**Actions**:

1. Use Glob to find all code files in the project
2. Filter to focus on source code (exclude node_modules, build outputs, etc.)
3. Group files by type/language
4. List primary source code directories
5. Show project structure overview
6. Display scope summary (informational only, no confirmation needed):
   - Total number of files to be refactored
   - Languages/file types detected
   - Main directories involved
   - Note: "Proceeding with project-wide refactoring automatically"

## Phase 2: Launch Refactoring Agent

**Goal**: Execute the code-simplifier agent on the entire project with cross-file optimization focus.

**Actions**:

1. Use Task tool with subagent_type="refactor:code-simplifier"
2. Pass "project-wide scope" indication
3. Pass emphasis on cross-file duplication reduction and consistent patterns
4. Pass aggressive mode flag to apply thorough refactoring, remove legacy code
5. The agent will automatically:
   - Load the refactor:best-practices skill
   - Analyze the entire codebase
   - Detect frameworks, libraries, and languages
   - Discover and apply relevant best practices from skill references
   - Emphasize cross-file duplication and consistent patterns
   - Aggressively refactor: remove backwards-compatibility hacks, unused code, rename properly
   - Preserve functionality while improving clarity, consistency, and maintainability
   - Apply Code Quality Standards as defined in the refactor:best-practices skill

## Phase 3: Summary

**Goal**: Provide comprehensive summary of all project-wide changes made during refactoring.

**Actions**:

1. Report total files refactored (count and percentage of project)
2. Describe what changed and why, categorized by improvement type
3. Report files touched (total count)
4. List best practices applied (which categories/patterns)
5. Document cross-file improvements made (deduplication, consistency)
6. Document quality standards enforced
7. Identify legacy code removed
8. Suggest tests to run
9. Recommend reviewing changes in logical groups
10. Provide git rollback command if needed: `git reset --hard HEAD`

## Requirements

- **NO user confirmations** - execute immediately after displaying scope
- **Refactor entire project** - apply improvements across all discovered code files
- **Aggressive refactoring** - remove legacy compatibility code, unused exports, rename improperly named vars
- Follow the refactor:best-practices workflow and references in the refactor plugin skills
- Let the agent self-discover best practices from skills
- Preserve functionality while improving clarity, consistency, and maintainability
- Emphasize cross-file duplication reduction and consistent patterns
- Apply Code Quality Standards as defined in the refactor:best-practices skill
