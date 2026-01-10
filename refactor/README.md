# Refactor Plugin

Agent and commands for code simplification and refactoring to improve code quality while preserving functionality.

## Overview

The Refactor Plugin provides specialized tools for code simplification and refactoring. It includes an expert code simplifier agent and commands for targeted and project-wide refactoring. All refactoring operations preserve functionality while improving clarity, consistency, and maintainability.

## Agent

### `code-simplifier`

Expert code simplification specialist focused on enhancing code clarity, consistency, and maintainability while preserving exact functionality.

**What it does:**
- Analyzes recently modified code
- Applies refinements that preserve functionality
- Follows project-specific coding standards (CLAUDE.md)
- Enhances code clarity and structure
- Maintains balance between simplicity and clarity

**Focus areas:**
- Preserve Functionality: Never changes what code does - only how it does it
- Apply Project Standards: Follows CLAUDE.md standards
- Enhance Clarity: Simplifies code structure
- Maintain Balance: Avoids over-simplification
- Focus Scope: Refines recently modified code by default

**Model:** Opus

**When triggered:**
- Automatically by `/refactor` and `/refactor-project` commands
- Can be invoked manually: `@code-simplifier Simplify this code`

**Refinement process:**
1. Identifies recently modified code sections
2. Analyzes for opportunities to improve elegance and consistency
3. Applies project-specific best practices and coding standards
4. Ensures all functionality remains unchanged
5. Verifies refined code is simpler and more maintainable
6. Documents only significant changes

**Example usage:**
```
@code-simplifier Simplify the authentication logic in src/auth/login.ts
```

## Commands

### `/refactor`

Refactors code for specific files/directories or recently modified code in the current session.

**What it does:**
1. Identifies target code (specified files/directories or recent changes)
2. Analyzes code using **@code-simplifier** agent for guidance
3. Applies refactoring improvements:
   - Simplifies control flow, reduces nesting
   - Eliminates redundancy
   - Improves readability
   - Maintains functionality
4. Validates changes with tests and lint checks
5. Documents significant changes

**Usage:**
```bash
/refactor
```

Or with specific files:
```bash
/refactor src/auth/login.ts
/refactor src/utils/
```

**Example workflow:**
```bash
# Make some changes to code
# Then refactor recently modified code
/refactor

# Or refactor specific files
/refactor src/auth/
```

**Features:**
- Targets specific files/directories or recent changes
- Uses **@code-simplifier** agent for guidance
- Preserves functionality while improving code
- Applies project standards automatically
- Validates changes with tests

**Scope options:**
1. **Specified files/directories**: If arguments provided, refactors only those
2. **Recently modified code**: If no arguments, focuses on recent changes
3. **Session changes**: Prioritizes files edited in current conversation

### `/refactor-project`

Project-wide code refactoring to improve quality across the entire codebase.

**What it does:**
1. Analyzes entire codebase to identify patterns
2. Finds duplicate code across multiple files
3. Identifies inconsistent patterns
4. Plans and executes refactorings:
   - Consolidates duplicate code
   - Standardizes patterns project-wide
   - Strengthens type safety
   - Updates legacy patterns to modern standards
5. Groups related changes by pattern or module
6. Validates all changes with project-wide tests
7. Creates atomic commits for logical units

**Usage:**
```bash
/refactor-project
```

**Example workflow:**
```bash
# Refactor entire project
/refactor-project

# Claude will:
# - Analyze entire codebase
# - Identify cross-file patterns
# - Consolidate duplicate code
# - Standardize patterns
# - Apply improvements consistently
```

**Features:**
- Project-wide analysis and refactoring
- Cross-file duplication consolidation
- Consistent pattern application
- Type safety strengthening
- Modern standards migration
- Atomic commits for related changes

**Focus areas:**
1. **Cross-File Duplication**: Consolidate duplicate patterns across files
2. **Consistent Patterns**: Ensure similar functionality uses consistent patterns
3. **Type Safety**: Strengthen type annotations across all modules
4. **Modern Standards**: Update legacy patterns to modern best practices
5. **Architecture Alignment**: Ensure code aligns with project architecture

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
