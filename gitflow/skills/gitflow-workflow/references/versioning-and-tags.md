# SemVer, Conventional Commits, and Tags

## SemVer

Versions follow `MAJOR.MINOR.PATCH`.

## Version bump rules (conventional commits)

- MAJOR:
  - commit footer contains `BREAKING CHANGE:`, or
  - commit type includes `!` (e.g. `feat!:`, `fix(api)!:`)
- MINOR:
  - at least one `feat:` since last tag, and no breaking changes
- PATCH:
  - at least one `fix:` since last tag, and no breaking changes/features

## Calculation algorithm

### Release branches

1. Find base version: latest tag on the production branch (`main`/`production`).
   - If no tags exist, start at `v0.1.0`.
2. Analyze commits from base tag to the integration branch (often `develop`).
3. Determine bump type using the rules above.
4. Compute next version:
   - MAJOR: `vX+1.0.0` (reset minor/patch)
   - MINOR: `vX.Y+1.0` (reset patch)
   - PATCH: `vX.Y.Z+1`

### Hotfix branches

- Default to PATCH bump from latest tag on the production branch.
- Rare exception: truly breaking hotfix → MAJOR.

## Tag format

Prefer `vX.Y.Z` for consistency.

Example annotated tag:

`git tag -a v1.2.4 -m "Release v1.2.4"`

## Version file updates (common patterns)

- Node.js: `package.json` `"version": "1.2.4"`
- Python: `__version__.py` `__version__ = "1.2.4"`
- Rust: `Cargo.toml` `version = "1.2.4"`
- Generic: `VERSION` / `version.txt` contains `1.2.4`

