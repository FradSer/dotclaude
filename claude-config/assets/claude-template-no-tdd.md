# Claude Development Guidelines

## Core Principles

- Follow Clean Architecture with a 4-layer structure; source code dependencies only point inwards
- Web search for latest best practices before planning and implementing
- Use Mermaid for all diagrams

## Code Quality

IMPORTANT: Do not generate AI code slop:
- Style or comments inconsistent with surrounding code or that a human wouldn't add
- Unnecessary defensive checks/try-catch in trusted codepaths
- Casts to `any` to bypass type issues

### Testing Strategy

- Write comprehensive tests to ensure code correctness
- Place tests in appropriate directories (tests/, __tests__, spec/)
