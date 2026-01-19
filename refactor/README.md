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
- `references/nextjs/INDEX.md` - Complete pattern index with all patterns organized by impact level
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

**Before:**
```typescript
export default async function UserProfile({ params }: { params: { id: string } }) {
  const user = await fetchUser(params.id);
  const posts = await fetchUserPosts(user.id);  // ⚠️ Waterfall: waits for user
  const comments = await fetchUserComments(user.id);  // ⚠️ Waterfall: waits for posts

  return <Profile user={user} posts={posts} comments={comments} />;
}
```

**After:**
```typescript
export default async function UserProfile({ params }: { params: { id: string } }) {
  // Parallelize independent operations
  const [user, posts, comments] = await Promise.all([
    fetchUser(params.id),
    fetchUserPosts(params.id),  // ✅ Runs in parallel
    fetchUserComments(params.id),  // ✅ Runs in parallel
  ]);

  return <Profile user={user} posts={posts} comments={comments} />;
}
```

**Improvements:**
- Eliminated sequential waterfalls with `Promise.all()`
- Reduced loading time by ~66% (3 sequential → 1 parallel)
- CRITICAL performance impact for user experience

### Python: Applying DRY and Type Safety

**Before:**
```python
def calculate_discount(price, customer_type):
    if customer_type == "regular":
        discount = price * 0.05
        final_price = price - discount
        return final_price
    elif customer_type == "premium":
        discount = price * 0.10
        final_price = price - discount
        return final_price
    elif customer_type == "vip":
        discount = price * 0.20
        final_price = price - discount
        return final_price
    else:
        return price
```

**After:**
```python
from enum import Enum
from typing import Final

class CustomerType(Enum):
    REGULAR = 0.05
    PREMIUM = 0.10
    VIP = 0.20

def calculate_discount(price: float, customer_type: CustomerType) -> float:
    """Calculate final price after applying customer type discount."""
    discount_rate = customer_type.value
    return price * (1 - discount_rate)

# Usage with type safety
final_price = calculate_discount(100.0, CustomerType.PREMIUM)
```

**Improvements:**
- Eliminated code duplication (DRY principle)
- Added type safety with Enum and type hints
- Simplified logic from 12 lines to 3 lines
- Made discount rates configurable and discoverable
- Prevented invalid customer types at compile time

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

## FAQ

### Q: Will refactoring break my code?

**A:** No. The `code-simplifier` agent is designed to preserve functionality while improving code quality. All refactoring operations maintain the exact same behavior - they only change *how* the code does something, never *what* it does. However, always review changes and run your test suite after refactoring to ensure everything works as expected.

### Q: How do I disable specific rules or patterns?

**A:** Add the rule ID to the `disabled_patterns` list in `.claude/refactor.local.md`:

```yaml
disabled_patterns: ["nextjs:async-defer-await", "typescript:no-explicit-any"]
```

You can find rule IDs in the YAML frontmatter of each pattern file in `skills/best-practices/references/`.

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
- **`/refactor-project`**: Project-wide refactoring across the entire codebase. Emphasizes cross-file duplication reduction and consistent patterns. Always shows preview and requires confirmation for safety.

Use `/refactor` for day-to-day work, and `/refactor-project` for major modernization efforts.

### Q: How do I configure which rules are applied?

**A:** The first time you run `/refactor` or `/refactor-project`, you'll be guided through interactive configuration setup. You can also manually edit `.claude/refactor.local.md`:

1. **Rule categories**: Enable/disable entire categories (Next.js async, bundle, TypeScript, etc.)
2. **Default mode**: Choose `all` (auto-apply), `selected` (interactive), or `weighted` (priority-based)
3. **Weighting strategy**: Prioritize by impact level or use custom weights
4. **Disabled patterns**: Exclude specific rules you don't want

### Q: What if I don't have a test suite?

**A:** While tests are recommended for validation, the refactoring will still work. The agent is designed to preserve functionality by design. However, we strongly recommend:

1. **Manual review**: Carefully review all changes before committing
2. **Incremental refactoring**: Use `/refactor` on small sections rather than `/refactor-project`
3. **Git**: Always commit working code before refactoring so you can revert if needed
4. **Build/lint**: Run your build and linting tools to catch any issues

### Q: Can I customize the refactoring rules?

**A:** Yes, in several ways:

1. **Enable/disable categories**: Turn entire rule categories on/off in configuration
2. **Disable specific patterns**: Add patterns to `disabled_patterns`
3. **Custom weights**: Assign priority to specific rules with `custom_weights`
4. **Add custom references**: Create additional reference files in `skills/best-practices/references/`

### Q: How do I see what rules are available?

**A:** You can explore the reference files:

- **Language-specific**: `skills/best-practices/references/{typescript,python,go,swift,universal}.md`
- **Next.js patterns**: `skills/best-practices/references/nextjs/` (50+ pattern files)
- **Pattern categories**: See `skills/best-practices/references/nextjs/_sections.md` for organized categories

Each pattern file includes a description, impact level, and code examples.

### Q: What impact levels mean CRITICAL, HIGH, MEDIUM, LOW?

**A:**
- **CRITICAL**: Direct, measurable impact on user experience (e.g., page load time, Core Web Vitals). Fix these first.
- **HIGH**: Significant performance or maintainability impact (e.g., server-side optimization, bundle size)
- **MEDIUM**: Noticeable improvements in specific scenarios (e.g., re-render optimization, client-side fetching)
- **LOW**: Micro-optimizations and code quality improvements (e.g., JavaScript patterns, advanced techniques)

The `impact-based` weighting strategy automatically prioritizes CRITICAL > HIGH > MEDIUM > LOW.

### Q: Does this work with monorepos?

**A:** Yes! The plugin works with monorepos. You can:

- Run `/refactor` on specific packages or workspaces
- Use `/refactor-project` to refactor the entire monorepo (with caution)
- Configure different rules per package by placing `.claude/refactor.local.md` in each package directory

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

## Version

1.0.0
