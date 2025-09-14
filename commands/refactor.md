---
allowed-tools: Bash(git:*), Read, Edit, MultiEdit, Glob, Grep, Task
description: Systematic code refactoring to improve quality while preserving functionality
---

## Context

- Current git status: !`git status`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -5`
- Code complexity indicators: Analyze files for functions >20 lines, nested conditionals, duplication
- Project structure: !`find . -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.java" -o -name "*.go" | head -20`

## Requirements

- Commit message title must be entirely lowercase
- Title must be less than 50 characters
- Follow conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
- Use atomic commits for logical units of work

## Your task

Systematically improve code quality through structural refactoring while preserving functionality. Target files/areas specified in $ARGUMENTS or analyze entire codebase if no specific target given.

### Refactoring Process

1. **Initial Assessment**
   - Analyze current branch status and code structure
   - Identify complexity indicators: long functions, nested conditionals, duplication
   - Search codebase to understand existing patterns and conventions

2. **Analysis and Planning**
   - Use Task tool with code-simplifier agent for comprehensive analysis
   - Prioritize improvements by impact: readability, maintainability, performance
   - Plan atomic refactoring steps to avoid breaking changes

3. **Apply Refactoring Techniques**
   - **Eliminate redundancy**: Extract common logic, apply DRY principle
   - **Reduce complexity**: Use guard clauses, early returns, break down large functions
   - **Modernize syntax**: Leverage built-in features and idiomatic expressions
   - **Improve structure**: Apply SOLID principles, enhance separation of concerns
   - **Enhance error handling**: Add meaningful error messages for all scenarios
   - **Strengthen typing**: Avoid loose types, use specific types throughout

4. **Validation**
   - **CRITICAL**: Never modify existing tests - only run them to validate
   - Test thoroughly using existing test suite to ensure functionality preserved
   - Run lint and build checks to ensure code quality standards
   - Verify no regressions through comprehensive validation

5. **Automatic Commits**
   - **Stage and commit each logical refactoring unit automatically**
   - Commit message title must be entirely lowercase
   - Title must be less than 50 characters
   - Follow conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
   - Use atomic commits for logical units of work
   - Ensure clean working directory before committing
   - **Push commits automatically** after all refactoring is complete

### Focus Areas

- Extract methods from functions >20 lines
- Replace magic numbers with named constants
- Simplify complex conditional logic
- Remove code duplication
- Improve naming conventions
- Apply modern language features and best practices
