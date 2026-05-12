# Task 011: Update `allowed-tools` Frontmatter in Both SKILL.md Files

**depends-on**: task-006-migrate-phase5c-impl, task-007-migrate-phase4-items-impl, task-008-migrate-phase6-closure-impl, task-009-systematic-debugging-emission-impl, task-010-phase1-reader-impl

## Description

Add the three new helper script paths to the `allowed-tools` arrays of the two SKILL.md files that now invoke them. Without this, the strict tool allowlist would block the new `bash "${CLAUDE_PLUGIN_ROOT}/lib/<helper>.sh"` invocations at runtime, leaving every migrated emission point silently disabled.

This is a config-only task — no test/impl split. The "verification" is grep + pytest of the existing suite (which exercises the `allowed-tools` field via the plugin validator).

## Execution Context

**Task Number**: 011 of 21
**Phase**: Config & docs
**Prerequisites**: All migration tasks landed.

## BDD Scenario

Not a BDD scenario per se — this is the **operational gate** that makes every prior task's emission actually reachable. The plugin validator and the existing test in `superpowers/tests/test_phase_integration.py` (or its successor) will verify the `allowed-tools` array contents.

## Files to Modify/Create

- Modify: `superpowers/skills/retrospective/SKILL.md` frontmatter `allowed-tools` array.
- Modify: `superpowers/skills/systematic-debugging/SKILL.md` frontmatter `allowed-tools` array.

## Steps

### Step 1: Add Two Entries to retrospective/SKILL.md
- Open the YAML frontmatter at the top.
- Locate the `allowed-tools` array.
- Append:
  - `Bash(${CLAUDE_PLUGIN_ROOT}/lib/observations.sh:*)`
  - `Bash(${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh:*)`

### Step 2: Add One Entry to systematic-debugging/SKILL.md
- Open the YAML frontmatter (visible at line 6 from earlier inspection: it already lists `Bash(${CLAUDE_PLUGIN_ROOT}/lib/bail-log.sh:*)`).
- Append:
  - `Bash(${CLAUDE_PLUGIN_ROOT}/lib/skill-events.sh:*)`

### Step 3: Do NOT Add `retro-events.sh`
- Per architecture.md §"`allowed-tools` field updates": `retro-events.sh` is not directly invocable by skills (it is sourced by the wrappers; skills only ever call the wrappers). Adding it would loosen the allowlist unnecessarily.

### Step 4: Do NOT Use Bare `Bash`
- Per `feedback_*` memory: bare `Bash` in `allowed-tools` defeats the strict allowlist. Each entry MUST be the explicit form `Bash(${CLAUDE_PLUGIN_ROOT}/lib/<helper>.sh:*)`.

### Step 5: Run Plugin Validator
- Run `python3 plugin-optimizer/scripts/validate-plugin.py superpowers --check=frontmatter` (the manifest/frontmatter check exercises the YAML).
- Expect: exit 0.

### Step 6: Run Full Test Suite
- All previous tasks' tests + the existing suite still green.

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude
python3 plugin-optimizer/scripts/validate-plugin.py superpowers --check=frontmatter -v 2>&1 | tail -20
python3 -m pytest superpowers/tests/ -q 2>&1 | tail -10
# Confirm the new entries are present:
grep -nE "lib/(observations|evolution-log|skill-events)\.sh:\*" superpowers/skills/retrospective/SKILL.md superpowers/skills/systematic-debugging/SKILL.md
# Expect: 3 lines (two for retrospective, one for systematic-debugging)
```

## Success Criteria

- `allowed-tools` in `retrospective/SKILL.md` contains both `observations.sh` and `evolution-log.sh` entries.
- `allowed-tools` in `systematic-debugging/SKILL.md` contains the `skill-events.sh` entry.
- `retro-events.sh` is NOT in any `allowed-tools` array.
- No bare `Bash` entry exists in either array.
- Plugin validator exits 0.
- Full test suite remains green.
