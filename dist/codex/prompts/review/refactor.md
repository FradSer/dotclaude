# Systematic Refactor

**Summary:** Systematic code refactoring to improve quality while preserving functionality

---

## Context

- Current git status: `git status`
- Current branch: `git branch --show-current`
- Recent commits: `git log --oneline -5`
- Complexity indicators: Identify functions >20 lines, nested conditionals, and duplicated logic
- Project snapshot: `find . -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.java" -o -name "*.go" | head -20`

## Requirements

- Preserve existing behaviour—tests should only be run, not altered.
- Apply SOLID and Clean Code principles to reduce complexity and duplication.
- Strengthen typing, error handling, and naming conventions.
- Stage and commit refactors atomically, pushing updates after validation.
- Commit message title must be entirely lowercase
- Title must be less than 50 characters
- Commit message body must use normal text formatting (proper capitalization and punctuation)
- Follow conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
- Use atomic commits for logical units of work

## Your Task

1. Analyse the codebase (or `$ARGUMENTS` scope) to pinpoint high-impact refactor targets using @code-simplifier for guidance.
2. Execute refactoring steps iteratively—eliminate duplication, simplify control flow, modernise syntax, and reinforce typing and error handling.
3. Validate with existing tests, run lint/build checks, and produce atomic commits before summarising improvements and remaining risks.

### Refactoring Workflow

- **Assessment**: Inspect branch status, catalogue complexity hot spots, and search for existing patterns to align with project conventions.
- **Planning**: Prioritise improvements by readability, maintainability, and performance impact; map steps into Task tool actions.
- **Execution**: Apply DRY, introduce guard clauses, extract helpers, adopt idiomatic constructs, and ensure descriptive names.
- **Validation & Delivery**: Re-run tests, lint, and builds; ensure a clean working directory; stage and commit each logical unit; push results and report the refactor summary.
