# Context Gathering for GitFlow Operations

This document describes the context information that should be gathered before executing GitFlow operations.

## Common Context Items

### Git Repository State

- **Current branch**: `git branch --show-current`
  - Identifies the active branch before operation
  - Used to determine if already on target branch

- **Git status**: `git status --porcelain`
  - Checks for uncommitted changes
  - Ensures clean working tree before branch operations

- **Recent commits**: `git log --oneline -5`
  - Shows recent commit history
  - Helps understand current state of branch

## Feature Branch Context

### Start Feature

- **Current branch**: Current active branch
- **Existing feature branches**: List all feature branches
  ```bash
  git branch --list 'feature/*' | sed 's/^..//'
  ```
- **Git status**: Check for uncommitted changes

### Finish Feature

- **Current branch**: Verify on feature branch
- **Git status**: Ensure all changes are committed
- **Recent commits**: Review commits to be merged
- **Test commands available**: Detect testing frameworks
  - Check for `package.json` (npm/yarn)
  - Check for `pytest.ini` or `setup.py` (Python)
  - Check for `Cargo.toml` (Rust)
  - Check for `go.mod` (Go)
  - Check for other test configuration files

## Hotfix Branch Context

### Start Hotfix

- **Current branch**: Current active branch
- **Existing hotfix branches**: List all hotfix branches
  ```bash
  git branch --list 'hotfix/*' | sed 's/^..//'
  ```
- **Latest tag**: Get most recent version tag
  ```bash
  git tag --list --sort=-creatordate | head -1
  ```
- **Current version from main**: Inspect version files on main branch
  - Check `package.json` for Node.js projects
  - Check `__version__.py` or `setup.py` for Python
  - Check `Cargo.toml` for Rust
  - Check `VERSION` or `version.txt` for generic projects
- **Git status**: Check for uncommitted changes

### Finish Hotfix

- **Current branch**: Verify on hotfix branch
- **Git status**: Ensure all changes are committed
- **Recent commits**: Review hotfix commits
- **Test commands available**: Detect testing frameworks
- **Current version**: Check version information in project files

## Release Branch Context

### Start Release

- **Current branch**: Current active branch
- **Existing release branches**: List all release branches
  ```bash
  git branch --list 'release/*' | sed 's/^..//'
  ```
- **Latest tag**: Get most recent version tag
  ```bash
  git tag --list --sort=-creatordate | head -1
  ```
- **Conventional commit scan**: Analyze commits since last tag
  ```bash
  git log $(git describe --tags --abbrev=0 2>/dev/null || echo)..develop --oneline --grep="feat\|fix\|BREAKING" 2>/dev/null || git log develop --oneline --grep="feat\|fix\|BREAKING"
  ```
- **Current version**: Inspect project configuration files

### Finish Release

- **Current branch**: Verify on release branch
- **Existing release branches**: List all release branches
- **Git status**: Ensure all changes are committed
- **Recent commits**: Review release commits
- **Test commands available**: Detect testing frameworks
- **Current version**: Check version information in project files

## Context Gathering Workflow

### Step 1: Repository State

1. Check current branch
2. Verify git status (should be clean)
3. List relevant existing branches

### Step 2: Version Information

1. Get latest tag from repository
2. Inspect version files on appropriate branch (main for hotfix, develop for release)
3. Calculate next version if needed

### Step 3: Commit Analysis

1. Scan commit history since last tag
2. Identify conventional commit types
3. Determine version bump type (major/minor/patch)

### Step 4: Project Configuration

1. Detect testing frameworks
2. Identify version file locations
3. Check for changelog files

## Best Practices

1. **Always check git status first**: Ensure clean working tree
2. **Verify branch context**: Confirm correct branch before operations
3. **Check for existing branches**: Avoid duplicate branch names
4. **Validate version files**: Ensure version files exist and are readable
5. **Test framework detection**: Use appropriate test commands for project type

## Error Handling

### Missing Branches

If required branches don't exist:
- **develop**: Create from main/master
- **main/master**: Should always exist in GitFlow repositories

### Missing Tags

If no tags exist:
- Start versioning from `v0.1.0`
- Create initial tag on first release

### Uncommitted Changes

If working tree is not clean:
- Stash changes if appropriate
- Commit changes if they belong to current operation
- Abort if changes conflict with operation
