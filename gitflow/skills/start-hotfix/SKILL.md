---
name: start-hotfix
allowed-tools: ["Bash(git-agent:*)", "Bash(git:*)", "Read", "Write"]
description: Begins a hotfix for a production issue using git-flow. This skill should be used when the user asks to "start a hotfix", "create hotfix branch", "fix a critical bug", "git flow hotfix start", or wants to begin a hotfix.
model: haiku
argument-hint: <version>
user-invocable: true
disable-model-invocation: true
---

## Workflow Execution

**Launch a general-purpose agent** that executes all phases in a single task.

**Prompt template**:
```
Execute the start-hotfix workflow.

## Pre-operation Checks
Verify working tree is clean per `${CLAUDE_PLUGIN_ROOT}/references/invariants.md`.

## Phase 1: Start Hotfix
**Goal**: Create hotfix branch and bump version.
1. Run `git flow hotfix start $ARGUMENTS`
2. Update version in project files (package.json, Cargo.toml, VERSION, etc.)
3. Stage version files: `git add <modified version files>`
4. Determine the correct Claude model name for co-author attribution
   - Valid models: Claude Sonnet 4.6, Claude Opus 4.6, Claude Haiku 4.5
5. Commit with git-agent: `git-agent commit --no-stage --intent "bump version to $ARGUMENTS" --co-author "Claude <Model> <Version> <noreply@anthropic.com>"`
6. On auth error (401), retry with `--free`
7. **Fallback** (git-agent unavailable): `git commit -m "chore: bump version to $ARGUMENTS"` with conventional format and `Co-Authored-By` footer
8. Push the branch: `git push -u origin hotfix/$ARGUMENTS`
```

**Execute**: Launch a general-purpose agent using the prompt template above
