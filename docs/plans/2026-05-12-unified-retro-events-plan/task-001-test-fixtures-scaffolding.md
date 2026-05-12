# Task 001: Test fixtures and scaffolding

**depends-on**: _(none — foundation)_

## Description

Create the test-fixtures directory layout and capture the **legacy inline `bash` block output** that `retrospective` Phase 5c (`harness-observations.jsonl`) and Phase 6 closure (`evolution-log.jsonl` — `retrospective_run`) currently produce. These captured fixtures are the byte-for-byte golden inputs that the migration-parity test (task 006) will compare against the new `helper` output.

This task does **not** create any production code. It is a foundation step: a directory layout + two small bash capture scripts + a README documenting the fixture-regeneration procedure.

## Execution Context

**Task Number**: 001 of 15
**Phase**: Setup
**Prerequisites**: None.

## BDD Scenario

This task does not satisfy a single Gherkin scenario on its own; it is foundation infrastructure for the migration-parity scenarios in §3 of `bdd-specs.md`. The downstream parity scenarios these fixtures serve:

```gherkin
Scenario: Phase 5c legacy bash vs log_harness_observation produce identical channel rows
  Given a fixture `tests/fixtures/legacy-harness-observation.jsonl` written by the pre-migration bash block
  When the same logical event is re-emitted via `log_harness_observation` with matching args
  Then both lines have field set `{event, component, timestamp, retrospective_id}` with identical key order and JSON types
  And `jq -S 'del(.timestamp)'` produces byte-equal output on both lines

Scenario: Phase 6 closure legacy bash vs log_evolution_event produce identical retrospective_run rows
  Given a fixture `tests/fixtures/legacy-retrospective-run.jsonl` from the pre-migration Phase 6 closure
  When the same closure is re-emitted via `log_evolution_event retrospective_run ...`
  Then top-level keys match in order and nested sub-objects (`self_value`, `post_plan_diff` when present) match in key order
  And `disable_test` stays `null` or a supported identifier — never a free-text component name
```

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §3.

## Files to Modify/Create

- Create: `superpowers/tests/fixtures/legacy-harness-observation.sh` — the inline `bash` block as it appears in `retrospective/SKILL.md` Phase 5c today, factored into a runnable script that takes args and appends one NDJSON line to a `$1` jsonl path.
- Create: `superpowers/tests/fixtures/legacy-retrospective-run.sh` — same idea for the Phase 6 `retrospective_run` closure inline block.
- Create: `superpowers/tests/fixtures/legacy-evolution-item.sh` — same for the Phase 4 `item_added` / `item_removed` / `item_modified` / `item_promoted` inline block (single script handling all four shapes via `$1=event_type`).
- Create: `superpowers/tests/fixtures/README.md` — one-paragraph note documenting that these scripts capture the pre-migration write surface verbatim and are the byte-equality reference for task 006. Include the exact pre-migration `SKILL.md` line citation (file + line range) used to derive each script.

## Steps

### Step 1: Locate the inline `bash` blocks
- Open `superpowers/skills/retrospective/SKILL.md`. Find:
  - Phase 5c `jq -nc --arg event "component_unsupported" …` block (`bdd-specs.md` §1.3 carries the canonical shape).
  - Phase 4 `jq -nc` block emitting `item_added` / etc.
  - Phase 6 `jq -nc` block emitting `retrospective_run` (with `--argjson self_value`).
- Record the exact line numbers in `superpowers/tests/fixtures/README.md`.

### Step 2: Factor each block into a self-contained fixture script
- Each script: `#!/usr/bin/env bash`, accept positional args, append to the path given as `$1`, exit 0.
- **PROHIBITED**: do not change the `jq` invocation syntax, the field order, or the `--arg`/`--argjson` ordering — verbatim is the point.
- **ALLOWED**: pass the timestamp in as an `--arg` argument (so the parity test can substitute a fixed value and assert byte-equality under deterministic timestamp).

### Step 3: Hand-verify a single round-trip
- Run each fixture script against a temp jsonl file with sample args drawn from `bdd-specs.md` §3 (e.g., `component=plan_evaluator`, `retrospective_id=docs/retros/x.md`).
- `cat` the resulting line; confirm it parses with `jq -e .`.
- Record the sample command in `superpowers/tests/fixtures/README.md`.

### Step 4: Verification
- This task has no test in the Red→Green sense; verification is "the fixture scripts run cleanly and produce valid NDJSON".
- Run each script once and assert `jq -e . <output>` returns 0.

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers

# Smoke-test each fixture script
mkdir -p /tmp/retro-fixture-smoke
bash tests/fixtures/legacy-harness-observation.sh \
  /tmp/retro-fixture-smoke/harness.jsonl \
  component_unsupported plan_evaluator docs/retros/test.md 2026-05-12T00:00:00Z
jq -e . /tmp/retro-fixture-smoke/harness.jsonl

bash tests/fixtures/legacy-retrospective-run.sh \
  /tmp/retro-fixture-smoke/evolution.jsonl \
  2026-05-12T00:00:00Z 'docs/retros/x.md' '{"proposals_total":0}'
jq -e . /tmp/retro-fixture-smoke/evolution.jsonl

bash tests/fixtures/legacy-evolution-item.sh \
  /tmp/retro-fixture-smoke/evolution.jsonl \
  item_added 'add design folder' 'rationale' 'docs/plans/x' 1 'report.md' \
  2026-05-12T00:00:00Z
jq -e . /tmp/retro-fixture-smoke/evolution.jsonl

# Cleanup
rm -rf /tmp/retro-fixture-smoke
```

## Success Criteria

- Three fixture scripts exist under `superpowers/tests/fixtures/`, each executable and self-contained (no sourcing of project lib).
- Each fixture script produces valid NDJSON (`jq -e .` passes).
- `superpowers/tests/fixtures/README.md` documents the source line numbers in `retrospective/SKILL.md` and the regeneration procedure.
- No production code under `superpowers/lib/` is touched.
- No SKILL.md file is modified.
