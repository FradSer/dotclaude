# Batch 2 Sprint Contract

## Tasks

| ID | Subject | Type |
|----|---------|------|
| 005 | Memory scan + rebuild — test | test |
| 006 | Memory scan + rebuild — impl | impl |
| 007 | Memory collapse grouping + archive-on-drop — test | test |
| 008 | Memory collapse grouping + archive-on-drop — impl | impl |

## Acceptance Criteria

### Task 005: Memory scan + rebuild — test (RED)

- [ ] `test_rebuild_discovers_memory_files`, `test_rebuild_extracts_summary_from_memory_frontmatter`, `test_rebuild_ignores_memory_archive_subdir`, `test_rebuild_preserves_existing_memory_status` exist in `superpowers/tests/run-docs-index-tests.sh` and are wired into the invocation list
- [ ] Running the suite shows exactly these 4 new tests FAIL (no memory rows appear at all after `rebuild` today)
- [ ] Zero regressions among pre-existing tests

### Task 006: Memory scan + rebuild — impl (GREEN)

- [ ] All 4 task-005 tests PASS
- [ ] Zero regressions among pre-existing tests
- [ ] A memory file's `summary:` frontmatter value survives a first-time `rebuild` (manual check: seed `docs/memory/pitfall_x.md` with `summary: hello world` frontmatter, run `rebuild`, confirm the row's summary column reads `hello world`)

### Task 007: Memory collapse grouping + archive-on-drop — test (RED)

- [ ] `test_topic_of_path_groups_memory_by_category`, `test_collapse_groups_three_expired_memory_rows_by_category`, `test_collapse_never_collapses_active_memory_rows`, `test_rebuild_archives_dropped_expired_memory_file`, `test_rebuild_does_not_archive_kept_rows` exist and are wired into the invocation list
- [ ] Running the suite shows all 5 new tests FAIL for the documented reason (no memory branch in `topic_of_path()`, no archive-move logic anywhere)
- [ ] Zero regressions among pre-existing tests

### Task 008: Memory collapse grouping + archive-on-drop — impl (GREEN)

- [ ] All 5 task-007 tests PASS
- [ ] Zero regressions among pre-existing tests (all prior tasks' tests plus the originally-shipped docs-index suite)
- [ ] Non-memory collapse/drop behavior (design/plan/retro rows) is byte-for-byte unchanged
- [ ] `collapse_rows()` remains a pure stdin→stdout filter — the archive side-effect lives only in `cmd_rebuild()`

## Red-Green Pairs

| Test Task | Impl Task | Expected Red State | Expected Green State |
|-----------|-----------|--------------------|----------------------|
| 005 | 006 | 4 new tests FAIL (no memory rows appear after `rebuild`) | 4 new tests PASS, zero regressions |
| 007 | 008 | 5 new tests FAIL (no memory branch in `topic_of_path()`, no archive logic) | 5 new tests PASS, zero regressions |

## Evaluation Criteria Preview

The evaluator will apply the following checklist items to this batch (source: `docs/retros/checklists/code-v3.md`):

| Item ID | Description |
|---------|-------------|
| CODE-VER-01 | All verification commands exit with code 0 |
| CODE-QUAL-01 | No TODO/FIXME/HACK/XXX/STUB patterns in produced files |
| CODE-QUAL-02 | No stub implementations (`NotImplementedError`, `pass`-only, `...`-only bodies) in produced files |
| CODE-ENV-ISO-01 | Test subprocess calls sanitize parent shell environment (applies only if produced test files invoke subprocess/child-process) |
| CODE-TEST-LIVE-01 | Produced tests actually run; none silently disabled, skipped, or focused |

## Sign-off

- **Generator:** executing-plans
- **Timestamp:** 2026-07-06T00:00:00Z
- **Status:** READY
- **Revision:** 0
