## Frad's `.claude`

A configuration repository for Claude Code that provides a multi-agent setup and command templates to accelerate code review, refactoring, security audits, tech-lead guidance, and UX evaluations.

## Quick Sync

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/FradSer/dotclaude/main/sync-to-github.sh)
```

What the script does:
- Syncs `~/.claude/{agents,commands,CLAUDE.md}` with the same paths in this repo (two-way comparison).
- Automatically detects whether it runs inside this repo or clones into `/tmp/dotclaude-sync`.
- Shows a diff for each item and lets you interactively choose: use local, use repo, or skip (supports color diff).
- At the end, you can choose to commit and push (generates a Conventional/Commitizen-style message or falls back to a built-in template).

Prerequisites:
- `git`, `curl`, `bash 3.2+` (macOS defaults are fine).
- Optional: `colordiff` (for colored diffs), `claude` CLI (for better commit message generation).

## Directory Structure

```text
dotclaude/
  - agents/
    - code-reviewer.md
    - code-simplifier.md
    - security-reviewer.md
    - tech-lead-reviewer.md
    - ux-reviewer.md
  - commands/
    - continue.md
    - fix/
      - code-quality.md
      - security.md
      - ui.md
    - gh/
      - create-issues.md
    - git/
      - commit-and-push.md
      - commit.md
      - push.md
      - release.md
    - refactor.md
    - review/
      - hierarchical.md
      - quick.md
  - CLAUDE.md
  - README.md
  - sync-to-github.sh
```

## Agents

- `agents/code-reviewer.md`: Comprehensive review for correctness, error handling, maintainability, and best practices.
- `agents/code-simplifier.md`: Refactoring to improve readability and reduce complexity without changing external behavior.
- `agents/security-reviewer.md`: Security audit focused on authN/authZ, input validation, dependencies, and configuration.
- `agents/tech-lead-reviewer.md`: Tech-lead perspective on architecture, technical direction, and risk assessment.
- `agents/ux-reviewer.md`: UX/usability review based on usability and accessibility standards.

## Commands

- Review workflows
  - `commands/review/quick.md`: Two-stage quick review.
  - `commands/review/hierarchical.md`: Layered parallel reviews with consolidated recommendations.
- Fix operations
  - `commands/fix/code-quality.md`: Improvements to naming, complexity, tests, and performance.
  - `commands/fix/security.md`: Security issue identification and remediation validation.
  - `commands/fix/ui.md`: UI/UX improvements for usability and consistency.
- Git operations
  - `commands/git/commit.md`, `commands/git/commit-and-push.md`, `commands/git/push.md`: Basic Git flows.
  - `commands/git/release.md`: Git-flow based release checklist.
- Other
  - `commands/continue.md`: Continue previous work.
  - `commands/refactor.md`: Systematic refactoring checklist.
  - `commands/gh/create-issues.md`: Notes for creating issues with the `gh` CLI.

## Using in Claude Code

1. Invoke agents directly in the conversation (e.g., `@tech-lead-reviewer`, `@code-reviewer`).
2. Open the relevant `commands/*.md` files as checklists to drive each stage.
3. Run the Quick Sync script to align your local `~/.claude` with the repo when needed.

## Development & Commit Conventions (Key Excerpts)

See `CLAUDE.md` for full details. Key points:

- Architecture: Follow SOLID; prefer composition over inheritance; use dependency injection for testability; Repository for data access and Strategy for algorithmic variations.
- Code quality: Semantic naming; avoid magic numbers; keep functions small; cover error scenarios with meaningful messages; comment on "why" rather than "what".
- Standards: Search first when unsure; write tests for core functionality; update docs with code changes; prefer `pnpm` for Node.js projects.
- Commit conventions (this repo):
  - Commit messages must be in English only.
  - Commitizen/Conventional style (e.g., `feat(scope): subject`).
  - Title lowercase, length ≤ 50 characters, focused on what changed.
  - Atomic commits; no emojis; PRs use merge commits.

Note: If any item in `CLAUDE.md` conflicts with this section, this section takes precedence (e.g., the 50-character title limit).

## FAQ

- Is the sync script non-interactive? It is interactive: choose local vs. repo per item and decide whether to commit and push at the end.
- No colored diffs? Optionally install `colordiff`; the script will auto-detect and use it.

## License

MIT License
