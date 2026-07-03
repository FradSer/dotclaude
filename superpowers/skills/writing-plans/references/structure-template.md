# Plan Structure Template

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

> **For Claude:** REQUIRED SUB-SKILL: Load `superpowers:executing-plans` skill using the Skill tool to implement this plan task-by-task.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

**Design Support:**
<!-- Template: replace YYYY-MM-DD-<topic>-design with actual folder name -->
- [BDD Specs](../YYYY-MM-DD-<topic>-design/bdd-specs.md)
- [Architecture](../YYYY-MM-DD-<topic>-design/architecture.md)

## Context

[Why this work is needed — motivation, constraints, prior incidents, or stakeholder requirement.]

<!-- Include a current-state vs target-state comparison when there is existing code being changed. Omit for greenfield work. -->
| Aspect | Current State | Target State |
|--------|--------------|--------------|
| [Dimension] | [As-is] | [To-be] |

## Global Constraints

Cross-task invariants every batch and every task must respect. These shared guardrails make parallel batches safe — list them here so a downstream task or parallel batch cannot silently violate one. One invariant per bullet, no prose. Omit the section only when the design carries zero cross-cutting constraints (rare).

- **Performance**: [e.g., p99 latency < 200ms on the auth hot path; no new blocking I/O in request handlers]
- **Security**: [e.g., all new endpoints require auth; no raw SQL interpolation; secrets via env only]
- **Compatibility**: [e.g., must run on Node 18+; preserve existing CLI flag names]
- **Forbidden**: [e.g., no new lodash imports; no `any` casts; no `console.log` in production code]

## Execution Plan

<!-- Inline task metadata for efficient execution by executing-plans skill -->
<!-- Format: YAML for easy parsing -->
<!-- slug: lowercase hyphenated version of subject, used for filename derivation -->
```yaml
tasks:
  - id: "001"
    subject: "Setup project structure"
    slug: "setup-project-structure"
    type: "setup"
    depends-on: []
  - id: "002"
    subject: "Create base authentication handler"
    slug: "create-base-auth-handler"
    type: "impl"
    depends-on: ["001"]
  - id: "003"
    subject: "Implement login test"
    slug: "implement-login-test"
    type: "test"
    depends-on: ["002"]
  - id: "004"
    subject: "Implement login handler"
    slug: "implement-login-handler"
    type: "impl"
    depends-on: ["003"]
```

**Task File References (for detailed BDD scenarios):**
- [Task 001: Setup project structure](./task-001-setup-project-structure.md)
- [Task 002: Create base authentication handler](./task-002-create-base-auth-handler.md)
- [Task 003: Implement login test](./task-003-implement-login-test.md)
- [Task 004: Implement login handler](./task-004-implement-login-handler.md)

## BDD Coverage

All BDD scenarios from the design are covered by these tasks. See individual task files for scenario mapping.

## Dependency Chain

```
task-001 (setup)
    │
    ├─→ task-002 (feature-a)
    │       └─→ task-004 (integration)
    │
    └─→ task-003 (feature-b)
            └─→ task-004 (integration)
```

**Analysis**:
- No circular dependencies
- Logical dependency flow: foundation → features → integration
- Parallel paths where independence allows (e.g., task-002/003 can proceed after task-001)

---

## Execution Handoff

**"Plan complete and saved to `docs/plans/YYYY-MM-DD-<topic>-plan/`. Load `superpowers:executing-plans` skill using the Skill tool — it orchestrates per-batch sub-agent coordinators through the full Phase 1-6 pipeline."**
```

**CRITICAL**: The Execution Plan section with task file references is MANDATORY in `_index.md`

### 2. Task Files - MANDATORY: One task per file

**File Naming Pattern**: `task-<NNN>-<feature>-<type>.md`

Example: `task-001-setup.md`, `task-002-auth-test.md`, `task-002-auth-impl.md`

- `<NNN>`: Sequential number (001, 002, ...)
- `<feature>`: Feature identifier (e.g., auth-handler, user-profile)
- `<type>`: Type (test, impl, config, refactor)
- **Test and implementation tasks for the same feature share the same NN prefix**

**Task File Template**:

```markdown
# Task <NNN>: [Task Title]

**depends-on**: task-<NNN-1>, task-<NNN-2>  <!-- TRUE technical prerequisites only; omit if independent -->

## Description

[What needs to be done - describe what, not how]

## Execution Context

**Task Number**: <NNN> of <TOTAL>
**Phase**: [Setup | Foundation | Core Features | Integration | Refinement | Testing | Documentation]
**Prerequisites**: [Conditions that must be met before starting this task]

## BDD Scenario

```gherkin
Scenario: [concise scenario title]
  Given [context or precondition]
  When [action or event occurs]
  Then [expected outcome]
  And [additional conditions or outcomes]
```

**Spec Source**: `../YYYY-MM-DD-<topic>-design/bdd-specs.md` (for reference)

## Interfaces

Contracts this task exposes or consumes. Tasks linked via `depends-on` connect through these blocks — a downstream task's consumed interface must match an upstream task's exposed interface. This makes parallel-batch interface compatibility verifiable before merge. Signatures only, no implementation bodies (the "describe what, not how" rule still holds).

**Exposes** (interfaces this task produces):
- `def validate_credentials(username: str, password: str) -> bool: ...`
- `class AuthError(Exception): ...`

**Consumes** (interfaces from `depends-on` tasks this task relies on):
- `get_user_by_email(email: str) -> User | None` (from task-002)

**Global Constraints respected**: [name the constraint(s) from `_index.md` ## Global Constraints this task is bound by, e.g., "no raw SQL interpolation — uses the shared prepared-statement helper"]

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
- **PROHIBITED**: Do not generate implementation bodies in task files — no function logic, no algorithm code
- **MANDATORY**: Each task file includes a `## Interfaces` section declaring exposed/consumed contracts (signatures only)
- **ALLOWED**: Interface signatures, type definitions, and function signatures that define the contract (e.g., `async function maybeSpawnTeammate(params: {...}): Promise<Result>`) — placed in the `## Interfaces` block
- Describe **what** to implement, not **how**
- Focus on actions: "Create a function that X", "Modify Y to do Z"
- One task = One file
- **Right-sizing**: Fold setup/config/docs into the single feature task that consumes them; a standalone setup task is justified only when 2+ downstream tasks share its output