# Task 008: Phase 4 + Phase 6 SKILL.md migration to evolution-log.sh

**depends-on**: task-006-impl

## Description

Migrate `retrospective/SKILL.md` Phase 4 (per-proposal `item_*` events) and Phase 6 (`retrospective_run` closure + `component_reinstated`) from inline `jq -nc … >> docs/retros/evolution-log.jsonl` blocks to `bash "${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh" …` invocations. SKILL.md refactor only; behavior is byte-equivalent by virtue of migration-parity test 006-impl already passing.

Also touches `retrospective/SKILL.md`'s `allowed-tools` to add `Bash(${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh:*)`.

## Execution Context

**Task Number**: 008 of 15
**Phase**: Migration (refactor)
**Prerequisites**: Migration parity test green (006-impl).

## BDD Scenario

```gherkin
Scenario: retrospective Phase 1 step 2 evaluation glob behavior is unchanged
  Given a plan directory with `evaluation-design-round-1.md`, `evaluation-plan-round-2.md`, and `evaluation-round-1.md`
  When retrospective Phase 1 step 2 enumerates evaluation reports
  Then the same three files are discovered as before the migration
  And no helper in the new family is invoked during the discovery phase
```

This task's load-bearing safety guarantee is the migration parity test from 006 (Phase 6 closure parity, item_added/etc. parity) — that test is the gate that already proved byte-equivalence. This SKILL.md edit relies on that prior verification.

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §3.2, §5.4.

## Files to Modify/Create

- Modify: `superpowers/skills/retrospective/SKILL.md` — three distinct edits in one file:
  - **Phase 4 section**: replace inline `jq -nc` blocks for `item_added`, `item_removed`, `item_modified`, `item_promoted` with `bash "${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh" <event_type> '<filter>' --arg ... --argjson ...` invocations.
  - **Phase 6 section**: replace the inline `jq -nc` block for `retrospective_run` and `component_reinstated` with helper invocations.
  - **YAML frontmatter `allowed-tools` array (line 6 — between the `---` fences at lines 1 and 7)**: append `"Bash(${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh:*)"`. The frontmatter is the single source of truth for `allowed-tools` in this skill.

## Steps

### Step 1: Identify all evolution-log inline blocks
- Open `superpowers/skills/retrospective/SKILL.md`.
- Locate Phase 4 (per-approved-proposal append).
- Locate Phase 6 (`retrospective_run` closure + `component_reinstated` veto).
- Cross-check `architecture.md` §"retrospective SKILL.md Phase 4 step 3 (proposal events)" and §"retrospective SKILL.md Phase 6 closure" for the canonical replacement form.

### Step 2: Replace each block with a helper invocation
- For each event kind (`item_added`, `item_removed`, `item_modified`, `item_promoted`, `retrospective_run`, `component_reinstated`):
  - Replace the inline `jq -nc '<full filter>' --arg ... >> docs/retros/evolution-log.jsonl` line with:
    ```
    bash "${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh" \
      <event_type> '<payload-only filter>' \
      --arg ... --argjson ...
    ```
  - The payload-only filter must NOT include `event` or `timestamp` (the helper's envelope handles those). The filter produces only the per-event-kind fields per `evolution-protocol.md` lines 85-170.
- **PROHIBITED**: do not change the surrounding prose, the `consecutive_zero_change` computation, or the `--argjson` ordering. The migration is line-level.
- Keep the `consecutive_zero_change` computation (and any other Phase 6 calibration-loop logic that lives outside the `jq -nc` line) inline in SKILL.md — only the final NDJSON append migrates.
- The `component_reinstated` veto event currently lives in `evolution-protocol.md` references — confirm its inline block is also migrated if SKILL.md owns the emission point, or note in this task's notes if it lives elsewhere.

### Step 3: Update `allowed-tools`
- Add `Bash(${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh:*)` to the SKILL.md frontmatter's `allowed-tools` array.

### Step 4: Verify
- Run `python3 -m unittest tests.test_migration_parity -v` — MUST PASS (already green from 006-impl; the SKILL.md change is downstream and shouldn't perturb the helper output).
- Run `python3 -m unittest tests.test_phase_integration -v` — MUST PASS (Phase 1 step 5 reader for the `item_id` history table must continue to read mixed-mode rows).
- Run the full suite — no regressions.
- Plugin validator: `python3 plugin-optimizer/scripts/validate-plugin.py superpowers` MUST PASS.

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
python3 -m unittest tests.test_migration_parity -v
python3 -m unittest tests.test_phase_integration -v
python3 -m unittest discover -s tests -v

cd /Users/FradSer/Developer/FradSer/dotclaude
python3 plugin-optimizer/scripts/validate-plugin.py superpowers
```

## Success Criteria

- `retrospective/SKILL.md` Phase 4 and Phase 6 sections no longer contain inline `jq -nc … >> evolution-log.jsonl` invocations.
- All six event kinds (`item_added`, `item_removed`, `item_modified`, `item_promoted`, `retrospective_run`, `component_reinstated`) route through `bash "${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh"`.
- `allowed-tools` frontmatter includes `Bash(${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh:*)`.
- Migration parity test still passes (no drift from the SKILL.md edit).
- Phase integration test still passes (Phase 1 step 5 reader unaffected).
- `consecutive_zero_change` computation logic remains in SKILL.md (only the NDJSON append migrated).
- Plugin validator passes.
