# Semantic Version Calculation

This document describes how semantic versions are calculated from conventional commits in GitFlow workflows.

## Semantic Versioning (SemVer)

Versions follow the format: `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes that are incompatible with previous versions
- **MINOR**: New features that are backward compatible
- **PATCH**: Bug fixes that are backward compatible

## Version Bump Rules

### Major Version (X.0.0)

Bump major version when:
- Commit contains `BREAKING CHANGE:` in footer
- Commit type includes `!` (e.g., `feat!:`, `fix(api)!:`)
- Breaking API changes are introduced

**Example:**
```
feat(api)!: migrate to oauth 2.0

BREAKING CHANGE: Authentication API now requires OAuth 2.0 tokens.
```

Result: `v1.2.3` → `v2.0.0`

### Minor Version (0.X.0)

Bump minor version when:
- Commit type is `feat:` (new feature)
- No breaking changes present

**Example:**
```
feat(auth): add google oauth login flow
```

Result: `v1.2.3` → `v1.3.0`

### Patch Version (0.0.X)

Bump patch version when:
- Commit type is `fix:` (bug fix)
- No breaking changes or new features

**Example:**
```
fix(api): handle null payload in session refresh
```

Result: `v1.2.3` → `v1.2.4`

## Calculation Algorithm

### For Release Branches

1. **Find base version**: Get latest tag from `main` branch
   - If no tags exist, start from `v0.1.0`
   - Parse tag format: `v1.2.3` or `1.2.3`

2. **Analyze commits**: Scan commits from base tag to `develop` branch
   - Use: `git log <base-tag>..develop --oneline`

3. **Determine bump type**:
   - If any commit has `BREAKING CHANGE` or `!` → **MAJOR**
   - Else if any commit has `feat:` → **MINOR**
   - Else if any commit has `fix:` → **PATCH**
   - Else → **PATCH** (default for other changes)

4. **Calculate new version**:
   - MAJOR: `v2.0.0` (reset minor and patch)
   - MINOR: `v1.3.0` (increment minor, reset patch)
   - PATCH: `v1.2.4` (increment patch)

### For Hotfix Branches

1. **Get current version**: Latest tag on `main` branch

2. **Always bump PATCH**: Hotfixes are patch-level fixes
   - `v1.2.3` → `v1.2.4`

3. **Exception**: If hotfix contains breaking change, bump MAJOR
   - Rare but possible for critical breaking fixes

## Version Detection Examples

### Example 1: Feature Release

**Commits since v1.2.0:**
```
feat(auth): add oauth login
fix(api): handle null payload
docs: update readme
```

**Analysis:**
- Has `feat:` → MINOR bump
- Result: `v1.3.0`

### Example 2: Breaking Change Release

**Commits since v1.2.0:**
```
feat(api)!: migrate to oauth 2.0

BREAKING CHANGE: API requires OAuth 2.0 tokens
feat(auth): add google login
fix(ui): update login form
```

**Analysis:**
- Has `BREAKING CHANGE` → MAJOR bump
- Result: `v2.0.0`

### Example 3: Bugfix Release

**Commits since v1.2.0:**
```
fix(api): handle null payload
fix(ui): correct date formatting
chore: update dependencies
```

**Analysis:**
- Only `fix:` commits → PATCH bump
- Result: `v1.2.1`

### Example 4: Hotfix

**Current version:** `v1.2.3`

**Hotfix commits:**
```
fix(payment): resolve gateway timeout
```

**Analysis:**
- Hotfix always PATCH bump
- Result: `v1.2.4`

## Version File Updates

After calculating version, update project files:

### Node.js (package.json)

```json
{
  "version": "1.2.4"
}
```

### Python (__version__.py)

```python
__version__ = "1.2.4"
```

### Rust (Cargo.toml)

```toml
[package]
version = "1.2.4"
```

### Generic (VERSION or version.txt)

```
1.2.4
```

## Tag Format

Create tags in format: `v1.2.4` or `1.2.4`

**Recommended:** Use `v` prefix for consistency:
```bash
git tag -a v1.2.4 -m "Release v1.2.4"
```

## Changelog Integration

Generate changelog entries grouped by version:

```markdown
## [1.2.4] - 2025-01-15

### Fixed
- fix(payment): resolve gateway timeout

## [1.2.3] - 2025-01-10

### Added
- feat(auth): add google oauth login

### Fixed
- fix(api): handle null payload
```

## Best Practices

1. **Always tag releases**: Create tags on `main` after release/hotfix merge
2. **Consistent format**: Use `v` prefix for all tags
3. **Changelog updates**: Update CHANGELOG.md with each version
4. **Version files**: Keep version files in sync with git tags
5. **Breaking changes**: Clearly mark breaking changes in commits
