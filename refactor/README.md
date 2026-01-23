# Refactor Plugin

Agent and skills for code simplification and refactoring to improve code quality while preserving functionality.

## Overview

The Refactor Plugin provides specialized tools for code simplification and refactoring. It includes an expert code simplifier agent and skills for targeted and project-wide refactoring. All refactoring operations preserve functionality while improving clarity, consistency, and maintainability.

## Agent

### `code-simplifier`

Expert code simplification specialist that enhances code clarity, consistency, and maintainability while preserving exact functionality. Automatically loads the `best-practices` skill (via frontmatter declaration) and applies language-specific standards based on your project.

**Scope Modes:**
- **Targeted**: Recently modified code or specific files/directories
- **Project-wide**: Entire codebase when explicitly requested (via `/refactor-project`)

**Example Usage:**
```
@code-simplifier Simplify the authentication logic in src/auth/login.ts
```

For detailed principles and workflow, see [code-simplifier.md](agents/code-simplifier.md) and [SKILL.md](skills/best-practices/SKILL.md).


## Skills

### `best-practices`

Comprehensive refactoring workflow with language-specific best practices and Next.js performance patterns.

**Metadata:**

| Field | Value |
|-------|-------|
| Version | `1.2.0` |
| User-invocable | No (internal skill) |

**Scope:**
- Targeted refactoring of recently modified or specified code
- Project-wide refactoring when explicitly requested

**Language References:**

Based on file extension, appropriate reference is loaded:
- `.ts`, `.tsx`, `.js`, `.jsx` → [typescript.md](skills/best-practices/references/typescript.md)
- `.py` → [python.md](skills/best-practices/references/python.md)
- `.go` → [go.md](skills/best-practices/references/go.md)
- `.swift` → [swift.md](skills/best-practices/references/swift.md)
- Universal principles → [universal.md](skills/best-practices/references/universal.md)

**Next.js Performance Patterns:**
- 47 performance optimization patterns organized by impact level and category
- See [SKILL.md](skills/best-practices/SKILL.md) for complete pattern index and usage guidance

**Code Quality Standards:**
- Comments: Only for complex business logic
- Error Handling: Only at system boundaries
- Type Safety: Never use `any` types
- Style Consistency: Match existing code patterns

**Workflow:**
1. **Identify**: Determine target scope
2. **Detect**: Identify frameworks and languages
3. **Load References**: Load language-specific and framework references
4. **Filter Rules**: Apply only relevant rules
5. **Analyze**: Review code for improvements
6. **Execute**: Apply behavior-preserving refinements following Code Quality Standards
7. **Validate**: Ensure tests pass and code is cleaner

### `/refactor`

Quick refactoring for recently modified or specified code.

**Metadata:**

| Field | Value |
|-------|-------|
| User-invocable | Yes |

**Usage:**
```bash
# Refactor recently modified code
/refactor

# Refactor specific files
/refactor src/auth/login.ts
/refactor src/utils/
```

Launches the `code-simplifier` agent with targeted scope, automatically applies language-specific refactoring, and preserves functionality while improving clarity.

---

### `/refactor-project`

Project-wide code refactoring for quality and maintainability across the entire codebase.

**Metadata:**

| Field | Value |
|-------|-------|
| User-invocable | Yes |

**Usage:**
```bash
/refactor-project
```

Launches the `code-simplifier` agent with project-wide scope, emphasizing cross-file duplication reduction, consistent patterns, and modern standards.

## Language References

The `best-practices` skill includes language-specific refactoring guidelines for TypeScript, JavaScript, Python, Go, and Swift. Universal principles apply to all languages. See [SKILL.md](skills/best-practices/SKILL.md) for the complete reference guide and framework detection logic.

## Example Refactoring

### TypeScript: Reducing Complexity

