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
| Skills | `best-practices` |

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

### `best-practices`

Comprehensive refactoring workflow with language-specific best practices and Next.js performance patterns.

**Metadata:**

| Field | Value |
|-------|-------|
| Version | `1.0.0` |

**Scope:**
- Targeted refactoring of recently modified or specified code
- Project-wide refactoring when explicitly requested

**Language References:**

Based on file extension, appropriate reference is loaded:
- `.ts`, `.tsx`, `.js`, `.jsx` → `references/typescript.md`
- `.py` → `references/python.md`
- `.go` → `references/go.md`
- `.swift` → `references/swift.md`
- Universal principles → `references/universal.md`

**Next.js Performance Patterns:**
- 50+ specific optimization patterns organized by category
- `references/nextjs/README.md` - Navigation guide
- `references/nextjs/_sections.md` - Priority categories
- Pattern categories: async, bundle, server, client, rerender, rendering, js

**Workflow:**
1. **Identify**: Determine target scope
2. **Load References**: Load language-specific and Next.js references as needed
3. **Analyze**: Review code for complexity, redundancy, and improvement opportunities
4. **Execute**: Apply behavior-preserving refinements
5. **Validate**: Ensure tests pass and code is cleaner

## Commands

### `/refactor`

Quick refactoring for recently modified or specified code with interactive rule selection.

**Usage:**
```bash
# Refactor recently modified code
/refactor

# Refactor specific files
/refactor src/auth/login.ts
/refactor src/utils/
```

**What it does:**
- Analyzes target code and shows preview of applicable rules
- **Interactive selection**: Lets you choose which rule categories to apply (if configured for interactive mode)
- Launches the `code-simplifier` agent with targeted scope
- Agent automatically loads the `best-practices` skill
- Applies language-specific refactoring based on file extensions
- Respects configuration from `.claude/refactor.local.md`
- Preserves functionality while improving clarity

**Interactive Features:**
- Preview of detected languages and applicable rules
- Multi-select rule categories (Next.js patterns, language-specific, universal)
- Confirmation before applying changes

---

### `/refactor-project`

Project-wide code refactoring for quality and maintainability across the entire codebase.

**Usage:**
```bash
/refactor-project
```

**What it does:**
- Analyzes entire project and shows preview of potential improvements
- **Always interactive**: Shows preview and requires confirmation for project-wide changes
- Launches the `code-simplifier` agent with project-wide scope
- Emphasizes cross-file duplication reduction and consistent patterns
- Loads all relevant language references
- Applies consistent refactoring across the entire codebase
- Respects configuration from `.claude/refactor.local.md`

**Focus Areas:**
1. Cross-file duplication: Consolidate duplicate code patterns into shared utilities
2. Consistent patterns: Standardize similar functionality throughout
3. Type safety: Strengthen type annotations and error handling
4. Modern standards: Update legacy patterns to modern best practices

**Interactive Features:**
- Preview of estimated files affected and changes per category
- Multi-select rule categories
- Confirmation required before proceeding (safety for project-wide changes)

## Language References

The `best-practices` skill includes language-specific refactoring guidelines:

| Language | File | Extensions |
|----------|------|------------|
| TypeScript/JavaScript | `skills/best-practices/references/typescript.md` | `.ts`, `.tsx`, `.js`, `.jsx` |
| Python | `skills/best-practices/references/python.md` | `.py` |
| Go | `skills/best-practices/references/go.md` | `.go` |
| Swift | `skills/best-practices/references/swift.md` | `.swift` |
| Universal | `skills/best-practices/references/universal.md` | All languages |

**Next.js Performance Patterns:**
- 50+ specific patterns in `skills/best-practices/references/nextjs/`
- Categories: async, bundle, server, client, rerender, rendering, js optimization
## Configuration

### Configuration File

The plugin supports per-project configuration via `.claude/refactor.local.md`:

**Location:** `.claude/refactor.local.md` (in project root)

**Format:**
```yaml
---
enabled: true
default_mode: all  # all | selected | weighted
rule_categories:
  nextjs:
    async: true      # Eliminating waterfalls (CRITICAL)
    bundle: true     # Bundle size optimization (CRITICAL)
    server: true     # Server-side performance (HIGH)
    client: true     # Client-side data fetching (MEDIUM-HIGH)
    rerender: true   # Re-render optimization (MEDIUM)
    rendering: true  # Rendering performance (MEDIUM)
    js: true         # JavaScript micro-optimizations (LOW-MEDIUM)
    advanced: true   # Advanced patterns (LOW)
  languages:
    typescript: true
    python: true
    go: true
    swift: true
    universal: true  # Universal principles (SOLID, DRY, KISS, etc.)
weighting_strategy: impact-based  # impact-based | equal | custom
custom_weights: {}
disabled_patterns: []
---
```

