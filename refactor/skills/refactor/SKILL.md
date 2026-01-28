---
name: refactor
description: Refactor code with code-simplifier
argument-hint: [files-or-directories-or-semantic-query]
allowed-tools: ["Task", "Read", "Write", "Bash(git:*)", "Grep", "Glob"]
user-invocable: true
---

# Refactor Command

## Core Principles

- **Fully automated**: Execute refactoring immediately without user confirmation
- **Aggressive refactoring**: Apply thorough improvements, remove legacy compatibility code
- **Self-discovery**: Agent discovers best practices from skills automatically
- **Git safety net**: Trust git to revert if needed, no preview confirmations

## Context

- **If arguments are provided**:
  - First, check if they are valid file/directory paths relative to the repo root.
  - If paths exist, treat them as target paths.
  - If paths don't exist or arguments contain semantic descriptions (e.g., "authentication logic", "user login components"), search the codebase for code matching that description.
- **If no arguments are provided**:
  - Default to refactoring code associated with the current session context.
  - Identify recently modified files from the current session.
  - If no recent changes are found, inform user to provide specific file/directory paths.

## Phase 1: Determine Target Scope

**Goal**: Identify and validate the files or directories to refactor based on arguments or session context.

**Actions**:

### If Arguments Provided

1. Check if arguments are file/directory paths by verifying if paths exist in the repository
2. If paths exist, use them directly as target scope
3. If paths don't exist or arguments are semantic descriptions, search the codebase for code matching the semantic description
4. Automatically include ALL matching files in the refactoring scope without user confirmation

### If No Arguments Provided (Default: Session Context)

1. Identify recently modified files that have been changed in the repository
2. Filter to focus on code files (exclude configuration, documentation, lock files unless needed)
3. If no recent changes found, inform user that no recent changes were detected and suggest providing specific file/directory paths or semantic descriptions as arguments, then exit without refactoring
4. Automatically proceed using all identified files as refactoring scope, displaying the file list for transparency

## Phase 2: Launch Refactoring Agent

**Goal**: Execute the code-simplifier agent on the determined scope with aggressive refactoring enabled.

**Actions**:

1. Use Task tool with subagent_type="refactor:code-simplifier"
2. Pass target scope (file paths, semantic search results, or session context)
3. Pass context about how scope was determined (paths, semantic query, or session context)
4. Pass aggressive mode flag to apply thorough refactoring, remove legacy code, no compatibility shims
5. The agent will automatically:
   - Load the refactor:best-practices skill
   - Analyze the code and detect languages/frameworks
   - Discover and apply relevant best practices from skill references
   - Aggressively refactor: remove backwards-compatibility hacks, unused code, rename properly
   - Preserve functionality while improving clarity, consistency, and maintainability
   - Apply Code Quality Standards as defined in the refactor:best-practices skill

## Phase 3: Summary

**Goal**: Provide comprehensive summary of all changes made during refactoring.

**Actions**:

1. Report total files refactored
2. Describe what changed and why, categorized by improvement type
3. List best practices applied (which categories/patterns)
4. Document quality standards enforced
5. Identify legacy code removed
6. Suggest tests to run
7. Provide git rollback command if needed: `git checkout -- <files>`

## Requirements

- **NO user confirmations** - execute immediately based on scope determination
- **Refactor ALL matching files** - when semantic search finds multiple results, refactor them all
- **Aggressive refactoring** - remove legacy compatibility code, unused exports, rename improperly named vars
- Follow the refactor:best-practices workflow and references in the refactor plugin skills
- Let the agent self-discover best practices from skills
- Preserve functionality while improving clarity, consistency, and maintainability
- Apply Code Quality Standards as defined in the refactor:best-practices skill
- If the user requests project-wide refactoring, direct them to use `/refactor-project`
