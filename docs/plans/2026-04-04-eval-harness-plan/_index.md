# Eval Harness Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Load `superpowers:executing-plans` skill using the Skill tool to implement this plan task-by-task.

**Goal:** Replace rubric-based scoring in superpowers-evaluator with binary PASS/FAIL checklist evaluation, add intra-plan learning to executing-plans, and create a retrospective skill for cross-plan checklist evolution.

**Architecture:** Three subsystems. Subsystem A updates the evaluator agent to read versioned checklist files and produce binary results instead of 1-5 scores. Subsystem B adds recurring failure pattern detection to executing-plans Phase 4. Subsystem C introduces a new retrospective skill that analyzes failure patterns across completed plans and proposes checklist evolution with user approval.

**Tech Stack:** Markdown-based Claude Code plugin files (agent definitions, skill definitions, checklists), JSONL for evolution log, Python validation script.

**Design Support:**
- [BDD Specs](../2026-04-03-eval-harness-design/bdd-specs.md)
- [Architecture](../2026-04-03-eval-harness-design/architecture.md)
- [Best Practices](../2026-04-03-eval-harness-design/best-practices.md)

## Context

The current evaluator uses 1-5 rubric scoring across 5 dimensions (Correctness, Completeness, Code Quality, Test Coverage, Spec Compliance). This approach suffers from score drift, subjective interpretation, and unactionable feedback. The design replaces it with binary checklist evaluation that produces concrete, file-referenced PASS/FAIL results with specific rework items.

| Aspect | Current State | Target State |
|--------|--------------|--------------|
| Evaluation approach | 1-5 rubric scoring across 5 dimensions | Binary PASS/FAIL checklist per item |
| Output format | Per-task scores table (Corr/Comp/Qual/Test/Spec) | Checklist results table (Item/Check/Result/Evidence) |
| Verdict basis | Aggregate dimension scores (>=3, no ==1) | All items PASS = PASS; any FAIL = REWORK |
| Evidence quality | Score justifications (one-line per dimension) | File:line evidence per FAIL item |
| Rework guidance | Score-derived issues with severity levels | Checklist-specific rework with exact location |
| Cross-plan learning | None | Retrospective skill: failure patterns to checklist evolution |
| Intra-plan learning | None | Phase 4: recurring failure injection into sprint contracts |
| Checklist management | N/A (static rubrics) | Version-tracked files with append-only evolution log |

## Execution Plan

```yaml
tasks:
  - id: "001"
    subject: "Setup docs/retros directory structure"
    slug: "setup-retros-directory"
    type: "setup"
    depends-on: []
  - id: "002"
    subject: "Create initial design checklist"
    slug: "design-checklist"
    type: "impl"
    depends-on: ["001"]
  - id: "003"
    subject: "Create initial plan checklist"
    slug: "plan-checklist"
    type: "impl"
    depends-on: ["001"]
  - id: "004"
    subject: "Create initial code checklist"
    slug: "code-checklist"
    type: "impl"
    depends-on: ["001"]
  - id: "005"
    subject: "Update evaluator design mode to binary checklist"
    slug: "evaluator-design-mode"
    type: "impl"
    depends-on: ["002"]
  - id: "006"
    subject: "Update evaluator plan mode to binary checklist"
    slug: "evaluator-plan-mode"
    type: "impl"
    depends-on: ["003"]
  - id: "007"
    subject: "Update evaluator code mode to binary checklist"
    slug: "evaluator-code-mode"
    type: "impl"
    depends-on: ["004"]
  - id: "008"
    subject: "Update evaluator shared standards and output format"
    slug: "evaluator-shared-standards"
    type: "impl"
    depends-on: ["005", "006", "007"]
  - id: "009"
    subject: "Update evaluation file formats to checklist format"
    slug: "evaluation-file-formats"
    type: "impl"
    depends-on: ["008"]
  - id: "010"
    subject: "Update executing-plans Phase 3f spawn context"
    slug: "phase-3f-spawn-context"
    type: "impl"
    depends-on: ["009"]
  - id: "011"
    subject: "Implement executing-plans Phase 4 intra-plan learning"
    slug: "phase-4-intra-plan-learning"
    type: "impl"
    depends-on: ["010"]
  - id: "012"
    subject: "Create retrospective skill pattern analysis"
    slug: "retrospective-pattern-analysis"
    type: "impl"
    depends-on: ["002", "003", "004"]
  - id: "013"
    subject: "Add evolution proposal and checklist update logic"
    slug: "evolution-proposals"
    type: "impl"
    depends-on: ["012"]
  - id: "014"
    subject: "Remove old rubrics and update cross-references"
    slug: "remove-rubrics-update-refs"
    type: "refactor"
    depends-on: ["010"]
  - id: "015"
    subject: "Update plugin.json and validate plugin"
    slug: "plugin-json-validation"
    type: "config"
    depends-on: ["011", "013", "014"]
```

