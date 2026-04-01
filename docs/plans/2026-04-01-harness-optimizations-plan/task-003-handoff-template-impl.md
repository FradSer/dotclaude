# Task 003: Create handoff template reference

**depends-on**: (none)

## Description

Create a Level 3 reference file providing the template for handoff summary files used in long plans (16+ tasks). Handoff summaries are documentation artifacts for progress tracking -- they do NOT reset or modify Claude Code's conversation context. The template defines the structure that the orchestrator follows when producing `handoff-summary-{N}.md` files at configurable boundaries.

## Execution Context

**Task Number**: 003 of 10
**Phase**: Foundation (REQ-004)
**Prerequisites**: None

## BDD Scenario

```gherkin
Scenario: Handoff summary produced at configurable boundary
  Given a plan with 18 tasks across 5 batches
  And handoff boundary is configured to every 3 batches (default)
  When batch 3 completes
  Then a handoff-summary-1.md file is produced in the plan directory
  And it contains: completed tasks with evaluation scores, remaining tasks with dependency state, key architectural decisions, file ownership map, and accumulated blockers

Scenario: Handoff summary is documentation only
  Given handoff mode is active for a long plan
  When a handoff summary is generated
  Then it is a documentation artifact for human-readable progress tracking
  And it does NOT reset, compress, or modify Claude Code's conversation context
  And TaskList remains the authoritative source of task state
```

**Spec Source**: `../2026-03-31-harness-optimizations-design/harness-optimizations-requirements.md` (REQ-004)

## Files to Modify/Create

- Create: `superpowers/skills/executing-plans/references/handoff-template.md`

## Steps

### Step 1: Verify scenario alignment
- Read REQ-004 from requirements document
- Confirm scope limitation: documentation artifact only, no context manipulation

### Step 2: Create handoff-template.md
- Create the reference file at the specified path
- Use imperative style consistent with existing references
- Define the template structure matching the format in `evaluation-file-formats.md` (task 002 output)
- Include: when to produce handoffs (configurable boundary, default every 3 batches or every 15 tasks)
- Include: required sections (Completed Tasks, Remaining Tasks, Key Decisions, File Ownership, Blockers)
- Explicitly state the scope limitation: documentation only, not context management
- Note that handoff files follow the Handoff Summary Format from `evaluation-file-formats.md`

### Step 3: Verify structure
- Confirm template includes all required sections
- Confirm scope limitation is explicitly stated

## Verification Commands

```bash
# File exists
test -f superpowers/skills/executing-plans/references/handoff-template.md && echo "PASS: file exists"

# Contains required sections
grep -q "Completed Tasks" superpowers/skills/executing-plans/references/handoff-template.md && \
grep -q "Remaining Tasks" superpowers/skills/executing-plans/references/handoff-template.md && \
grep -q "File Ownership" superpowers/skills/executing-plans/references/handoff-template.md && \
echo "PASS: required sections present"

# Contains scope limitation
grep -qi "documentation" superpowers/skills/executing-plans/references/handoff-template.md && \
echo "PASS: scope limitation documented"
```

## Success Criteria

- File created at correct path
- Template includes all 5 required sections from REQ-004
- Configurable boundary documented (default: every 3 batches or every 15 tasks)
- Scope limitation explicitly stated: documentation artifact, not context reset
- References `evaluation-file-formats.md` for the canonical format
