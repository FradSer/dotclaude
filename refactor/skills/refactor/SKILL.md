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

## Step 1: Determine Target Scope

### If Arguments Provided

1. **Check if arguments are file/directory paths**:
   - Verify if paths exist in the repository
   - If paths exist, use them directly as target scope

2. **If paths don't exist or arguments are semantic descriptions**:
   - Search the codebase for code matching the semantic description
   - **Automatically include ALL matching files** in the refactoring scope
   - No user confirmation needed - trust the search results

### If No Arguments Provided (Default: Session Context)

1. **Identify recently modified files**:
   - Find files that have been recently changed in the repository
   - Filter to focus on code files (exclude configuration, documentation, lock files unless needed)

2. **If no recent changes found**:
   - Inform user that no recent changes were detected
   - Suggest providing specific file/directory paths or semantic descriptions as arguments
   - Exit without refactoring

3. **Automatically proceed**:
   - Use all identified files as refactoring scope
   - Display the file list for transparency, but proceed immediately without asking

## Step 2: Launch Refactoring Agent

Immediately launch the refactoring agent:

1. Use Task tool with subagent_type="refactor:code-simplifier"
2. Pass:
   - Target scope (file paths, semantic search results, or session context)
   - Context about how scope was determined (paths, semantic query, or session context)
   - **Aggressive mode flag**: Apply thorough refactoring, remove legacy code, no compatibility shims
3. The agent will automatically:
   - Load the refactor:best-practices skill
   - Analyze the code and detect languages/frameworks
   - Discover and apply relevant best practices from skill references
   - **Aggressively refactor**: Remove backwards-compatibility hacks, unused code, rename properly
   - Preserve functionality while improving clarity, consistency, and maintainability
   - Apply Code Quality Standards as defined in the refactor:best-practices skill

## Step 3: Summary

After completion:

1. **Summarize Changes**:
   - Total files refactored
   - What changed and why (categorized by improvement type)
   - Best practices applied (which categories/patterns)
   - Quality standards enforced
   - Legacy code removed
   - Suggested tests to run
   - Git rollback command if needed: `git checkout -- <files>`

## Requirements

- **NO user confirmations** - execute immediately based on scope determination
- **Refactor ALL matching files** - when semantic search finds multiple results, refactor them all
- **Aggressive refactoring** - remove legacy compatibility code, unused exports, rename improperly named vars
- Follow the refactor:best-practices workflow and references in the refactor plugin skills
- Let the agent self-discover best practices from skills
- Preserve functionality while improving clarity, consistency, and maintainability
- Apply Code Quality Standards as defined in the refactor:best-practices skill
- If the user requests project-wide refactoring, direct them to use `/refactor-project`