**Before:**
```typescript
function processUser(user: any) {
  if (user) {
    if (user.age) {
      if (user.age >= 18) {
        if (user.verified) {
          return { status: 'active', user: user };
        } else {
          return { status: 'unverified', user: user };
        }
      } else {
        return { status: 'minor', user: user };
      }
    }
  }
  return { status: 'invalid', user: null };
}
```

**After:**
```typescript
interface User {
  age: number;
  verified: boolean;
}

function processUser(user: User | null): { status: string; user: User | null } {
  // Early returns for guard clauses
  if (!user?.age) {
    return { status: 'invalid', user: null };
  }

  if (user.age < 18) {
    return { status: 'minor', user };
  }

  const status = user.verified ? 'active' : 'unverified';
  return { status, user };
}
```

**Improvements:**
- Eliminated nested conditionals with guard clauses
- Added proper TypeScript types
- Reduced cognitive complexity from high to low
- Made logic flow more obvious and testable

### Next.js: Eliminating Waterfalls (CRITICAL)

Demonstrates parallelizing independent async operations to eliminate sequential waterfalls, reducing loading time by up to 66%. See [async-parallel.md](skills/best-practices/references/nextjs/async-parallel.md) for detailed examples and patterns.

### Python: Applying DRY and Type Safety

Demonstrates eliminating code duplication using Enums and type hints, reducing logic complexity while improving type safety. See [python.md](skills/best-practices/references/python.md) for comprehensive Python refactoring patterns.

## Installation

This plugin is included in the Claude Code repository. The agent and skills are automatically available when using Claude Code.

## Best Practices

### Using `/refactor`
- Use for targeted refactoring during development
- Run after making changes to improve code quality
- Review refactored code to ensure functionality is preserved
- Use on specific files when focusing on particular areas
- The `code-simplifier` agent will automatically load the `best-practices` skill

### Using `/refactor-project`
- Use when starting large refactoring efforts
- Ensure all tests pass before running
- Review changes carefully - affects entire codebase
- Use for modernizing legacy code
- Group related changes together

### Using `@code-simplifier` Agent
- Invoke directly for specific code simplification
- Agent automatically loads the `best-practices` skill (via frontmatter declaration)
- Trust agent's expertise in code quality
- Review changes to ensure they match your preferences

## Workflow Integration

### Initial Setup:
```bash
# Use targeted refactoring for recent changes
/refactor
# Or for project-wide refactoring:
/refactor-project
```

