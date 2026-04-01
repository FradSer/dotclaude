# Task 001: Delete historical design directory

**depends-on**: (none)

## Description

Delete the superseded design directory `docs/plans/2026-03-31-superpowers-harness-optimizations-design/` which contains `best-practices.md` and `bdd-specs.md`. These files have been reconciled into the authoritative requirements document at `docs/plans/2026-03-31-harness-optimizations-design/harness-optimizations-requirements.md`. The historical BDD specs contain conflicts with the final requirements (model auto-detection assumed, context reset assumed), making them misleading if kept alongside the requirements.

## Execution Context

**Task Number**: 001 of 10
**Phase**: Cleanup
**Prerequisites**: None

## BDD Scenario

```gherkin
Scenario: Historical design directory removed
  Given the directory docs/plans/2026-03-31-superpowers-harness-optimizations-design/ exists
  And it contains best-practices.md and bdd-specs.md
  When the cleanup task is executed
  Then the directory and all its contents are deleted
  And only docs/plans/2026-03-31-harness-optimizations-design/ remains as the design source
```

**Spec Source**: `../2026-03-31-harness-optimizations-design/harness-optimizations-requirements.md` (Section 1, overall consolidation rationale)

## Files to Modify/Create

- Delete: `docs/plans/2026-03-31-superpowers-harness-optimizations-design/best-practices.md`
- Delete: `docs/plans/2026-03-31-superpowers-harness-optimizations-design/bdd-specs.md`
- Delete: `docs/plans/2026-03-31-superpowers-harness-optimizations-design/` (directory)

## Steps

### Step 1: Verify directory exists
- Confirm `docs/plans/2026-03-31-superpowers-harness-optimizations-design/` exists with expected files

### Step 2: Delete directory
- Remove the entire directory and its contents
- Use `git rm -r` to stage the deletion for git tracking

### Step 3: Verify deletion
- Confirm the directory no longer exists
- Confirm `docs/plans/2026-03-31-harness-optimizations-design/` still exists and is untouched

## Verification Commands

```bash
# Verify deleted
test ! -d docs/plans/2026-03-31-superpowers-harness-optimizations-design/ && echo "PASS: historical dir deleted"

# Verify requirements still exist
test -f docs/plans/2026-03-31-harness-optimizations-design/harness-optimizations-requirements.md && echo "PASS: requirements intact"
```

## Success Criteria

- Historical design directory fully removed
- Requirements document at `2026-03-31-harness-optimizations-design/` untouched
- Deletion staged for git
