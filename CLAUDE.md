# Global Development Guidelines

## Architecture
- Follow SOLID principles
- Prefer composition over inheritance, dependency injection for testability
- Use repository pattern for data access, strategy pattern for algorithmic variations

## Code Quality
- Use descriptive names, avoid abbreviations and magic numbers
- Keep functions under 20 lines, files concise
- Handle all error scenarios with meaningful messages
- Comment "why" not "what"

## Development Standards
- Search first when uncertain, write tests for core functionality
- Update documentation when modifying code
- Prefer pnpm for Node.js projects
- Commit titles: lowercase, max 50 characters
- Merge PRs with merge commits
- No emojis, avoid hardcoding secrets