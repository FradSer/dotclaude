# Batch 1 Sprint Contract

## Tasks

| ID | Subject | Type |
|----|---------|------|
| 001 | Memory kind vocabulary — test | test |
| 002 | Memory kind vocabulary — impl | impl |
| 003 | Memory status restriction + category flag — test | test |
| 004 | Memory status restriction + category flag — impl | impl |

## Acceptance Criteria

### Task 001: Memory kind vocabulary — test (RED)

- [ ] `test_memory_kind_accepted_by_upsert`, `test_memory_kind_accepted_by_list_filter`, `test_memory_kind_rejected_message_mentions_memory`, `test_memory_default_status_is_active` exist in `superpowers/tests/run-docs-index-tests.sh` and are wired into the `run_test` invocation list
- [ ] Running `bash superpowers/tests/run-docs-index-tests.sh` shows exactly these 4 new tests FAIL (script still rejects `memory` as an unknown kind) — failing for the right reason, not a test-authoring bug
- [ ] Zero regressions among pre-existing tests
- [ ] Each test targets a specific behavior from BDD Scenario 1 (Cold start)

### Task 002: Memory kind vocabulary — impl (GREEN)

- [ ] All 4 task-001 tests PASS
- [ ] Every pre-existing test in `run-docs-index-tests.sh` and `test-skill-touchpoints.sh` still passes (zero regressions)
- [ ] `bash superpowers/lib/docs-index.sh upsert memory docs/memory/x.md --summary "test"` (no `--status`) writes a row with `status=active`
- [ ] Only the five specified case-arm edits are made (`validate_kind`, `default_status_for_kind`, `cmd_list`'s `--kind` arm, `seed_header`, `usage()`/header comment) — no other function touched

### Task 003: Memory status restriction + category flag — test (RED)

- [ ] All 11 new test functions (status-subset + category-flag) exist in `superpowers/tests/run-docs-index-tests.sh` and are wired into the invocation list
- [ ] Running the suite shows all 11 new tests FAIL for the documented reason (no kind-aware status restriction, no `--category` flag at all)
- [ ] Zero regressions among pre-existing tests (including task-001/002's 4 tests)

### Task 004: Memory status restriction + category flag — impl (GREEN)

- [ ] All 11 task-003 tests PASS
- [ ] Zero regressions in pre-existing tests
- [ ] `upsert memory <path> --status active --summary "x" --category pitfall` succeeds
- [ ] `upsert memory <path> --status active --summary "x" --category type` exits 2
- [ ] `set-status <memory-path> wip` exits 2
- [ ] `set-status <memory-path> "expired:r:reason"` exits 0

## Red-Green Pairs

| Test Task | Impl Task | Expected Red State | Expected Green State |
|-----------|-----------|--------------------|----------------------|
| 001 | 002 | 4 new tests FAIL (`memory` kind rejected as unknown) | 4 new tests PASS, zero regressions |
| 003 | 004 | 11 new tests FAIL (no kind-aware status restriction, no `--category` flag) | 11 new tests PASS, zero regressions |

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
