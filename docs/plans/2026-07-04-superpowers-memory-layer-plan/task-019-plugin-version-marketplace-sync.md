# Task 019: Plugin version bump + marketplace.json sync

**depends-on**: task-010, task-012, task-014, task-016, task-018

## Description

Bump `superpowers`'s plugin version to reflect the completed memory-layer feature (a backward-compatible, additive extension — minor version bump per the plugin's existing `3.0.0`→`3.5.0` cadence of feature-level bumps), and sync the corresponding entry in the marketplace manifest. Surfaced by `git-agent related` as a historically high-coupling co-change (86 co-changes) whenever `lib/docs-index.sh` + the 5 skills' `SKILL.md` files change together — this repo's `CLAUDE.md` states "Plugin versions in individual `plugin.json` files are authoritative. Keep `.claude-plugin/marketplace.json` entries in sync when bumping versions."

## Execution Context

**Task Number**: 019 of 020
**Phase**: Housekeeping
**Prerequisites**: all 5 skill touchpoint pairs (009-018) merged — this task bumps the version only after the full feature set has landed, not mid-implementation.

## BDD Scenario

N/A — this task has no BDD scenario of its own (pure version/config metadata, no runtime behavior). Verification is by direct inspection of the two JSON files' `version` fields, per this repo's `CLAUDE.md` Version sync convention (not part of the design's `bdd-specs.md`, which scopes runtime behavior only).

## Interfaces

**Exposes**: none (config-value edit, no new function/CLI surface)

**Consumes**: none

**Global Constraints respected**: version sync is the two files' `version` fields matching exactly, per the repo's existing convention; no other field in either file changes.

## Files to Modify/Create

- Modify: `superpowers/.claude-plugin/plugin.json:4` — `"version": "3.5.0"` → `"version": "3.6.0"`
- Modify: `.claude-plugin/marketplace.json:93` (the `superpowers` entry's `version` field) — `"version": "3.5.0"` → `"version": "3.6.0"`

## Steps

### Step 1: Verify Scenario
- N/A (no BDD scenario for this task — confirmed above).

### Step 2: Implement Logic
- Edit both `version` fields to `3.6.0`, and no other field.

### Step 3: Verify & Refactor
- Confirm both files remain valid JSON (`python3 -m json.tool <file> >/dev/null` or equivalent) and that the two version strings match exactly.

## Verification Commands

```bash
python3 -m json.tool superpowers/.claude-plugin/plugin.json >/dev/null && echo "plugin.json valid"
python3 -m json.tool .claude-plugin/marketplace.json >/dev/null && echo "marketplace.json valid"
grep '"version"' superpowers/.claude-plugin/plugin.json
grep -A2 '"name": "superpowers"' .claude-plugin/marketplace.json | grep '"version"'
```

## Success Criteria

- Both JSON files remain syntactically valid
- Both `version` fields read `3.6.0`
- No other field in either file was touched
