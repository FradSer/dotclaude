# Frontend Plugin Slim-Down — Design

## Context

`frontend/` (v0.5.1) bundles 9 skills sourced from 6+ independent upstream repos, plus 2 agents, 1 UserPromptSubmit hook, 7 sync scripts sharing `scripts/lib/sync-common.sh`, a `modifications/` replay log, and `.sync-snapshots/` upstream-hash manifests. The bundle conflates two unrelated kinds of content:

1. **Upstream mirrors** — skills synced verbatim (or near-verbatim) from external repos: `supabase`, `supabase-postgres-best-practices` (supabase/agent-skills), `web-design-guidelines` (vercel-labs/agent-skills), `impeccable` (pbakaus/impeccable, verbatim), `shadcn` (shadcn-ui/ui). These carry the full sync-machine burden (7 scripts + snapshots + replay log + SYNC.md) for value the user could get by installing the upstream repo directly via marketplace `source: "github"`.
2. **Original integration layer** — content authored locally that exists nowhere else: the `design-md-first.sh` hook + token-authority ladder (binds design-md/impeccable/shadcn into one design system), `design-md` local SKILL.md, `articulate` (sourced from index.how, a website, not a git repo — cannot be re-installed via marketplace github source), `frontend-expert`/`frontend-anti-patterns` agents, `next-devtools-guide`, and the `modifications/` patches.

The user's decision (after challenging the premise per `feedback_null_alternative_first`): **slim `frontend/` down in place to only the original integration layer; delete the 5 mirror skills; do NOT split into 3 plugins.** Mirror-skill consumers install upstream repos directly.

## Discovery Results

- `frontend/SYNC.md:1-93` is the authoritative source↔plugin map. 7 of 9 skills are upstream-synced; only `articulate` (index.how, manual) and `next-devtools-guide` (local) are not git-upstreamed.
- Coupling matrix (from research): exactly ONE hard runtime cross-skill dependency exists — `frontend-anti-patterns` agent → `skills/impeccable/scripts/detect.mjs` (`agents/frontend-anti-patterns.md:50-57`, the `find ~/.claude -path '*/frontend/skills/impeccable/SKILL.md'` resolution + `node "$SKILL_DIR/scripts/detect.mjs"`). All other `frontend:<skill>` references are SOFT advisory prose (verified by greps: `design-md/SKILL.md:188-194`, `articulate/SKILL.md:22`, `impeccable/*.local.md:13,26-28`, `frontend-expert.md` pipeline text).
- `frontend/modifications/` contains: `impeccable.md` (replay count 0, verbatim policy doc), `shadcn.md` + `patches/shadcn-tailwind-v4.md` (1 patch targeting `skills/shadcn/rules/styling.md`), `react-best-practices.md` (12 `## Add`/`## Edit` blocks targeting `skills/react-best-practices/...`). ALL three target mirror skills being deleted — they cannot survive the deletion (Target files vanish, `check-coherence.sh` assertion 3 fails).
- `frontend-anti-patterns` agent's only hard dependency (`detect.mjs`) lives in `impeccable`, a mirror being deleted → the agent must be rewritten to drop the detector, or deleted.
- `frontend-expert` coordinator (`agents/frontend-expert.md:36-185`) references `frontend:supabase`, `frontend:supabase-postgres-best-practices`, `frontend:shadcn`, `frontend:react-best-practices`, `frontend:web-design-guidelines`, `frontend:impeccable`, `frontend:impeccable-<cmd>` — all being deleted. Surviving refs: `frontend:design-md`, `frontend:articulate`, `frontend:next-devtools-guide`. The coordinator's pipelines must be pruned to surviving skills only.
- `hooks/design-md-first.sh:44-47` preamble ladder references `frontend:design-md` (survives), `frontend:impeccable` (deleted), `frontend:shadcn` (deleted), and the anti-patterns agent (rewritten). Steps 2-3 of the ladder collapse.
- `next-devtools` mcpServer (`plugin.json:55-64`) + `next-devtools-guide` skill are a local pair — both survive.
- Marketplace (`.claude-plugin/marketplace.json`) lists `frontend` v0.5.1 with `source: "./frontend"`. No `dependencies` field anywhere; no cross-plugin install contract exists.
- Per memory `project_readme_sync_manual.md`: top-level `README.md` + `README.zh-CN.md` plugin listings are manual sync; `/utils:update-readme` is disabled for model calls.

## Glossary

