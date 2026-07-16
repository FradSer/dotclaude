# Plugin-install notes for impeccable (local, not synced)

> **Not synced from upstream.** This file is a local supplement kept outside
> `SKILL.md` so `sync-impeccable.sh` (which wipes the skill dir and copies
> upstream verbatim) does not touch it. The upstream `SKILL.md` is the source
> of truth for behavior; this file only documents how its bundled-script
> paths resolve when the skill ships inside the `frontend` **plugin**.

## The script-path caveat

Upstream `SKILL.md` (v3.9.1) invokes five bundled helper scripts via a
hardcoded standalone-install path:

```
node .claude/skills/impeccable/scripts/<context|palette|context-signals|detect|pin>.mjs
```

That `.claude/skills/...` path is correct for the standalone `npx impeccable
install` layout (which materializes `.claude/skills/impeccable/` in the user's
project root) but **does not resolve** when the skill ships as a plugin — the
scripts live under the plugin's install directory, not under the project's
`.claude/skills/`.

Verified (claude-code-guide, 2026-06-16; re-checked 2026-06-20):
`${CLAUDE_PLUGIN_ROOT}` is **not** exported to the Bash tool, and
`${CLAUDE_SKILL_DIR}` is only reliable inside load-time `!` injection. So there
is **no clean one-line path swap** from within a SKILL.md body.

## How to run the scripts in a plugin install

Resolve the plugin root by locating the installed `frontend` plugin, then run
the script from there. The plugin directory is the one containing this file
(`skills/impeccable/PLUGIN-INSTALL-NOTES.local.md`), so the scripts are at
`scripts/` relative to the skill dir — i.e. two levels up from this file's
parent's `scripts/`. Concretely, if the skill dir is `$SKILL_DIR`, the scripts
are at `$SKILL_DIR/scripts/`:

```bash
# From any cwd, find the plugin root by locating this notes file's skill dir,
# then run the script directly from there.
SKILL_DIR="$(find ~/.claude -path '*/frontend/skills/impeccable/SKILL.md' 2>/dev/null | head -1 | xargs dirname)"
node "$SKILL_DIR/scripts/context.mjs"            # or palette / context-signals / detect / pin
```

If that resolution fails (plugin installed in a non-standard location), fall
back to upstream's graceful degradation:

- `context.mjs` → read `PRODUCT.md` / `DESIGN.md` directly (upstream: "If the
  request names or implies a file… infer the concrete path"). If
  `NO_PRODUCT_MD`, follow `reference/init.md`.
- `detect.mjs` → skip detection, recommend the user run `audit` themselves
  (upstream: "never block the suggestion on it").
- `palette.mjs` → only needed for brand-new projects with no committed colors;
  if unavailable, ask the user for a brand seed color.
- `pin.mjs` / `context-signals.mjs` → advisory; skip if unavailable.

## Why we don't patch SKILL.md

Per the maintainer directive "所有的内容必须以上游为优先", `SKILL.md` is
upstream verbatim. Any local path rewrite would be wiped on every sync and
fights open Claude Code bugs (`${CLAUDE_PLUGIN_ROOT}` not exported, GitHub
#48230 closed "not planned"). Option B (load-time `!` injection) would
re-introduce a local patch that must be re-verified per CC version. This
notes file (Option A + documentation) is the chosen posture: scripts degrade
gracefully per upstream design, and this file tells the agent how to resolve
them when it can.

See `modifications/impeccable.md` for the A/B/C decision record.
