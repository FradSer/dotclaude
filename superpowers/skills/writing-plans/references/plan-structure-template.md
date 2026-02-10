# Writing Plans Details (1/2)

# Detailed Guidance

This file preserves the previously detailed SKILL.md guidance for deeper reference.

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. BDD. Frequent commits.
For unit-test tasks, explicitly require test doubles to isolate external dependencies (databases, networks, third-party services).

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** This should be run in a dedicated worktree (created by brainstorming skill).

**Save plans to folder:** `docs/plans/YYYY-MM-DD-<feature-name>-plan/`

## Folder Structure

The plan must be split into multiple files:

### 1. `_index.md` (Plan Overview)

```markdown
# [Feature Name] Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use Skill tool load `superpowers:executing-plans` skill to implement this plan task-by-task.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

**Design Support:**
- [BDD Specs](../YYYY-MM-DD-<topic>-design/bdd-specs.md)
- [Architecture](../YYYY-MM-DD-<topic>-design/architecture.md)

**Execution Plan:**
- [Phase 1: Setup](tasks-phase1-setup.md)
- [Phase 2: Core Logic](tasks-phase2-core.md)
- ...

---

## Execution Handoff

**"Plan complete and saved to `docs/plans/YYYY-MM-DD-<topic>-plan/`. Execution options:**

**1. Orchestrated Execution (Recommended)** - Use Skill tool load `superpowers:executing-plans` skill.

**2. Direct Agent Team** - Use Skill tool load `superpowers:agent-team-driven-development` skill.

**3. BDD-Focused Execution** - Use Skill tool load `superpowers:behavior-driven-development` skill for specific scenarios.
```

### 2. Task Files (e.g., `tasks-phase1.md`)

```markdown
# Phase 1 Execution Tasks

## Task Structure

### Task N: [Scenario Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`
- Spec: `docs/plans/.../bdd-specs.md` (Scenario: [Scenario Name])

**Step 1: Verify Scenario**
- Ensure `[Scenario Name]` exists in `bdd-specs.md`.

**Step 2: Implement Test Case**

- File: `tests/exact/path/to/test.py`
- Action: Create/Update test function `test_scenario_name`
- Logic:
  - **Given**: Initialize [State/Context]
  - **When**: Trigger [Action]
  - **Then**: Assert [Expected Result]

**Step 3: Run test (Red)**

Run: `pytest tests/path/test.py::test_scenario_name -v`
Expected: FAIL

**Step 4: Implement Logic (Green)**

- File: `exact/path/to/file.py`
- Action: Implement method/function to satisfy the test
- Details: [Brief description of logic if needed]

**Step 5: Verify & Refactor**

Run: `pytest tests/path/test.py::test_scenario_name -v`
Expected: PASS
```
