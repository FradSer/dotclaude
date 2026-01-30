# Changelog Generation from Conventional Commits

## Mapping Rules

This document defines how conventional commit types map to Keep a Changelog categories.

### Primary Mappings

| Commit Type | Changelog Category | Notes |
|-------------|-------------------|-------|
| `feat:` | **Added** | New features for users |
| `fix:` | **Fixed** | Bug fixes |
| `refactor:` | **Changed** | Code restructuring without behavior change |
| `perf:` | **Changed** | Performance improvements (note in description) |
| `docs:` | **Changed** | Documentation updates |
| `feat!:` or `BREAKING CHANGE:` | **Changed** | Breaking changes (mark explicitly) |
| deprecate keywords | **Deprecated** | Features marked for future removal |
| remove keywords | **Removed** | Features removed in this version |
| security keywords | **Security** | Security-related changes |

### Excluded Types

These commit types are **not included** in user-facing changelog:
- `chore:` - Maintenance tasks
- `build:` - Build system changes
- `ci:` - CI/CD pipeline changes
- `test:` - Test additions or modifications
- Merge commits

## Processing Algorithm

### Step 1: Collect Commits

```bash
git log --oneline --no-merges <previous-tag>..HEAD
```

### Step 2: Parse and Categorize

For each commit:
1. Extract type from format `type(scope): message`
2. Check for breaking change indicators:
   - `!` after type: `feat!:`, `fix!:`
   - `BREAKING CHANGE:` in commit footer
3. Categorize using mapping rules above
4. Extract scope and message for changelog entry

### Step 3: Format Entries

**Standard entry format:**
```markdown
- <message> (<scope>)
```

**Breaking change format:**
```markdown
- **BREAKING CHANGE**: <message> (<scope>)
```

**Examples:**
- `feat(auth): add OAuth2 support` → `- Add OAuth2 support (auth)`
- `fix(api): handle null responses` → `- Handle null responses (api)`
- `feat(ui)!: redesign navigation` → `- **BREAKING CHANGE**: Redesign navigation (ui)`

### Step 4: Group by Category

Organize entries under Keep a Changelog sections:

```markdown
## [v1.2.3] - 2026-01-30

### Added
- <feat entries>

### Changed
- <refactor/perf/docs entries>
- **BREAKING CHANGE**: <breaking entries>

### Deprecated
- <deprecation entries>

### Removed
- <removal entries>

### Fixed
- <fix entries>

### Security
- <security entries>
```

**Category ordering** (as per Keep a Changelog):
1. Added
2. Changed
3. Deprecated
4. Removed
5. Fixed
6. Security

### Step 5: Merge with Manual Entries

If `## [Unreleased]` contains manual entries:
1. Parse manual entries by category
2. Merge with generated entries
3. Deduplicate identical entries
4. **Prioritize manual curation** - if a commit has both manual and generated entry, keep manual version

## Detection Keywords

### Breaking Changes
- `BREAKING CHANGE:` in footer
- `!` after type: `feat!:`, `fix!:`
- Keywords in message: "breaking", "incompatible"

### Security
- Commit types: `security:`, `sec:`
- Keywords: "security", "vulnerability", "CVE", "XSS", "SQL injection", "authentication", "encryption"

### Deprecation
- Keywords: "deprecate", "deprecated", "deprecation", "obsolete"

### Removal
- Keywords: "remove", "delete", "drop support", "end of life"

## Special Cases

### Empty Categories
Omit categories with no entries. Don't include:
```markdown
### Added
(no entries)
```

### Multiple Scopes
If commits affect multiple areas, consider creating separate entries:
```
feat(ui): add dark mode
feat(api): add dark mode endpoint
```
→
```markdown
### Added
- Add dark mode (ui)
- Add dark mode endpoint (api)
```

### Commit Message Formatting
- Capitalize first letter of changelog entry
- Remove trailing periods
- Keep scope in parentheses
- Preserve links to issues/PRs if present: `(#123)`

## Example Workflow

**Input commits:**
```
d59f12f docs(refactor): restructure skills and add refs
bb5249c refactor(po): consolidate validation scripts
3e4e18e docs(gitflow): restructure skill documentation
```

**Generated changelog:**
```markdown
## [v1.6.1] - 2026-01-30

### Changed
- Restructure skills and add refs (refactor)
- Consolidate validation scripts (po)
- Restructure skill documentation (gitflow)
```
