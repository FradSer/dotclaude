# Lark CLI Skills Sync

**Upstream**: [larksuite/cli](https://github.com/larksuite/cli) `skills/` directory
**Last sync**: 2026-04-16

## Sync Strategy

Uses `git sparse-checkout` to clone only the `skills/` directory from upstream, then copies all contents into this directory (excluding SKILL.md and SYNC.md at the root level which are local additions).

## Local Additions

The following files are maintained locally and are NOT overwritten by sync:

- `SKILL.md` -- Top-level router skill (local orchestration layer)
- `SYNC.md` -- This file

## Running Sync

```bash
# Check for updates (dry-run)
bash office/scripts/sync-lark.sh --check

# Sync with backup
bash office/scripts/sync-lark.sh

# Force sync, skip confirmation
bash office/scripts/sync-lark.sh --force
```
