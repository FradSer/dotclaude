---
description: Refactor code with code-simplifier
argument-hint: [files-or-directories-or-semantic-query]
allowed-tools: ["Task", "AskUserQuestion", "Read", "Write", "Bash(git:*)", "Grep", "Glob"]
---

# Refactor Command

## Core Principles

- **Self-discovery**: Agent discovers best practices from skills automatically
- **Interactive and safe**: Show preview and get user confirmation before making changes
- **Use TodoWrite**: Track all progress throughout the workflow

## Context

- **If arguments are provided**:
  - First, check if they are valid file/directory paths relative to the repo root.
  - If paths exist, treat them as target paths.
  - If paths don't exist or arguments contain semantic descriptions (e.g., "authentication logic", "user login components"), search the codebase for code matching that description.
- **If no arguments are provided**:
  - Default to refactoring code associated with the current session context.
  - Identify recently modified files from the current session.
  - If no recent changes are found, inform user to provide specific file/directory paths.

## Initial Setup

**Actions**:
1. Create todo list with all workflow steps:
   - Determine target scope
   - Confirm scope with user
   - Launch refactoring agent
   - Summarize results
2. Mark current step as in_progress as you proceed through the workflow
3. Complete todos immediately after finishing each step

## Step 1: Determine Target Scope

### If Arguments Provided

1. **Check if arguments are file/directory paths**:
   - Verify if paths exist in the repository
   - If paths exist, use them directly as target scope

2. **If paths don't exist or arguments are semantic descriptions**:
   - Search the codebase for code matching the semantic description
   - Collect relevant file paths from the search
   - If multiple results, use AskUserQuestion to confirm scope:
     - header: "Confirm scope"
     - question: "Found multiple files matching your query. Which should be refactored?"
     - multiSelect: true
     - options: [List of file paths from search results]

### If No Arguments Provided (Default: Session Context)

1. **Identify recently modified files**:
   - Find files that have been recently changed in the repository
   - Filter to focus on code files (exclude configuration, documentation, lock files unless needed)

2. **If no recent changes found**:
   - Inform user that no recent changes were detected
   - Suggest providing specific file/directory paths or semantic descriptions as arguments

3. **Present scope to user**:
   - Show identified files
   - Use AskUserQuestion to confirm:
     - header: "Confirm scope"
     - question: "I found these files related to recent changes. Should I refactor them?"
     - multiSelect: true
     - options: [List of identified files]

## Step 2: Launch Refactoring Agent

After user confirms the scope:

1. Use Task tool with subagent_type="refactor:code-simplifier"
2. Pass:
   - Target scope (file paths, semantic search results, or session context)
   - Context about how scope was determined (paths, semantic query, or session context)
3. The agent will automatically:
   - Load the refactor:best-practices skill
   - Analyze the code and detect languages/frameworks
   - Discover and apply relevant best practices from skill references
   - Preserve functionality while improving clarity, consistency, and maintainability
4. **Enforce Code Quality Standards** - The agent must apply these standards during refactoring:
   - **Comments**: Only add comments explaining complex business logic or non-obvious decisions; remove comments that restate code or conflict with file style
   - **Error Handling**: Add try-catch only where errors can be handled/recovered; remove defensive checks in trusted internal paths (validate only at boundaries: user input, external APIs)
   - **Type Safety**: Never use `any` to bypass type issues; use proper types, `unknown` with type guards, or refactor the root cause
   - **Style Consistency**: Match existing code style in file and project; check CLAUDE.md for conventions

## Step 3: Validate and Summary

After completion:

1. **Verify Code Quality Standards** were applied:
   - Comments are meaningful and match file style
   - No unnecessary defensive checks or empty try-catch blocks
   - No `any` types introduced
   - Style is consistent with surrounding code

2. **Summarize Changes**:
   - What changed and why
   - Files touched
   - Best practices applied (which categories/patterns)
   - Quality standards enforced
   - Suggested tests to run

## Requirements

- Follow the best-practices workflow and references in the refactor plugin skills
- Let the agent self-discover best practices from skills
- Preserve functionality while improving clarity, consistency, and maintainability
- Enforce code quality standards as defined in Step 2
- If the user requests project-wide refactoring, direct them to use `/refactor-project`
