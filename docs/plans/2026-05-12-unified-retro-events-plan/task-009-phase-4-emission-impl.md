# Task 009-impl: systematic-debugging Phase 4 emission impl (Green)

**depends-on**: task-009-test

## Description

Add the `fix_completed` emission point to `systematic-debugging/SKILL.md` Phase 4 terminal step. Implement the SKILL.md prose plus the bash invocation that:
1. Reads `skill_name` from the session state file via the same `state_read` path used by `_loop_log_plan_completion_if_executing` (NOT hardcoded — see `best-practices.md`).
2. Performs the tail-200 dedup scan via `retro-events.sh::dedup_check` to satisfy §6.1.
3. Calls `bash "${CLAUDE_PLUGIN_ROOT}/lib/skill-events.sh" "$skill_name" fix_completed '<payload filter>' --arg ... --argjson ...`.
4. Does NOT fire on the bail-out branch (§4.2) or the architecture-questioning branch (§4.4).

Also touches `systematic-debugging/SKILL.md`'s `allowed-tools` to add `Bash(${CLAUDE_PLUGIN_ROOT}/lib/skill-events.sh:*)`.

## Execution Context

**Task Number**: 009-impl of 15
**Phase**: Emission Point (Green)
**Prerequisites**: 009-test exists and fails.

## BDD Scenario

Same six scenarios as 009-test. The Green pair satisfies all §4 + §6 scenarios.

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §4 (all), §6 (all).

## Files to Modify/Create

- Modify: `superpowers/skills/systematic-debugging/SKILL.md`:
  - **Phase 4 terminal step ("Verify Fix" success branch)**: add the emission prose + bash invocation block.
  - **YAML frontmatter `allowed-tools` array (line 6 — between the `---` fences at lines 1 and 7)**: append `"Bash(${CLAUDE_PLUGIN_ROOT}/lib/skill-events.sh:*)"`. The existing `Bash(${CLAUDE_PLUGIN_ROOT}/lib/bail-log.sh:*)` entry stays as-is — both are needed.
  - **Confirm no emission on Phase 4 failure branch** (Phase 4 step 4 "If Fix Doesn't Work") or architecture-questioning branch (≥3 failed cycles).
  - **Bail-out top-of-skill section**: leave unchanged (the bail-out emits via `bail-log.sh`, not `skill-events.sh` — explicit prohibition in `best-practices.md` §"Do not duplicate the bail-out event").

## Steps

### Step 1: Confirm Red
- Run `python3 -m unittest tests.test_systematic_debugging_phase4_emission -v`. Confirm failure.

### Step 2: Read state_read pattern from loop.sh
- Open `superpowers/lib/loop.sh`. Find `_loop_log_plan_completion_if_executing` and the `state_read` helper it uses to fetch `skill_name`.
- The Phase 4 emission must use the same pattern — either by sourcing the same helper or by replicating the read idiom in the SKILL.md emission bash.
- **PROHIBITED**: do not hardcode the literal string `"systematic-debugging"` as the helper's `$1` argument. The architecture explicitly forbids this (§"Do not hardcode skill_name").

### Step 3: Add Phase 4 emission to SKILL.md
- Locate the end of Phase 4 step 3 ("Verify Fix" success branch). The exact line is decided by the implementer based on the current SKILL.md structure; the emission lands at the point where the success outcome is confirmed but before the skill hands control back.
- Insert prose describing the emission step (one short paragraph) followed by a concrete bash block:
  ```
  # Read skill_name from session state (same pattern as _loop_log_plan_completion_if_executing)
  skill_name=$(state_read skill_name 2>/dev/null || true)
  if [[ -z "$skill_name" ]]; then
    # Silent skip per BDD spec §4.3
    :
  else
    # Dedup check — last 200 lines of skill-events.jsonl for matching (skill, event, args_hash)
    repo=$(superpowers/lib/utils.sh::repo_root 2>/dev/null || true)
    log="$repo/docs/retros/skill-events.jsonl"
    args_hash=$(printf '%s' "$ROOT_CAUSE|$REGRESSION_TEST_PATH" | shasum 2>/dev/null | cut -c1-12 || echo "")
    if [[ -n "$args_hash" ]] && \
       source "${CLAUDE_PLUGIN_ROOT}/lib/retro-events.sh" && \
       dedup_check "$log" "\"args_hash\":\"$args_hash\""; then
      # Already emitted in this session — skip
      :
    else
      bash "${CLAUDE_PLUGIN_ROOT}/lib/skill-events.sh" \
        "$skill_name" fix_completed \
        '{root_cause: $rc, regression_test_path: $rt, investigation_phase_count: $count}' \
        --arg rc "$ROOT_CAUSE" \
        --arg rt "$REGRESSION_TEST_PATH" \
        --argjson count "$PHASE_COUNT"
    fi
  fi
  ```
  (The exact shape is the implementer's call; the contract is "skill_name from state, dedup, payload carries root_cause + regression_test_path + investigation_phase_count, no test stdout/stderr/diff".)
- **PROHIBITED**: do not add a `fix_abandoned` event (§4.4 explicitly out of scope). Do not emit on the bail-out branch (`best-practices.md` prohibition). Do not include test stdout, stderr, or fix diff text in the payload (`best-practices.md` §"No transcript content").

### Step 4: Update `allowed-tools`
- Add `Bash(${CLAUDE_PLUGIN_ROOT}/lib/skill-events.sh:*)` to the SKILL.md frontmatter.
- Keep all existing entries unchanged.

### Step 5: Verify Test Passes (Green)
- Run `python3 -m unittest tests.test_systematic_debugging_phase4_emission -v`. MUST PASS.
- Run the full suite: `python3 -m unittest discover -s tests -v`. No regressions.
- Plugin validator: `python3 plugin-optimizer/scripts/validate-plugin.py superpowers` MUST PASS.

### Step 6: Refactor & Lint
- Review the SKILL.md prose for consistency with the surrounding Phase 4 voice. Match imperative style, no emojis, no AI-slop comments.
- If the emission bash block grew too large, consider moving the dedup logic into a helper function in `retro-events.sh` (only if it's already needed by another caller — otherwise inline it).

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
python3 -m unittest tests.test_systematic_debugging_phase4_emission -v
python3 -m unittest discover -s tests -v

cd /Users/FradSer/Developer/FradSer/dotclaude
python3 plugin-optimizer/scripts/validate-plugin.py superpowers
```

## Success Criteria

- `systematic-debugging/SKILL.md` Phase 4 terminal step calls `log_skill_event` (via the bash invocation form).
- `skill_name` is read from the session state file, not hardcoded.
- Dedup tail-200 scan is in place (§6.1).
- No emission on bail-out branch (§4.2) or architecture-questioning branch (§4.4).
- `allowed-tools` frontmatter includes `Bash(${CLAUDE_PLUGIN_ROOT}/lib/skill-events.sh:*)`.
- All six §4 + §6 BDD scenarios pass.
- Full suite green.
- Plugin validator passes.
