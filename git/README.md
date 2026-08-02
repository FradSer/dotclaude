# Git Plugin

Conventional Git automation, advanced repository management, and GitFlow workflow automation.

**Version**: 0.6.0

## Installation

```bash
claude plugin install git@frad-dotclaude
```

## Overview

This plugin automates commits via **git-agent** and drives the full GitFlow lifecycle (feature, hotfix, release branches) through the git-flow-next CLI, with post-finish cleanup.

- **Conventional Commits**: AI-generated messages follow the conventional commits specification.
- **Auto Co-Author**: Every commit carries a `Co-Authored-By` trailer derived from the executing model's identity.
- **GitFlow Automation**: `/start-*` skills resolve branch names or next versions (semver-aware); `/finish-*` skills run tests, generate the changelog, merge, and tag.
- **Post-Finish Cleanup**: Prunes stale remote-tracking branches and worktrees after every finish operation.
- **Safety**: A PreToolUse hook guards raw `git add` / `git commit` (see Safety).

## Skills

This plugin provides 8 user-invocable skills:

### Commit

- `/commit` — Creates a conventional commit via git-agent. Derives the co-author from the running model; retries with `--free` on auth errors; falls back to manual `git commit` when git-agent is unavailable.
- `/commit-and-push` — All of `/commit`, then pushes to the remote (setting the upstream if needed).

### GitFlow

- `/start-feature [name-or-description]` — Starts a `feature/*` branch from develop via git-flow-next.
- `/finish-feature [name]` — Runs tests, updates the changelog, finishes the feature into develop, pushes, and cleans up.
- `/start-hotfix [version-or-description]` — Resolves the next patch version and starts a `hotfix/*` branch from main, bumping version files.
- `/finish-hotfix [version]` — Runs tests, generates the changelog, finishes the hotfix into main and develop with a tag, and cleans up.
- `/start-release [version-or-description]` — Resolves the next semver version and starts a `release/*` branch from develop, bumping version files.
- `/finish-release [version]` — Runs tests, generates the changelog, finishes the release with a tag, creates a GitHub release, and cleans up.

Finish skills run tests first and abort on failure. Changelog content is derived from commits since the previous tag (see `references/changelog-generation.md`).

## Safety

A PreToolUse hook (`hooks/validate-commit-pretool.sh`) intercepts raw `git add` / `git commit` and redirects to the `/git:commit` skill. Two exceptions pass the guard: scoped staging chained with git-agent in one command (`git add <path> && git-agent commit --no-stage ...`), and the skills' manual fallback path.

The plugin never runs destructive commands (`force push`, `hard reset`).

## Configuration

Edit `.git-agent/config.yml` directly to customize scopes, hooks, or other settings. Use `git-agent config set <key> <value>` for individual fields.

## Troubleshooting

- **git-agent auth error**: Retry with `--free` flag, or configure `~/.config/git-agent/config.yml`.
- **git-agent not installed**: The skills fall back to the `/git:commit` skill, then to a manual `git commit` with conventional format and a `Co-Authored-By` trailer.
- **Nothing to commit**: Verify changes are not ignored.
- **Push failed**: Check remote permissions and branch protection rules.

## References

- `references/invariants.md` — pre-operation checks, changelog rules, commit ladder
- `references/cleanup.md` — post-finish branch and worktree cleanup
- `references/changelog-generation.md` — changelog include/exclude rules
- `references/cli.md` — git-agent CLI reference

## Author

Frad LEE (fradser@gmail.com)

## License

MIT
