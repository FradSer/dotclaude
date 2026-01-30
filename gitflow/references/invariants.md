# GitFlow Plugin Invariants

Core rules enforced by this plugin.

## Pre-operation Checks

Before any start/finish operation:
- Working tree must be clean (`git status`)
- Current branch must match operation type
  (`feature/*`, `hotfix/*`, `release/*`)

## Testing Requirements

Before finishing any branch:
- Run available test commands (npm test, pytest, etc.)
- Exit if tests fail; user must fix issues first

## Changelog Generation

When updating CHANGELOG.md during finish operations:

**Core principle:** Include commits representing **user-facing
changes** since the previous version tag.

**Include types:**
- feat, fix, refactor, docs, perf
- Security-related changes
- Deprecation and removal notices

**Exclude types:**
- chore, build, ci, test
- Merge commits and release commits

See `changelog-generation.md` for complete mapping rules.

## External References

- [git-flow-next Documentation](https://git-flow.sh/docs/)
- [git-flow-next Commands](https://git-flow.sh/docs/commands/)
