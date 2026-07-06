# Batch 3 Sprint Contract

## Tasks

| ID | Subject | Type |
|----|---------|------|
| 009 | Brainstorming memory touchpoint — test | test |
| 010 | Brainstorming memory touchpoint — impl | impl |
| 011 | Writing-plans memory touchpoint — test | test |
| 012 | Writing-plans memory touchpoint — impl | impl |

## Acceptance Criteria

### Task 009: Brainstorming memory touchpoint — test (RED)

- [ ] The 3 new assertions ("brainstorming Initialization consults list --kind memory", "brainstorming Phase 3 has a conditional memory-write step gated on REWORK 2+ rounds", "brainstorming's memory-write step is explicitly conditional, not unconditional") exist in `superpowers/tests/test-skill-touchpoints.sh` in a new `== Brainstorming memory touchpoints ==` block
- [ ] Running `bash superpowers/tests/test-skill-touchpoints.sh` shows exactly these 3 new assertions FAIL (brainstorming's `SKILL.md` has no memory-related text yet)
- [ ] Zero regressions among the file's pre-existing assertions

### Task 010: Brainstorming memory touchpoint — impl (GREEN)

- [ ] All 3 task-009 assertions PASS
- [ ] Zero regressions among pre-existing `test-skill-touchpoints.sh` assertions
- [ ] Initialization step 2 extended with a `list --kind memory --status active` call, read before Phase 1 exploration
- [ ] Phase 3 Wrap-up gains new step 0.5 (conditional on the existing "REWORK 2+ rounds" trigger), calling `upsert memory docs/memory/<category>_<slug>.md ... --category <category>`; the step is a no-op when fewer than 2 REWORK rounds occurred

### Task 011: Writing-plans memory touchpoint — test (RED)

- [ ] The 3 new assertions ("writing-plans Initialization consults list --kind memory", "writing-plans Phase 5 has a conditional memory-write step gated on Phase 4 FAIL", "writing-plans's memory-write step names the FAIL/rework gate") exist in a new `== Writing-Plans memory touchpoints ==` block
- [ ] Running the suite shows all 3 new assertions FAIL for the documented reason
- [ ] Zero regressions among pre-existing assertions

### Task 012: Writing-plans memory touchpoint — impl (GREEN)

- [ ] All 3 task-011 assertions PASS
- [ ] Zero regressions among pre-existing assertions
- [ ] Initialization step 1 ("Design Check") extended with a `list --kind memory --status active` call
- [ ] Phase 5 "Git Commit" gains new step 0.5 (conditional on a Phase 4 sub-agent FAIL requiring fix-and-rerun), calling `upsert memory docs/memory/pitfall_<slug>.md ... --category pitfall`; no-op if every sub-agent passed first try

## Red-Green Pairs

| Test Task | Impl Task | Expected Red State | Expected Green State |
|-----------|-----------|--------------------|----------------------|
| 009 | 010 | 3 new assertions FAIL (no memory text in `brainstorming/SKILL.md`) | 3 new assertions PASS, zero regressions |
| 011 | 012 | 3 new assertions FAIL (no memory text in `writing-plans/SKILL.md`) | 3 new assertions PASS, zero regressions |

**Scheduling note:** 009 and 011 both append to the shared file `tests/test-skill-touchpoints.sh` — 011 must start only after 009's edit lands (file-conflict guard from `_index.md`). 010 (edits `brainstorming/SKILL.md`) and 011 (edits `test-skill-touchpoints.sh`) touch distinct files and may run in parallel once 009 completes. 012 depends only on 011.

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