**Configuration Options:**
- `enabled`: Enable/disable refactoring (default: true)
- `default_mode`: How rules are applied by default
  - `all`: Apply all applicable rules (no interaction needed)
  - `selected`: Always show interactive selection
  - `weighted`: Apply rules based on weights
- `rule_categories`: Enable/disable specific rule categories
- `weighting_strategy`: How to prioritize rules
  - `impact-based`: CRITICAL > HIGH > MEDIUM > LOW
  - `equal`: All enabled rules have equal priority
  - `custom`: Use `custom_weights` for specific priorities
- `custom_weights`: Override weights for specific rules
- `disabled_patterns`: List of pattern IDs to never apply

**Creating Configuration:**
- **First-time use**: Configuration is automatically set up when you first run `/refactor` or `/refactor-project`
  - You'll be guided through interactive setup questions
  - Configuration file will be created at `.claude/refactor.local.md`
- **Manual setup**: Copy the example file: `cp examples/refactor.local.md .claude/refactor.local.md` and customize
- **Edit existing**: Edit `.claude/refactor.local.md` manually anytime

**Example File:**
- See `examples/refactor.local.md` for a complete example configuration

**Note:** The configuration file is gitignored and won't be committed to your repository.

## Installation

This plugin is included in the Claude Code repository. The agent and commands are automatically available when using Claude Code.

## Best Practices

### Using `/refactor`
- Use for targeted refactoring during development
- Run after making changes to improve code quality
- Review the preview and select appropriate rule categories
- Review refactored code to ensure functionality is preserved
- Use on specific files when focusing on particular areas
- The `code-simplifier` agent will automatically load the `best-practices` skill
- Configuration from `.claude/refactor.local.md` is automatically respected

### Using `/refactor-project`
- Use when starting large refactoring efforts
- **Always review the preview** - shows estimated files affected
- Ensure all tests pass before running
- Review changes carefully - affects entire codebase
- Use for modernizing legacy code
- Group related changes together
- Configuration from `.claude/refactor.local.md` is automatically respected

### Configuration Setup
- **First-time use**: When you first run `/refactor` or `/refactor-project`, you'll be guided through configuration setup
- Choose rule categories that match your project's needs
- Use `selected` mode if you want to choose rules each time
- Use `all` mode for automatic application of all rules (recommended for quick start)
- Use `weighted` mode with custom weights for fine-grained control
- Edit `.claude/refactor.local.md` manually anytime to fine-tune settings

### Using `@code-simplifier` Agent
- Invoke directly for specific code simplification
- Agent automatically loads the `best-practices` skill
- Agent respects configuration from `.claude/refactor.local.md`
- Trust agent's expertise in code quality
- Review changes to ensure they match your preferences

## Workflow Integration

### Initial Setup:
```bash
# First-time use: Configuration is set up automatically
/refactor
# Or for project-wide refactoring:
/refactor-project
# You'll be guided through configuration questions
```

### Development Workflow:
```bash
# Make changes
# Refactor recent changes (with interactive selection if configured)
/refactor
# Review preview and select rules
# Review changes and commit
```

### Targeted Refactoring:
```bash
# Refactor specific module
/refactor src/auth/
# Review preview and select applicable rules
# Review changes
# Commit improvements
```

### Project Modernization:
```bash
# Plan project-wide refactoring
/refactor-project
# Review preview (always shown for safety)
# Select rule categories to apply
# Confirm project-wide changes
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
- **Trust the agent**: `code-simplifier` has deep expertise and automatically loads best practices
- **Review changes**: Always verify functionality is preserved
- **Modernize gradually**: Use project-wide refactoring strategically

## Acknowledgments

**React/Next.js Best Practices:**
- React and Next.js performance optimization guidelines are sourced from [Vercel Engineering's agent-skills repository](https://github.com/vercel-labs/agent-skills/tree/main/skills/react-best-practices)
- Contains 40+ rules across 8 categories, prioritized by impact
- Originally created by [@shuding](https://x.com/shuding) at [Vercel](https://vercel.com)

## Author

Frad LEE (fradser@gmail.com)

## Version

1.0.0
