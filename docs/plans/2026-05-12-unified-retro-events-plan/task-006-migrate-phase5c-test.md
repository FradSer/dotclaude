# Task 006: Migrate retrospective Phase 5c (Harness Observations) — Tests (Red)

**depends-on**: task-004-observations-impl

## Description

Write failing tests that **assert the post-migration state** of `superpowers/skills/retrospective/SKILL.md` Phase 5c. The migration replaces an inline `jq -nc ... >> docs/retros/harness-observations.jsonl` `bash` block with a one-line `bash "${CLAUDE_PLUGIN_ROOT}/lib/observations.sh" ...` invocation. The tests verify two surfaces:

1. **SKILL.md textual contract**: the new helper invocation appears in Phase 5c; the legacy inline `jq -nc ... >> docs/retros/harness-observations.jsonl` invocation is absent.
2. **Behavioral parity**: running the migrated Phase 5c against a synthesized refusal scenario produces a `harness-observations.jsonl` row whose JSON content matches the legacy fixture (modulo timestamp).

A purely textual SKILL.md test is brittle on its own (a refactor that changes whitespace would break it), so the assertion targets the high-signal anchors: the helper script path appears, the obsolete inline pattern does not appear, and the surrounding bash-fenced block invokes the helper exactly once per refusal-gate sub-case (`component_unsupported`, `component_unknown`).

## Execution Context

**Task Number**: 006 of 21
**Phase**: Migration of retrospective SKILL.md
**Prerequisites**: Tasks 004 impl (the helper exists).

## BDD Scenario

```gherkin
Scenario: existing harness-observations.jsonl rows are not rewritten
  Given a project with legacy rows in docs/retros/harness-observations.jsonl
  When log_harness_observation appends a new row
  Then the appended row is added at end-of-file
  And no in-place edit, no truncation, and no schema-rewrite pass touches prior rows
  And the file remains a valid NDJSON stream
```

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §5.19; cross-references §1.3, §3.11.

## Files to Modify/Create

- Modify: `superpowers/tests/test_migration_parity.py` (empty after Task 001).

## Steps

### Step 1: Test Helpers
- Module-level constants:
  ```python
  RETROSPECTIVE_SKILL_MD = SUPERPOWERS_DIR / "skills" / "retrospective" / "SKILL.md"
  OBSERVATIONS_SH = SUPERPOWERS_DIR / "lib" / "observations.sh"
  ```

### Step 2: TestCase — `RetrospectiveMigrationPhase5cTests`
- `test_phase_5c_invokes_observations_helper` — read `RETROSPECTIVE_SKILL_MD`; locate the Phase 5c section (regex on the heading "## Phase 5" or the prose anchor "If a component is unsupported"); assert the new invocation string `bash "${CLAUDE_PLUGIN_ROOT}/lib/observations.sh"` appears in that section.
- `test_phase_5c_no_inline_jq_to_harness_observations` — read full SKILL.md; assert the legacy inline pattern is absent. Use a precise regex (the absence of the literal substring `>> docs/retros/harness-observations.jsonl` is the strongest single anchor, because the pattern uniquely identifies the legacy path's terminus). The new helper does the same append internally, so this substring should not appear in SKILL.md prose any more.
- `test_phase_5c_invocation_covers_both_event_kinds` — within the Phase 5c section, assert both `component_unsupported` AND `component_unknown` appear as `<event>` arguments to the helper invocation (two helper calls, or one shared block templated over the two kinds).
- `test_phase_5c_does_not_emit_cleared_marker` — per architecture.md §"Integration Points → retrospective Phase 5c", the `cleared` observation is explicitly out of scope. Assert no `log_harness_observation ... cleared` substring in Phase 5c.

### Step 3: TestCase — `RetrospectiveMigrationPhase5cBehavioralTests`
- `test_helper_appends_to_existing_jsonl_unchanged` — set up a `tmpdir` with `docs/retros/harness-observations.jsonl` containing two pre-existing rows (one rich from `executing-plans`-style schema, one terse from a hypothetical prior Phase 5c run). Record each row's exact bytes. Run `bash lib/observations.sh component_unsupported '{component:$c, retrospective_id:$r}' --arg c "evaluator_per_batch" --arg r "docs/retros/2026-05-12.md"` from `tmpdir`. Read the new file; assert lines 1 and 2 are byte-equal to the originals; line 3 is the new emission and parses as JSON with the expected key set. (§5.19)
- `test_mixed_schema_rows_remain_a_valid_ndjson_stream` — after the helper write, run `jq -e . docs/retros/harness-observations.jsonl` row-by-row; assert every row parses (no broken stream).
- `test_mtime_of_prior_rows_unchanged` — capture the file's `(ctime, sha256-of-first-N-bytes)` covering the original two rows; after the helper invocation, re-read those first N bytes; assert sha256 unchanged. (mtime of the FILE changes because we appended; mtime of the existing ROWS is not exposed by the filesystem — the byte-substring check is the strongest available proof.)

### Step 4: Confirm RED
- The first TestCase (textual) fails because SKILL.md has not been migrated yet.
- The second TestCase (behavioral) passes IF the helper is implemented (Task 004 done) — these are independent of the SKILL.md edit. Mark them XPASS-tolerant or as a separate TestCase that's expected-green. For RED-clarity, label the SECOND TestCase methods `@unittest.skipUnless(SKILL_MD_MIGRATED, ...)` with `SKILL_MD_MIGRATED` evaluated at import time by re-running the first TestCase's textual checks. Document in the docstring: "These tests gate the Task 006 impl by being skipped pre-migration and assertive post-migration."

Alternative cleaner approach: keep the behavioral tests *always-on* (they pass on the helper, independent of SKILL.md). The textual tests are the ones that flip from RED to GREEN at Task 006 impl. State this in the test file's module docstring.

### Step 5: Verification
- Run module; expect `RetrospectiveMigrationPhase5cTests` to fail RED, `RetrospectiveMigrationPhase5cBehavioralTests` to pass already.

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude
python3 -m pytest superpowers/tests/test_migration_parity.py::RetrospectiveMigrationPhase5cTests -v 2>&1 | tail -30
# Expect: all FAIL
python3 -m pytest superpowers/tests/test_migration_parity.py::RetrospectiveMigrationPhase5cBehavioralTests -v 2>&1 | tail -30
# Expect: all PASS (depend only on observations.sh which is shipped)
```

## Success Criteria

- ≥ 4 tests in `RetrospectiveMigrationPhase5cTests` failing RED on textual contract checks.
- ≥ 3 tests in `RetrospectiveMigrationPhase5cBehavioralTests` passing on the helper's runtime behavior.
- The textual tests' anchor is the absence of `>> docs/retros/harness-observations.jsonl` plus presence of `bash "${CLAUDE_PLUGIN_ROOT}/lib/observations.sh"`.
