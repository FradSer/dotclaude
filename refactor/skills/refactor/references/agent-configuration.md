# Agent Configuration Details

## Task Tool Invocation

### Required Parameters

```
Task tool parameters:
  subagent_type: "refactor:code-simplifier"
  description: "Refactor code with aggressive cleanup"
  prompt: <detailed context below>
```

### Prompt Context Structure

Pass the following information to the agent:

```
Refactor the following files with aggressive cleanup enabled:

Target Scope: <list of file paths>

Scope Determination: <one of: "explicit paths", "semantic search: <query>", "session context">

Aggressive Mode: Remove legacy code, unused exports, backwards-compatibility hacks, and rename improperly named variables.

<if semantic search>
Semantic Query: "<original query>"
Search Results: <number> files matched
</if>

<if session context>
Recent Changes: <number> files modified in git working tree
</if>
```

### Example Invocations

**Path-based**:
```
Target Scope:
- src/auth/login.ts
- src/auth/session.ts

Scope Determination: explicit paths

Aggressive Mode: Remove legacy code, unused exports, backwards-compatibility hacks, and rename improperly named variables.
```

**Semantic search**:
```
Target Scope:
- src/services/user-validator.ts
- src/lib/validation-utils.ts
- src/middleware/auth-check.ts

Scope Determination: semantic search: "user validation logic"

Semantic Query: "user validation logic"
Search Results: 3 files matched

Aggressive Mode: Remove legacy code, unused exports, backwards-compatibility hacks, and rename improperly named variables.
```

**Session context**:
```
Target Scope:
- src/components/Button.tsx
- src/styles/theme.ts

Scope Determination: session context

Recent Changes: 2 files modified in git working tree

Aggressive Mode: Remove legacy code, unused exports, backwards-compatibility hacks, and rename improperly named variables.
```

## Agent Internal Workflow

The code-simplifier agent executes the following workflow autonomously:

### 1. Load Best Practices Skill

```
Load refactor:best-practices skill using Skill tool
```

This provides:
- Language-specific refactoring rules (TypeScript, Python, Go, Swift)
- Framework detection patterns (Next.js, React)
- Universal code quality principles
- Performance optimization patterns

### 2. Analyze Target Files

For each file in target scope:

1. **Detect Language** - Based on file extension
2. **Detect Framework** - Scan for framework imports (Next.js, React, etc.)
3. **Load Relevant References** - From best-practices skill based on detection
4. **Identify Issues** - Complexity, redundancy, code quality violations

### 3. Apply Refactoring

**Aggressive Mode Changes**:
- Remove all unused imports, exports, variables, functions
- Delete backwards-compatibility shims (e.g., `_unusedVar`, re-exports of deleted code)
- Rename misleading identifiers to descriptive names
- Remove commented-out code blocks
- Delete try-catch in trusted code paths
- Eliminate defensive null checks when type system guarantees non-null

**Behavior-Preserving Changes**:
- Simplify nested ternaries to if-else or guard clauses
- Extract complex conditions to named boolean variables
- Replace magic numbers with named constants
- Modernize syntax (e.g., arrow functions, destructuring)
- Apply framework-specific optimizations when applicable

### 4. Validate Changes

- Suggest running tests relevant to refactored files
- Provide specific test commands (e.g., `npm test auth.test.ts`)
- Note manual verification steps for UI changes

### 5. Generate Summary

Track all changes by category for summary report (see `output-requirements.md`).

## Best Practices Skill Integration

### Automatic Loading

The agent's `skills` manifest includes `refactor:best-practices`, so it loads automatically on launch.

### Framework Detection Examples

**Next.js Detection**:
```typescript
import { useRouter } from 'next/router'
import Image from 'next/image'
```

**React Detection**:
```typescript
import React from 'react'
import { useState } from 'react'
```

### Rule Filtering

Agent applies **only** rules relevant to detected frameworks:
- Next.js rules → only if Next.js detected
- React rules → only if React detected
- Universal rules → apply to all code

### Reference File Loading

Based on detection, agent loads:

- TypeScript: `references/typescript.md`
- Python: `references/python.md` + `references/python/INDEX.md`
- Next.js: `references/react/` directory with rule index
- Universal: `references/universal.md`

## Model and Performance

### Model Configuration

```yaml
model: opus  # High reasoning for complex refactoring decisions
```

Opus provides superior:
- Code quality judgment
- Complex pattern recognition
- Multi-file consistency
- Behavioral preservation verification

### Allowed Tools

```yaml
allowed-tools:
  - Read       # Read target files
  - Edit       # Apply refactoring changes
  - Glob       # Discover related files
  - Grep       # Search for patterns
  - Bash(git:*)  # Git status, diff for context
  - Skill      # Load best-practices
```

**No Write tool**: Agent uses Edit for surgical changes, not full rewrites.

**Restricted Bash**: Only git commands allowed for safety.
