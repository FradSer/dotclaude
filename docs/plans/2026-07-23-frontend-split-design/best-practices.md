# Frontend Plugin Slim-Down — Best Practices

## Migration safety

- **Existing `frontend` users lose 5 skills on next `/reload-plugins`.** The README migration note (REQ-013) must list each deleted skill with the exact upstream repo URL to install directly via marketplace `source: "github"`:
  - `supabase`, `supabase-postgres-best-practices` → `supabase/agent-skills`
  - `web-design-guidelines` → `vercel-labs/agent-skills`
  - `shadcn` → `shadcn-ui/ui`
  - `impeccable` → `pbakaus/impeccable`
- Do NOT silently delete `frontend/` — the plugin stays in place (slimmed), so existing slash-command IDs like `/frontend:design-md` keep working. Only the 5 deleted-skill IDs break, and they break toward upstream repos.
- Pin a deprecation note in `frontend/README.md` at the top so users see it before the skill list.
- SCOPE-CREEP-01: if the slim-down surfaces unrelated fixes (e.g. stale `next-devtools`/`shadcn` mentions already noted in `dotclaude/CLAUDE.md` "Version sync"), extract them into a sibling PR — do not bundle into the slim-down commit.

## Token-budget discipline

- Budget is per-SKILL.md body (L2, <5000 tokens), not per-plugin. L2 loads per-skill on trigger, not at plugin startup.
- Surviving skills are well under ceiling: `design-md` 3069, `articulate` 1184, `next-devtools-guide` ~1100. No survivor approaches 5k.
- The deleted `impeccable` (5200, verbatim-mirror exempted) and `shadcn` (4684) carried the token risk — both leave. The slimmed plugin has no over-budget skill, so no verbatim-mirror exemption is needed post-slim. Confirm with `validate-plugin.py`.
- Memory link: `feedback_skill_level_enforcement` — L2 SKILL.md CRITICAL markers must survive the rewrites of `design-md`/`articulate` (do not strip CRITICAL tags while pruning sibling refs).

## Sync-machine deprecation

- Deleting `sync-supabase-skills.sh`, `sync-vercel-skills.sh`, `sync-shadcn.sh`, `sync-impeccable.sh` + their `.sync-snapshots/*.manifest` removes the bulk of the sync burden. Only `sync-design-md.sh` survives (design-md caches its upstream spec).
- Verify `sync-design-md.sh` does not share a manifest key with a deleted script (it uses a `design-md` key, not the shared `vercel-skills`/`supabase-skills` keys — confirm before deleting manifests).
- `SYNC.md` sections for deleted skills are removed; only the design-md section remains.

## README bilingual sync (manual)

- Per memory `project_readme_sync_manual.md`: top-level `dotclaude/README.md` + `README.zh-CN.md` plugin listings are edited by hand. `/utils:update-readme` is disabled for model calls — do NOT invoke it.
- The frontend row stays (the plugin persists, just slimmed); update its description/skill-count if the listing enumerates skills. Do not add/remove rows — `frontend` is not renamed.
- `frontend/README.md` (the plugin's own README) gets the migration note (REQ-013). No `frontend/README.zh-CN.md` exists (verified: `find` surfaced only `README.md`).

## Common pitfalls

- **Do not delete `modifications/` piecemeal and leave the dir half-populated** — if no modifications survive, delete the dir AND `check-coherence.sh` assertion 3, else the checker fails on an empty `modifications/`.
- **Do not forget the `find` path in `frontend-anti-patterns.md:53`** — it hard-codes `*/frontend/skills/impeccable/SKILL.md`. After deleting impeccable, that `find` returns empty and the agent silently degrades. The rewrite (REQ-004) must remove the block, not leave it to fail at runtime.
- **Do not strip CRITICAL markers from `design-md`/`articulate` SKILL.md** while pruning sibling refs — per `feedback_skill_level_enforcement`, losing CRITICAL tags causes downstream rules to be skipped.
- **Do not rewrite the hook to call the Skill tool** — it is advisory prose (UserPromptSubmit additionalContext), not a load command. Keep the declarative framing documented in `design-md-first.sh:14-17`.
- **Do not invoke `/utils:update-readme`** for the marketplace README sync — it is disabled for model calls.

## Testing strategy

- The slim-down is verified by the grep + `validate-plugin.py` block in `architecture.md` §5. Run it post-implementation; all commands must exit 0.
- No formal test suite exists for `frontend/` itself — the `check-coherence.sh` + `check-references.sh` scripts are the integration tests; both must pass post-slim after re-scoping (REQ-011).
- BDD scenarios in `bdd-specs.md` are executable as the same grep assertions — they double as the acceptance criteria.
