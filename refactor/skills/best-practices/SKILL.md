---
name: best-practices
description: Provides language-specific best practices, code quality standards, and framework detection for refactoring workflows
user-invocable: false
version: 1.3.0
---

# Best Practices

## Language References

Each file extension maps to a specific reference:

- `.ts`, `.js` — `references/typescript.md`
- `.tsx`, `.jsx` — `references/typescript.md` + `references/react/react.md`
- `.py` — `references/python.md` + `references/python/INDEX.md`
- `.go` — `references/go.md`
- `.swift` — `references/swift.md`

Universal principles are in `references/universal.md`.

## Next.js/React References

For Next.js projects, the `references/react/` directory provides:

1. `references/react/rules/INDEX.md` — pattern index by impact level
2. `references/react/rules/_sections.md` — priorities and categories
3. Specific rule files matching observed patterns

## Rule Application

- Framework-specific rules (e.g., Next.js) apply only when that framework is detected
- **CRITICAL** rules have highest priority: waterfalls, bundle size, hydration
- All refactoring MUST preserve behavior and public interfaces

## Code Quality Standards

- **Comments**: Only for complex business logic; code-restating comments are unnecessary
- **Error Handling**: Try-catch only where recoverable; no defensive checks in trusted paths
- **Type Safety**: No `any`; proper types or `unknown` with guards are required
- **Style**: Existing code style and CLAUDE.md conventions take precedence
- **Cleanup**: Unused imports, variables, functions, and types are removed
- **No compat hacks**: Unused `_vars` and re-exports of deleted code are deleted
- **Renaming**: Descriptive names are preferred over marking as unused
- **Dead code**: Dead code is deleted, never commented out
- **File Organization**: Single Responsibility applies at file level; files with multiple concerns are candidates for splitting (see `references/universal.md`)
