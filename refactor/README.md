# Refactor Plugin

Agent and commands for code simplification and refactoring to improve code quality while preserving functionality.

## Overview

The Refactor Plugin provides specialized tools for code simplification and refactoring. It includes an expert code simplifier agent and commands for targeted and project-wide refactoring. All refactoring operations preserve functionality while improving clarity, consistency, and maintainability.

## Agent

### `code-simplifier`

Expert code simplification specialist focused on enhancing code clarity, consistency, and maintainability while preserving exact functionality. Adapts scope based on command invocation context.

**Metadata:**

| Field | Value |
|-------|-------|
| Model | `opus` |
| Color | `blue` |
| Tools | `Read`, `Edit`, `MultiEdit`, `Glob`, `Grep`, `Bash` |
| Skills | `refactor`, `refactor-project` |

**Scope Modes:**
1. **Default** - Recently modified code in the current session
2. **Files/Directories** - Specific paths provided in the context
3. **Project-wide** - Entire codebase when explicitly requested

**Universal Principles:**
- **SOLID Principles**: Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion
- **DRY (Don't Repeat Yourself)**: Eliminate code duplication through shared utilities and abstractions
- **KISS (Keep It Simple, Stupid)**: Favor simplicity over cleverness
- **YAGNI (You Aren't Gonna Need It)**: Don't implement features until they're actually needed
- **Convention over Configuration**: Prefer sensible defaults and standard patterns
- **Law of Demeter**: Minimize coupling between components

**Core Principles:**
1. **Preserve Functionality**: Never change what the code does - only how it does it
2. **Apply Language-Specific Standards**: Follow language-specific standards or fall back to CLAUDE.md
3. **Enhance Clarity**: Simplify code structure, reduce complexity, improve readability
4. **Maintain Balance**: Avoid over-simplification that reduces clarity or maintainability

**Refinement Process:**
1. Identify the target code sections based on scope
2. Analyze for opportunities to improve elegance and consistency
3. Apply project-specific best practices and coding standards
4. Ensure all functionality remains unchanged
5. Verify the refined code is simpler and more maintainable
6. Document only significant changes that affect understanding

**Example Usage:**
```
@code-simplifier Simplify the authentication logic in src/auth/login.ts
```

## Skills

### `/refactor:refactor`

Quick refactoring for recently modified or specified code.

**Metadata:**

| Field | Value |
|-------|-------|
| Version | `1.0.0` |
| Context | `fork` |
| Agent | `code-simplifier` |
| Allowed Tools | `Bash(git:*)`, `Read`, `Edit`, `MultiEdit`, `Glob`, `Grep`, `Task` |

**Scope:**
- Refactor recently modified code in the current session
- Or specific files/directories if provided

**Language References:**

Based on file extension, appropriate reference is loaded:
- `.ts`, `.tsx`, `.js`, `.jsx` → `references/typescript.md`
- `.py` → `references/python.md`
- `.go` → `references/go.md`
- `.swift` → `references/swift.md`
- Universal principles → `references/universal.md`

**Workflow:**
1. **Identify**: Determine target scope (specified files or session modifications)
2. **Load References**: Load language-specific references for the files being refactored
3. **Analyze**: Review code for complexity, redundancy, and improvement opportunities
4. **Execute**: Apply refinements following the loaded references
5. **Validate**: Ensure tests pass and code is cleaner

**Usage:**
```bash
# Refactor recently modified code
/refactor

# Refactor specific files
/refactor src/auth/login.ts
/refactor src/utils/
```

---

### `/refactor:refactor-project`

Project-wide code refactoring for quality and maintainability across the entire codebase.

**Metadata:**

| Field | Value |
|-------|-------|
| Version | `1.0.0` |
| Context | `fork` |
| Agent | `code-simplifier` |
| Allowed Tools | `Bash(git:*)`, `Read`, `Edit`, `MultiEdit`, `Glob`, `Grep`, `Task` |

**Scope:**

Refactor the entire codebase when explicitly requested, focusing on:
1. **Cross-file patterns**: Identify and consolidate duplicate code patterns across multiple files
2. **Consistent standards**: Ensure similar functionality uses consistent patterns throughout the codebase
3. **Architecture alignment**: Ensure code aligns with project architecture and conventions

**Language References:**

Based on file extensions found in the project, appropriate references are loaded:
- `.ts`, `.tsx`, `.js`, `.jsx` → `references/typescript.md`
- `.py` → `references/python.md`
- `.go` → `references/go.md`
- `.swift` → `references/swift.md`
- Universal principles → `references/universal.md`

**Workflow:**
1. **Assessment**: Analyze codebase structure and identify complexity hotspots
2. **Load References**: Load language-specific references for all languages used in the project
3. **Pattern Analysis**: Find cross-file duplication and inconsistent patterns
4. **Execute**: Apply refinements consistently following the loaded references
5. **Validate**: Ensure tests pass and code quality improves

**Focus Areas:**
1. **Cross-File Duplication**: Consolidate duplicate code patterns into shared utilities
2. **Consistent Patterns**: Standardize similar functionality throughout the codebase
3. **Type Safety**: Strengthen type annotations and error handling
4. **Modern Standards**: Update legacy patterns to modern best practices

**Usage:**
```bash
/refactor-project
```

## Language References

The plugin includes language-specific refactoring guidelines:

| Language | File | Extensions |
|----------|------|------------|
| TypeScript/JavaScript | `references/typescript.md` | `.ts`, `.tsx`, `.js`, `.jsx` |
| Python | `references/python.md` | `.py` |
| Go | `references/go.md` | `.go` |
| Swift | `references/swift.md` | `.swift` |
| Universal | `references/universal.md` | All languages |

## Installation

This plugin is included in the Claude Code repository. The agent and commands are automatically available when using Claude Code.

## Best Practices

### Using `/refactor`
- Use for targeted refactoring during development
- Run after making changes to improve code quality
- Review refactored code to ensure functionality is preserved
- Use on specific files when focusing on particular areas
- Let **@code-simplifier** agent guide improvements

### Using `/refactor-project`
- Use when starting large refactoring efforts
- Ensure all tests pass before running
- Review changes carefully - affects entire codebase
- Use for modernizing legacy code
- Group related changes together

### Using `@code-simplifier` Agent
- Invoke directly for specific code simplification
- Use as guidance in refactoring commands
- Trust agent's expertise in code quality
- Review changes to ensure they match your preferences

## Workflow Integration

### Development Workflow:
```bash
# Make changes
# Refactor recent changes
/refactor
# Review and commit
```

### Targeted Refactoring:
```bash
# Refactor specific module
/refactor src/auth/
# Review changes
# Commit improvements
```

### Project Modernization:
```bash
# Plan project-wide refactoring
/refactor-project
# Review all changes
# Commit in logical groups
# Run full test suite
```

## Requirements

- Git repository for change tracking
- Project with CLAUDE.md standards (recommended)
- Test suite for validation
- Lint/build tools for quality checks

## Troubleshooting

### Refactoring changes too much

**Issue**: Refactoring makes extensive changes

**Solution**:
- Use `/refactor` with specific files for targeted changes
- Review changes before committing
- Refactor incrementally rather than all at once
- Verify functionality is preserved with tests

### Functionality breaks after refactoring

**Issue**: Refactored code doesn't work correctly

**Solution**:
- Run test suite after refactoring
- Review changes carefully
- Agent preserves functionality by design
- Report issues if they occur
- Use git to revert if needed

### Project refactoring takes too long

**Issue**: `/refactor-project` is slow on large codebase

**Solution**:
- This is normal for large projects
- Refactor incrementally by module
- Use `/refactor` for specific areas first
- Consider splitting large refactoring into phases

## Tips

- **Refactor frequently**: Keep code clean during development
- **Use targeted refactoring**: Focus on specific areas when needed
- **Trust the agent**: **@code-simplifier** has deep expertise
- **Review changes**: Always verify functionality is preserved
- **Modernize gradually**: Use project-wide refactoring strategically

## Author

Frad LEE (fradser@gmail.com)

## Version

1.0.0
