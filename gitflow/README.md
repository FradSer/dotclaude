# GitFlow Plugin

GitFlow workflow automation for feature, hotfix, and release branches.

## Overview

Automates the GitFlow branching model with commands to start and finish feature, hotfix, and release branches.

## Branch Model

```
main (production)
  ├── hotfix/v1.0.1
  └── release/v1.1.0
develop (integration)
  ├── feature/auth
  └── feature/profile
```

## Commands

### Feature Development

```bash
/gitflow:start-feature user-auth    # Create feature/user-auth from develop
/gitflow:finish-feature             # Merge to develop, delete branch
```

### Hotfix (Production Fixes)

```bash
/gitflow:start-hotfix security-fix  # Create hotfix from main
/gitflow:finish-hotfix              # Merge to main+develop, tag, release
```

### Release

```bash
/gitflow:start-release              # Auto-version from commits
/gitflow:finish-release             # Merge, tag, release
```

## Command Reference

| Command | Description |
|---------|-------------|
| `/gitflow:start-feature [name]` | Start feature branch from develop |
| `/gitflow:finish-feature` | Merge feature to develop |
| `/gitflow:start-hotfix [name]` | Start hotfix from main |
| `/gitflow:finish-hotfix` | Merge hotfix to main+develop, tag |
| `/gitflow:start-release` | Start release from develop |
| `/gitflow:finish-release` | Merge release, tag, GitHub release |

## Versioning

- **Hotfix**: Patch bump (v1.2.3 → v1.2.4)
- **Release**: Minor/major bump based on commits
  - `feat:` → minor (v1.2.0)
  - `BREAKING CHANGE:` → major (v2.0.0)
  - `fix:` only → patch (v1.1.1)

## Requirements

- Git installed
- `main` and `develop` branches exist
- Conventional commits format

## Author

Frad LEE (fradser@gmail.com)

## Version

1.0.0
