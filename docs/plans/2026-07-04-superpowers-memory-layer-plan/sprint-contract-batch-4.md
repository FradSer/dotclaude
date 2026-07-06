# Batch 4 Sprint Contract

## Tasks

| ID | Subject | Type |
|----|---------|------|
| 013 | Executing-plans memory touchpoint — test | test |
| 014 | Executing-plans memory touchpoint — impl | impl |
| 015 | Systematic-debugging memory touchpoint — test | test |
| 016 | Systematic-debugging memory touchpoint — impl | impl |

## Acceptance Criteria

### Task 013: Executing-plans memory touchpoint — test (RED)

- [ ] The 3 new assertions ("executing-plans Initialization consults list --kind memory", "executing-plans Phase 5 has a conditional memory-write step gated on the variety-gap signal", "executing-plans distinguishes the variety-gap trigger from the batch-execution-playbook hard-abort cap") exist in `superpowers/tests/test-skill-touchpoints.sh` in a new `== Executing-Plans memory touchpoints ==` block
- [ ] Running `bash superpowers/tests/test-skill-touchpoints.sh` shows exactly these 3 new assertions FAIL
- [ ] Zero regressions among pre-existing assertions

### Task 014: Executing-plans memory touchpoint — impl (GREEN)

- [ ] All 3 task-013 assertions PASS
- [ ] Zero regressions among pre-existing assertions
- [ ] Initialization step 1 ("Plan Check") extended with a `list --kind memory --status active` call
- [ ] Phase 5's existing CRITICAL post-commit index-flip block extended with a conditional memory-write step gated on the intra-plan-learning "variety gap" signal (2+ rework rounds, batch eventually PASSes) — explicitly distinct from `batch-execution-playbook.md`'s separate hard-abort cap, which is NOT a memory-write trigger; folded into the same dedicated follow-up commit the block already creates

### Task 015: Systematic-debugging memory touchpoint — test (RED)

- [ ] The 5 new assertions ("systematic-debugging allowed-tools includes docs-index.sh scope", "systematic-debugging new step 0 consults list --kind memory before Phase 1", "systematic-debugging's memory read is skipped on the bail-out path", "systematic-debugging's memory-write step reuses the existing 3+ failed-fixes trigger", "systematic-debugging's memory-write is its ONLY docs/ touchpoint, not a new phase") exist in a new `== Systematic-Debugging touchpoints ==` block
- [ ] Running the suite shows all 5 new assertions FAIL (the skill's `SKILL.md` has no memory text and no `docs-index.sh` scope in `allowed-tools` yet)
- [ ] Zero regressions among pre-existing assertions

### Task 016: Systematic-debugging memory touchpoint — impl (GREEN)

- [ ] All 5 task-015 assertions PASS
- [ ] Zero regressions among pre-existing assertions
- [ ] `allowed-tools` frontmatter gains the `docs-index.sh` scope string
- [ ] New step 0 prepended to Phase 1 (before existing step 1), skipped whenever the Bail-Out Check fires, calls `list --kind memory --status active`
- [ ] New step 6 appended after the existing "3+ Failed Fixes" step — this skill's ONLY `docs/` touchpoint, not a new phase or separate commit — fires on the existing 3+-fixes trigger OR an explicit cross-cutting gotcha
- [ ] The skill's existing deliverable-discipline sentence ("fix + regression test, never a planning artifact") is unchanged

## Red-Green Pairs

| Test Task | Impl Task | Expected Red State | Expected Green State |
|-----------|-----------|--------------------|----------------------|
| 013 | 014 | 3 new assertions FAIL (no memory text in `executing-plans/SKILL.md`) | 3 new assertions PASS, zero regressions |
| 015 | 016 | 5 new assertions FAIL (no memory text, no `docs-index.sh` scope in `systematic-debugging/SKILL.md`) | 5 new assertions PASS, zero regressions |

**Scheduling note:** 013 and 015 both append to the shared file `tests/test-skill-touchpoints.sh` — 015 must start only after 013's edit lands. 014 (edits `executing-plans/SKILL.md`) and 015 (edits `test-skill-touchpoints.sh`) touch distinct files and may run in parallel once 013 completes. 016 depends only on 015.

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
