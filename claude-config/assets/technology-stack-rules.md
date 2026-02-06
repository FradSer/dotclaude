# Technology Stack Rules

Use these lines as the single language best-practice bullet for each language in `## Technology Stack Configuration`.
Rules in this file must focus on language-level engineering practices, not package-manager choices.
Do not add URLs to generated `CLAUDE.md` technology sections.

| Language | Rule |
| - | - |
| Node.js | Keep server hot paths non-blocking with async I/O, move CPU-heavy work off the event loop, and treat unhandled promise rejections as production failures. |
| Python | Follow PEP 8 for consistent readability, add explicit type hints on public APIs, and use context managers for deterministic resource cleanup. |
| Rust | Model recoverable failures with `Result` and `?`, reserve `unwrap` and `expect` for tests or proven invariants, and keep ownership and borrowing intent explicit in API boundaries. |
| Swift | Prefer `struct` over `class` unless shared identity is required, model concurrent workflows with `async`/`await`, and isolate shared mutable state with actors under strict concurrency checking. |
| Go | Define small interfaces at the point of use, pass `context.Context` as the first parameter for request-scoped work, and return wrapped errors using `%w` with actionable context. |
| Java | Design domain models as immutable by default, validate inputs at boundaries and use `Optional` for absent return values, and prefer modern Java language features that keep APIs explicit and null-safe. |
