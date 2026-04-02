# Keep a Changelog Format Reference

Source: https://keepachangelog.com/en/1.1.0/

## File Structure

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2023-03-05

### Added
- New feature description

### Changed
- Modification to existing functionality

### Deprecated
- Feature planned for removal

### Removed
- Deleted feature

### Fixed
- Bug fix description

### Security
- Vulnerability patch description

## [1.0.0] - 2023-01-15

### Added
- Initial release features

[Unreleased]: https://github.com/owner/repo/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/owner/repo/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/owner/repo/releases/tag/v1.0.0
```

## Change Type Categories

Only these six categories are valid. Use them in this exact order when present:

1. `Added` -- new features
2. `Changed` -- changes to existing functionality
3. `Deprecated` -- soon-to-be removed features
4. `Removed` -- now removed features
5. `Fixed` -- bug fixes
6. `Security` -- vulnerability fixes

Omit any category that has no entries for a given version.

## Rules

- Versions are listed in reverse chronological order (newest first).
- Dates use ISO 8601 format: `YYYY-MM-DD`.
- Each version heading links to a diff comparison (see footer links).
- The `[Unreleased]` section sits at the top, tracking changes not yet in a release.
- At release time, entries move from `[Unreleased]` into the new version section.
- The first release has no comparison link -- use a tag link instead.
- Yanked releases are marked with `[YANKED]` suffix: `## [1.0.1] - 2023-02-01 [YANKED]`.

## Guiding Principles

- Changelogs are for humans, not machines.
- There should be an entry for every single version.
- The same types of changes should be grouped.
- Versions and sections should be linkable.
- The latest version comes first.
- The release date of each version is displayed.
- Mention whether the project follows Semantic Versioning.

## Diff Link Patterns

### GitHub
```
[Unreleased]: https://github.com/OWNER/REPO/compare/vVERSION...HEAD
[VERSION]: https://github.com/OWNER/REPO/compare/vPREVIOUS...vVERSION
[FIRST_VERSION]: https://github.com/OWNER/REPO/releases/tag/vFIRST_VERSION
```

### GitLab
```
[Unreleased]: https://gitlab.com/OWNER/REPO/-/compare/vVERSION...HEAD
[VERSION]: https://gitlab.com/OWNER/REPO/-/compare/vPREVIOUS...vVERSION
```

### Bitbucket
```
[Unreleased]: https://bitbucket.org/OWNER/REPO/branches/compare/HEAD..vVERSION
[VERSION]: https://bitbucket.org/OWNER/REPO/branches/compare/vVERSION..vPREVIOUS
```
