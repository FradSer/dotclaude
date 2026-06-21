# Modifications — impeccable

Upstream: `pbakaus/impeccable` → `skills/impeccable`
Sync script: `scripts/sync-impeccable.sh`

**Current policy: track upstream verbatim — no local `SKILL.md` override, plus two
local `*.local.md` sidecars the sync wipe preserves.**

Per the maintainer directive "所有的内容必须以上游为优先", the impeccable skill's
`SKILL.md` is the upstream `SKILL.md` **byte-for-byte** (currently v3.7.1). The sync
script wipes the skill dir, copies upstream content in (including upstream's own
`SKILL.md`), and also saves a pristine copy to `reference/upstream-SKILL.md`. Because
the live `SKILL.md` IS the upstream one, **there is nothing to replay after a sync** —
this file contains no actionable `## Replace/Add/Edit` blocks, so the sync replay-check
counts zero pending modifications for impeccable.

"Verbatim", honestly stated, means: upstream files byte-for-byte **plus** two local
sidecars that upstream never ships and the wipe step skips —
`skills/impeccable/PLUGIN-INSTALL-NOTES.local.md` (plugin-layout script-path recipe) and
`skills/impeccable/AUDIT-AUTHORITY.local.md` (audit evidence-type reconciliation ladder).
The `.local.md` suffix is what makes them collision-proof: upstream has no same-named file
to overwrite them. The embedded version string above is auto-backfilled from the live
`SKILL.md` by `sync-impeccable.sh` on every sync, so it cannot drift again.

> History: an earlier curated slim `SKILL.md` (v2.x — slim plugin entry deferring the
> full guide to `reference/upstream-SKILL.md`) was retired on 2026-06-16 in favor of
> upstream verbatim.

---

### Known caveat (resolved as Option A + doc, 2026-06-20): bundled script paths don't resolve in the plugin

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

**Resolution (2026-06-20): Option A + local notes file.** `SKILL.md` stays upstream
verbatim. A local supplement `skills/impeccable/PLUGIN-INSTALL-NOTES.local.md` (not synced —
`sync-impeccable.sh` skips it during wipe) documents the plugin-layout script-path caveat
and gives the agent a resolution recipe + upstream's graceful-degradation fallbacks. The
coordinator (`agents/frontend-expert.md`) points to this notes file when impeccable's flow
calls those scripts. Options B/C remain available if scripts must truly run in-plugin;
they would become actionable `## Edit` blocks here:

- **A. Leave verbatim + local notes (current).** Zero `SKILL.md` patch; scripts degrade
  per upstream design; `PLUGIN-INSTALL-NOTES.local.md` tells the agent how to resolve when it
  can. Most faithful to "上游为优先".
- **B. Load-time injection + `claude -p` fallback.** Add one `!` injection that resolves
  the skill's absolute dir at load, rewrite the five calls to use it, and fall back to a
  headless `claude -p` invocation when a script is unavailable or `PRODUCT.md` is missing.
  Scripts work, but it's a local patch fighting open CC bugs — re-verify per CC version.
- **C. Native agent.** Drop the `node …` calls; have the running agent read
  `PRODUCT.md`/`DESIGN.md` and reason directly. Simplest, no subprocess, no `claude -p`.
  Note: cannot fix `live.md`'s stateful browser session.

### Known limitation (accepted): SKILL.md token budget is upstream-bound

`validate-plugin.py` warns (`should`) that impeccable's SKILL.md body is approaching the
5000-token Level-2 budget (currently ~4654). **This is accepted, not a defect.** Because
the body IS upstream verbatim, there is no local lever to trim it without violating the
"上游为优先" policy, and any trim would be wiped on the next sync anyway. If an upstream
bump pushes the body past 5000, `validate-plugin.py` escalates to a `must` (exit 2) — at
that point the correct response is to accept the breach (it is upstream's file), not to
edit SKILL.md. Do not treat the token warning/breach on this one skill as a ship blocker.

### Resolved (2026-06-21): anti-patterns agent can now run the executable detector

The `frontend-anti-patterns` agent previously cited
`scripts/detector/registry/antipatterns.mjs` as an authoritative source but could not
reach it: its tool allowlist lacked `node`/`find`, and the plugin layout breaks upstream's
hardcoded `.claude/skills/...` script path. Both are fixed — the agent now has
`Bash(node:*)` + `Bash(find:*)`, and a *Running the executable detector* section gives it
the `SKILL_DIR` resolution recipe (same one in `PLUGIN-INSTALL-NOTES.local.md`) so it runs
`detect.mjs --json <targets>` and folds the ~40 computed rules into its findings, degrading
gracefully to manual checks if resolution fails.

### Resolved (2026-06-20): `anti-patterns.md` retired

The local frozen `agents/references/anti-patterns.md` has been **deleted** and the
`sync-impeccable.sh` anti-patterns sync step converted to a no-op. Upstream never shipped
an independent `anti-patterns.md` (repo code search = 0, git history = 0); the authoritative
sources are `skills/impeccable/SKILL.md`'s `### Absolute bans` (text bans) and
`scripts/detector/registry/antipatterns.mjs` (executable rules, ~40 ids) — both synced
verbatim with the skill. The `frontend-anti-patterns` agent now points at those two sources
instead of the deleted local copy.
