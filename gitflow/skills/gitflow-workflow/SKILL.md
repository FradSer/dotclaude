---
name: gitflow-workflow
description: Use this skill for GitFlow tasks: starting/finishing features, releases, hotfixes; managing branches; versioning; or general GitFlow operations.
user-invocable: false
allowed-tools: Read
version: 0.1.0
---

## Purpose

All detailed command manuals live under `./references/` and should be consulted when you need exact flags/options.

## Required invariants (used by the 6 skills)

### Preflight

- Working tree should be clean before start/finish operations.
- Confirm current branch and that the branch type matches the operation (`feature/*`, `hotfix/*`, `release/*`).
- Identify the active workflow preset (Classic GitFlow vs GitHub Flow vs GitLab Flow) before deciding base/target branches.

### Branch naming

- Use kebab-case and a strict prefix: `<type>/<kebab-case>` (e.g. `feature/user-authentication`).

### Finish behavior

- Prefer non-fast-forward merges when finishing (e.g. `--no-ff`) to preserve a visible integration history, unless the repo workflow config says otherwise.
- Run tests if available before finishing; fix failures before merging.
- After finishing hotfix/release, ensure the integration branch receives the changes (often merging back into `develop`).
- Delete topic branches locally and remotely after finishing when policy allows.

## Minimal templates (what the 6 skills assume)
The operation-specific templates have been moved into the corresponding `start-*` / `finish-*` skills to keep those tasks self-contained.

## Reference index

- `./references/context-gathering.md`
- `./references/naming-rules.md`
- `./references/workflow-presets.md`
- `./references/versioning-and-tags.md`
- `./references/commands-core.md`
- `./references/commands-topic.md`

## External References

- [git-flow-next Documentation](https://git-flow.sh/docs/)
- [git-flow-next Commands](https://git-flow.sh/docs/commands/)
- [git-flow-next Cheat Sheet](https://git-flow.sh/docs/cheat-sheet/)
