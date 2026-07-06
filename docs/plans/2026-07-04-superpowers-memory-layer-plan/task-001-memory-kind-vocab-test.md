# Task 001: Memory kind vocabulary — test (RED)

**depends-on**: (none — first task)

## Description

Extend `tests/run-docs-index-tests.sh` with test functions proving `lib/docs-index.sh` accepts `memory` as a `kind` value everywhere `design|plan|retro` is currently accepted, and defaults its status to `active` (matching the existing `retro` precedent, not the `design`/`plan` `wip` default). These tests MUST fail against the current script (kind vocabulary is still `design|plan|retro` only).

## Execution Context

**Task Number**: 001 of 020
**Phase**: Foundation
**Prerequisites**: none

## BDD Scenario

```gherkin
Scenario: Cold start — first memory write creates docs/memory/ and the first kind=memory row
  Given the file `docs/README.md` does not exist
  And the directory `docs/memory/` does not exist
  When the systematic-debugging skill's write-gate fires for the first time in this project's history
  Then it creates `docs/memory/pitfall_<slug>.md` with valid `name`, `category`, `summary`, `source` frontmatter
  And it invokes `lib/docs-index.sh upsert memory docs/memory/pitfall_<slug>.md --status active --summary "<one-line>" --category pitfall`
  And the file `docs/README.md` is created with the header preamble and table header row
  And the table contains exactly one data row
  And that row's `kind` column equals `memory`
  And that row's `status` column equals `active`
```

**Spec Source**: `../2026-07-04-superpowers-memory-layer-design/bdd-specs.md` Scenario 1 (Cold start)

## Interfaces

**Exposes** (test functions added to `tests/run-docs-index-tests.sh`, called from the file's `run_test` invocation list at the bottom):
- `test_memory_kind_accepted_by_upsert()` — `upsert memory <path> --status active --summary "x" --category pitfall` exits 0 and writes a `kind=memory` row
- `test_memory_kind_accepted_by_list_filter()` — `list --kind memory` returns only memory rows, given a mixed index
- `test_memory_kind_rejected_message_mentions_memory()` — `upsert bogus-kind <path>` exit-2 stderr message enumerates `design|plan|retro|memory` (not just the old 3)
- `test_memory_default_status_is_active()` — `upsert memory <path>` with no `--status` flag defaults to `active`, not `wip`

**Consumes** (from `lib/docs-index.sh`, unmodified in this task):
- `bash "$DOCS_INDEX_SH" upsert <kind> <path> [--status <status>] [--summary <summary>] [--category <category>]` (the `--category` flag does not exist yet — pass it anyway; per task 003/004 it will be required for `kind=memory`, so these task-001 tests must also pass `--category pitfall` to avoid failing on the *category* gate once 004 lands, isolating this task to the *kind* gate only)
- `bash "$DOCS_INDEX_SH" list --kind <kind>`

**Global Constraints respected**: no new test framework (plain-bash `assert_*` helpers from `test_helpers.sh` only); no new index file/format.

## Files to Modify/Create

- Modify: `superpowers/tests/run-docs-index-tests.sh` — add the 4 test functions above in a new `# --- Task 001: memory kind vocabulary tests ---` section, and add 4 corresponding `run_test "..." test_...` lines to the invocation list at the bottom of the file (mirror the existing invocation-list style).

## Steps

### Step 1: Verify Scenario
- Confirm Scenario 1 (Cold start) exists in `../2026-07-04-superpowers-memory-layer-design/bdd-specs.md`.

### Step 2: Implement Test (Red)
- Add the 4 test functions using `setup_tmp_repo`/`assert_exit`/`assert_stdout_contains`/`assert_stdout_line_count` from `test_helpers.sh` (same idioms as the existing `test_list_no_filter_prints_all_rows`-style tests already in the file).
- Add their `run_test` invocations at the bottom of the file.
- **Verification**: `bash superpowers/tests/run-docs-index-tests.sh` — the 4 new tests FAIL (script still rejects `memory` as an unknown kind); pre-existing tests still PASS.

## Verification Commands

```bash
bash superpowers/tests/run-docs-index-tests.sh
```

## Success Criteria

- The 4 new test functions exist and are wired into the invocation list
- Running the suite shows exactly the 4 new tests as FAIL, zero regressions among pre-existing tests
