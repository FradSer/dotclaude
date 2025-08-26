# Claude Development Guidelines

## Task Management & Workflow Priority

### Task Tool Usage
- **Task tool** - Launch specialized subagents for complex work (code review, security analysis)
- **TodoWrite tool** - Create and manage task lists for tracking progress
- Use Task tool for delegation, TodoWrite for organization and status tracking
- Create todo lists proactively for any work with 3+ steps
- Mark tasks completed IMMEDIATELY, keep ONE task in_progress for focus
- Use parallel execution within individual tasks for efficiency

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
- **Task-driven development** - use Task/TodoWrite tools for planning and tracking
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

## Parallel Execution Best Practices
- **Batch independent tasks** in single tool calls for optimal performance
- Use for: file operations, validation checks, git commands, data collection
- **Sequential only when required** - when later tasks depend on earlier results
- Examples: `git status + diff + log`, multiple file reads, concurrent linting

## Quality Standards
- All linting, building, and testing must pass before merging
- Security best practices must be followed
