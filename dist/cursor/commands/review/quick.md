---
description: Streamlined code review for rapid assessment and targeted feedback
trigger: /quick-review
argumentHint: "[files-or-directories]"
---

## Context

- Current branch: `git branch --show-current`
- Git status: `git status --porcelain`
- Base branch: `(git show-branch | grep '*' | grep -v "$(git rev-parse --abbrev-ref HEAD)" | head -1 | sed 's/.*\[\([^]]*\)\].*/\1/' | sed 's/\^.*//' 2>/dev/null) || echo "develop"`
- Changes since base: `BASE=$(git merge-base HEAD develop 2>/dev/null || git merge-base HEAD main 2>/dev/null) && git log --oneline $BASE..HEAD`
- Files changed since base: `BASE=$(git merge-base HEAD develop 2>/dev/null || git merge-base HEAD main 2>/dev/null) && git diff --name-only $BASE..HEAD`
- Test commands available: `([ -f package.json ] && echo "npm/pnpm/yarn test") || ([ -f Cargo.toml ] && echo "cargo test") || ([ -f pyproject.toml ] && echo "pytest/uv run pytest") || ([ -f go.mod ] && echo "go test") || echo "no standard test framework detected"`

## Requirements

- Use @tech-lead-reviewer to scope the review and decide which specialized agents are required.
- Launch only the necessary specialized reviews to minimize turnaround time.
- Summarize results by priority (Critical → High → Medium → Low) and confidence (High → Medium → Low).
- Offer optional implementation support and ensure resulting commits follow conventional standards.
- Commit message title must be entirely lowercase
- Title must be less than 50 characters
- Commit message body must use normal text formatting (proper capitalization and punctuation)
- Follow conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
- Use atomic commits for logical units of work

## Your Task

1. Run an initial assessment with @tech-lead-reviewer to gauge architectural, security, and UX risk, and determine if a deeper review is needed.
2. Trigger the relevant specialized reviews via the Task tool, gather targeted feedback, and resolve conflicting recommendations.
3. Present a concise summary, ask whether the user wants fixes implemented, and if confirmed, apply changes, refactor with @code-simplifier, test, and stage commits before reporting outcomes.

### Targeted Review Flow

- **Selective Agents**: Engage @code-reviewer, @security-reviewer, and/or @ux-reviewer only when their expertise is required by the change scope.
- **Results Analysis**: Organize findings using the priority/confidence matrix and provide actionable steps.
- **Optional Implementation**: Execute requested fixes, optimize the code, rerun tests, and prepare commits that adhere to the standards fragment.
- **Closure**: Push updates if changes were made and confirm review completion with the user.
