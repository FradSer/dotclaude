# GitFlow Plugin

GitFlow workflow automation for feature, hotfix, and release branches with semantic versioning and conventional commits.

## Overview

The GitFlow Plugin automates the GitFlow branching model, providing commands to start and finish feature, hotfix, and release branches. It ensures proper branch naming, merging, and tagging according to GitFlow conventions, with automatic versioning and changelog generation.

## GitFlow Branch Model

Three workflow presets are supported:

| Workflow | Description |
|----------|-------------|
| **Classic GitFlow** | main + develop with feature/, release/, hotfix/ branches |
| **GitHub Flow** | main with feature/ branches only |
| **GitLab Flow** | production + staging + main with feature/, hotfix/ branches |

## Commands

All commands use the `Skill` tool to load `gitflow-workflow` for GitFlow operations.

### `/gitflow:start-feature`

Start new feature branch from develop.

| Field | Value |
|-------|-------|
| Model | `haiku` |
| Allowed Tools | `Bash(git:*)`, `Read`, `Skill` |
| Argument | `[feature-name]` |

```bash
/gitflow:start-feature user-authentication
```

---

### `/gitflow:finish-feature`

Complete and merge feature branch to develop.

| Field | Value |
|-------|-------|
| Model | `haiku` |
| Allowed Tools | `Bash(git:*)`, `Read`, `Skill` |
| Argument | `[feature-name]` |

```bash
/gitflow:finish-feature
```

---

### `/gitflow:start-hotfix`

Start new hotfix branch from main.

| Field | Value |
|-------|-------|
| Model | `haiku` |
| Allowed Tools | `Bash(git:*)`, `Read`, `Write`, `Skill` |
| Argument | `[hotfix-name]` |

```bash
/gitflow:start-hotfix critical-security-fix
```

---

### `/gitflow:finish-hotfix`

Complete hotfix by merging to main and develop with version tagging.

| Field | Value |
|-------|-------|
| Model | `haiku` |
| Allowed Tools | `Bash(git:*)`, `Read`, `Write`, `Skill` |
| Argument | `[version]` |

```bash
/gitflow:finish-hotfix
```

---

### `/gitflow:start-release`

Start new release branch from develop.

| Field | Value |
|-------|-------|
| Model | `haiku` |
| Allowed Tools | `Bash(git:*)`, `Read`, `Write`, `Skill` |
| Argument | `[version]` |

```bash
/gitflow:start-release v1.2.0
# or auto-determine version
/gitflow:start-release
```

---

### `/gitflow:finish-release`

Complete release by merging to main and develop with version tagging.

| Field | Value |
|-------|-------|
| Model | `haiku` |
| Allowed Tools | `Bash(git:*)`, `Read`, `Write`, `Skill` |

```bash
/gitflow:finish-release
```

## Skills

### `gitflow-workflow`

Expert in GitFlow branching model and semantic versioning, based on [git-flow-next](https://git-flow.sh/docs/).

**Capabilities:**
- GitFlow branch model (main, develop, feature, hotfix, release, support)
- Workflow presets (Classic GitFlow, GitHub Flow, GitLab Flow)
- Semantic version calculation from conventional commits
- Branch naming validation and conventions
- Merge strategies (merge, rebase, squash, --no-ff)
- Version file updates and changelog generation
- git-flow-next command compatibility

**Reference Documentation:**
- `references/commands-core.md` - git-flow-next core commands (init, config)
- `references/commands-topic.md` - Topic branch commands (start, finish, etc.)
- `references/context-gathering.md` - Pre-operation context requirements
- `references/naming-rules.md` - Branch naming conventions
- `references/versioning-and-tags.md` - Version management and tagging
- `references/workflow-presets.md` - Workflow presets (Classic, GitHub, GitLab Flow)

**External References:**
- [git-flow-next Documentation](https://git-flow.sh/docs/)
- [git-flow-next Commands](https://git-flow.sh/docs/commands/)
- [git-flow-next Cheat Sheet](https://git-flow.sh/docs/cheat-sheet/)

## Best Practices

### Feature Development
- Use `/gitflow:start-feature` for all new features
- Keep features focused and short-lived (2-3 days max)
- Commit atomic changes with conventional format
- Run tests before finishing features

### Hotfix Workflow
- Use for urgent production fixes only
- Scope limited to critical bugs
- Patch version increment automatically
- Merges to both main and develop

### Release Process
- Start when feature set is complete
- Final testing and bug fixes on release branch
- Never add new features to release branch
- Auto-generates changelog from commits

## Complete Workflow Examples

### Feature Development:
```bash
# Start feature
/gitflow:start-feature user-authentication

# Develop with conventional commits
/git:commit
/git:commit

# Finish when complete
/gitflow:finish-feature
```

### Critical Hotfix:
```bash
# Start from production
/gitflow:start-hotfix fix-payment-bug
# Results in v1.2.3-patch.1

# Fix and test
/git:commit

# Deploy to production
/gitflow:finish-hotfix
# Creates v1.2.4 release
```

### Major Release:
```bash
# Start release preparation
/gitflow:start-release
# Auto-determines v1.2.0 from commits

# Final testing and fixes
/git:commit

# Release to production
/gitflow:finish-release
# Creates v1.2.0 release
```

## Requirements

- **git-flow-next** must be installed ([installation guide](https://git-flow.sh/docs/installation/))
  - macOS: `brew install gittower/tap/git-flow-next`
  - Manual: Download from [releases page](https://github.com/gittower/git-flow-next/releases)
- Git must be installed and configured
- Repository must have `main` or `master` branch
- Repository should have `develop` branch
- All commits must follow conventional format

## Troubleshooting

### git-flow-next not installed

If `git flow` command fails:

```bash
# Check if installed
git flow version

# If not found, install git-flow-next
# macOS:
brew install gittower/tap/git-flow-next

# Manual installation:
# 1. Download from https://github.com/gittower/git-flow-next/releases
# 2. Extract to PATH (e.g., /usr/local/bin/)
# 3. Make executable: chmod +x /path/to/git-flow
```

See [installation guide](https://git-flow.sh/docs/installation/) for detailed instructions.

### Branch not found
```bash
# Create missing branches
git checkout -b develop
git checkout -b main  # or master
```

### Merge conflicts
```bash
# Resolve conflicts manually
# Ensure branches are up-to-date
# Consider rebasing feature branches
```

### Version calculation error
```bash
# Ensure conventional commits format
# Tag previous releases properly
# Manually specify version if needed
```

## Commit Format

All GitFlow commands use the `@git/conventional-commits` skill for commit message formatting. This ensures:
- **Atomic commits**: One logical change per commit
- **Conventional format**: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
- **Proper structure**: Title, body, and footer formatting per Conventional Commits specification

## Version Tagging

- Hotfixes: v1.2.3 → v1.2.4 (patch)
- Releases: v1.1.0 → v1.2.0 (minor) or v2.0.0 (major)
- Tags created on main branch merge
- GitHub releases auto-generated

## Author

Frad LEE (fradser@gmail.com)

## Version

0.2.0
