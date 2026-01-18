---
name: refactor
description: Quick refactoring for recently modified or specified code. Use when refactoring code, cleaning up after implementation, or improving code quality.
version: 1.0.0
context: fork
agent: code-simplifier
allowed-tools: Bash(git:*), Read, Edit, MultiEdit, Glob, Grep, Task
---

# Code Refactoring (Quick)

## Scope

Refactor recently modified code in the current session, or specific files/directories if provided.

## Language Reference

Based on file extension, load the appropriate reference:

- `.ts`, `.tsx`, `.js`, `.jsx` → See [references/typescript.md](references/typescript.md)
- `.py` → See [references/python.md](references/python.md)
- `.go` → See [references/go.md](references/go.md)
- `.swift` → See [references/swift.md](references/swift.md)

For universal principles applicable to all languages, see [references/universal.md](references/universal.md).

## Workflow

1. **Identify**: Determine target scope (specified files or session modifications)
2. **Load References**: Load language-specific references for the files being refactored
3. **Analyze**: Review code for complexity, redundancy, and improvement opportunities
4. **Execute**: Apply refinements following the loaded references
5. **Validate**: Ensure tests pass and code is cleaner
