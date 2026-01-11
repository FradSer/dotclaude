---
allowed-tools: Bash(git:*), Read, Edit, MultiEdit, Glob, Grep, Task
description: Refactor code for specific files/directories or recently modified code in the current session, improving clarity and maintainability while preserving functionality
argument-hint: [files-or-directories]
---

## Scope

**Focus on one of the following:**

1. **Specified files/directories**: If `$ARGUMENTS` are provided, refactor only those files or directories
2. **Recently modified code**: If no arguments, focus on code that has been recently modified or touched in the current session

## Your Task

**IMPORTANT: You MUST use the Task tool to complete ALL tasks.**

Invoke **@code-simplifier** agent with the appropriate scope:

- If `$ARGUMENTS` provided: "Refactor these files/directories: `$ARGUMENTS`"
- If no arguments: "Refactor code modified in the current session"

The agent will apply all refactoring principles (preserve functionality, apply project standards, enhance clarity, maintain balance).

### Workflow

1. **Identify**: Determine target scope (arguments or session modifications)
2. **Analyze**: Review code for complexity, redundancy, and improvement opportunities
3. **Execute**: Apply refinements via **@code-simplifier**
4. **Validate**: Ensure tests pass and code is cleaner
