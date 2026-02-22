# GitFlow Plugin

GitFlow workflow automation using [git-flow-next](https://git-flow.sh/docs/) CLI.

**Version**: 1.0.1

## Installation

```bash
claude plugin install gitflow@frad-dotclaude
```

## Requirements

- **git-flow-next** CLI installed ([installation guide](https://git-flow.sh/docs/installation/))
  - macOS: `brew install gittower/tap/git-flow-next`
- Git configured
- Repository initialized with `git flow init`

## Overview

Automates the GitFlow branching model — feature branches off `develop`, hotfixes off `main`, and releases merged into both. All finish operations generate changelogs from conventional commit history and enforce branch naming conventions defined in `references/invariants.md`.

## Skills

### `/gitflow:start-feature <name>`

Start a new feature branch from `develop`.

```bash
/gitflow:start-feature user-authentication
```

### `/gitflow:finish-feature [name]`

Finish the current feature branch and merge into `develop`.

```bash
/gitflow:finish-feature
```

### `/gitflow:start-hotfix <version>`

Start a hotfix branch from `main` for a critical production fix.

```bash
/gitflow:start-hotfix 1.2.4
```

### `/gitflow:finish-hotfix [version]`

Finish the hotfix and merge into both `main` and `develop`.

```bash
/gitflow:finish-hotfix
```

### `/gitflow:start-release <version>`

Start a release branch from `develop`.

```bash
/gitflow:start-release 1.3.0
```

### `/gitflow:finish-release [version]`

Finish the release and merge into both `main` and `develop` with a version tag.

```bash
/gitflow:finish-release
```

## Reference Documentation

### Plugin References

- `references/invariants.md` — Core rules enforced by plugin
- `references/changelog-generation.md` — Conventional commit to changelog mapping
- `examples/changelog.md` — Keep a Changelog format

### External References

- [git-flow-next Documentation](https://git-flow.sh/docs/)
- [git-flow-next Commands](https://git-flow.sh/docs/commands/)
- [git-flow-next Cheat Sheet](https://git-flow.sh/docs/cheat-sheet/)

## Author

Frad LEE (fradser@gmail.com)

## License

MIT
