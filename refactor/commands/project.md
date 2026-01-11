---
allowed-tools: Bash(git:*), Read, Edit, MultiEdit, Glob, Grep, Task
description: Project-wide code refactoring to improve quality and maintainability while preserving functionality across the entire codebase
---

## Scope

**Project-wide refactoring**: Analyze and refactor code across the entire codebase, focusing on:

1. **Cross-file patterns**: Identify and consolidate duplicate code patterns across multiple files
2. **Consistent standards**: Ensure similar functionality uses consistent patterns throughout the codebase
3. **Architecture alignment**: Ensure code aligns with project architecture and conventions

## Your Task

**IMPORTANT: You MUST use the Task tool to complete ALL tasks.**

Invoke **@code-simplifier** agent with project-wide scope: "Refactor the entire codebase"

The agent will apply all refactoring principles (preserve functionality, apply project standards, enhance clarity, maintain balance) while focusing on project-wide improvements.

### Workflow

1. **Assessment**: Analyze codebase structure and identify complexity hotspots
2. **Pattern Analysis**: Find cross-file duplication and inconsistent patterns
3. **Execute**: Apply refinements consistently via **@code-simplifier**
4. **Validate**: Ensure tests pass and code quality improves

### Focus Areas

1. **Cross-File Duplication**: Consolidate duplicate code patterns into shared utilities
2. **Consistent Patterns**: Standardize similar functionality throughout the codebase
3. **Type Safety**: Strengthen type annotations and error handling
4. **Modern Standards**: Update legacy patterns to modern best practices
