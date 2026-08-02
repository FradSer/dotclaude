# Hyperframes Plugin

HyperFrames HTML-based video authoring skills, mirrored from [heygen-com/hyperframes](https://github.com/heygen-com/hyperframes).

**Version**: 0.1.0
**Display Name**: Hyperframes

## What This Plugin Does

HTML-based video authoring and rendering skills — compositions, animation, keyframes, creative direction, media handling, CLI dev loop, plus video workflows (motion-graphics, slideshow, product-launch, pr-to-video, talking-head recut, faceless explainer, embedded captions, and more).

## Structure

- **`skills/SKILL.md` (hyperframes router)** — local router that indexes the mirrored sub-skills.
- **`skills/`** — mirrored sub-skills, each stored as `<name>/<name>.md` (denested: `SKILL.md` renamed after sync so only the router is auto-discovered), plus binary assets (fonts/SVG). Synced from `heygen-com/hyperframes`.
- **`scripts/sync-hyperframes.sh`** — syncs the sub-tree, then denests sub-skills.
- **`scripts/denest-skills.py`** — renames `<name>/SKILL.md` → `<name>/<name>.md` and rewrites relative links (`HF_TREE_ROOT=1` mode; a copy of `marketing/scripts/denest-marketing-skills.py` — keep the two in sync when editing that logic).
- **`skills/SYNC.md`** — sync metadata and strategy.

## Installation

```bash
claude plugin install hyperframes@frad-dotclaude
```

## Syncing from Upstream

```bash
bash hyperframes/scripts/sync-hyperframes.sh --check   # dry-run
bash hyperframes/scripts/sync-hyperframes.sh           # sync with backup
```

## License

MIT (local plugin). Mirrored content sourced from `heygen-com/hyperframes` (Apache-2.0).
