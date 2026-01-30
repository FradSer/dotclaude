# Refactor Plugin

Agent and skills for code simplification and refactoring to improve code quality while preserving functionality.

**Version:** 1.5.1

## Installation

```bash
claude plugin install refactor@frad-dotclaude
```

## Overview

Provides specialized tools for code simplification and refactoring. Includes an expert code simplifier agent and skills for targeted and project-wide refactoring. All refactoring operations preserve functionality while improving clarity, consistency, and maintainability.

## Directory Structure

```
refactor/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── agents/
│   └── code-simplifier.md   # Expert refactoring agent
├── skills/
│   ├── best-practices/      # Knowledge skill (internal)
│   │   ├── SKILL.md
│   │   └── references/      # 111 reference files
│   │       ├── typescript.md
│   │       ├── python.md (+ python/ subdir)
│   │       ├── go.md
│   │       ├── swift.md
│   │       ├── universal.md
│   │       ├── framework-detection.md
│   │       └── react/rules/ # 47 Next.js/React patterns
│   ├── refactor/            # Instruction skill (user-invocable)
│   │   └── SKILL.md
│   └── refactor-project/    # Instruction skill (user-invocable)
│       └── SKILL.md
└── README.md
```

## Agent

### `code-simplifier`

Expert code simplification specialist that enhances code clarity, consistency, and maintainability while preserving functionality. Automatically loads `refactor:best-practices` skill for language-specific standards.

**Usage:**
```
@code-simplifier Simplify the authentication logic in src/auth/login.ts
```

For details, see [agents/code-simplifier.md](agents/code-simplifier.md).


## Skills

### `best-practices` (Internal)

Provides language-specific best practices, code quality standards, and framework detection for refactoring workflows. Automatically loaded by `code-simplifier` agent.

**Language Support:** TypeScript, Python, Go, Swift, JavaScript
**Framework Support:** React (47 performance patterns), Next.js

For details, see [skills/best-practices/SKILL.md](skills/best-practices/SKILL.md).

### `/refactor`

Quick refactoring for recently modified or specified code.

**Usage:**
```bash
# Refactor recently modified code
/refactor

# Refactor specific files
/refactor src/auth/login.ts src/utils/
```

Launches `code-simplifier` agent with targeted scope. For details, see [skills/refactor/SKILL.md](skills/refactor/SKILL.md).

### `/refactor-project`

Project-wide code refactoring across entire codebase.

**Usage:**
```bash
/refactor-project
```

Launches `code-simplifier` agent with project-wide scope, emphasizing cross-file duplication reduction and consistent patterns. For details, see [skills/refactor-project/SKILL.md](skills/refactor-project/SKILL.md).

## Quick Start

### Targeted Refactoring
```bash
# Refactor recent changes
/refactor

# Refactor specific files
/refactor src/auth/login.ts
```

### Project-Wide Refactoring
```bash
/refactor-project
```

### Using Agent Directly
```
@code-simplifier Simplify the authentication logic in src/auth/login.ts
```

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
- Reduced cognitive complexity
- Made logic flow more obvious and testable

### Next.js: Eliminating Waterfalls

Demonstrates parallelizing independent async operations to eliminate sequential waterfalls. See [skills/best-practices/references/nextjs/async-parallel.md](skills/best-practices/references/nextjs/async-parallel.md) for detailed examples.

### Python: Applying DRY and Type Safety

Demonstrates eliminating code duplication using Enums and type hints. See [skills/best-practices/references/python.md](skills/best-practices/references/python.md) for comprehensive patterns.

## Key Features

- **Language Support**: TypeScript, JavaScript, Python, Go, Swift
- **Framework Support**: Next.js (47 performance patterns), React
- **Automated Workflow**: Agent-driven refactoring with best practices
- **Safe Refactoring**: Preserves functionality, uses git for rollback
- **Impact-Based**: Prioritizes CRITICAL > HIGH > MEDIUM > LOW improvements

## Best Practices

- **Refactor frequently** during development
- **Use `/refactor`** for targeted improvements
- **Use `/refactor-project`** for major modernization
- **Review changes** to ensure functionality is preserved
- **Run tests** after refactoring to validate
- **Trust git** for rollback if needed

## Requirements

- Git repository for change tracking
- Test suite for validation (recommended)
- Lint/build tools for quality checks (recommended)

## Troubleshooting

**Q: Will refactoring break my code?**
A: No. The agent preserves functionality. Always run tests after refactoring.

**Q: Refactoring changes too much**
A: Use `/refactor` with specific files for targeted changes. Review changes before committing.

**Q: What's the difference between `/refactor` and `/refactor-project`?**
A: `/refactor` is for targeted changes (recent/specified files). `/refactor-project` is for entire codebase.

For more FAQs and detailed troubleshooting, see individual skill documentation in [skills/](skills/).

## Author

Frad LEE (fradser@gmail.com)

## Credits

**React/Next.js Best Practices:**
- React and Next.js performance optimization guidelines are sourced from [Vercel Engineering's agent-skills repository](https://github.com/vercel-labs/agent-skills/tree/main/skills/react-best-practices)
- Contains 40+ rules across 8 categories, prioritized by impact
- Originally created by [@shuding](https://x.com/shuding) at [Vercel](https://vercel.com)
