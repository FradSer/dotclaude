# Interfaces Skills Sync

**Upstream**: [jakubkrehel/skills](https://github.com/jakubkrehel/skills) `skills/` (main branch)
**Last sync**: 2026-08-04
**Synced commit**: a673333

## Sync Strategy

Uses `git sparse-checkout` to clone the upstream `skills/` directory, then
mirrors it into this directory. The upstream `agents/` dirs (OpenAI agent
configs, not Claude skills) are excluded, and upstream `better-interface/`
is skipped entirely — the local `better-interface/SKILL.md` above is the
authoritative router and is never overwritten. The local
`.claude-plugin/plugin.json` and `README.md` are also local files, outside
this tree.

`interfaces/` does not use the `<dirname>.md` denest of the marketing/lark/
hyperframes mirrors. It uses the **ref-pack** transform: only the router
skill is registered, and every other domain is a reference pack.

### Ref-pack demotion (required)

Upstream ships every domain as a standalone `<name>/SKILL.md`. Claude Code
auto-discovers any directory containing a file named `SKILL.md`, so leaving
those nested files would register 6 extra skills alongside the router.

After each sync, `scripts/sync-interfaces.sh` invokes
`tools/skill-sync/denest.py` with `--ref-pack better-interface
--strip-prefix better-`:

1. Moves each `better-*` dir into `better-interface/references/<domain>/`
   (e.g. `better-accessibility/` → `references/accessibility/`).
2. Renames each pack's `SKILL.md` → `overview.md`, stripping the skill
   frontmatter and the standalone **Review Output Format** section (refs are
   never invoked standalone; the router owns the output format).
3. Rewrites backtick name references (`` `better-accessibility` `` →
   `` `references/accessibility/overview.md` ``) and drops the article before
   rewritten paths.

`better-interface/references/` is derived content: each sync rebuilds it from
scratch, so domains removed upstream disappear locally. The router
`better-interface/SKILL.md` is local-authored and preserved. The transform is
idempotent — `denest.py --check` on a synced tree reports no drift.
