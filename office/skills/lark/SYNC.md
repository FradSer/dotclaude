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

- `SKILL.md` -- Top-level router skill (local orchestration layer). Its Sub-skill Index table is regenerated from sub-skill frontmatter by `office/scripts/gen-lark-index.py` (see below) — do not hand-edit the table rows; edit the description in each `lark-*/SKILL.md` and rerun the script.
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

## Regenerating the SKILL.md Index Table

After every sync (or whenever a sub-skill's `description` frontmatter
changes), regenerate the Sub-skill Index table in `SKILL.md` so it matches
the real sub-directories:

```bash
# Rewrite the index table from sub-skill frontmatter
python3 office/scripts/gen-lark-index.py

# Dry-run: exit 1 if the table is stale, 0 if in sync
python3 office/scripts/gen-lark-index.py --check
```

The script reads `name` / `version` / `description` from each `lark-*/SKILL.md`
and replaces only the region between the `## Sub-skill Index` and
`## Routing Rules` markers; everything else in `SKILL.md` is preserved.
