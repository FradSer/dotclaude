# Claude Development Guidelines

## Core Principles

- Follow Clean Architecture with a 4-layer structure; source code dependencies only point inwards
- Web search for latest best practices before planning and implementing
- Use Mermaid for all diagrams

## Code Quality

IMPORTANT: Do not generate AI code slop:
- Extra comments inconsistent with file style or that a human wouldn't add
- Unnecessary defensive checks/try-catch in trusted codepaths
- Casts to `any` to bypass type issues
- Any style inconsistent with surrounding code

### Testing Strategy

- Write comprehensive tests to ensure code correctness
- Place tests in appropriate directories (tests/, __tests__, spec/)
- Run validation tests to verify implementation behavior
