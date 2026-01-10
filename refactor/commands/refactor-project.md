---
allowed-tools: Bash(git:*), Read, Edit, MultiEdit, Glob, Grep, Task
description: Project-wide code refactoring to improve quality and maintainability while preserving functionality across the entire codebase
---

## Context

- Current git status: !`git status`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`
- Project structure: !`find . -type f -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.java" -o -name "*.go" | head -50`
- Complexity indicators: Identify functions >20 lines, nested conditionals, duplicated logic across the entire project

## Scope

**Project-wide refactoring**: Analyze and refactor code across the entire codebase, focusing on:

1. **Cross-file patterns**: Identify and consolidate duplicate code patterns across multiple files
2. **Consistent standards**: Ensure similar functionality uses consistent patterns throughout the codebase
3. **Project-wide improvements**: Apply refactorings that benefit the entire codebase
4. **Architecture alignment**: Ensure code aligns with project architecture and conventions

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

1. **Identify Project-Wide Patterns**:
   - Analyze the entire codebase to identify duplicate code patterns across multiple files
   - Find inconsistent patterns that should be standardized
   - Identify complexity hotspots and opportunities for improvement
   - Use **@code-simplifier** agent for guidance on refactoring principles

2. **Plan and Execute Refactorings**:
   - Group related changes by pattern or module
   - Prioritize improvements by impact on readability and maintainability
   - Apply project-specific best practices and coding standards consistently
   - Simplify control flow, reduce nesting, eliminate redundancy across the project
   - Ensure all functionality remains unchanged

3. **Validate and Document**:
   - Verify refactored code is clearer and more maintainable
   - Run existing tests to ensure behavior is preserved across the entire project
   - Run lint/build checks for the full codebase
   - Document only significant changes that affect understanding

### Project-Wide Refactoring Workflow

- **Assessment**: Inspect branch status, catalogue complexity hot spots across the entire codebase, and search for existing patterns to align with project conventions
- **Analysis**: Review codebase for cross-file duplication, inconsistent patterns, and opportunities for improvement
- **Planning**: Prioritize refactorings by impact on readability and maintainability; group related changes by pattern or module; map steps into Task tool actions
- **Execution**: Apply refinements using **@code-simplifier** principles consistently across modules:
  - Break down large functions into focused helpers
  - Replace nested conditionals with guard clauses and early returns
  - Remove redundant branches and dead code
  - Consolidate duplicate code patterns into shared utilities
  - Adopt idiomatic language features
  - Use descriptive variable and function names
  - Standardize error handling and type annotations
- **Validation**: Ensure functionality is preserved, tests pass across the entire project, and code is cleaner and more consistent

### Focus Areas

1. **Cross-File Duplication**: Identify and consolidate duplicate code patterns across multiple files
2. **Consistent Patterns**: Ensure similar functionality uses consistent patterns throughout the codebase
3. **Type Safety**: Strengthen type annotations and error handling across all modules
4. **Modern Standards**: Update legacy patterns to modern best practices project-wide
5. **Architecture Alignment**: Ensure refactored code aligns with project architecture and conventions

### Commit Guidelines

- **Use atomic commits for logical units of work**: Each commit should represent one complete, cohesive change across related files
- Group related changes together (e.g., all error handling improvements in one commit, all import modernizations in another)
- Title: entirely lowercase, <50 chars, imperative mood, conventional commits format (refactor:, chore:)
  - Scope (optional): lowercase noun, 1-2 words. Must match existing scopes in git history.
- Body: blank line after title, ≤72 chars per line, must start with uppercase letter, standard capitalization and punctuation. Describe what changed and why, not how.

### Example Commits

```
refactor: consolidate duplicate error handling

- Extract common error handling logic into utility functions
- Standardize error response format across API endpoints
- Remove redundant try/catch blocks in favor of guard clauses
- Update error types to be consistent throughout codebase

Improves maintainability and reduces code duplication across
the project.
```

```
refactor: modernize import statements project-wide

- Convert CommonJS require() to ES6 import/export
- Add file extensions to all import statements
- Sort imports consistently across all modules
- Remove unused imports discovered during migration

Aligns codebase with modern JavaScript standards and improves
build performance.
```

```
refactor: consolidate utility functions across modules

- Merge similar helper functions into shared utils
- Remove redundant implementations found in 15+ files
- Create centralized utility modules by category
- Update all references to use consolidated functions

Reduces code duplication and improves maintainability across
the entire project.
```
