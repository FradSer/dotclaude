# Task 006: Memory scan + rebuild — impl (GREEN)

**depends-on**: task-005, task-004 (file-conflict guard: both task-004 and this task edit `superpowers/lib/docs-index.sh`; serialized to avoid a concurrent-write race if scheduled in the same batch — see plan reflection File Conflict Review)

## Description

Add a new loop to `scan_folders()` that globs `docs/memory/*.md` (plain, non-recursive — this is what makes `docs/memory/archive/` invisible with zero extra logic) and emits one `"<path>\t<kind>\t<default_status>"` row per file with `kind=memory`, `default_status=active`. Additionally extract the file's own `summary:` frontmatter line so a first-time `rebuild` doesn't seed a blank summary (unlike design/plan folders, which have no internal summary to read).

## Execution Context

**Task Number**: 006 of 020
**Phase**: Foundation
**Prerequisites**: task-005's tests exist and FAIL; task-004 merged (avoids a concurrent-write race on the shared `docs-index.sh` file)

## BDD Scenario

```gherkin
Scenario: An expired memory row's file is archived and dropped from the index
  And a subsequent `rebuild` does NOT re-add a row for the archived file
    (its non-recursive `docs/memory/*.md` glob does not descend into `archive/`)
```

**Spec Source**: `../2026-07-04-superpowers-memory-layer-design/bdd-specs.md` Scenario 15; `architecture.md` §2

## Interfaces

**Exposes** (modified function in `lib/docs-index.sh`):
- `scan_folders(root: str) -> stream of "<path>\t<kind>\t<status>"` — gains a fourth loop (after the existing design/plan/retro loops, before the `docs/writing-skills/` seed line):
  ```
  for f in "${root}/docs/memory/"*.md; do
    [[ -f "$f" ]] || continue
    printf '%s\t%s\t%s\n' "${f#${root}/}" "memory" "active"
  done
  ```

**Note on summary extraction**: `scan_folders()` itself only ever emitted 3 tab-fields (`path\tkind\tstatus`) — summary is populated downstream in `cmd_rebuild()`'s merge step from `existing_status_map` (prior index state), which already defaults to blank for a never-before-seen path. To satisfy task-005's `test_rebuild_extracts_summary_from_memory_frontmatter`, extend `cmd_rebuild()`'s merge loop: when `final_summary` would otherwise be blank AND `k == "memory"`, extract the file's own `summary:` frontmatter line via `grep -m1 '^summary:' "${root}/${p}" | sed 's/^summary: *//'` and use that as `final_summary` instead of the empty string. This is the one piece of behavior genuinely new to `cmd_rebuild()` in this task — everything else is the `scan_folders()` loop addition.

**Consumes**: none new

**Global Constraints respected**: non-recursive glob (no `**`), so `docs/memory/archive/` is structurally excluded; no `jq` — frontmatter extraction via `grep`/`sed` only.

## Files to Modify/Create

- Modify: `superpowers/lib/docs-index.sh:502-524` (`scan_folders()` — add the new loop)
- Modify: `superpowers/lib/docs-index.sh:696-726` (`cmd_rebuild()`'s merge loop — add the frontmatter-summary-extraction fallback for `kind=memory` rows with a blank existing summary)

## Steps

### Step 1: Verify Scenario
- Re-confirm Scenario 15's rebuild-does-not-resurrect clause against current (pre-edit) behavior.

### Step 2: Implement Logic (Green)
- Add the `scan_folders()` loop exactly as specified.
- Add the `cmd_rebuild()` merge-loop fallback exactly as specified.

### Step 3: Verify & Refactor
- Run the full suite through task-005.
- Manually verify with a throwaway tmp repo: `mkdir -p docs/memory && printf -- '---\nname: x\ncategory: pitfall\nsummary: hello world\n---\n' > docs/memory/pitfall_x.md && bash lib/docs-index.sh rebuild` produces a row with `summary` = `hello world`.

## Verification Commands

```bash
bash superpowers/tests/run-docs-index-tests.sh
bash superpowers/tests/test-skill-touchpoints.sh
```

## Success Criteria

- All 4 task-005 tests PASS
- Zero regressions among pre-existing tests
- A memory file's `summary:` frontmatter value survives a first-time `rebuild`
