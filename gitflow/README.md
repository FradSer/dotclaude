# GitFlow Plugin

> **Version**: 1.0.1

GitFlow workflow automation using [git-flow-next](https://git-flow.sh/docs/) CLI.

## Installation

```bash
claude plugin install gitflow@frad-dotclaude
```

## Requirements

- **git-flow-next** CLI installed ([installation guide](https://git-flow.sh/docs/installation/))
  - macOS: `brew install gittower/tap/git-flow-next`
- Git configured
- Repository initialized with `git flow init`

## Commands

### `/gitflow:start-feature <name>`

```bash
/gitflow:start-feature user-authentication
```

### `/gitflow:finish-feature [name]`

```bash
/gitflow:finish-feature
```

### `/gitflow:start-hotfix <version>`

```bash
/gitflow:start-hotfix 1.2.4
```

### `/gitflow:finish-hotfix [version]`

```bash
/gitflow:finish-hotfix
```

### `/gitflow:start-release <version>`

```bash
/gitflow:start-release 1.3.0
```

### `/gitflow:finish-release [version]`

```bash
/gitflow:finish-release
```

## Reference Documentation

### Plugin References

- `references/invariants.md` - Core rules enforced by plugin
- `references/changelog-generation.md` - Conventional commit to changelog mapping
- `examples/changelog.md` - Keep a Changelog format

### External References

- [git-flow-next Documentation](https://git-flow.sh/docs/)
- [git-flow-next Commands](https://git-flow.sh/docs/commands/)
- [git-flow-next Cheat Sheet](https://git-flow.sh/docs/cheat-sheet/)

## Author

Frad LEE (fradser@gmail.com)
