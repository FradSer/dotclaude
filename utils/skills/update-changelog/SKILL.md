---
name: update-changelog
description: Creates or updates CHANGELOG.md following the Keep a Changelog 1.1.0 format. Use this skill when the user asks to "update the changelog", "generate changelog", "add changelog entry", "create CHANGELOG.md", "sync changelog with tags", or wants to document project changes based on git tags and commit history.
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "Bash(git:*)"]
disable-model-invocation: true
---

# Update Changelog

Create or update CHANGELOG.md following the [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) format, using git tags as version boundaries.

## CRITICAL: Human-First Entries and Format

- Do NOT copy commit messages verbatim. Changelogs are for humans -- readers who care about what changed and why, not how the code was modified. Group related commits into logical changes and write each entry as a clear, meaningful description.
- The `[Unreleased]` section MUST always be present, even if empty.
- Versions MUST be in reverse chronological order (newest first), with ISO 8601 dates (`YYYY-MM-DD`).
- Omit empty categories -- only include categories that have entries.
- When updating an existing changelog, preserve any hand-edited entries in existing version sections -- do not overwrite them.

See `references/keepachangelog-format.md` for the full format specification.

## Process

### 1. Gather git tag and remote info

Run these commands to understand the project's release history:

```bash
git tag --sort=-v:refname
git log --oneline --decorate
git remote get-url origin
```

Collect:
- All tags sorted by version (descending). Both `v1.0.0` and `1.0.0` prefixes are valid -- detect which convention the project uses and stay consistent.
- The remote URL to construct diff comparison links.
- The hosting platform (GitHub, GitLab, Bitbucket) to pick the correct comparison URL pattern.

If no tags exist, inform the user and generate only an `[Unreleased]` section from the full commit history.

### 2. Check for existing CHANGELOG.md

Look for `CHANGELOG.md` (case-insensitive) in the project root.

- **Exists**: Read it. Preserve any hand-written content. Only add or update version sections that are missing or incomplete.
- **Does not exist**: Create a new file from scratch.

### 3. Build version sections from git history

For each pair of adjacent tags (newest to oldest), extract commits with their full messages:

```bash
git log --format="%h %s%n%b" <older-tag>..<newer-tag>
```

For the oldest tag:

```bash
git log --format="%h %s%n%b" <oldest-tag>
```

For unreleased changes (commits after the latest tag):

```bash
git log --format="%h %s%n%b" <latest-tag>..HEAD
```

Get the tag date for each version:

```bash
git log -1 --format=%ai <tag>
```

### 4. Synthesize meaningful changelog entries

Do NOT copy commit messages verbatim. Changelogs are for humans -- readers who care about what changed and why, not how the code was modified.

Analyze the full commit messages gathered in step 3 (subject lines and bodies) to understand the intent and impact of each change. Group related commits into logical changes. Multiple commits that together implement one feature become a single entry. A refactor that splits one file into three is one change, not three.

Classify each logical change into exactly one category (in this order of precedence):

| Category | What belongs here |
|----------|-------------------|
| **Added** | New capabilities users can now do |
| **Changed** | Existing behavior that now works differently |
| **Deprecated** | Capabilities that will be removed in a future version |
| **Removed** | Capabilities that no longer exist |
| **Fixed** | Broken behavior that now works correctly |
| **Security** | Vulnerabilities that have been addressed |

Omit changes with no user-facing impact (internal refactors, CI tweaks, test additions, doc typo fixes) unless they substantially affect the development experience for contributors.

Write each entry as a clear, meaningful description:
- Describe **what the user can now do** or **what changed for them**, not what files were touched.
- Provide enough context that a reader unfamiliar with the codebase understands the significance.
- Consolidate: 5 commits fixing the same parser become one entry like "Fix CSV parser failing on quoted fields with newlines".
- One entry per line, prefixed with `- `.

**Bad** (git log copy-paste):
```
- Update auth middleware
- Fix bug in login
- Refactor token validation
```

**Good** (meaningful for readers):
```
- Session tokens now refresh automatically 5 minutes before expiry, eliminating unexpected logouts during long sessions
- Fix login failing silently when the email contains uppercase characters
```

### 5. Assemble the changelog

Follow this exact structure. See `references/keepachangelog-format.md` for the full format specification.

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [x.y.z] - YYYY-MM-DD

### Added
- Entry

### Fixed
- Entry

[Unreleased]: https://github.com/owner/repo/compare/vx.y.z...HEAD
[x.y.z]: https://github.com/owner/repo/compare/vPREV...vx.y.z
```

Rules:
- Versions in reverse chronological order (newest first).
- Dates in ISO 8601 format (`YYYY-MM-DD`).
- Omit empty categories -- only include categories that have entries.
- The `[Unreleased]` section is always present, even if empty.
- Footer contains comparison links for every version.
- The first (oldest) release links to its tag, not a comparison.

### 6. Write the file

Write CHANGELOG.md to the project root. After writing, briefly confirm what was generated (number of versions, notable entries).

## Updating an existing changelog

When CHANGELOG.md already exists:

1. Parse existing version sections and their entries.
2. Identify tags not yet represented in the changelog.
3. Add only missing version sections in the correct chronological position.
4. Refresh the `[Unreleased]` section with commits after the latest tag.
5. Update footer diff links to include all versions.
6. Preserve any hand-edited entries in existing version sections -- do not overwrite them.

## References

- `references/keepachangelog-format.md` -- Full format specification, diff link patterns, and category ordering
