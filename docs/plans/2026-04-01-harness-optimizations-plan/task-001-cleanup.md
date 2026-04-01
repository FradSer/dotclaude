# Task 001: Delete historical design directories

**depends-on**: (none)

## Description

Delete both superseded design directories: `docs/plans/2026-03-31-superpowers-harness-optimizations-design/` (best-practices.md, bdd-specs.md) and `docs/plans/2026-03-31-harness-optimizations-design/` (harness-optimizations-requirements.md). All relevant requirements have been consolidated into the task files within this plan. The historical BDD specs contained conflicts with the final requirements (model auto-detection assumed, context reset assumed).

## Execution Context

**Task Number**: 001 of 10
**Phase**: Cleanup
**Prerequisites**: None

## BDD Scenario

```gherkin
Scenario: Historical design directories removed
  Given the directories docs/plans/2026-03-31-superpowers-harness-optimizations-design/ and docs/plans/2026-03-31-harness-optimizations-design/ exist
  When the cleanup task is executed
  Then both directories and all their contents are deleted
  And requirements are self-contained in this plan's task files
```

## Files to Modify/Create

- Delete: `docs/plans/2026-03-31-superpowers-harness-optimizations-design/` (directory)
- Delete: `docs/plans/2026-03-31-harness-optimizations-design/` (directory)

## Steps

### Step 1: Delete directories
- Remove both directories and their contents
- Use `git rm -r` to stage the deletions for git tracking

### Step 2: Verify deletion
- Confirm neither directory exists

## Verification Commands

```bash
# Verify both deleted
test ! -d docs/plans/2026-03-31-superpowers-harness-optimizations-design/ && \
test ! -d docs/plans/2026-03-31-harness-optimizations-design/ && \
echo "PASS: historical dirs deleted"
```

## Success Criteria

- Both historical design directories fully removed
- Deletions staged for git
