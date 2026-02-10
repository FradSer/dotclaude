# Writing Plans Details (1/2)

# Detailed Guidance

This file preserves the previously detailed SKILL.md guidance for deeper reference.

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. BDD. Frequent commits.
For unit-test tasks, explicitly require test doubles to isolate external dependencies (databases, networks, third-party services).

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** This should be run in a dedicated worktree (created by brainstorming skill).

**Save plans to folder:** `docs/plans/YYYY-MM-DD-<feature-name>-plan/`

## Folder Structure

The plan must be split into multiple files: **ONE TASK PER FILE**

### 1. `_index.md` (Plan Overview) - MANDATORY

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
- [Task 001: Setup project structure](./task-001-setup-project-structure.md)
- [Task 002: Create base authentication handler](./task-002-create-base-auth-handler.md)
- [Task 003: Implement login test](./task-003-implement-login-test.md)
- ...

---

## Execution Handoff

**"Plan complete and saved to `docs/plans/YYYY-MM-DD-<topic>-plan/`. Execution options:**

**1. Orchestrated Execution (Recommended)** - Use Skill tool load `superpowers:executing-plans` skill.

**2. Direct Agent Team** - Use Skill tool load `superpowers:agent-team-driven-development` skill.

**3. BDD-Focused Execution** - Use Skill tool load `superpowers:behavior-driven-development` skill for specific scenarios.
```

**CRITICAL**: The Execution Plan section with task file references is MANDATORY in `_index.md`

### 2. Task Files - MANDATORY: One task per file

**File Naming Pattern**: `task-<NNN>-<short-description>.md`

Example: `task-001-setup-project-structure.md`

**Task File Template**:

```markdown
# Task <NNN>: [Task Title]

## Description

[What needs to be done - describe what, not how]

## BDD Scenario Reference

**Spec**: `../YYYY-MM-DD-<topic>-design/bdd-specs.md`
**Scenario**: [Scenario Name]

## Files to Modify/Create

- Create: `path/to/new/file.ext`
- Modify: `path/to/existing/file.ext:line-range` (optional)

## Steps

### Step 1: Verify Scenario
- Ensure `[Scenario Name]` exists in the BDD specs

### Step 2: Implement Test (Red)
- Create test file: `tests/path/to/test_file.ext`
- Test name: `test_scenario_name`
- Test should verify the expected behavior
- **Verification**: Run test command and verify it FAILS

### Step 3: Implement Logic (Green)
- Implement the required functionality in: `src/path/to/file.ext`
- Follow the test requirements from Step 2
- **Verification**: Run test command and verify it PASSES

### Step 4: Verify & Refactor
- Run full test suite to ensure no regressions
- Refactor code if needed while keeping tests passing

## Verification Commands

```bash
# Run specific test
<test command>

# Run all tests
<test command>
```

## Success Criteria

- Test passes after implementation
- No test failures in the suite
- Code follows project conventions
```

**CRITICAL RULES FOR TASK FILES**:
- **PROHIBITED**: Do not generate actual code in task files
- Describe **what** to implement, not **how**
- Focus on actions: "Create a function that X", "Modify Y to do Z"
- One task = One file