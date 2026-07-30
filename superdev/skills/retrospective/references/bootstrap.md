# Phase 0: Bootstrap — Detailed Procedure

Run only when no checklists exist. Before Phase 1, check whether `docs/retros/checklists/` contains `{mode}-v1.md` for each mode (spec / tickets / code).

If all three modes already have a v1 file, log `Phase 0: all checklists present, skipping seed` and proceed to Phase 1.

Phase 0 runs per-mode independently — only modes missing a v{N} file are seeded. Do not skip the entire phase because one mode already has a checklist.

## Path A — Completed specs/tickets or evaluation reports exist

Seed the generic template and proceed to Phase 1:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/lib/seed-checklists.sh" <mode> docs/retros/checklists/<mode>-v1.md
```

Log `Seeded initial checklist: {mode}-v1.md`. Skip the Full History Analysis below — Phase 1 has real evaluation data to work with.

## Path B — Cold start (no completed specs/tickets, no evaluation reports)

When `docs/retros/evolution-log.jsonl` is absent or empty AND no `evaluation-round-*.md` files exist anywhere under `docs/specs/` or `docs/tickets/`, the retrospective has no evaluation data. Instead of producing a zero-signal run, perform a **Full History Bootstrap**: analyze the project's entire git history to extract project-specific failure patterns and augment the generic template with tailored checklist items.

**Step 1 — Seed the generic template** (same command as Path A):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/lib/seed-checklists.sh" <mode> docs/retros/checklists/<mode>-v1.md
```

**Step 2 — Git history gate**: count commits via `git rev-list --count HEAD`. If < 50, log `Phase 0: insufficient git history ({N} commits, need 50+) for bootstrap analysis`, skip Step 3, and proceed to Phase 1 with the generic template only.

**Step 3 — Full History Analysis** (methodology in `./analysis-patterns.md` §Bootstrap Analysis):

1. `git log --oneline --all` — collect all commits
2. Classify each commit by conventional-commit prefix into **feedback** (`fix:`, `refactor:`, `style:`, `perf:`) or **evolution** (`feat:`, `docs:`, `chore:`, `build:`, `ci:`, `test:`)
3. Group feedback commits by scope+type combination, rank by frequency
4. For the top clusters, `git show <sha>` the diffs and extract recurring failure patterns
5. Classify each pattern into a mode layer:
   - **code**: dead code, lint violations, i18n gaps, duplicate definitions, stub implementations
   - **spec**: stale references, missing Gherkin scenarios, references to deleted features
   - **tickets**: oversized tickets, missing cleanup tickets, dependency-edge violations
6. Generate one checklist item per failure pattern using the `evolution-protocol.md` New Item Template format (ID + description + check method + evidence format + rework format)

**Step 4 — Append project-specific items**: for each mode that received items, insert a new `## Project-Specific Items (Bootstrap Analysis)` section into the seeded `{mode}-v1.md` immediately before the existing `## Evaluation Protocol` section. Each item gets a unique ID following `{MODE}-{CATEGORY}-{NN}` naming (e.g., `CODE-I18N-01`, `SPEC-STALE-01`, `TICKETS-SCOPE-01`).

**Step 5 — Report**: log the analysis statistics (total commits, feedback/evolution split, top clusters, items generated per mode) in the retrospective report.

## Exit Code Handling

The seed script refuses to clobber an existing checklist (exit code 3) — treat that as "already seeded, proceed". Real failures (exit 1 = unknown mode, exit 2 = usage error) abort the phase. To genuinely reset an existing checklist (e.g., after a major harness change), append `--force` after the output path.

The canonical v1 template content lives in `lib/seed-checklists.sh`. To inspect or modify the seed bodies, edit that script — do NOT re-inline templates here.
