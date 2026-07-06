# Task 007: Memory collapse grouping + archive-on-drop — test (RED)

**depends-on**: task-004, task-006

## Description

Extend `tests/run-docs-index-tests.sh` with test functions proving two behaviors, both specific to `kind=memory` rows within the already-shipped 60-line ceiling / collapse machinery:

1. **Collapse grouping by category, not by unique filename.** `topic_of_path()` today strips a `docs/plans/YYYY-MM-DD-` prefix and a `-design`/`-plan` suffix; for any path that doesn't match that shape (every `docs/memory/<category>_<slug>.md` path), it falls back to the bare basename (`${p##*/}`) — which is **unique per file**, so 3+ memory rows would never share a `(topic, cat)` key and would never collapse. This is a real gap: without a memory-specific branch, `collapse_rows()`'s stage-1 grouping silently never fires for memory rows.
2. **Archive-on-drop.** When `collapse_rows()`'s stage-2 "drop expired entries entirely" rule fires on a `kind=memory` row (index still over 60 after stage-1 collapse), the underlying file must be physically moved to `docs/memory/archive/<basename>` — not left as an orphaned file with no index row pointing at it (the existing behavior for dropped design/plan/retro rows is fine, since their content is a `docs/plans/`/`docs/retros/` folder/file that stays discoverable by directory listing regardless of the index; a lone memory `.md` file with no row is easy to lose track of).

These tests MUST fail against the current script (`topic_of_path()` has no memory branch; no archive-move logic exists anywhere).

## Execution Context

**Task Number**: 007 of 020
**Phase**: Foundation
**Prerequisites**: task-004 and task-006 merged

## BDD Scenario

```gherkin
Scenario: The 60-line ceiling collapse rule applies to memory rows exactly like other kinds
  Given the index already contains 58 rows across design/plan/retro/memory
  And 3 more `kind=memory` rows are upserted, each with `status=expired:<reason>` and `category=pitfall`
  When the total row count would reach 61
  Then the first-line collapse groups rows sharing `status=expired` and `category=pitfall`
    into a single summary line (grouped by `category`, since flat `docs/memory/<category>_<slug>.md`
    paths carry no date-prefixed topic the way `docs/plans/YYYY-MM-DD-*` folders do)
  And the collapsed line reads "... and 3 prior expired pitfall memory entries — see git history"
  And the final index contains at most 60 rows
  And active `kind=memory` rows are never collapsed

Scenario: An expired memory row's file is archived and dropped from the index
  Given the index contains one `kind=memory` row with `status=expired:<reason>`
  When the shipped 60-line second-line-defense "drop expired rows" rule applies to that row
  Then the underlying file `docs/memory/<category>_<slug>.md` is moved to
    `docs/memory/archive/<category>_<slug>.md`
  And the row is dropped entirely from `docs/README.md`
  And the file remains recoverable via `docs/memory/archive/` and git history
```

**Spec Source**: `../2026-07-04-superpowers-memory-layer-design/bdd-specs.md` Scenario 17, Scenario 15

## Interfaces

**Exposes** (test functions added to `tests/run-docs-index-tests.sh`):
- `test_topic_of_path_groups_memory_by_category()` — direct unit test: `topic_of_path "docs/memory/pitfall_foo.md"` and `topic_of_path "docs/memory/pitfall_bar.md"` both return `pitfall` (not their distinct basenames)
- `test_collapse_groups_three_expired_memory_rows_by_category()` — 3+ `kind=memory status=expired:*` rows sharing `category=pitfall` (encoded in the filename prefix) collapse into one summary row when total > 60
- `test_collapse_never_collapses_active_memory_rows()` — active `kind=memory` rows are excluded from the stage-1 collapse candidate set (same rule already applies to active design/plan/retro rows)
- `test_rebuild_archives_dropped_expired_memory_file()` — a `kind=memory status=expired:*` row that gets dropped by stage-2 (index still >60 after stage-1) results in its file being moved from `docs/memory/<name>.md` to `docs/memory/archive/<name>.md`
- `test_rebuild_does_not_archive_kept_rows()` — a `kind=memory status=active` row present alongside 60+ other rows is never moved to `archive/`

**Consumes** (from `lib/docs-index.sh`, unmodified in this task):
- `topic_of_path()`, `collapse_rows()`, `cmd_rebuild()`

**Global Constraints respected**: reuses the shipped 60-line ceiling and two-stage collapse rule verbatim — no new ceiling, no new collapse mechanism, only a memory-specific grouping key and a memory-specific archive side-effect.

## Files to Modify/Create

- Modify: `superpowers/tests/run-docs-index-tests.sh` — add the 5 test functions above in a new `# --- Task 007: memory collapse grouping + archive tests ---` section, plus `run_test` invocations. Fixture generation: write a small bash loop seeding 61+ rows (or 58 boilerplate + 3 memory rows, per the scenario) via `make_index`, plus real files under `docs/memory/` for the archive tests (archive-on-drop needs real files on disk, not just index rows, since it asserts a file move).

## Steps

### Step 1: Verify Scenario
- Confirm Scenario 17 and Scenario 15 exist in the design's `bdd-specs.md`.

### Step 2: Implement Test (Red)
- `test_topic_of_path_groups_memory_by_category` calls `topic_of_path` directly as a bash function (source `lib/docs-index.sh` in a subshell, or invoke via a small `bash -c` wrapper, matching however the existing suite tests other bare functions — check for precedent in the file before choosing an invocation style).
- The collapse/archive tests seed a temp repo with the described row/file counts, run `rebuild`, and assert on the resulting `docs/README.md` content plus `docs/memory/archive/` directory contents.
- **Verification**: `bash superpowers/tests/run-docs-index-tests.sh` — all 5 new tests FAIL.

## Verification Commands

```bash
bash superpowers/tests/run-docs-index-tests.sh
```

## Success Criteria

- The 5 new tests exist, are wired in, and FAIL for the documented reason
- Zero regressions among pre-existing tests
