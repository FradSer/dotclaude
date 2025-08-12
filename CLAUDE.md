# Development Guidelines

## Architecture Principles
- Follow SOLID principles and prefer composition over inheritance
- Use dependency injection for testability
- Apply repository pattern for data access and strategy pattern for algorithms

## Code Quality Standards
- Use descriptive names and avoid abbreviations or magic numbers
- Keep functions under 20 lines and maintain concise files
- Handle all error scenarios with meaningful messages
- Comment "why" not "what"

## Development Workflow
- Search codebase first when uncertain
- Write tests for core functionality using TDD approach
- Update documentation when modifying code
- Make atomic commits for each completed feature stage and push

## Technical Preferences
- Use pnpm for Node.js projects
- Write lowercase commit titles (max 50 characters)
- Merge PRs with merge commits
- Avoid emojis and hardcoded secrets

## Quality Gates
- Run lint and build checks before closing issues
- Ensure all tests pass before merging