| Term | Locked form | Rejected variants | Why canonical |
|---|---|---|---|
| The operation | slim-down | "split", "拆分", "refactor" | user chose in-place slimming, not 3-way split |
| Deleted skills | mirror skills | "upstream skills", "synced skills" | names what they are (verbatim mirrors) |
| Surviving content | original integration layer | "local content", "原创件" | names the function (integration), not the origin |
| The hook | design-md-first hook | "UserPromptSubmit hook", "design-md-first.sh" | names the function per its comment |
| The ladder | token-authority ladder | "authority ladder", "token authority ladder" | term in `design-md-first.sh:4-13` |
| Cross-skill refs | qualified skill ID | "plugin-scoped ID", "namespaced ref" | the platform term |
| Sync burden | sync machinery | "sync scripts", "sync infra" | names the whole apparatus |
| Re-applied local edits | modifications replay log | "modifications/" | names the function |

## Requirements

### Functional (MUST)

- **REQ-001** — Delete the 5 mirror skill directories: `skills/supabase/`, `skills/supabase-postgres-best-practices/`, `skills/web-design-guidelines/`, `skills/impeccable/`, `skills/shadcn/`. *Rationale: these are upstream mirrors; users install upstream repos directly via marketplace `source: "github"`.*
- **REQ-002** — Delete the sync machinery that serviced only mirror skills: `scripts/sync-supabase-skills.sh`, `scripts/sync-vercel-skills.sh`, `scripts/sync-shadcn.sh`, `scripts/sync-impeccable.sh`, and the `.sync-snapshots/{supabase-skills,vercel-skills,shadcn,impeccable}.manifest` files. *Rationale: no remaining skill uses these; keeping dead scripts is cruft.*
- **REQ-003** — Delete `modifications/impeccable.md`, `modifications/shadcn.md`, `modifications/patches/shadcn-tailwind-v4.md`, `modifications/react-best-practices.md` — every modification block whose Target is a deleted mirror skill. *Rationale: Target files vanish; `check-coherence.sh` assertion 3 would fail on every block.*
- **REQ-004** — Rewrite `agents/frontend-anti-patterns.md` to remove the `detect.mjs` hard dependency (the `find ... impeccable/SKILL.md` + `node detect.mjs --json` block at `:50-57,95`), since `impeccable` is deleted. The agent degrades to its manual-check fallback (already documented in-agent at `:57`). *Rationale: the only hard runtime coupling was to a deleted skill; the agent must not ship a broken `find` path.*
- **REQ-005** — Prune `agents/frontend-expert.md` pipelines (`:36-185`) of all references to deleted skills (`frontend:supabase`, `frontend:supabase-postgres-best-practices`, `frontend:shadcn`, `frontend:react-best-practices`, `frontend:web-design-guidelines`, `frontend:impeccable`, `frontend:impeccable-<cmd>`). Surviving refs only: `frontend:design-md`, `frontend:articulate`, `frontend:next-devtools-guide`, plus the rewritten anti-patterns agent. *Rationale: coordinator must not reference non-existent skills.*
- **REQ-006** — Rewrite `hooks/design-md-first.sh` preamble (`:44-47`) to drop ladder steps for deleted `frontend:impeccable` and `frontend:shadcn`. Step 1 (`frontend:design-md` source of truth) survives; the "four quality authorities" framing collapses to design-md + (manual) anti-patterns. *Rationale: hook must not inject references to deleted skills.*
- **REQ-007** — Update `skills/design-md/SKILL.md` "Sibling Skill Integration" (`:188-194`) to remove refs to deleted `frontend:impeccable`, `frontend:web-design-guidelines`, `frontend:shadcn`. *Rationale: SKILL.md must not cite deleted skills.*
- **REQ-008** — Update `skills/articulate/SKILL.md:22` to remove `frontend:impeccable` / `frontend:web-design-guidelines` pairing refs. *Rationale: same.*
- **REQ-009** — Update `.claude-plugin/plugin.json`: remove deleted skills from `commands`/`skills` arrays; keep `design-md` + `impeccable`→remove, `articulate`, `next-devtools-guide` in skills; keep hook + agents + `next-devtools` mcpServer. *Rationale: manifest must match surviving content.*

### Functional (SHOULD)

- **REQ-010** — Keep `scripts/sync-design-md.sh` + `scripts/lib/sync-common.sh` + `.sync-snapshots/` (if design-md still uses snapshot sync) — design-md survives, so its sync survives. Verify design-md sync does not share machinery with deleted skills. *Rationale: design-md is local SKILL.md but caches upstream spec; its sync is independent.*
- **REQ-011** — Keep `scripts/check-coherence.sh` + `scripts/check-references.sh`, re-scoped to surviving skills. Assertion 1 (no phantom `frontend:impeccable-<cmd>`) — drop (impeccable deleted). Assertion 2 (`node *.mjs` paths) — drop (no surviving skill runs .mjs). Assertion 3 (modifications Target files exist) — drop (no surviving modifications) or retire the script. Assertion 4 (frontend-expert IDs registered) — keep, re-validated against pruned plugin.json. *Rationale: coherence checker must reflect new content set.*
- **REQ-012** — Bump `frontend` plugin version (e.g. 0.5.1 → 0.6.0) to signal the structural slim-down, and sync marketplace.json version. *Rationale: a deletion of 5 skills is a breaking-ish change worth a minor bump.*
- **REQ-013** — Add a migration note in `frontend/README.md`: list deleted skills + the upstream repo URL each user should install instead (supabase/agent-skills, vercel-labs/agent-skills, shadcn-ui/ui, pbakaus/impeccable). *Rationale: existing `frontend` users lose 5 skills on update; they need the replacement path.*

