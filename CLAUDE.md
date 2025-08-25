# Claude Development Guidelines

## Architecture & Design
- Follow SOLID principles and prefer composition over inheritance
- Use dependency injection for testability
- Apply repository pattern for data access and strategy pattern for algorithms
- Use descriptive names and avoid abbreviations or magic numbers
- Keep functions under 20 lines and maintain concise files

## Code Quality
- Handle all error scenarios with meaningful messages
- Comment "why" not "what" - focus on business logic and complex decisions
- Search codebase first when uncertain about existing patterns
- Write tests for core functionality using TDD approach
- Update documentation when modifying code

## Development Workflow
- Make atomic commits for each completed feature stage
- Write lowercase commit titles (max 50 characters) following Conventional Commits
- Merge PRs with merge commits
- All tests must pass before merging pull requests
- Run lint and build checks before closing issues
- Push commits after completing logical units of work

## Technology Stack Preferences
- **Node.js**: Use `pnpm` for package management
- **Python**: Use `uv` for dependency management and virtual environments
- **General**: Avoid emojis and hardcoded secrets in code

## Quality Standards
- All linting, building, and testing must pass before merging
- Code must pass linting and formatting checks
- Error handling must be comprehensive and user-friendly
- Security best practices must be followed
