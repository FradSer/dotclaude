---
name: start-release
allowed-tools: ["Bash(git-agent:*)", "Bash(git:*)", "Read", "Write"]
description: Begins a new version release using git-flow. This skill should be used when the user asks to "start a release", "create release branch", "prepare a release", "git flow release start", or wants to begin a new version release. Accepts either an explicit version or a natural-language description of the release.
model: haiku
argument-hint: <version-or-description>
user-invocable: true
disable-model-invocation: true
---

## Workflow Execution

**Launch a general-purpose agent** that executes all phases in a single task.

**Prompt template**:
```
Execute the start-release workflow.

`$ARGUMENTS` is either an explicit semver version (e.g. `1.3.0`) OR a
natural-language description of the release (e.g. "add dark mode and fix login").
Phase 0 resolves it to a concrete target version.

CRITICAL:
- Verify working tree is clean (`git status --porcelain` is empty) before starting. Abort if dirty.
- The resolved target version MUST be strictly greater than the latest tag (semver), else abort.
See `${CLAUDE_PLUGIN_ROOT}/references/invariants.md` for details.

## Phase 0: Resolve Target Version
**Goal**: Turn `$ARGUMENTS` into a concrete next version `TARGET`.
1. Run `git tag --sort=-v:refname | head -1` to get the latest tag; strip the leading `v`.
   If no tags exist, treat the latest as `0.0.0`.
2. If `$ARGUMENTS` matches a semver pattern (`^v?\d+\.\d+\.\d+$`), use it directly as `TARGET` (strip any `v`).
3. Otherwise, treat `$ARGUMENTS` as a description and choose a semver bump from the latest tag:
   - **major** (X+1.0.0): breaking/incompatible changes, removals, a rewrite, or wording like "major", "breaking", "2.0"
   - **minor** (x.Y+1.0): new feature(s) or enhancements — the default for a release when unsure
   - **patch** (x.y.Z+1): only bug fixes / no new behavior
   To disambiguate, you MAY inspect commits since the latest tag: `git log <latest-tag>..develop --oneline` (feat -> minor, fix-only -> patch, breaking -> major).
4. Set `TARGET` to the bumped version. If `TARGET` is not strictly greater than the latest tag, abort:
   "Resolved version <TARGET> is not greater than the current latest tag <latest>."
5. Report the resolved version: "Resolved release version: <TARGET> (from: $ARGUMENTS)."

## Phase 1: Start Release
**Goal**: Create release branch and bump version. Use `TARGET` from Phase 0 everywhere below.
1. Run `git flow release start <TARGET>`
2. Update version in project files (package.json, Cargo.toml, VERSION, etc.) to `<TARGET>`
3. Determine the Claude model name for co-author attribution
   - Derive it from your own runtime model identity (e.g. Claude Opus 4.8) so it never goes stale; do not hardcode a fixed version
4. Stage and commit in ONE chained command — a standalone `git add` is denied (see invariants.md §Committing): `git add <modified version files> && git-agent commit --no-stage --intent "bump version to <TARGET>" --co-author "Claude <Model> <Version> <noreply@anthropic.com>"`
5. On auth error (401), retry with `--free`
6. **Fallback** (git-agent unavailable): invoke the `/git:commit` skill via the Skill tool; full ladder in invariants.md §Committing
7. Push the branch: `git push -u origin release/<TARGET>`

**Note**: CHANGELOG.md is updated during finish-release, not here.
```

**Execute**: Launch a general-purpose agent using the prompt template above
