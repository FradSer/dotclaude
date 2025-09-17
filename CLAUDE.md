# Claude Development Guidelines

## Core Principles
- **MANDATORY TDD** - RED: Write failing test first → GREEN: Write minimal code to pass → REFACTOR: Clean up code while keeping tests green
- **MANDATORY Clean Architecture** - Follow 4-layer structure with dependency rule: source code dependencies only point inwards
- **Research-driven workflow** - Always web search for latest best practices before planning and implementing

## Development Process

### Task Management
- **Plan then act** - Assess complexity and create todo lists for 3+ steps before acting
- Mark tasks completed IMMEDIATELY, keep ONE task in_progress for focus
- **Batch independent tasks** in single tool calls for optimal performance
- **Sequential only when required** - when later tasks depend on earlier results

### Workflow Standards
- Make atomic commits for logical units of work
- Commit message title must be entirely lowercase
- Title must be less than 50 characters
- Follow conventional commits format (feat:, fix:, chore:, etc.)
- Push commits after completing logical units of work
- All linting, building, and testing must pass before merging pull requests
- Run lint and build checks before closing issues
- Merge PRs with merge commits
- Security best practices must be followed

## Code Standards

### Architecture & Design
- Follow SOLID principles and prefer composition over inheritance
- Use dependency injection for testability and layer isolation
- Apply repository pattern for data access and strategy pattern for algorithms
- Use descriptive names and avoid abbreviations or magic numbers
- Keep functions under 50 lines and maintain concise files

### Implementation Quality
- Handle all error scenarios with meaningful messages
- Comment "why" not "what" - focus on business logic and complex decisions
- Search codebase first when uncertain about existing patterns
- Update documentation when modifying code
- **Clean code principles** - eliminate redundancy (DRY), reduce complexity (guard clauses, early returns), modernize syntax, use strong typing

## Technology Stack
- **Node.js**: Use `pnpm` for package management, JSDoc for documentation
- **Python**: Use `uv` for dependency management and virtual environments, docstrings for documentation
- **General**: Avoid emojis and hardcoded secrets in code, use language-specific doc standards