### Non-functional

- **REQ-014** — No LLM/network/subprocess call on the UserPromptSubmit critical path after the rewrite. The hook already does pure file checks + `sed`/`grep`; the rewrite preserves this. *Rationale: PERF-01 — hook must stay sub-millisecond.*
- **REQ-015** — Surviving SKILL.md bodies stay under the 5k L2 token budget. Only `design-md` (3069) is large among survivors; well under ceiling. *Rationale: token-budget rule.*
- **REQ-016** — `/utils:update-readme` is NOT invoked (disabled for model calls per memory `project_readme_sync_manual.md`); top-level `README.md` + `README.zh-CN.md` plugin-listing edits are manual. *Rationale: memory-enforced constraint.*

## Rationale

**Why slim-in-place over 3-way split.** The original "split into 3 plugins" framing preserved 100% of the sync-machine burden — just re-grouped. Challenging the premise (`feedback_null_alternative_first`) exposed that ~60% of the bundle is verbatim upstream mirror that the marketplace can serve directly via `source: "github"`. Re-hosting mirrors + maintaining sync scripts for them is pure overhead with no user value. The slim-down deletes the overhead and keeps only what exists nowhere else (the integration layer). This matches the user's actual intent ("专门" = focused, not "split for splitting's sake").

**Why not delete `frontend/` entirely.** The hook + ladder, `articulate` (non-git source), `design-md` local SKILL.md, the two agents, and the next-devtools-guide/MCP pair are original content with no upstream home. Deleting them loses real value. The user explicitly chose "挽救原创件" (rescue originals).

**Why the anti-patterns agent is rewritten, not deleted.** Its detector coupling is to a deleted skill, but its manual-check fallback (`:57,95+`) is self-contained original content worth keeping. Dropping the detector block is cheaper than re-deriving the manual checks elsewhere.

**Why `next-devtools` mcpServer stays.** It is a local pair with `next-devtools-guide` (both original); the MCP server config moves nowhere because the plugin stays in place.

## Risks

| Risk | Concrete mitigation |
|---|---|
| Existing `frontend` users lose 5 skills on next `/reload-plugins` with no replacement path | `frontend/README.md` migration note (REQ-013) lists each deleted skill + its upstream repo URL to install directly. |
| `frontend-anti-patterns` agent loses its computed detector, degrades to heuristic-only | Rewrite (REQ-004) keeps the manual fallback; document in-agent that the detector was removed because `impeccable` was slimmed out. |
| `frontend-expert` coordinator pipelines reference deleted skills, half-break | Prune pipelines (REQ-005) to 3 surviving skills; the coordinator becomes design-md/articulate/next-devtools-guide scoped. |
| Hook ladder steps 2-3 collapse, token-authority story weakens | Rewrite preamble (REQ-006) to a 1-step ladder (design-md = source of truth) + note anti-patterns as manual check. Honest about reduced scope. |
| `modifications/README.md` references deleted modification files | Trim `modifications/README.md` workflow text (or delete the dir if no modifications survive — verify whether `modifications/` retains any non-mirror entries; if empty, delete the dir and the `check-coherence.sh` assertion 3). |
| Marketplace version drift | REQ-012 bumps plugin.json + marketplace.json in lockstep. |
| README bilingual drift | Manual edit (REQ-016) — do not invoke `/utils:update-readme`. |

## Detailed Design

See companion files:

- `bdd-specs.md` — Gherkin scenarios for the slim-down (deletion correctness, manifest consistency, hook/coordinator rewrite invariants, migration note presence).
- `architecture.md` — file-level delete/keep/rewrite map, the surviving `frontend/` tree, verification commands.
- `best-practices.md` — migration safety, token-budget, sync-machine deprecation, common pitfalls.

## Design Documents

- `_index.md` — this file (context, discovery, glossary, requirements, rationale, risks).
- `bdd-specs.md` — BDD scenarios traced to REQ-NNNN.
- `architecture.md` — delete/keep/rewrite map + verification.
- `best-practices.md` — migration, token budget, pitfalls.
