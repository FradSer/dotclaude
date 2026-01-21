---
description: Run project-wide refactoring with code-simplifier
argument-hint: (no arguments needed - refactors entire project)
allowed-tools: ["Task", "AskUserQuestion", "Read", "Write", "Bash(git:*)", "Grep", "Glob"]
---

# Refactor Project Command

## Core Principles

- **Safety first**: Always show preview and require explicit confirmation for project-wide changes
- **Self-discovery**: Agent discovers best practices from skills automatically
- **Cross-file focus**: Emphasize duplication reduction and consistent patterns
- **Use TodoWrite**: Track all progress throughout the workflow

## Context

- This command is for project-wide refactoring across the entire codebase.
- This command supports interactive preview before applying refactoring.

## Initial Setup

**Actions**:
1. Create todo list with all workflow steps:
   - Analyze project scope
   - Confirm scope with user
   - Launch refactoring agent
   - Summarize results
2. Mark current step as in_progress as you proceed through the workflow
3. Complete todos immediately after finishing each step

## Step 1: Analyze Project Scope

Perform a quick analysis to determine the refactoring scope:

1. **Count code files**:
   - Use Glob to find all code files in the project
   - Filter to focus on source code (exclude node_modules, build outputs, etc.)
   - Group by file type/language

2. **Identify main directories**:
   - List primary source code directories
   - Show project structure overview

3. **Prepare scope summary**:
   - Total number of files to be refactored
   - Languages/file types detected
   - Main directories involved

## Step 2: Confirm Scope with User

**CRITICAL**: For project-wide refactoring, ALWAYS show preview and get confirmation.

Show preview summary:
- Total files to be refactored
- Languages detected (e.g., "TypeScript, Python, Go")
- Main directories
- Warning about project-wide scope

Use AskUserQuestion:

**Question: Scope Confirmation**
- header: "Confirm scope"
- question: "This will refactor the entire project. The agent will analyze the code and apply best practices automatically. Are you sure?"
- options:
  - Yes (Proceed with project-wide refactoring)
  - No (Cancel)
  - Targeted (Switch to /refactor for specific files)

If user selects "No", exit without changes.

If user selects "Targeted", suggest using `/refactor` command instead.

## Step 3: Launch Refactoring Agent

If user confirms:

1. Use Task tool with subagent_type="refactor:code-simplifier"
2. Pass:
   - "project-wide scope" indication
   - Emphasis on cross-file duplication reduction and consistent patterns
3. The agent will automatically:
   - Load the refactor:best-practices skill
   - Analyze the entire codebase
   - Detect frameworks, libraries, and languages
   - Discover and apply relevant best practices from skill references
   - Emphasize cross-file duplication and consistent patterns
   - Preserve functionality while improving clarity, consistency, and maintainability
4. **Enforce Code Quality Standards** - The agent must apply these standards during refactoring:
   - **Comments**: Only add comments explaining complex business logic or non-obvious decisions; remove comments that restate code or conflict with file style
   - **Error Handling**: Add try-catch only where errors can be handled/recovered; remove defensive checks in trusted internal paths (validate only at boundaries: user input, external APIs)
   - **Type Safety**: Never use `any` to bypass type issues; use proper types, `unknown` with type guards, or refactor the root cause
   - **Style Consistency**: Match existing code style in file and project; check CLAUDE.md for conventions

## Step 4: Validate and Summary

After completion:

1. **Verify Code Quality Standards** were applied across the project:
   - Comments are meaningful and match file style
   - No unnecessary defensive checks or empty try-catch blocks
   - No `any` types introduced
   - Style is consistent within and across files

2. **Summarize Changes**:
   - What changed and why
   - Files touched (total count)
   - Best practices applied (which categories/patterns)
   - Cross-file improvements made
   - Quality standards enforced
   - Suggested tests to run
   - Recommendation to review changes in logical groups

## Requirements

- Follow the best-practices workflow and references in the refactor plugin skills
- Let the agent self-discover best practices from skills
- Preserve functionality while improving clarity, consistency, and maintainability
- Emphasize cross-file duplication reduction and consistent patterns
- Enforce code quality standards as defined in Step 3
- ALWAYS show preview and get confirmation for project-wide changes
