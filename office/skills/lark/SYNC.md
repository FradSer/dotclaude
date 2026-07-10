# Lark CLI Skills Sync

**Upstream**: [larksuite/cli](https://github.com/larksuite/cli) `skills/` (main branch)
**Last sync**: 2026-07-10
**lark-cli version**: 1.0.68
**Synced commit**: 0dd844c

## Sync Strategy

Uses `git sparse-checkout` to clone only the `skills/` directory from upstream `main`, then mirrors all contents into this directory (excluding `SKILL.md` and `SYNC.md` at the root level, which are local additions). Directories removed upstream (e.g. `lark-whiteboard-cli`, merged into `lark-whiteboard`) are deleted locally to match.

## Version Tracking

`**lark-cli version**` records the locally installed `lark-cli` at sync time; `**Synced commit**` records the upstream `main` commit the skills were pulled from. Re-sync whenever `lark-cli` updates so the bundled skills stay aligned with the CLI you actually run. The sync script refreshes all three header fields automatically on each run.

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
