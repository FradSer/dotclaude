# Context Gathering for GitFlow Operations

Minimum context to collect before any start/finish operation:

## Repository state

- Current branch
- Working tree status (must be clean for finish; typically clean for start)
- Recent commits on the current branch

## Branch inventory (by operation)

- Start feature: list existing `feature/*` branches; confirm base branch exists
- Finish feature: confirm you are on the intended `feature/*` branch; identify target integration branch
- Start hotfix: list existing `hotfix/*` branches; identify production base branch (`main`/`production`)
- Finish hotfix: identify production merge target + integration propagation target
- Start release: list existing `release/*` branches; identify `develop` base branch
- Finish release: identify `main` merge target + `develop` back-merge target

## Versioning (if repo uses SemVer + tags)

- Latest tag on the production branch
- Current version in version files
- Conventional commits since the last tag (for release bump decisions)

## Test commands (if available)

Detect and run the appropriate test command(s) for the repository before finishing operations:
- Node.js: `pnpm test` or `npm test` (check for package.json)
- Python: `pytest` (check for pytest.ini or pyproject.toml)
- Swift: `swift test` (check for Package.swift)
- Other stacks: use the repo's documented test command (check README.md)

If no test command is found, proceed without running tests but inform the user.

