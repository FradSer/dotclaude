# Modifications — impeccable

Upstream: `pbakaus/impeccable` → `skills/impeccable`
Sync script: `scripts/sync-impeccable.sh`

**Current policy: track upstream verbatim — no local `SKILL.md` override.**

Per the maintainer directive "所有的内容必须以上游为优先", the impeccable skill's
`SKILL.md` is the upstream `SKILL.md` **byte-for-byte** (currently v3.7.0). The sync
script wipes the skill dir, copies upstream content in (including upstream's own
`SKILL.md`), and also saves a pristine copy to `reference/upstream-SKILL.md`. Because
the live `SKILL.md` IS the upstream one, **there is nothing to replay after a sync** —
this file contains no actionable `## Replace/Add/Edit` blocks, so the sync replay-check
counts zero pending modifications for impeccable.

> History: an earlier curated slim `SKILL.md` (v2.x — slim plugin entry deferring the
> full guide to `reference/upstream-SKILL.md`) was retired on 2026-06-16 in favor of
> upstream verbatim.

---

### Known caveat (NOT patched): bundled script paths don't resolve in the plugin

Upstream's `SKILL.md` Setup/routing invokes five bundled helper scripts via a hardcoded
standalone path: `node .claude/skills/impeccable/scripts/<X>.mjs` for
`context`, `palette`, `context-signals`, `detect`, and `pin`. That `.claude/skills/...`
path assumes the standalone install; when the skill ships as an installed **plugin**, it
will not resolve.

Verified (claude-code-guide, 2026-06-16): `${CLAUDE_PLUGIN_ROOT}` is **not** exported to
the Bash tool from a SKILL.md body (GitHub issue #48230, closed "not planned"), and
`${CLAUDE_SKILL_DIR}` is only reliable inside load-time `!` injection (open bug #36135).
So there is **no clean one-line path swap**. Upstream's own steps degrade gracefully
(context.mjs → fall back to `reference/init.md` / read `PRODUCT.md` directly; detect.mjs
→ "skip if it errors"), so a verbatim copy is functional, just without the script
conveniences.

We keep upstream verbatim (no patch). If/when the maintainer wants the scripts to
actually run in-plugin, pick one and it becomes an actionable `## Edit` block here:

- **A. Leave verbatim (current).** Zero local patch; scripts no-op in-plugin and fall
  back per upstream design. Most faithful to "上游为优先".
- **B. Load-time injection + `claude -p` fallback.** Add one `!` injection that resolves
  the skill's absolute dir at load, rewrite the five calls to use it, and fall back to a
  headless `claude -p` invocation when a script is unavailable or `PRODUCT.md` is missing.
  Scripts work, but it's a local patch fighting open CC bugs — re-verify per CC version.
- **C. Native agent.** Drop the `node …` calls; have the running agent read
  `PRODUCT.md`/`DESIGN.md` and reason directly. Simplest, no subprocess, no `claude -p`.

### Known caveat (separate issue): `anti-patterns.md` removed upstream

`sync-impeccable.sh` still tries to copy `anti-patterns.md` from the upstream agents path
into `frontend/agents/references/anti-patterns.md`, but upstream removed the standalone
file (methodology now lives in `SKILL.md`'s "Absolute bans" / "AI slop test" and
`scripts/detector/registry/antipatterns.mjs`). The sync therefore prints
"上游未找到 anti-patterns.md" and the local copy is now a **frozen** artifact still
consumed by the `frontend-anti-patterns` agent. Refreshing it from upstream's new
sources, and retiring the dead sync step, is a separate decision.
