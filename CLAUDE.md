# Claude Development Guidelines

## Core Principles
- **MANDATORY TDD** - RED: Write failing test first → GREEN: Write minimal code to pass → REFACTOR: Clean up code while keeping tests green
- **MANDATORY Clean Architecture** - Follow 4-layer structure with dependency rule: source code dependencies only point inwards
- **Research-driven workflow** - Always web search for latest best practices before planning and implementing

## Documentation Standards

### CLAUDE.md Requirements
All CLAUDE.md files must satisfy these four mandatory criteria:

- Every sentence provides unique value, eliminate duplicate information
- Emphasize hard-to-discover architectural patterns and design decisions
- Explicitly state key constraints behind technical choices and trade-offs
- Include executable commands, verification steps, and concrete implementation guidance

## Development Process

### Task Management
- **Plan then act** - Assess complexity and create todo lists for 3+ steps before acting
- **Batch independent tasks** in single tool calls for optimal performance
- **Sequential only when required** - when later tasks depend on earlier results

### Version Control & Git Workflow
- Make atomic commits for logical units of work
- Commit message title must be entirely lowercase and under 50 characters
- Follow conventional commits format (feat:, fix:, chore:, etc.)
- Push commits after completing logical units of work
- All linting, building, and testing must pass before merging pull requests
- Run lint and build checks before closing issues
- Merge PRs with merge commits
- Security best practices must be followed

## Architecture & Design Principles

### Design Standards
- Follow SOLID principles and prefer composition over inheritance
- Use dependency injection for testability and layer isolation
- Apply repository pattern for data access and strategy pattern for algorithms
- Use descriptive names and avoid abbreviations or magic numbers
- Keep functions under 50 lines and maintain concise files

### Clean Code Practices
- Eliminate redundancy (DRY principle)
- Reduce complexity using guard clauses and early returns
- Modernize syntax and use strong typing
- Handle all error scenarios with meaningful messages

## Implementation Standards

### Code Quality
- Comment "why" not "what" - focus on business logic and complex decisions
- Search codebase first when uncertain about existing patterns
- Update documentation when modifying code
- Follow language-specific documentation standards

### Testing Strategy
- **No temporary test scripts in root directory** - Avoid creating temporary test files in the project root
- **Use proper test directories** - Place formal tests in appropriate directories (tests/, __tests__, spec/) for TDD
- **Temporary validation** - Run quick test scripts directly with bash for temporary validation

## Technology Stack

### Node.js Projects
- Use `pnpm` for package management
- Use JSDoc for documentation
- Avoid emojis and hardcoded secrets in code

### Python Projects
- Use `uv` for dependency management and virtual environments
- Use docstrings for documentation
- Follow PEP standards for code structure
