---
name: best-practices
description: This skill should be used when the user asks to "refactor", "refactor the whole project", "simplify code", "clean up code", "apply best practices", "improve readability", "reduce duplication", "standardize patterns", "improve performance", "optimize Next.js performance", "make code more maintainable", "follow coding standards", "optimize code quality", or requests behavior-preserving refactoring with best-practice guidance.
version: 1.0.0
---

# Best Practices

## Scope

Support both:

- **Targeted refactoring**: recently modified code in the current session, or specific files/directories provided by the user
- **Project-wide refactoring**: entire repository when explicitly requested

## Agent Invocation

Use the Task tool to launch the `code-simplifier` agent for execution. Pass the target scope and any constraints. If already running inside `code-simplifier`, skip launching and proceed with the workflow.

## Language References

Based on file extension, load the appropriate reference:

- `.ts`, `.tsx`, `.js`, `.jsx` → See `references/typescript.md`
- `.py` → See `references/python.md`
- `.go` → See `references/go.md`
- `.swift` → See `references/swift.md`

For universal principles applicable to all languages, see `references/universal.md`.

## Next.js Best Practices References

Use the Next.js reference set when the target includes Next.js code (typically `.tsx`, `.jsx`, Next.js app/pages routes, Server Components, Client Components).

Reference directory:

- `references/nextjs/`

Recommended entry points:

1. Read `references/nextjs/INDEX.md` for complete pattern index organized by impact level and category.
2. Read `references/nextjs/_sections.md` to understand priorities and categories.
3. Read the specific rule file(s) that match the pattern observed (for example, `async-defer-await.md`, `bundle-dynamic-imports.md`).

## Rule Application Guidance

- Prefer **CRITICAL** rules first when there is evidence of user-facing impact (waterfalls, bundle size, hydration issues).
- Keep changes minimal and targeted; optimize only when the pattern is present in the code.
- Preserve behavior and public interfaces; do not change externally visible semantics during a refactor.

## Workflow

1. **Identify**: Determine target scope (specified files/directories, session modifications, or entire project)
2. **Load References**: Load language references for the target files, plus Next.js best-practices references when applicable
3. **Analyze**: Review code for complexity, redundancy, and best-practice violations that matter for the target scope
4. **Execute**: Apply behavior-preserving refinements following the loaded references
5. **Validate**: Ensure tests pass (or suggest the most relevant tests to run) and the code is cleaner
