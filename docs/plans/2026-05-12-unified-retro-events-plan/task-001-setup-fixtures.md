# Task 001: Setup Test Fixtures and Scaffolding

**depends-on**: (none — foundation task)

## Description

Establish the test fixtures and scaffolding that subsequent tasks consume. The migration parity tests (Tasks 004, 005) and the retrospective-Phase-1-reader test (Task 010) all need access to "legacy" reference outputs — byte-snapshots of what the pre-migration inline `bash` blocks emit so the new `helper`s can be proven to produce byte-equivalent rows. This task creates those fixtures plus an empty test file each subsequent task will populate, so later tasks never need to invent fixture paths from scratch.

No production code is written here; this task is pure test-side scaffolding.

## Execution Context

**Task Number**: 001 of 21
**Phase**: Setup
**Prerequisites**: working tree clean on `develop`; `jq`, `date`, `shasum` available on PATH (already required by existing `tests/test_bail_log_sh.py`).

## BDD Scenario

This task does not directly verify a BDD scenario — it is foundation for the parity-verification scenarios below, which are exercised in later tasks:

```gherkin
Scenario: Phase 5c legacy bash vs log_harness_observation produce identical channel rows
  Given a fixture tests/fixtures/legacy-harness-observation.jsonl written by the pre-migration bash block
  When the same logical event is re-emitted via log_harness_observation with matching args
  Then both lines have field set {event, component, timestamp, retrospective_id} with identical key order and JSON types
  And jq -S 'del(.timestamp)' produces byte-equal output on both lines

Scenario: Phase 6 closure legacy bash vs log_evolution_event produce identical retrospective_run rows
  Given a fixture tests/fixtures/legacy-retrospective-run.jsonl from the pre-migration Phase 6 closure
  When the same closure is re-emitted via log_evolution_event retrospective_run ...
  Then top-level keys match in order and nested sub-objects (self_value, post_plan_diff when present) match in key order
  And disable_test stays null or a supported identifier — never a free-text component name
```

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §3 (Migration Parity)

## Files to Modify/Create

- Create: `superpowers/tests/fixtures/legacy-harness-observation.sh` — executable shell script that emits one `harness-observations.jsonl` row using the verbatim pre-migration `jq -nc` invocation from `skills/retrospective/SKILL.md` Phase 5c. Reads its inputs as positional args (`<component>`, `<retrospective_id>`) and writes to stdout.
- Create: `superpowers/tests/fixtures/legacy-retrospective-run.sh` — executable shell script that emits one `evolution-log.jsonl` row carrying a `retrospective_run` event using the verbatim pre-migration `jq -nc` invocation from `skills/retrospective/SKILL.md` Phase 6. Inputs: `<plans_analyzed_json>` (`--argjson`), `<report>`, `<proposals_approved_int>`, `<proposals_rejected_int>`, `<disable_test_or_null>`, `<self_value_json>`, `<post_plan_diff_json_or_empty>`.
- Create: `superpowers/tests/fixtures/legacy-evolution-item-added.sh` — same idea for an `item_added` row (smallest of the evolution schemas, exercised in Task 005).
- Create: `superpowers/tests/fixtures/__init__.py` (empty marker so pytest can import alongside `tests/`).
- Create: `superpowers/tests/test_retro_events_sh.py` — empty Python test module with module docstring + imports (`json`, `subprocess`, `tempfile`, `unittest`, `pathlib.Path`) and the `SUPERPOWERS_DIR` constant. Task 002 populates the TestCases.
- Create: `superpowers/tests/test_skill_events_sh.py` — same shell, populated in Task 003.
- Create: `superpowers/tests/test_observations_sh.py` — same shell, populated in Task 004.
- Create: `superpowers/tests/test_evolution_log_sh.py` — same shell, populated in Task 005.
- Create: `superpowers/tests/test_migration_parity.py` — same shell, populated by Tasks 006, 007, 008.

## Steps

### Step 1: Verify Scenario Source
- Open `../2026-05-12-unified-retro-events-design/bdd-specs.md` and read §3 plus the "Testing Strategy" section at the bottom; confirm the fixture filenames match what `TestMigrationParity` expects.

### Step 2: Extract Legacy Snippets
- Open `superpowers/skills/retrospective/SKILL.md` and locate the inline `bash` blocks Phase 5c (line ~146) and Phase 6 (lines ~176–191). Copy each `jq -nc` invocation verbatim into the matching fixture script — these become the **golden reference** the helpers must produce byte-equivalent output for.

### Step 3: Create Fixture Scripts
- Each fixture script accepts its event-specific inputs as positional args, builds the `--arg` / `--argjson` invocation, prints the resulting NDJSON line to stdout, and exits 0.
- No `mkdir`, no file append — the fixtures emit to stdout so tests can compare strings directly.
- Make each fixture file executable: `chmod +x superpowers/tests/fixtures/legacy-*.sh`.

### Step 4: Create Empty Test Module Shells
- Each new `test_*.py` file contains:
  ```python
  """Tests for ... — populated by Task NNN."""
  from __future__ import annotations
  import json, shutil, subprocess, tempfile, unittest
  from pathlib import Path

  SUPERPOWERS_DIR = Path(__file__).resolve().parents[1]
  # Helper script path constants added in the populating task.
  ```
- This lets `pytest --collect-only` succeed before downstream tasks land.

### Step 5: Verification
- Run each fixture script with sample args; capture stdout; pipe to `jq -e .` to confirm valid NDJSON.
- Run `pytest superpowers/tests/ --collect-only` and confirm collection succeeds (each new module reports zero tests).

## Verification Commands

```bash
# Confirm fixtures emit valid NDJSON
bash superpowers/tests/fixtures/legacy-harness-observation.sh evaluator_per_batch docs/retros/foo.md | jq -e .
bash superpowers/tests/fixtures/legacy-retrospective-run.sh '[]' "docs/retros/foo.md" 0 0 null '{"proposals_total":0,"disable_test_set":false,"consecutive_zero_change":1}' ''
bash superpowers/tests/fixtures/legacy-evolution-item-added.sh add ITEM_X "desc" "rationale" '[]' v1 docs/retros/foo.md | jq -e .

# Confirm test scaffolding collects
cd /Users/FradSer/Developer/FradSer/dotclaude && python3 -m pytest superpowers/tests/ --collect-only -q
```

## Success Criteria

- Three executable fixture scripts exist under `superpowers/tests/fixtures/` and each produces a `jq -e .`-valid NDJSON line.
- Five empty Python test modules exist; `pytest --collect-only` exits 0.
- No production-code changes in `superpowers/lib/` or `superpowers/skills/` yet.