**Executor notes:**
- Tasks 005, 006, 007 all modify `superpowers/agents/superpowers-evaluator.md` (different sections). Execute with worktree isolation or serialize within a batch to avoid merge conflicts.
- Tasks 011, 014 both modify `superpowers/skills/executing-plans/SKILL.md` (different sections). Same serialization or worktree strategy applies.

**Task File References (for detailed BDD scenarios):**
- [Task 001: Setup docs/retros directory structure](./task-001-setup-retros-directory.md)
- [Task 002: Create initial design checklist](./task-002-design-checklist.md)
- [Task 003: Create initial plan checklist](./task-003-plan-checklist.md)
- [Task 004: Create initial code checklist](./task-004-code-checklist.md)
- [Task 005: Update evaluator design mode to binary checklist](./task-005-evaluator-design-mode.md)
- [Task 006: Update evaluator plan mode to binary checklist](./task-006-evaluator-plan-mode.md)
- [Task 007: Update evaluator code mode to binary checklist](./task-007-evaluator-code-mode.md)
- [Task 008: Update evaluator shared standards and output format](./task-008-evaluator-shared-standards.md)
- [Task 009: Update evaluation file formats to checklist format](./task-009-evaluation-file-formats.md)
- [Task 010: Update executing-plans Phase 3f spawn context](./task-010-phase-3f-spawn-context.md)
- [Task 011: Implement executing-plans Phase 4 intra-plan learning](./task-011-phase-4-intra-plan-learning.md)
- [Task 012: Create retrospective skill pattern analysis](./task-012-retrospective-pattern-analysis.md)
- [Task 013: Add evolution proposal and checklist update logic](./task-013-evolution-proposals.md)
- [Task 014: Remove old rubrics and update cross-references](./task-014-remove-rubrics-update-refs.md)
- [Task 015: Update plugin.json and validate plugin](./task-015-plugin-json-validation.md)

## BDD Coverage

All 27 BDD scenarios from the design are covered by these tasks:

| Feature | Scenarios | Covering Tasks |
|---------|-----------|----------------|
| Binary Checklist -- Design Mode | 6 | 002 (Background), 005 (all 6 scenarios) |
| Binary Checklist -- Plan Mode | 5 | 003 (Background), 006 (all 5 scenarios) |
| Command Exit Code -- Code Mode | 5 | 004 (Background), 007 (all 5 scenarios) |
| Retrospective Failure Pattern Analysis | 6 | 012 (all 6 scenarios) |
| Evolution Proposal Review | 5 | 013 (all 5 scenarios) |

Architecture-driven tasks without direct BDD scenarios: 001, 008, 009, 010, 011, 014, 015.

## Dependency Chain

```
task-001 (setup)
    |
    +---> task-002 (design-checklist) ---> task-005 (evaluator-design) ---+
    |                                                                    |
    +---> task-003 (plan-checklist) ----> task-006 (evaluator-plan) -----+
    |                                                                    |
    +---> task-004 (code-checklist) ----> task-007 (evaluator-code) -----+
    |                                                                    |
    |     +--------------------------------------------------------------+
    |     v
    |     task-008 (shared-standards)
    |         |
    |         v
    |     task-009 (file-formats)
    |         |
    |         v
    |     task-010 (phase-3f)
    |      /         \
    |     v           v
    |  task-011    task-014 (remove-rubrics)
    |  (phase-4)  \       |
    |     |        \      |
    +---> task-012  \     |
    | (retrospective)\   |
    |  <--- 002+003+004  |
    |         |           |
    |         v           |
    |     task-013        |
    |    (evolution)      |
    |         |           |
    |         v           v
    +----> task-015 (plugin.json) <--- 011+013+014
```

**Analysis:**
- No circular dependencies
- Logical flow: infrastructure (001) to checklists (002-004) to evaluator (005-008) to integration (009-011, 014) to finalization (015)
- Maximum parallelism at Tier 1 (tasks 002, 003, 004) and Tier 2 (tasks 005, 006, 007, 012)
- Tasks 005/006/007 are logically independent but modify the same file -- executor should serialize or use worktrees
- Tasks 011/014 both modify executing-plans/SKILL.md -- same serialization applies
- Retrospective skill path (012-013) runs independently from evaluator update path (005-011)

---

## Execution Handoff

Plan complete and saved to `docs/plans/2026-04-04-eval-harness-plan/`. Execution options:

**1. Orchestrated Execution (Recommended)** - Load `superpowers:executing-plans` skill using the Skill tool.

**2. Direct Agent Team** - Load `superpowers:agent-team-driven-development` skill using the Skill tool.

**3. BDD-Focused Execution** - Load `superpowers:behavior-driven-development` skill using the Skill tool for specific scenarios.
