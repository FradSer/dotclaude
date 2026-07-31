# Design Evaluation Checklist Reference

## Purpose

Reference for the superpowers-evaluator when operating in design mode. The evaluator applies binary PASS/FAIL checklist items from `docs/retros/checklists/design-v{N}.md` to determine whether design documents meet the bar for implementation planning.

## Checklist Source

The canonical checklist lives at `docs/retros/checklists/design-v{N}.md` (latest version). The evaluator reads this file at spawn time via the path provided in the spawn context. This reference file provides context on how the checklist items map to design quality dimensions.

## Checklist Item Categories

| Category | Example Items | What They Check |
|----------|---------------|-----------------|
| BDD Concreteness | SCEN-CONC-01 | Given clauses use specific data values (no vague placeholders) |
| Requirements Traceability | REQ-TRACE-01 | Every requirement ID mapped to at least one scenario |
| Architecture Soundness | ARCH-01 | No inner-to-outer layer dependencies described |
| Risk Coverage | RISK-02 | Each risk mitigation specifies a concrete action |

## Verdict Rules

| Verdict | Condition |
|---------|-----------|
| **PASS** | All checklist items PASS |
| **REWORK** | Any checklist item FAIL (include count and IDs of failing items) |

When the verdict is REWORK, produce rework items for each FAIL with: item ID, file, location, issue, and rework action.

## Output Responsibility

The evaluator outputs report content as text. The parent skill (brainstorming) is responsible for writing the report to disk. The evaluator never writes files directly.

## Calibration Example

### Design: `docs/plans/2026-03-15-plugin-notifications-design/`

A design for a plugin notification system with 6 requirements and 8 BDD scenarios.

**Checklist Evaluation:**

| Item ID | Check | Result | Evidence |
|---------|-------|--------|----------|
| SCEN-CONC-01 | Given clauses use specific data | PASS | no vague placeholders found |
| REQ-TRACE-01 | Requirement IDs in scenarios | FAIL | REQ-006 not referenced in bdd-specs.md |
| ARCH-01 | No inner-to-outer dependencies | PASS | no violations found |
| RISK-02 | Concrete risk mitigations | FAIL | "monitor closely" specifies no action |

**Verdict:** REWORK (2 items FAIL: REQ-TRACE-01, RISK-02)

**Rework Items:**

| Item ID | File | Location | Issue |
|---------|------|----------|-------|
| REQ-TRACE-01 | bdd-specs.md | -- | Add scenario referencing REQ-006 |
| RISK-02 | _index.md | Risks | Replace "monitor closely" with concrete mitigation |
