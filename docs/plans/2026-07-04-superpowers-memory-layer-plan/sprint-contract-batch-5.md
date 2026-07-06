# Batch 5 Sprint Contract

## Tasks

| ID | Subject | Type |
|----|---------|------|
| 017 | Retrospective memory touchpoint — test | test |
| 018 | Retrospective memory touchpoint — impl | impl |
| 019 | Plugin version bump + marketplace.json sync | config |
| 020 | README memory-layer documentation | docs |

## Acceptance Criteria

### Task 017: Retrospective memory touchpoint — test (RED)

- [ ] The 5 new assertions ("retrospective Phase 1 consults list --kind memory", "retrospective Phase 4 drafts a memory file for applied ADD/MODIFY proposals", "retrospective explicitly excludes REMOVE/PROMOTE from the memory write-gate", "retrospective documents the Pre-Check-B promotion bridge", "retrospective documents memory-file consolidation via set-status expired:superseded-by-consolidation") exist in a new `== Retrospective memory touchpoints ==` block
- [ ] Running `bash superpowers/tests/test-skill-touchpoints.sh` shows all 5 new assertions FAIL
- [ ] Zero regressions among pre-existing assertions (including any existing Pre-Check B assertions)

### Task 018: Retrospective memory touchpoint — impl (GREEN)

- [ ] All 5 task-017 assertions PASS
- [ ] Zero regressions among pre-existing assertions
- [ ] Phase 1 "Data Collection" step 1 extended with a `list --kind memory --status active` call
- [ ] Phase 4 "Auto-Apply" gains new step 3.5: drafts one `docs/memory/<category>_<slug>.md` file for every ADD/MODIFY proposal actually applied this run; REMOVE and PROMOTE proposals, even if applied, do NOT trigger this step
- [ ] Phase 6 "Output" gains new step 8: runs `upsert memory` for each memory file drafted in Phase 4 step 3.5
- [ ] Pre-Check B (lines 31-41) gains exactly one appended sentence describing the promotion bridge (recalled hook cited as supporting evidence for an approved proposal + proves project-specific/durable → recorded in the drafted file's `## Why` section as `Promoted from private assistant memory hook: <hook-name>, <date>`); the private hook itself is never deleted or modified; cross-project stances are explicitly NOT promoted
- [ ] Pre-Check B's original paragraph (lines 31-40) is otherwise byte-identical — only the new trailing sentence added
- [ ] Phase 3 "Evolution Proposals" extended to flag 2+ active `kind=memory` files on the same concept as a memory-consolidation MODIFY candidate; when applied, the absorbed file's row is flipped via `set-status <path> "expired:superseded-by-consolidation:<survivor-path>"` then dropped by the existing collapse rule — no new subcommand

### Task 019: Plugin version bump + marketplace.json sync (config)

- [ ] `superpowers/.claude-plugin/plugin.json` remains valid JSON with `"version": "3.6.0"`
- [ ] `.claude-plugin/marketplace.json`'s `superpowers` entry remains valid JSON with `"version": "3.6.0"`
- [ ] No other field in either file was touched

### Task 020: README memory-layer documentation (docs)

- [ ] Each of the 5 skill sections in `superpowers/README.md`'s "User-Invocable Skills" (`/superpowers:brainstorming`, `/superpowers:writing-plans`, `/superpowers:executing-plans`, `/superpowers:retrospective`, `/superpowers:systematic-debugging`) gains exactly one new bullet describing its memory-layer touchpoint, matching each section's existing tone/bullet density
- [ ] No pre-existing bullet, heading, or section is altered or removed
- [ ] `grep -c "memory layer\|kind=memory" superpowers/README.md` returns a count consistent with 5 new bullets

## Red-Green Pairs

| Test Task | Impl Task | Expected Red State | Expected Green State |
|-----------|-----------|--------------------|----------------------|
| 017 | 018 | 5 new assertions FAIL (no memory text in `retrospective/SKILL.md`) | 5 new assertions PASS, zero regressions |

Tasks 019 and 020 are not part of a Red-Green pair (config and docs tasks) — standard acceptance criteria apply: verification command exits 0 and all checklist items satisfied.

**Scheduling note:** this batch is a strict linear chain — 019 depends on all 5 touchpoint impl tasks (010, 012, 014, 016, and this batch's own 018), and 020 depends on 019. No parallelism is available within this batch: 017 → 018 → 019 → 020.

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
