---
name: start-hotfix
allowed-tools: ["Bash(git-agent:*)", "Bash(git:*)", "Read", "Write"]
description: Begins a hotfix for a production issue using git-flow. This skill should be used when the user asks to "start a hotfix", "create hotfix branch", "fix a critical bug", "git flow hotfix start", or wants to begin a hotfix. Accepts either an explicit version or a natural-language description of the fix.
model: haiku
argument-hint: <version-or-description>
user-invocable: true
disable-model-invocation: true
---

## Workflow Execution

**Launch a general-purpose agent** that executes all phases in a single task.

**Prompt template**:
```
Execute the start-hotfix workflow.

`$ARGUMENTS` is either an explicit semver version (e.g. `1.2.4`) OR a
natural-language description of the fix (e.g. "fix crash on empty input").
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
3. Otherwise, treat `$ARGUMENTS` as a description and bump the **patch** component of the latest tag
   (x.y.Z+1) — hotfixes are patch-level fixes to production by definition.
4. If `TARGET` is not strictly greater than the latest tag, abort:
   "Resolved version <TARGET> is not greater than the current latest tag <latest>."
5. Report the resolved version: "Resolved hotfix version: <TARGET> (from: $ARGUMENTS)."

## Phase 1: Start Hotfix
**Goal**: Create hotfix branch and bump version. Use `TARGET` from Phase 0 everywhere below.
1. Run `git flow hotfix start <TARGET>`
2. Update version in project files (package.json, Cargo.toml, VERSION, etc.) to `<TARGET>`
3. Stage version files: `git add <modified version files>`
4. Determine the Claude model name for co-author attribution
   - Derive it from your own runtime model identity (e.g. Claude Opus 4.8) so it never goes stale; do not hardcode a fixed version
5. Commit with git-agent: `git-agent commit --no-stage --intent "bump version to <TARGET>" --co-author "Claude <Model> <Version> <noreply@anthropic.com>"`
6. On auth error (401), retry with `--free`
7. **Fallback** (git-agent unavailable): `git commit -m "chore: bump version to <TARGET>"` with conventional format and `Co-Authored-By` footer
8. Push the branch: `git push -u origin hotfix/<TARGET>`
```

**Execute**: Launch a general-purpose agent using the prompt template above
