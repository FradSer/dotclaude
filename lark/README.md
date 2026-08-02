# Lark Plugin

Feishu/Lark CLI skills, mirrored from [larksuite/cli](https://github.com/larksuite/cli).

**Version**: 0.1.0
**Display Name**: Lark

## What This Plugin Does

Lark/Feishu CLI operations — docs, sheets, IM, calendar, approval, attendance, drive, wiki, contacts, minutes, mail, tasks, events, video conferences, whiteboards, and more.

## Structure

- **`skills/SKILL.md` (lark router)** — local router that indexes the mirrored sub-skills; the table is regenerated from sub-skill frontmatter by `scripts/gen-lark-index.py`.
- **`skills/`** — mirrored sub-skills, each stored as `<name>/<name>.md` (denested: `SKILL.md` renamed after sync so only the router is auto-discovered). Synced from `larksuite/cli`.
- **`scripts/sync-lark.sh`** — syncs the sub-tree, then denests sub-skills.
- **`scripts/denest-lark-skills.py`** — renames `<name>/SKILL.md` → `<name>/<name>.md` and rewrites relative links.
- **`scripts/gen-lark-index.py`** — regenerates the router `SKILL.md` index table.
- **`skills/SYNC.md`** — sync metadata and strategy.

## Installation

```bash
claude plugin install lark@frad-dotclaude
```

## Syncing from Upstream

```bash
bash lark/scripts/sync-lark.sh --check     # dry-run
bash lark/scripts/sync-lark.sh             # sync with backup
```

## License

MIT (local plugin). Mirrored content sourced from `larksuite/cli`.
