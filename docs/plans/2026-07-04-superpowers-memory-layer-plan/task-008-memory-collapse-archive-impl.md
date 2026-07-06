# Task 008: Memory collapse grouping + archive-on-drop — impl (GREEN)

**depends-on**: task-007

## Description

Two isolated additions:

1. **`topic_of_path()` memory branch.** Add an early case for `docs/memory/` paths that returns the leading `<category>` token (the substring before the first `_`), bypassing the existing `docs/plans/`-specific prefix/suffix stripping entirely.
2. **Archive-on-drop.** `collapse_rows()` stays a pure stdin→stdout filter (no file I/O) — the archive side-effect belongs in its caller, `cmd_rebuild()`, which already has the pre-collapse (`merged`) and post-collapse (`collapsed`) row sets in scope. After collapsing, diff the two sets: any row present in `merged` but absent from `collapsed` (by path) whose `kind == memory` and whose pre-drop status category was `expired` gets its file moved to `docs/memory/archive/<basename>` (creating the `archive/` directory on first use).

## Execution Context

**Task Number**: 008 of 020
**Phase**: Foundation
**Prerequisites**: task-007's tests exist and FAIL

## BDD Scenario

```gherkin
Scenario: The 60-line ceiling collapse rule applies to memory rows exactly like other kinds
  Then the first-line collapse groups rows sharing `status=expired` and `category=pitfall`
    into a single summary line (grouped by `category`, since flat `docs/memory/<category>_<slug>.md`
    paths carry no date-prefixed topic the way `docs/plans/YYYY-MM-DD-*` folders do)

Scenario: An expired memory row's file is archived and dropped from the index
  Then the underlying file `docs/memory/<category>_<slug>.md` is moved to
    `docs/memory/archive/<category>_<slug>.md`
  And the row is dropped entirely from `docs/README.md`
```

**Spec Source**: `../2026-07-04-superpowers-memory-layer-design/bdd-specs.md` Scenario 17, Scenario 15; `architecture.md` §2 (`collapse_rows()`/`topic_of_path()` diff-table row)

## Interfaces

**Exposes** (modified functions in `lib/docs-index.sh`):
- `topic_of_path(p: str) -> str` — new leading branch:
  ```
  case "$p" in
    docs/memory/*)
      local base="${p#docs/memory/}"
      printf '%s' "${base%%_*}"
      return 0
      ;;
  esac
  ```
  (placed before the existing `docs/plans/YYYY-MM-DD-` stripping logic, which is otherwise unreached for `docs/memory/` paths since they never match that prefix anyway — this branch is what actually makes grouping-by-category happen, replacing the unique-per-file basename fallback that would otherwise apply)
- `cmd_rebuild()` — after computing `collapsed` (the post-`collapse_rows` row set) from `merged` (the pre-collapse set), add an archive pass: build the set of paths present in `merged` but absent from `collapsed`; for each such path where the corresponding `merged` row's `kind == memory` and `status_category(<that row's status>) == expired`, run `mkdir -p "${root}/docs/memory/archive"` (once) and `mv -f "${root}/${path}" "${root}/docs/memory/archive/$(basename "$path")"` if the source file still exists.

**Consumes**: `status_category()` (unmodified, reused)

**Global Constraints respected**: `collapse_rows()` remains a pure function (no new file I/O inside it) — the archive side-effect lives entirely in `cmd_rebuild()`, keeping the two concerns (row filtering vs. filesystem mutation) separated, matching the script's existing separation of "compute" functions from the `cmd_*` orchestration layer.

## Files to Modify/Create

- Modify: `superpowers/lib/docs-index.sh:483-496` (`topic_of_path()` — add the new leading case)
- Modify: `superpowers/lib/docs-index.sh` `cmd_rebuild()` (the section that calls `collapse_rows` and writes the final file — add the archive diff-and-move pass between computing `collapsed` and writing it out)

## Steps

### Step 1: Verify Scenario
- Re-confirm Scenario 17 and Scenario 15 against current (pre-edit) behavior.

### Step 2: Implement Logic (Green)
- Add the `topic_of_path()` branch exactly as specified.
- Add the `cmd_rebuild()` archive pass exactly as specified.

### Step 3: Verify & Refactor
- Run the full suite through task-007.
- Confirm non-memory collapse/drop behavior (design/plan/retro rows) is byte-for-byte unchanged — re-run every pre-existing collapse test from the shipped docs-index suite.

## Verification Commands

```bash
bash superpowers/tests/run-docs-index-tests.sh
bash superpowers/tests/test-skill-touchpoints.sh
```

## Success Criteria

- All 5 task-007 tests PASS
- Zero regressions among pre-existing tests (all prior tasks' tests plus the originally-shipped docs-index suite)
- This completes the full `lib/docs-index.sh` foundation — all 5 skills' touchpoint tasks (009-018) can now proceed
