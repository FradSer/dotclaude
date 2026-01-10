---
allowed-tools: Bash(git:*), Read, Edit, MultiEdit, Glob, Grep, Task
description: Refactor code for specific files/directories or recently modified code in the current session, improving clarity and maintainability while preserving functionality
argument-hint: [files-or-directories]
---

## Context

- Current git status: !`git status`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -5`
- Recently modified files: !`git diff --name-only HEAD`
- Files modified in current session: Check conversation history for files that were edited or created

## Scope

**Focus on one of the following:**

1. **Specified files/directories**: If `$ARGUMENTS` are provided, refactor only those files or directories
2. **Recently modified code**: If no arguments, focus on code that has been recently modified or touched in the current session
3. **Session changes**: Prioritize files that were edited, created, or discussed in the current conversation

## Requirements

- **Preserve Functionality**: Never change what the code does - only how it does it. All original features, outputs, and behaviors must remain intact.
- **Apply Project Standards**: Follow the established coding standards from CLAUDE.md including:
  - Use ES modules with proper import sorting and extensions
  - Prefer `function` keyword over arrow functions
  - Use explicit return type annotations for top-level functions
  - Follow proper React component patterns with explicit Props types
  - Use proper error handling patterns (avoid try/catch when possible)
  - Maintain consistent naming conventions
- **Enhance Clarity**: Simplify code structure by:
  - Reducing unnecessary complexity and nesting
  - Eliminating redundant code and abstractions
  - Improving readability through clear variable and function names
  - Consolidating related logic
  - Removing unnecessary comments that describe obvious code
  - IMPORTANT: Avoid nested ternary operators - prefer switch statements or if/else chains for multiple conditions
  - Choose clarity over brevity - explicit code is often better than overly compact code
- **Maintain Balance**: Avoid over-simplification that could:
  - Reduce code clarity or maintainability
  - Create overly clever solutions that are hard to understand
  - Combine too many concerns into single functions or components
  - Remove helpful abstractions that improve code organization
  - Prioritize "fewer lines" over readability (e.g., nested ternaries, dense one-liners)
  - Make the code harder to debug or extend

## Your Task

**IMPORTANT: You MUST use the Task tool to complete ALL tasks.**

1. **Identify Target Code**:
   - If `$ARGUMENTS` provided: Focus on specified files/directories
   - If no arguments: Identify recently modified code sections from git diff and session history
   - Use **@code-simplifier** agent for guidance on refactoring principles

2. **Analyze and Refactor**:
   - Analyze for opportunities to improve elegance and consistency
   - Apply project-specific best practices and coding standards
   - Simplify control flow, reduce nesting, eliminate redundancy
   - Ensure all functionality remains unchanged

3. **Validate and Document**:
   - Verify the refactored code is clearer and more maintainable
   - Run existing tests to ensure behavior is preserved
   - Run lint/build checks
   - Document only significant changes that affect understanding

### Refactoring Workflow

- **Identification**: Determine target scope (arguments, recent changes, or session modifications)
- **Analysis**: Review code for complexity, redundancy, and opportunities for improvement
- **Planning**: Prioritize refactorings by impact on readability and maintainability
- **Execution**: Apply refinements using **@code-simplifier** principles:
  - Break down large functions into focused helpers
  - Replace nested conditionals with guard clauses and early returns
  - Remove redundant branches and dead code
  - Adopt idiomatic language features
  - Use descriptive variable and function names
- **Validation**: Ensure functionality is preserved, tests pass, and code is cleaner

### Commit Guidelines (if changes are made)

- **Use atomic commits for logical units of work**: Each commit should represent one complete, cohesive change
- Title: entirely lowercase, <50 chars, imperative mood, conventional commits format (refactor:, chore:)
  - Scope (optional): lowercase noun, 1-2 words. Must match existing scopes in git history.
- Body: blank line after title, ≤72 chars per line, must start with uppercase letter, standard capitalization and punctuation. Describe what changed and why, not how.

### Example Commit

```
refactor(auth): improve login flow structure

- Extract validation logic into separate helper function
- Replace nested ternary with if/else chain for clarity
- Remove redundant error handling branches
- Improve variable naming for better readability

Improves code maintainability without changing functionality.
```
