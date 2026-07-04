# Task 002: Memory kind vocabulary — impl (GREEN)

**depends-on**: task-001

## Description

Extend `lib/docs-index.sh`'s `kind` controlled vocabulary from `design|plan|retro` to `design|plan|retro|memory` at every enforcement site, and default `memory`'s status to `active` (same rule as `retro`). This is the minimal enum-extension edit — it does not add the `--category` flag or the status-subset restriction (those are task 003/004) and does not add `rebuild` support for `docs/memory/` (task 005/006).

## Execution Context

**Task Number**: 002 of 020
**Phase**: Foundation
**Prerequisites**: task-001's tests exist and FAIL

## BDD Scenario

```gherkin
Scenario: Cold start — first memory write creates docs/memory/ and the first kind=memory row
  Given the file `docs/README.md` does not exist
  When the systematic-debugging skill's write-gate fires for the first time in this project's history
  Then it invokes `lib/docs-index.sh upsert memory docs/memory/pitfall_<slug>.md --status active --summary "<one-line>"`
  And that row's `kind` column equals `memory`
  And that row's `status` column equals `active`
```

**Spec Source**: `../2026-07-04-superpowers-memory-layer-design/bdd-specs.md` Scenario 1

## Interfaces

**Exposes** (modified functions in `lib/docs-index.sh`):
- `validate_kind(kind: str) -> str` — case arm becomes `design|plan|retro|memory)`; error message becomes `"upsert: unknown kind '$kind' (expected: design|plan|retro|memory)"`
- `default_status_for_kind(kind: str) -> str` — case arm becomes `retro|memory) printf 'active' ;;`
- `cmd_list()`'s inline `--kind` validation case arm — becomes `design|plan|retro|memory) : ;;`; error message updated to match
- `seed_header()` — preamble text: `"One row per design/plan/retro folder"` → `"One row per design/plan/retro folder, or memory fact file"`
- `usage()` and the top-of-file header comment — `<design|plan|retro>` → `<design|plan|retro|memory>` in both doc strings

**Consumes**: none (leaf edits to existing functions, no new dependencies)

**Global Constraints respected**: additive-only edits — every existing `design|plan|retro` case arm keeps its exact prior behavior; no rewrite of unrelated logic.

## Files to Modify/Create

- Modify: `superpowers/lib/docs-index.sh:128` (`validate_kind` case arm + line 130 error string)
- Modify: `superpowers/lib/docs-index.sh:204` (`default_status_for_kind` case arm)
- Modify: `superpowers/lib/docs-index.sh:235-236` (`cmd_list` inline `--kind` case arm + error string)
- Modify: `superpowers/lib/docs-index.sh:117` (`seed_header` preamble text)
- Modify: `superpowers/lib/docs-index.sh:59-75` (`usage()` doc string) and the file's top-of-file header comment block (`Usage:` line near the top)

## Steps

### Step 1: Verify Scenario
- Re-confirm Scenario 1 against the current (pre-edit) script behavior — `upsert memory ...` currently exits 2.

### Step 2: Implement Logic (Green)
- Apply the five edits listed under Files to Modify/Create, exactly as specified in Interfaces.
- Do not touch `validate_status`, `cmd_upsert`'s status/summary handling, `cmd_show`, `cmd_set_status`, `transition_allowed`, `collapse_rows`, or `scan_folders` in this task — those are out of scope here.

### Step 3: Verify & Refactor
- Run the full existing suite plus task-001's 4 new tests; all must PASS.
- Run `bash superpowers/tests/test-skill-touchpoints.sh` to confirm zero regressions (this task touches no `SKILL.md` files).

## Verification Commands

```bash
bash superpowers/tests/run-docs-index-tests.sh
bash superpowers/tests/test-skill-touchpoints.sh
```

## Success Criteria

- All 4 task-001 tests PASS
- Every pre-existing test in `run-docs-index-tests.sh` and `test-skill-touchpoints.sh` still PASSes (zero regressions)
- `bash superpowers/lib/docs-index.sh upsert memory docs/memory/x.md --summary "test"` (no `--status`) writes a row with `status=active`
