# Task 005: Memory scan + rebuild — test (RED)

**depends-on**: task-002, task-003 (file-conflict guard: both task-003 and this task append new sections to `superpowers/tests/run-docs-index-tests.sh`; serialized to avoid a concurrent-write race if scheduled in the same batch — see plan reflection File Conflict Review)

## Description

Extend `tests/run-docs-index-tests.sh` with test functions proving `rebuild` discovers `docs/memory/*.md` files (a plain, non-recursive glob), seeds each as `kind=memory status=active`, extracts the file's own `summary:` frontmatter value instead of leaving the summary blank (unlike the design/plan/retro folders, which have no such internal summary to extract), and never picks up files sitting in `docs/memory/archive/` (the glob must not descend into that subdirectory). These tests MUST fail against the current script (`scan_folders()` has no memory loop).

## Execution Context

**Task Number**: 005 of 020
**Phase**: Foundation
**Prerequisites**: task-002 merged (kind=memory accepted by validate_kind); task-003 merged (avoids a concurrent-write race on the shared test file)

## BDD Scenario

```gherkin
Scenario: Cold start — first memory write creates docs/memory/ and the first kind=memory row
  Given the file `docs/README.md` does not exist
  And the directory `docs/memory/` does not exist
  When the systematic-debugging skill's write-gate fires for the first time in this project's history
  Then it creates `docs/memory/pitfall_<slug>.md` with valid `name`, `category`, `summary`, `source` frontmatter
  And the file `docs/README.md` is created with the header preamble and table header row

Scenario: An expired memory row's file is archived and dropped from the index
  ...
  Then a subsequent `rebuild` does NOT re-add a row for the archived file
    (its non-recursive `docs/memory/*.md` glob does not descend into `archive/`)
```

**Spec Source**: `../2026-07-04-superpowers-memory-layer-design/bdd-specs.md` Scenario 1, Scenario 15 (rebuild-does-not-resurrect clause); `architecture.md` §2 (`scan_folders()` diff-table row)

## Interfaces

**Exposes** (test functions added to `tests/run-docs-index-tests.sh`):
- `test_rebuild_discovers_memory_files()` — one `docs/memory/pitfall_x.md` file on disk → `rebuild` produces exactly one `kind=memory status=active` row for it
- `test_rebuild_extracts_summary_from_memory_frontmatter()` — a memory file with `summary: foo bar` in its frontmatter → the rebuilt row's `summary` column equals `foo bar` (not blank, unlike a fresh design/plan folder)
- `test_rebuild_ignores_memory_archive_subdir()` — a file under `docs/memory/archive/pitfall_old.md` produces NO row on `rebuild`
- `test_rebuild_preserves_existing_memory_status()` — an existing `expired:<reason>` row for a still-present memory file is preserved across `rebuild` (reuses the existing `existing_status_map` merge behavior — no memory-specific change needed here, but must be asserted so a future edit can't silently break it)

**Consumes** (from `lib/docs-index.sh`, unmodified in this task):
- `bash "$DOCS_INDEX_SH" rebuild`
- `scan_folders()` (indirectly, via `rebuild`)

**Global Constraints respected**: no `jq` dependency (frontmatter extraction via `grep`/`awk` only); no new index file/format.

## Files to Modify/Create

- Modify: `superpowers/tests/run-docs-index-tests.sh` — add the 4 test functions above in a new `# --- Task 005: memory scan + rebuild tests ---` section, plus their `run_test` invocations. Use plain file writes (`mkdir -p docs/memory && cat > docs/memory/pitfall_x.md <<'EOF' ... EOF`) to seed fixture memory files — mirror how existing rebuild tests seed `docs/plans/*-design/` fixture folders.

## Steps

### Step 1: Verify Scenario
- Confirm Scenario 1 and Scenario 15 exist in the design's `bdd-specs.md`.

### Step 2: Implement Test (Red)
- Seed fixture `docs/memory/` files (and one `docs/memory/archive/` file) inside `setup_tmp_repo`'s temp repo, run `rebuild`, then assert on the resulting `docs/README.md` content via `assert_file_contains` / `assert_file_not_contains`.
- **Verification**: `bash superpowers/tests/run-docs-index-tests.sh` — the 4 new tests FAIL (no memory rows appear at all after `rebuild` today).

## Verification Commands

```bash
bash superpowers/tests/run-docs-index-tests.sh
```

## Success Criteria

- The 4 new tests exist, are wired in, and FAIL for the documented reason
- Zero regressions among pre-existing tests
