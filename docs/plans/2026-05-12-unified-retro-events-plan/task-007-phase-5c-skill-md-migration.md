# Task 007: Phase 5c SKILL.md migration to observations.sh

**depends-on**: task-006-impl

## Description

Migrate `retrospective/SKILL.md` Phase 5c — the refusal gate that currently writes `harness-observations.jsonl` via an inline `bash` block — to invoke `lib/observations.sh::log_harness_observation` instead. This is a SKILL.md refactor task; the behavior is unchanged by design (the migration parity test from 006-impl is already green, proving byte-equivalence).

Also touches `retrospective/SKILL.md`'s `allowed-tools` frontmatter to add `Bash(${CLAUDE_PLUGIN_ROOT}/lib/observations.sh:*)`.

## Execution Context

**Task Number**: 007 of 15
**Phase**: Migration (refactor)
**Prerequisites**: Migration parity test green (006-impl).

## BDD Scenario

This is a SKILL.md refactor; the behavior gate is `bdd-specs.md` §5.4 (the existing Phase 1 step 2 evaluation glob behavior must not regress) and the cross-cutting §3 migration-parity scenarios (already green from 006).

```gherkin
Scenario: retrospective Phase 1 step 2 evaluation glob behavior is unchanged
  Given a plan directory with `evaluation-design-round-1.md`, `evaluation-plan-round-2.md`, and `evaluation-round-1.md`
  When retrospective Phase 1 step 2 enumerates evaluation reports
  Then the same three files are discovered as before the migration
  And no helper in the new family is invoked during the discovery phase
```

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §5.4.

## Files to Modify/Create

- Modify: `superpowers/skills/retrospective/SKILL.md` — two distinct edits in one file:
  - **Phase 5c section**: replace the inline `bash` block(s) for `component_unsupported` and `component_unknown` emission with `bash "${CLAUDE_PLUGIN_ROOT}/lib/observations.sh" …` invocations.
  - **YAML frontmatter `allowed-tools` array (line 6 — between the `---` fences at lines 1 and 7)**: append `"Bash(${CLAUDE_PLUGIN_ROOT}/lib/observations.sh:*)"`. The frontmatter is the single source of truth for `allowed-tools` in this skill; there is no separate `.claude-plugin/` config file to modify.

## Steps

### Step 1: Identify the inline block(s)
- Open `superpowers/skills/retrospective/SKILL.md`.
- Locate the Phase 5c section. There are two emission cases per `architecture.md` §"retrospective SKILL.md Phase 5c — migrate to log_harness_observation":
  - `component_unsupported` (the canonical "user asked to disable a non-component" branch).
  - `component_unknown` (the "user asked to disable a component we have no record of" branch).
- Cross-check that no other Phase 5c branch writes to `harness-observations.jsonl` (the design explicitly defers the `cleared` marker — do not add it).

### Step 2: Replace each block with a helper invocation
- For each block, replace the existing inline `jq -nc … >> docs/retros/harness-observations.jsonl` prose with:
  ```
  bash "${CLAUDE_PLUGIN_ROOT}/lib/observations.sh" \
    <component-identifier> component_unsupported "<short reason>"
  ```
  (and the analogous form for `component_unknown`).
- **PROHIBITED**: do not change the argument values, the surrounding prose, or the CRITICAL refusal-gate guidance. The migration is line-level — same args, same reasoning, different write surface.
- Keep the `harness-config.json` write path (a separate non-NDJSON file write in the same section) inline — only the `.jsonl` append migrates.

### Step 3: Update `allowed-tools`
- Open `superpowers/skills/retrospective/SKILL.md` and locate the YAML frontmatter (lines 1–7, opening `---` and closing `---`). The `allowed-tools` array is on line 6.
- Append `"Bash(${CLAUDE_PLUGIN_ROOT}/lib/observations.sh:*)"` to that array, preserving the existing entries and the array's JSON-style formatting.
- The skill does not currently expose a bare `Bash(jq:*)` entry; the Phase 5c `harness-config.json` write path is composed inline with the existing `Read`/`Edit`/`Write` tools. No change to the existing entries is required beyond the append.

### Step 4: Verify §5.4 — Phase 1 step 2 glob unchanged
- Read `tests/test_phase_integration.py` (or equivalent) to confirm the Phase 1 evaluation-glob test exists. If it does, run it: `python3 -m unittest tests.test_phase_integration -v`. MUST PASS.
- If no such test exists, hand-verify: create a temp plan dir with `evaluation-design-round-1.md`, `evaluation-plan-round-2.md`, `evaluation-round-1.md`; manually re-trace Phase 1 step 2 glob; confirm all three files match (no helper is even invoked at this stage).

### Step 5: Re-run migration parity
- Run `python3 -m unittest tests.test_migration_parity -v` again to confirm the SKILL.md change did not introduce any drift (the fixture-vs-helper byte-equality still holds — the SKILL.md edit is downstream of the helper).
- Run the full suite — no regressions.

### Step 6: Verify the SKILL.md is still well-formed
- `python3 superpowers/scripts/validate-plugin.py superpowers` (or equivalent plugin validator) MUST PASS.
- `bash superpowers/skills/retrospective/SKILL.md`-extracted frontmatter: confirm `allowed-tools` is valid YAML and parses.

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude

# §5.4 — Phase 1 step 2 glob unchanged
cd superpowers && python3 -m unittest tests.test_phase_integration -v

# Migration parity still green
python3 -m unittest tests.test_migration_parity -v

# Full suite
python3 -m unittest discover -s tests -v

# Plugin validation
cd /Users/FradSer/Developer/FradSer/dotclaude
python3 plugin-optimizer/scripts/validate-plugin.py superpowers
```

## Success Criteria

- `retrospective/SKILL.md` Phase 5c no longer contains inline `jq -nc … >> harness-observations.jsonl` invocations.
- `bash "${CLAUDE_PLUGIN_ROOT}/lib/observations.sh"` appears for both `component_unsupported` and `component_unknown` branches.
- `allowed-tools` frontmatter includes `Bash(${CLAUDE_PLUGIN_ROOT}/lib/observations.sh:*)`.
- All existing tests still pass (no regressions).
- Plugin validator passes.
- §5.4 evaluation-glob behavior is verified unchanged.
