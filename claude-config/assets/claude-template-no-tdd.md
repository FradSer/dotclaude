# Claude Development Guidelines

## Core Principles
- **MUST** follow Clean Architecture with a 4-layer structure and an inward-only dependency rule
- **MUST** run a web search for the latest best practices before planning and implementing

## Documentation Standards

### CLAUDE.md Requirements
All CLAUDE.md files MUST satisfy these criteria:

- **MUST** ensure every sentence provides unique value and eliminate duplicate information
- **MUST** emphasize hard-to-discover architectural patterns and design decisions
- **MUST** state key constraints behind technical choices and trade-offs
- **MUST** include executable commands, verification steps, and concrete implementation guidance
- **MUST** use RFC 2119 keywords: **MUST**/**MUST NOT**, **SHOULD**/**SHOULD NOT**, **MAY**; **MUST NOT** use REQUIRED, SHALL, RECOMMENDED, OPTIONAL

## Development Process

### Task Management
- **MUST** assess complexity and create todo lists for tasks with 3+ steps before acting
- **SHOULD** batch independent tasks in single tool calls for optimal performance
- **MUST** keep tasks sequential only when later tasks depend on earlier results

### Version Control & Git Workflow
- **MUST** make atomic commits for logical units of work
- **MUST** keep commit message titles entirely lowercase and under 50 characters
- **MUST** follow conventional commits format (feat:, fix:, chore:, etc.)
- **MUST** push commits after completing logical units of work
- **MUST** ensure linting, building, and testing pass before merging pull requests
- **MUST** run lint and build checks before closing issues
- **MUST** merge PRs with merge commits
- **MUST** follow security best practices

## Architecture & Design Principles

### Design Standards
- **SHOULD** follow SOLID principles and **SHOULD** prefer composition over inheritance
- **SHOULD** use dependency injection for testability and layer isolation
- **SHOULD** apply the repository pattern for data access and the strategy pattern for algorithms
- **SHOULD** use descriptive names and **SHOULD NOT** use abbreviations or magic numbers
- **SHOULD** keep functions under 50 lines and files concise

### Clean Code Practices
- **SHOULD** eliminate redundancy (DRY principle)
- **SHOULD** reduce complexity using guard clauses and early returns
- **SHOULD** modernize syntax and use strong typing
- **SHOULD** handle all error scenarios with meaningful messages
- **MUST NOT** generate AI code slop, including:
  - Extra comments inconsistent with file style or that a human wouldn't add
  - Unnecessary defensive checks/try-catch in trusted codepaths
  - Casts to `any` to bypass type issues
  - Any style inconsistent with surrounding code

## Implementation Standards

### Code Quality
- **SHOULD** comment "why" not "what" to focus on business logic and complex decisions
- **MUST** search the codebase first when uncertain about existing patterns
- **MUST** update documentation when modifying code
- **SHOULD** follow language-specific documentation standards

### Testing Strategy
- **SHOULD** write comprehensive tests to ensure code correctness
- **MUST** place tests in appropriate directories (tests/, __tests__, spec/)
- **SHOULD** run validation tests to verify implementation behavior