### Development Workflow:
```bash
# Make changes
# Refactor recent changes
/refactor
# Review changes and commit
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
- **Trust the agent**: `code-simplifier` has deep expertise and automatically loads best practices
- **Review changes**: Always verify functionality is preserved
- **Modernize gradually**: Use project-wide refactoring strategically

## FAQ

### Q: Will refactoring break my code?

**A:** No. The `code-simplifier` agent is designed to preserve functionality while improving code quality. All refactoring operations maintain the exact same behavior - they only change *how* the code does something, never *what* it does. However, always review changes and run your test suite after refactoring to ensure everything works as expected.

### Q: How do I disable specific rules or patterns?

**A:** The refactoring plugin applies best practices automatically based on detected frameworks and languages. For fine-grained control over specific patterns, you can provide feedback to the agent during refactoring to skip certain changes.

You can find rule IDs in the YAML frontmatter of each pattern file in [skills/best-practices/references/](skills/best-practices/references/).

### Q: Can I use this with frameworks other than Next.js?

**A:** Yes! The plugin supports:
- **TypeScript/JavaScript**: React, Vue, Angular, Node.js, or any JS/TS project
- **Python**: Django, Flask, FastAPI, or any Python project
- **Go**: Any Go project
- **Swift**: iOS, macOS, or any Swift project
- **Universal principles**: Apply to all languages (SOLID, DRY, KISS, YAGNI)

The Next.js patterns are only applied when Next.js code is detected in your project.

### Q: What's the difference between `/refactor` and `/refactor-project`?

**A:**
- **`/refactor`**: Targeted refactoring for recently modified or specified files. Fast, focused, and ideal for incremental improvements during development.
- **`/refactor-project`**: Project-wide refactoring across the entire codebase. Emphasizes cross-file duplication reduction and consistent patterns.

Use `/refactor` for day-to-day work, and `/refactor-project` for major modernization efforts.

### Q: How do I configure which rules are applied?

**A:** The plugin automatically detects your project's frameworks and languages, then applies appropriate rules:

1. **Automatic framework detection**: Identifies Next.js, React, Vite, and other frameworks
2. **Language detection**: Scans file extensions to determine languages in use
3. **Rule application**: Applies only relevant rules based on detected frameworks and languages
4. **Priority-based**: Uses impact-based weighting (CRITICAL > HIGH > MEDIUM > LOW) to prioritize changes

### Q: What if I don't have a test suite?

**A:** While tests are recommended for validation, the refactoring will still work. The agent is designed to preserve functionality by design. However, we strongly recommend:

1. **Manual review**: Carefully review all changes before committing
2. **Incremental refactoring**: Use `/refactor` on small sections rather than `/refactor-project`
3. **Git**: Always commit working code before refactoring so you can revert if needed
4. **Build/lint**: Run your build and linting tools to catch any issues

### Q: Can I customize the refactoring rules?

**A:** Yes, the plugin is designed to be flexible:

1. **Provide feedback**: During refactoring, you can guide the agent to skip certain patterns or focus on specific areas
2. **Framework-aware**: The agent automatically applies only relevant rules based on detected frameworks
3. **Impact-based**: Rules are prioritized by their impact level (CRITICAL > HIGH > MEDIUM > LOW)
4. **Add custom references**: You can create additional reference files in [skills/best-practices/references/](skills/best-practices/references/) for project-specific patterns

### Q: How do I see what rules are available?

**A:** You can explore the reference files:

- **Language-specific**: See language reference files in [skills/best-practices/references/](skills/best-practices/references/)
- **Next.js patterns**: [nextjs/](skills/best-practices/references/nextjs/) (50+ pattern files)
- **Pattern categories**: See [_sections.md](skills/best-practices/references/nextjs/_sections.md) for organized categories

Each pattern file includes a description, impact level, and code examples.

### Q: What impact levels mean CRITICAL, HIGH, MEDIUM, LOW?

**A:**
- **CRITICAL**: Direct, measurable impact on user experience (e.g., page load time, Core Web Vitals). Fix these first.
- **HIGH**: Significant performance or maintainability impact (e.g., server-side optimization, bundle size)
- **MEDIUM**: Noticeable improvements in specific scenarios (e.g., re-render optimization, client-side fetching)
- **LOW**: Micro-optimizations and code quality improvements (e.g., JavaScript patterns, advanced techniques)

The `impact-based` approach automatically prioritizes CRITICAL > HIGH > MEDIUM > LOW.

### Q: Does this work with monorepos?

**A:** Yes! The plugin works with monorepos. You can:

- Run `/refactor` on specific packages or workspaces
- Use `/refactor-project` to refactor the entire monorepo (with caution)

### Q: Can I use this in CI/CD?

**A:** The plugin is designed for interactive use with Claude Code, not CI/CD automation. However, you can:

1. Use the refactored code patterns as inspiration for linting rules
2. Extract specific rules into ESLint/Pylint/golangci-lint configurations
3. Run refactoring locally before pushing to CI/CD

## Acknowledgments

**React/Next.js Best Practices:**
- React and Next.js performance optimization guidelines are sourced from [Vercel Engineering's agent-skills repository](https://github.com/vercel-labs/agent-skills/tree/main/skills/react-best-practices)
- Contains 40+ rules across 8 categories, prioritized by impact
- Originally created by [@shuding](https://x.com/shuding) at [Vercel](https://vercel.com)

## Author

Frad LEE (fradser@gmail.com)

