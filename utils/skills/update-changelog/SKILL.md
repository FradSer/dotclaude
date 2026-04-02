---
name: update-changelog
description: Creates or updates CHANGELOG.md following the Keep a Changelog 1.1.0 format. Use this skill when the user asks to "update the changelog", "generate changelog", "add changelog entry", "create CHANGELOG.md", "sync changelog with tags", or wants to document project changes based on git tags and commit history.
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "Bash(git:*)"]
disable-model-invocation: true
---

# Update Changelog

Create or update CHANGELOG.md following the [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) format, using git tags as version boundaries.

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

For each pair of adjacent tags (newest to oldest), extract commits:

```bash
git log --oneline <older-tag>..<newer-tag>
```

For the oldest tag, extract all commits up to that tag:

```bash
git log --oneline <oldest-tag>
```

For unreleased changes (commits after the latest tag):

```bash
git log --oneline <latest-tag>..HEAD
```

Get the tag date for each version:

```bash
git log -1 --format=%ai <tag>
```

### 4. Classify commits into change types

Read each commit message and classify it into exactly one of these categories (in this order of precedence):

| Category | Commit indicators |
|----------|-------------------|
| **Added** | `feat`, new files, new functionality |
| **Changed** | `refactor`, `perf`, modifications to existing behavior |
| **Deprecated** | Explicit deprecation notices |
| **Removed** | Deletions, removals |
| **Fixed** | `fix`, bug corrections |
| **Security** | Security patches, vulnerability fixes |

Other commits (`docs`, `chore`, `test`, `ci`, `style`) go into the category that best reflects their user-facing impact. If a commit has no user-facing impact, omit it.

Rewrite commit messages into human-readable changelog entries:
- Strip conventional commit prefixes (`feat(scope):` becomes a plain sentence).
- Start each entry with a capital letter.
- Describe the change from a user's perspective, not the implementation.
- One entry per line, prefixed with `- `.

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

- `references/keepachangelog-format.md` -- Full format specification and diff link patterns
