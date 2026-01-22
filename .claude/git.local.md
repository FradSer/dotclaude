---
enabled: true
# Commit Message Conventions
scopes:
  - git
  - gitflow
  - refactor
  - office
  - po
  - claude-config
  - utils
  - docs
  - ci
types:
  - feat
  - fix
  - docs
  - refactor
  - test
  - chore
  - perf
# Branch Naming Conventions
branch_prefixes:
  feature: feature/*
  fix: fix/*
  hotfix: hotfix/*
  refactor: refactor/*
  docs: docs/*
---

# Project-Specific Git Settings

This file configures the git plugin for this project. The settings above in the YAML frontmatter define valid scopes, types, and branch naming conventions.

## Scopes

- **git**: Git plugin and commit-related changes
- **gitflow**: GitFlow workflow commands and documentation
- **refactor**: Code refactoring plugin
- **office**: Office/patent-architect plugin
- **po**: Plugin optimizer plugin
- **claude-config**: Claude configuration plugin
- **utils**: Utility modules and helpers
- **docs**: Documentation files and guides
- **ci**: CI/CD configuration and GitHub Actions

## Usage

- When creating a commit with `/git:commit`, choose from the defined scopes
- Ensure all tests pass before committing
- Reference issue numbers in commit footers if applicable
- Use conventional commits format: `type(scope): description`
