# Lark CLI Skills Sync

**Upstream**: [larksuite/cli](https://github.com/larksuite/cli) `skills/` (main branch)
**Last sync**: 2026-07-23
**lark-cli version**: 1.0.72
**Synced commit**: 67015ee

## Sync Strategy

Uses `git sparse-checkout` to clone only the `skills/` directory from upstream `main`, then mirrors all contents into this directory (excluding `SKILL.md` and `SYNC.md` at the root level, which are local additions). Directories removed upstream (e.g. `lark-whiteboard-cli`, merged into `lark-whiteboard`) are deleted locally to match.

### Nested SKILL.md denest (required)

Upstream ships every sub-skill as `lark-*/SKILL.md`. Claude Code / Cursor auto-discover any directory that contains a file named `SKILL.md`, so leaving those nested files would register ~27 extra skills alongside the router.

After each sync, `office/scripts/denest-lark-skills.py` (invoked by `sync-lark.sh`):

1. Renames `lark-*/SKILL.md` → `lark-*/<dirname>.md` (e.g. `lark-doc/lark-doc.md`)
2. Rewrites relative links (`…/lark-foo/lark-foo.md` → `…/lark-foo/lark-foo.md`, `../SKILL.md` → `../<dirname>.md`)

Only the root `SKILL.md` remains discoverable. `--check` denests a temp copy of upstream before diffing so local transforms do not look like drift.

## Version Tracking

`**lark-cli version**` records the locally installed `lark-cli` at sync time; `**Synced commit**` records the upstream `main` commit the skills were pulled from. Re-sync whenever `lark-cli` updates so the bundled skills stay aligned with the CLI you actually run. The sync script refreshes all three header fields automatically on each run.

## Local Additions

The following files are maintained locally and are NOT overwritten by sync:

- `SKILL.md` -- Top-level router skill (local orchestration layer). Its Sub-skill Index table is regenerated from sub-skill frontmatter by `office/scripts/gen-lark-index.py` (see below) — do not hand-edit the table rows; edit the description in each `lark-*/<dirname>.md` and rerun the script.
- `SYNC.md` -- This file

## Running Sync

```bash
# Check for updates (dry-run)
bash office/scripts/sync-lark.sh --check

# Sync with backup
bash office/scripts/sync-lark.sh

# Force sync, skip confirmation
bash office/scripts/sync-lark.sh --force

# Re-run denest only (e.g. after a partial sync)
python3 office/scripts/denest-lark-skills.py
python3 office/scripts/denest-lark-skills.py --check
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

The script reads `name` / `version` / `description` from each
`lark-*/<dirname>.md` and replaces only the region between the
`## Sub-skill Index` and `## Routing Rules` markers; everything else in
`SKILL.md` is preserved. The **Entry** column is a markdown link to
`lark-foo/lark-foo.md` so the router can load the denested sub-skill.
