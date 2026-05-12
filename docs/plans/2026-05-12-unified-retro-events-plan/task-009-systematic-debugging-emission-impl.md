# Task 009: systematic-debugging Phase 4 fix_completed Emission — Implementation (Green)

**depends-on**: task-009-systematic-debugging-emission-test

## Description

Edit `superpowers/skills/systematic-debugging/SKILL.md` to add the `fix_completed` emission at the END of Phase 4 step 3 ("Verify Fix") on the success branch only. The bail-out branch, the architecture-questioning branch, and Phases 1–3 do NOT emit. The skill name is read from the session state file via the same `state_read` path used by `_loop_log_plan_completion_if_executing` (in `lib/loop.sh`).

## Execution Context

**Task Number**: 009 of 21
**Phase**: systematic-debugging emission point
**Prerequisites**: Task 009 test is RED; Task 003 impl shipped the helper.

## BDD Scenario

See `task-009-systematic-debugging-emission-test.md`. Four scenarios pinned.

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §4; `architecture.md` §"Integration Points → systematic-debugging".

## Files to Modify/Create

- Modify: `superpowers/skills/systematic-debugging/SKILL.md` Phase 4 step 3 success branch.

## Steps

### Step 1: Locate Phase 4 Step 3 Success Branch
- Open the file; find the Phase 4 step "Verify Fix" prose. The success branch is the path taken when the regression test passes and the issue is resolved.

### Step 2: Add the Emission Block

After the Phase 4 step 3 success-criteria prose (test passes, no other tests broken, issue resolved), insert one bash-fenced block (prefixed by a short prose paragraph explaining why it exists) that:

- Reads `skill_name` from the session state file via the same `state_read` mechanism `lib/loop.sh::_loop_log_plan_completion_if_executing` uses. The implementer reads `lib/utils.sh` and `lib/loop.sh` first to confirm the function name and import path — do NOT invent a name. If the state read returns an empty string, the emission silently skips (matching BDD §4.3 "if the state file is missing or skill_name is empty, the emission silently skips and returns 0"). There is NO fallback to the literal `"systematic-debugging"`; the bdd contract requires skip-not-write on empty state.
- Invokes `bash "${CLAUDE_PLUGIN_ROOT}/lib/skill-events.sh"` with the state-resolved skill name, the literal event name `fix_completed`, and a payload filter object that includes `symptom`, `root_cause`, `regression_test_path`, `investigation_phase_count` unconditionally, plus `fix_commit` conditionally (use jq's `if … then … else {} end` to omit `fix_commit` when the git short-SHA cannot be resolved). The implementer derives the conditional pattern from Task 008's `post_plan_diff` precedent.
- Sets `symptom` from a 200-char-truncated `$ARGUMENTS`, `root_cause` from the Phase 1 evidence one-liner (the executing Claude fills the value at runtime from the actual debugging session), `fix_commit` from `git rev-parse --short HEAD` (best-effort — empty on failure), `regression_test_path` from the repo-relative path the executor knows from Phase 4 work, and `investigation_phase_count` from the count of phases actually traversed (1 for a bail-out, 4 for the full pipeline, more on re-entry).
- Does NOT pass any `--arg` named `stdout`, `stderr`, `fix_diff`, or `diff` — the test at Task 009 §3 will fail if any of those appear.

The emission is best-effort: Phase 4 success criteria hold regardless of whether the helper writes the line. The implementer reads BDD §4 (all four scenarios) once before writing the block to ensure the success / bail-out / state-missing / architecture-questioning branches all behave as specified.

### Step 3: Do NOT Edit the Bail-out Branch
- Confirm the bail-out branch in SKILL.md (the top-of-skill check around line 41–48 per `grep` results) is unchanged. It already calls `bail-log.sh`; it must NOT call `skill-events.sh`.

### Step 4: Do NOT Edit the Architecture-questioning Branch
- Confirm Phase 4 step 4 (the "If Fix Doesn't Work" branch that loops back to Phase 1 or transitions to "question the architecture") is unchanged. No new emission.

### Step 5: Verify Tests
- Run Task 009's test module; every test passes.
- Run the systematic-debugging-specific `test_skill_events_sh.py` from Task 003; remains green.
- Full suite green.

### Step 6: Final Grep Audit
- `grep -n "lib/skill-events.sh" superpowers/skills/systematic-debugging/SKILL.md` should return exactly the lines in Phase 4 step 3 success branch (count: 1, or 2 if the documentation comment also names the script).
- The same grep should return 0 results in Phases 1, 2, 3 and in both the bail-out and architecture-questioning branches of Phase 4.

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude
python3 -m pytest superpowers/tests/test_systematic_debugging_emission.py -v 2>&1 | tail -50
python3 -m pytest superpowers/tests/ -q 2>&1 | tail -10
grep -nc "lib/skill-events.sh" superpowers/skills/systematic-debugging/SKILL.md
# Expect: small integer (1-2), only in Phase 4 step 3 success branch
```

## Success Criteria

- Task 009's tests pass.
- The emission appears exactly once in Phase 4 step 3 success branch.
- The bail-out, architecture-questioning, Phase 1, Phase 2, Phase 3 sections contain no `lib/skill-events.sh` reference.
- `state_read skill_name` is the source of the first positional arg.
- Full suite green.
