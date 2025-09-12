# Claude Development Guidelines

## Task Management & Workflow Priority

### Task Tool Usage
- **Plan first, act second** - assess complexity and create todo lists for 3+ steps before acting
- Mark tasks completed IMMEDIATELY, keep ONE task in_progress for focus

## Architecture & Design
- **MANDATORY Clean Architecture** - Follow 4-layer structure: Entities → Use Cases → Interface Adapters → Frameworks & Drivers
- **Dependency Rule** - Source code dependencies only point inwards, outer layers depend on inner layers
- Follow SOLID principles and prefer composition over inheritance
- Use dependency injection for testability and layer isolation
- Apply repository pattern for data access and strategy pattern for algorithms
- Use descriptive names and avoid abbreviations or magic numbers
- Keep functions under 50 lines and maintain concise files
- **Research-driven decisions** - Use web search for latest best practices before implementing

## Code Quality
- **MANDATORY TDD** - RED: Write failing test first (define behavior) → GREEN: Write minimal code to pass → REFACTOR: Clean up code while keeping tests green. Never write production code without a failing test.
- Handle all error scenarios with meaningful messages
- Comment "why" not "what" - focus on business logic and complex decisions
- Search codebase first when uncertain about existing patterns, use web search for latest best practices
- Update documentation when modifying code
- **Eliminate redundancy** - extract common logic, apply DRY principle
- **Reduce complexity** - use guard clauses, early returns, break down large functions
- **Modernize syntax** - leverage built-in features and idiomatic expressions
- **Strong typing** - avoid `any` or `unknow` type and similar loose types, use specific types

## Development Workflow
- Make atomic commits for logical units of work
- Commit message title must be entirely lowercase
- Title must be less than 50 characters
- Follow conventional commits format (feat:, fix:, chore:, etc.)
- Merge PRs with merge commits
- Push commits after completing logical units of work

## Technology Stack Preferences
- **Node.js**: Use `pnpm` for package management, JSDoc for documentation
- **Python**: Use `uv` for dependency management and virtual environments, docstrings for documentation
- **General**: Avoid emojis and hardcoded secrets in code, use language-specific doc standards

## Parallel Execution Best Practices
- **Batch independent tasks** in single tool calls for optimal performance
- Use for: file operations, validation checks, git commands, data collection
- **Sequential only when required** - when later tasks depend on earlier results
- Examples: `git status + diff + log`, multiple file reads, concurrent linting

## Quality Standards
- All linting, building, and testing must pass before merging pull requests
- Run lint and build checks before closing issues
- Security best practices must be followed
