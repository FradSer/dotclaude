# Harness Optimizations Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Load `superpowers:executing-plans` skill using the Skill tool to implement this plan task-by-task.

**Goal:** Add an independent Evaluator agent and supporting infrastructure (sprint contracts, graded rubrics, handoff documentation, intensity presets, file-based communication) to the superpowers executing-plans workflow, with all optimizations as additive opt-in layers.

**Architecture:** Layered integration on top of existing Phase 1-6 structure. The Evaluator is a sub-agent (not teammate) with restricted tools, spawned after batch completion. All evaluator-generator communication flows through structured files in the plan directory. Configuration follows a 3-tier precedence: skill argument > plan metadata > plugin defaults.

**Tech Stack:** Markdown agent definitions, YAML configuration, Bash validation scripts

**Design Support:**
- [Requirements Document](../2026-03-31-harness-optimizations-design/harness-optimizations-requirements.md)

## Context

The current executing-plans workflow relies on self-evaluation in Phase 4 (binary pass/fail via exit codes). Anthropic's "Harness Design for Long-Running Apps" research shows that self-evaluation bias causes agents to grade themselves too generously. This plan introduces an architecturally separate Evaluator agent with graded scoring, sprint contracts, and file-based communication to close this quality gap -- all as opt-in layers that preserve backwards compatibility.

| Aspect | Current State | Target State |
|--------|--------------|--------------|
| Evaluation | Self-evaluation in Phase 4 (binary pass/fail) | Independent Evaluator sub-agent + graded 1-5 scoring |
| Quality Gate | Exit code 0 = pass | Exit code gate (baseline) + evaluator rubric assessment (additional) |
| Sprint Contract | None (implicit criteria in task YAML) | Explicit per-batch contract file negotiated by Evaluator |
| Agent Directory | No `agents/` directory in superpowers | `agents/evaluator.md` with restricted tools |
| Handoff Docs | None | Structured handoff summaries for 16+ task plans |
| Evaluation Intensity | Fixed (always same) | 3 manual presets: thorough / standard / light |
| Agent Communication | Through conversation context | File-based: evaluation reports, contracts, handoffs |
| Historical Design Files | Two design directories exist | Single requirements doc, historical dir deleted |

## Execution Plan

```yaml
tasks:
  - id: "001"
    subject: "Delete historical design directory"
    slug: "cleanup"
    type: "cleanup"
    depends-on: []
  - id: "002"
    subject: "Create evaluation file formats reference"
    slug: "file-formats-impl"
    type: "impl"
    depends-on: []
  - id: "003"
    subject: "Create handoff template reference"
    slug: "handoff-template-impl"
    type: "impl"
    depends-on: []
  - id: "004"
    subject: "Create evaluator agent definition"
    slug: "evaluator-agent-impl"
    type: "impl"
    depends-on: ["002"]
  - id: "005"
    subject: "Create evaluation rubrics reference"
    slug: "evaluation-rubrics-impl"
    type: "impl"
    depends-on: ["002"]
  - id: "006"
    subject: "Create sprint contract template reference"
    slug: "sprint-contract-impl"
    type: "impl"
    depends-on: ["002"]
  - id: "007"
    subject: "Update executing-plans SKILL.md with evaluator integration"
    slug: "skill-update-refactor"
    type: "refactor"
    depends-on: ["002", "004", "005", "006"]
  - id: "008"
    subject: "Update batch-execution-playbook with evaluation mode"
    slug: "playbook-update-refactor"
    type: "refactor"
    depends-on: ["004"]
  - id: "009"
    subject: "Update blocker-and-escalation with evaluator triggers"
    slug: "escalation-update-refactor"
    type: "refactor"
    depends-on: ["004"]
  - id: "010"
    subject: "Register evaluator agent and validate plugin"
    slug: "plugin-registration-config"
    type: "config"
    depends-on: ["004", "007", "008", "009"]
```

**Task File References (for detailed BDD scenarios):**
- [Task 001: Delete historical design directory](./task-001-cleanup.md)
- [Task 002: Create evaluation file formats reference](./task-002-file-formats-impl.md)
- [Task 003: Create handoff template reference](./task-003-handoff-template-impl.md)
- [Task 004: Create evaluator agent definition](./task-004-evaluator-agent-impl.md)
- [Task 005: Create evaluation rubrics reference](./task-005-evaluation-rubrics-impl.md)
- [Task 006: Create sprint contract template reference](./task-006-sprint-contract-impl.md)
- [Task 007: Update executing-plans SKILL.md](./task-007-skill-update-refactor.md)
- [Task 008: Update batch-execution-playbook](./task-008-playbook-update-refactor.md)
- [Task 009: Update blocker-and-escalation](./task-009-escalation-update-refactor.md)
- [Task 010: Register evaluator and validate plugin](./task-010-plugin-registration-config.md)

## BDD Coverage

All BDD scenarios are derived from the 6 requirements (REQ-001 through REQ-006) in the requirements document. Each task file contains self-contained Gherkin scenarios mapped to specific success criteria from the requirements.

| Requirement | Task(s) | Scenarios |
|-------------|---------|-----------|
| REQ-006: File-Based Communication | 002 | 3 scenarios (contract format, report format, handoff format) |
| REQ-001: Independent Evaluator | 004 | 3 scenarios (separation, restricted tools, calibration) |
| REQ-003: Graded Criteria | 005 | 3 scenarios (dimensions, type weighting, pivot flag) |
| REQ-002: Sprint Contract | 006 | 3 scenarios (pre-execution contract, Red-Green distinction, ambiguity) |
| REQ-004: Handoff Documentation | 003 | 2 scenarios (boundary production, scope limitation) |
| REQ-005: Intensity Configuration | 007 | 2 scenarios (presets, auto mode) |
| Integration | 007, 008, 009, 010 | 6 scenarios across files |

## Dependency Chain

```
Tier 0 (Batch 1)       Tier 1 (Batch 2)      Tier 2 (Batch 3)        Tier 3 (Batch 4)
================       ================      ================        ================
                            +-> 004 --+---> 007 ---+
  001                  /    |         |             |
  002 ----------------+---> 005 -----+   008 ------+---> 010
  003                  \    |              |        |
                        +-> 006 -----+    009 -----+
```

**Analysis:**
- No circular dependencies
- Logical flow: cleanup + foundations (Tier 0) -> core features (Tier 1) -> integration (Tier 2) -> finalization (Tier 3)
- Parallel paths within each tier: 001/002/003 independent; 004/005/006 independent; 008/009 independent
- Task 007 is the convergence point (depends on 002, 004, 005, 006)

---

## Execution Handoff

Plan complete and saved to `docs/plans/2026-04-01-harness-optimizations-plan/`. Execution options:

**1. Orchestrated Execution (Recommended)** - Load `superpowers:executing-plans` skill using the Skill tool.

**2. Direct Agent Team** - Load `superpowers:agent-team-driven-development` skill using the Skill tool.

**3. BDD-Focused Execution** - Load `superpowers:behavior-driven-development` skill using the Skill tool for specific scenarios.
