# Task 012: Discharge T-002 + Update README + Bump Version

**depends-on**: task-011-allowed-tools-config

## Description

Land the documentation closure for this PR:

1. Append a one-line entry under `superpowers/TODO-v3.md` T-002 marking it discharged with a link to this design folder.
2. Update `superpowers/skills/retrospective/references/` to reflect the new write path (file + line citations only — no schema duplication; the helper script comments are the source of truth).
3. Update `superpowers/README.md` "Harness Calibration" section to mention the new `skill-events.jsonl` `channel` alongside the existing four.
4. Bump `superpowers/.claude-plugin/plugin.json` and the marketplace entry to `v2.9.0` (per `_index.md:5` "Target version: superpowers v2.9.0").

This is the final task before commit. After this, the plan is implementation-complete.

## Execution Context

**Task Number**: 012 of 21
**Phase**: Config & docs
**Prerequisites**: All 011 prior tasks landed.

## BDD Scenario

This task does not directly verify a BDD scenario — it documents the design's discharge of T-002 and the operational visibility of the new channel.

## Files to Modify/Create

- Modify: `superpowers/TODO-v3.md` (T-002 entry).
- Modify: `superpowers/skills/retrospective/references/evolution-protocol.md` and any sibling reference file that mentions the inline `jq -nc` pattern.
- Modify: `superpowers/README.md` "Harness Calibration" section.
- Modify: `superpowers/.claude-plugin/plugin.json` `version` field.
- Modify: `.claude-plugin/marketplace.json` superpowers entry's `version` field.

## Steps

### Step 1: Discharge T-002 in TODO-v3.md
- Open `superpowers/TODO-v3.md`; locate the T-002 entry.
- Append a discharge line at the end of the T-002 block:
  ```
  **Discharged**: 2026-05-12 by `docs/plans/2026-05-12-unified-retro-events-plan/`
  (introduces `lib/retro-events.sh` shared core + three wrapper helpers
  `lib/observations.sh`, `lib/evolution-log.sh`, `lib/skill-events.sh`;
  migrates two manual-write channels and adds one new emission point in
  `systematic-debugging` Phase 4).
  ```

### Step 2: Update retrospective references
- Open `superpowers/skills/retrospective/references/evolution-protocol.md`.
- Locate any prose describing the manual `jq -nc ... >> docs/retros/evolution-log.jsonl` inline pattern.
- Replace with file + line citations pointing at `lib/evolution-log.sh::log_evolution_event` (with the line range where the function is defined). Do NOT duplicate the schema — the helper's comment block is the source of truth.
- Same for any reference to the harness-observations inline pattern → point at `lib/observations.sh::log_harness_observation`.

### Step 3: Update README "Harness Calibration" Section
- Open `superpowers/README.md`; locate the "Harness Calibration" section.
- Update the list of `channel`s under `docs/retros/` to include the new fifth entry:
  - `plans-completed.jsonl` — plan completions (existing)
  - `bail-out-events.jsonl` — skill bail-outs (existing)
  - `harness-observations.jsonl` — refusal-gate observations (existing; now written via `lib/observations.sh`)
  - `evolution-log.jsonl` — proposals + retrospective_run (existing; now written via `lib/evolution-log.sh`)
  - `skill-events.jsonl` — skill activity events; currently populated by `systematic-debugging` Phase 4 with `fix_completed` rows (new in v2.9.0)

### Step 4: Bump Version to v2.9.0
- Edit `superpowers/.claude-plugin/plugin.json`: change `"version"` to `"2.9.0"`.
- Edit `.claude-plugin/marketplace.json`: locate the superpowers entry; change its `"version"` to `"2.9.0"`.
- Both files MUST be in sync (per `CLAUDE.md` "Plugin versions in individual `plugin.json` files are authoritative. Keep `.claude-plugin/marketplace.json` entries in sync").

### Step 5: Run Plugin Optimizer + README Updater
- Run `python3 plugin-optimizer/scripts/validate-plugin.py superpowers -v 2>&1 | tail -30` — expect exit 0.
- Run `/utils:update-readme` to refresh root `README.md` / `README.zh-CN.md` plugin listings (per `CLAUDE.md` "Version sync … run `/utils:update-readme` whenever you add, remove, or rename a plugin"). This task does not add/remove a plugin, but the version bump warrants the same regeneration — confirm by reading the README's superpowers entry contains `v2.9.0` after the run.

### Step 6: Final Full-Suite Sanity Check
- Run the entire test suite (`python3 -m pytest superpowers/tests/ -q`); expect green.
- Run `shellcheck superpowers/lib/*.sh`; expect zero output beyond `SC1091` lines.

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude
grep -n "Discharged" superpowers/TODO-v3.md | grep -i T-002
grep -nE "\"version\"\s*:\s*\"2\.9\.0\"" superpowers/.claude-plugin/plugin.json .claude-plugin/marketplace.json
python3 plugin-optimizer/scripts/validate-plugin.py superpowers -v 2>&1 | tail -20
python3 -m pytest superpowers/tests/ -q 2>&1 | tail -10
```

## Success Criteria

- T-002 has a "Discharged" line pointing at this plan folder.
- Both `plugin.json` and `marketplace.json` show `2.9.0`.
- README "Harness Calibration" lists the five channels.
- Retrospective references no longer describe inline `jq -nc` for the two migrated channels.
- Plugin optimizer + full test suite both pass.
