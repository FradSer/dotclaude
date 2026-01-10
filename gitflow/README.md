# GitFlow Plugin

GitFlow workflow automation for feature, hotfix, and release branches with semantic versioning and conventional commits.

## Overview

The GitFlow Plugin automates the GitFlow branching model, providing commands to start and finish feature, hotfix, and release branches. It ensures proper branch naming, merging, and tagging according to GitFlow conventions, with automatic versioning and changelog generation.

## GitFlow Branch Model

```
main/master (production)
  │
  ├── hotfix/v1.0.1 ──┐
  │                    │
  └── release/v1.1.0 ──┤
                       │
develop (integration)  │
  │                    │
  ├── feature/auth ────┘
  ├── feature/profile
  └── feature/settings
```

## Commands

### `/gitflow:start-feature`

Starts a new feature branch from develop or continues existing feature development.

**Usage:**
```bash
/gitflow:start-feature user-authentication
```

**Features:**
- Automatic `feature/[kebab-case-name]` format
- Branches from develop
- Clean working tree validation
- Publishes to origin for collaboration
- Atomic commits with conventional format

### `/gitflow:finish-feature`

Completes and merges feature development into develop branch.

**Usage:**
```bash
/gitflow:finish-feature
```

**Features:**
- Validates `feature/*` naming
- Runs full test suite
- Merges to develop with `--no-ff`
- Deletes branch locally and remotely
- Handles merge conflicts

### `/gitflow:start-hotfix`

Starts a new hotfix branch from main for urgent production fixes.

**Usage:**
```bash
/gitflow:start-hotfix critical-security-fix
```

**Features:**
- Branches from main/master
- Automatic patch version increment
- Updates version files
- Publishes hotfix branch
- Critical production fixes only

### `/gitflow:finish-hotfix`

Completes hotfix by merging to both main and develop, with version tagging.

**Usage:**
```bash
/gitflow:finish-hotfix
```

**Features:**
- Merges to both main and develop
- Creates version tag
- Updates changelog
- Creates GitHub release
- Deletes hotfix branches completely

### `/gitflow:start-release`

Starts a new release branch from develop for preparing production releases.

**Usage:**
```bash
/gitflow:start-release v1.2.0
# or auto-determine version
/gitflow:start-release
```

**Features:**
- Semantic version calculation from commits
- Breaking changes → major bump (v2.0.0)
- New features → minor bump (v1.2.0)
- Bug fixes → patch bump (v1.1.1)
- Auto-generates changelog
- Updates version files

### `/gitflow:finish-release`

Completes release by merging to main and develop with version tagging.

**Usage:**
```bash
/gitflow:finish-release
```

**Features:**
- Comprehensive test validation
- Version tagging with release notes
- Dual merge to main + develop
- GitHub release creation
- Complete branch cleanup

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

- Git must be installed and configured
- Repository must have `main` or `master` branch
- Repository should have `develop` branch
- All commits must follow conventional format

## Troubleshooting

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

## Commit Format Enforcement

All GitFlow commands enforce:
- **Atomic commits**: One logical change per commit
- **Conventional format**: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
- **Title**: lowercase, <50 chars, imperative mood
- **Body**: Describes what changed and why (≤72 chars)
- **Footer**: References issues with auto-closing keywords

## Version Tagging

- Hotfixes: v1.2.3 → v1.2.4 (patch)
- Releases: v1.1.0 → v1.2.0 (minor) or v2.0.0 (major)
- Tags created on main branch merge
- GitHub releases auto-generated

## Author

Frad LEE (fradser@gmail.com)

## Version

1.0.0
