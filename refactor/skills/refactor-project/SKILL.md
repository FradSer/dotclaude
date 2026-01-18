---
name: refactor-project
description: Project-wide code refactoring for quality and maintainability across the entire codebase. Use when requested to refactor the whole project or improve code quality project-wide.
version: 1.0.0
context: fork
agent: code-simplifier
---

# Code Refactoring (Project)

## Scope

Refactor the entire codebase when explicitly requested, focusing on:

1. **Cross-file patterns**: Identify and consolidate duplicate code patterns across multiple files
2. **Consistent standards**: Ensure similar functionality uses consistent patterns throughout the codebase
3. **Architecture alignment**: Ensure code aligns with project architecture and conventions

## Language Reference

Based on file extensions found in the project, load the appropriate references:

- `.ts`, `.tsx`, `.js`, `.jsx` → See [references/typescript.md](references/typescript.md)
- `.py` → See [references/python.md](references/python.md)
- `.go` → See [references/go.md](references/go.md)
- `.swift` → See [references/swift.md](references/swift.md)

For universal principles applicable to all languages, see [references/universal.md](references/universal.md).

## Workflow

1. **Assessment**: Analyze codebase structure and identify complexity hotspots
2. **Load References**: Load language-specific references for all languages used in the project
3. **Pattern Analysis**: Find cross-file duplication and inconsistent patterns
4. **Execute**: Apply refinements consistently following the loaded references
5. **Validate**: Ensure tests pass and code quality improves

## Focus Areas

1. **Cross-File Duplication**: Consolidate duplicate code patterns into shared utilities
2. **Consistent Patterns**: Standardize similar functionality throughout the codebase
3. **Type Safety**: Strengthen type annotations and error handling
4. **Modern Standards**: Update legacy patterns to modern best practices
