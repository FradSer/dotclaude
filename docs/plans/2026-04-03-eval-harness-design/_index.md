# Eval Harness Design v2: Executable Verification

## Context

**Original request**: Design a multi-round eval mechanism and optimization loop for the superpowers plugin, following Anthropic's harness design blog post.

**Revised direction**: The original rubric-calibration approach has a fundamental flaw — it calibrates a proxy (rubric scores) rather than replacing the proxy with direct verification. The Anthropic article's core principle is to externalize subjective judgment as executable tests that produce objective pass/fail results, not to calibrate subjective scores against human baselines.

**Core problem with rubric scoring**:
- LLMs are sycophantic — the same artifact scored twice may get different scores as model behavior shifts
- "Architecture Soundness: 3/5" gives the generator nothing concrete to fix
- Calibrating rubric scores requires golden artifacts, human baselines, and a permanent calibration pipeline
- The calibration system itself suffers from the same bias problem it's trying to solve

**Core principle**: Externalize subjective judgment as executable tests. A test either passes or fails — it does not drift.

## Discovery Results

**What exists and is preserved:**

- `superpowers-evaluator` already runs verification commands in code mode (`Bash(test:*)`, `Bash(npm:*)`, `Bash(pnpm:*)`) — Step 3 of code mode
- Sprint contracts define per-task acceptance criteria before execution — the right source for checklist items
- Task files contain verification commands — these are the executable tests
- `executing-plans` Phase 3f already spawns the evaluator — integration point unchanged

**What is eliminated:**

- 1-5 rubric scoring in `superpowers-evaluator` (all modes)
- Calibration pipeline (eval-orchestrator, eval-bias-analyzer, eval-rubric-optimizer)
- Golden artifact management and human-scores.json
- Evaluation-history.json trend tracking
- `references/evaluation-rubrics.md` files (all three modes)

**What replaces them:**

- Binary checklists (`docs/retros/checklists/{mode}-v{N}.md`) — PASS/FAIL per item
- Retrospective process — evolves checklists from actual execution failures
- Evolution log — append-only audit trail of checklist changes

## Requirements

### VER — Verification-First Evaluation

- **VER-1**: Evaluation verdict is determined solely by verification command exit codes (code mode) or binary checklist results (design/plan mode) — no numeric rubric scores
- **VER-2** (code mode): `superpowers-evaluator` runs task verification commands independently; PASS/FAIL per task is determined by exit code 0 vs. non-zero
- **VER-3** (design mode): `superpowers-evaluator` applies the binary checklist from `docs/retros/checklists/design-v{N}.md`; each item is PASS or FAIL with specific evidence
- **VER-4** (plan mode): `superpowers-evaluator` applies the binary checklist from `docs/retros/checklists/plan-v{N}.md`; each item is PASS or FAIL with specific evidence
- **VER-5**: Rework items are produced only from FAIL checklist results; each item must name the exact file, location, and violated check — "code quality could be improved" is not a valid rework item
- **VER-6**: Evaluator output format: checklist results table (item, result, evidence) + rework items list + overall verdict — no scores table
- **VER-7**: Each checklist check is independently verifiable — a third party can confirm the result by reading the cited file or running the cited command without judgment calls

### CHK — Checklist Design

- **CHK-1** (design checklist): Covers requirement→scenario traceability, scenario concreteness (data specificity), architecture validity (layer dependency direction), risk identification
- **CHK-2** (plan checklist): Covers scenario→task traceability, task completeness (all required sections present), dependency validity (no cycles, no missing IDs), verification command quality (concrete and executable)
- **CHK-3** (code checklist): Test suite exits 0, type checker exits 0, linter exits 0, no prohibited patterns (stubs/TODOs) in produced files
- **CHK-4**: Each checklist item is: binary (not "partially met"), concrete (references specific file paths or grep patterns), actionable (a FAIL result tells the generator exactly what to change)
- **CHK-5**: Checklists stored at `superpowers/docs/retros/checklists/{mode}-v{N}.md`; sprint contracts reference the checklist version in use
- **CHK-6**: Checklist version increments when any item is added, modified, or removed; prior version files are preserved

### EVO — Evolution Tracking

- **EVO-1**: Every checklist change (item added/modified/removed) is logged to `docs/retros/evolution-log.jsonl` as a structured JSON line
- **EVO-2**: Each evolution event records: timestamp, event type, mode, item ID, rationale, driving plan IDs
- **EVO-3**: Evolution proposals require explicit user approval via AskUserQuestion before any checklist file is modified
- **EVO-4**: Items with 0 failures across 10+ plan evaluations are flagged as removal candidates — not automatically removed
- **EVO-5**: Items proposed for addition must have appeared as a real failure source in at least 2 distinct plans
- **EVO-6**: Max 3 item changes per mode per retrospective run, to prevent rapid oscillation

### RTR — Retrospective Process

- **RTR-1**: Retrospective is triggered manually via `/superpowers:retrospective [plan-path...]` after plan execution; not automatic
- **RTR-2**: Retrospective skill reads all evaluation reports from provided plan directories directly; identifies recurring FAIL items, plateau tasks, and never-failing items
- **RTR-3**: Best practices document written to `docs/retros/{topic}.md`; topic is derived from the dominant failure pattern; this file is the human-readable rationale for checklist evolution and is attributed to the retrospective skill that produced it
- **RTR-4**: Report includes: failure frequency table (by checklist item), plateau task analysis, proposed evolution items with rationale
- **RTR-5**: User approves or rejects each proposed evolution item; approved items are applied to the checklist file; evolution log is appended
- **RTR-6**: Retrospective can span multiple plans — the skill accepts a list of plan directories for cross-plan pattern detection

### PLG — Plugin Integration

- **PLG-1**: Add `retrospective` skill to `superpowers/.claude-plugin/plugin.json` commands → `/superpowers:retrospective`
- **PLG-2**: `superpowers-evaluator` updated in-place to use binary checklists instead of rubric scoring — agent structure and tool permissions unchanged
- **PLG-4**: Checklist file path is injected into evaluator spawn context by executing-plans (not hardcoded in agent definition)
- **PLG-5**: Never modify checklist files without user approval; enforced by retrospective skill flow

### Constraints and Non-Goals

**Constraints (MUST)**:
- `superpowers-evaluator` is updated, not replaced — separate evaluator agent architecture from the Anthropic article remains
- No numeric rubric scores (1-5) in any evaluation output
- Checklist evolution requires user approval — no auto-apply
- Code mode ground truth is command exit codes — never subjective assessment
- Evaluator runs commands independently; never trusts generator-reported results

**Non-Goals (explicitly out of scope)**:
- Calibration against human baselines
- Golden artifact management
- CI/CD integration
- Automated checklist generation (items are manually authored or retrospective-proposed)
- Cross-plugin checklist sharing

## Architecture

### Overview

```
Subsystem A: Verification-Based Evaluation  (per batch, Phase 3f)

  executing-plans Phase 3f
    → superpowers-evaluator (updated)
        design mode: apply binary design checklist → PASS/FAIL per item
        plan mode:   apply binary plan checklist   → PASS/FAIL per item
        code mode:   run verification commands     → exit codes → PASS/FAIL per task
    ← returns: checklist results table + rework items (no scores)

Subsystem B: Intra-Plan Learning  (per batch, Phase 4 enhancement)

  executing-plans Phase 4 (after evaluator, before user confirmation)
    reads: all evaluation reports in current *-evals/ so far
    identifies: checklist items failing across 2+ batches in this plan
    injects: pattern context into next batch sprint contract preamble
    surfaces: pattern summary in evidence block to user

Subsystem C: Cross-Plan Evolution  (out-of-band, user-triggered)

  /superpowers:retrospective [plan-path...]
    reads: *-evals/ from multiple completed plans
    identifies: recurring FAILs, plateau patterns, never-failing items
    proposes: checklist additions/modifications/removals
    → AskUserQuestion: user approves/rejects each proposal
    → [approved] write checklist updates + append to evolution-log.jsonl
    → writes: docs/retros/{topic}.md
```

### Data Structures

**`docs/retros/checklists/design-v1.md`** — binary design checklist:
```markdown
# Design Evaluation Checklist v1

## Requirements Traceability
- [ ] REQ-TRACE-01: Every requirement in _index.md maps to at least one BDD scenario
- [ ] REQ-TRACE-02: Every BDD scenario references a requirement (no orphan scenarios)

## Scenario Concreteness
- [ ] SCEN-CONC-01: All Given clauses use specific data values, not vague placeholders
- [ ] SCEN-CONC-02: All Then clauses state observable outcomes (not "should work" or "should be correct")

## Architecture Validity
- [ ] ARCH-01: No import described from inner layer to outer layer
- [ ] ARCH-02: All external dependencies named in _index.md Constraints section
- [ ] ARCH-03: No circular component dependencies described

## Risk Identification
- [ ] RISK-01: Design includes at least 3 identified risks with mitigation strategies
- [ ] RISK-02: Each risk mitigation is concrete (not "monitor closely" or "handle carefully")
```

**`docs/retros/checklists/plan-v1.md`** — binary plan checklist:
```markdown
# Plan Evaluation Checklist v1

## Scenario Coverage
- [ ] PLAN-COV-01: Every BDD scenario from design maps to at least one task
- [ ] PLAN-COV-02: No BDD scenario is unassigned in batch planning

## Task Completeness
- [ ] TASK-COMP-01: Every task has an acceptance criteria section
- [ ] TASK-COMP-02: Every task has verification commands
- [ ] TASK-COMP-03: No verification command is descriptive ("verify manually", "check that it works")

## Dependency Validity
- [ ] DEP-01: No circular dependencies in task dependency graph
- [ ] DEP-02: All task IDs in depends-on fields exist in the plan

## Test Coverage
- [ ] TEST-01: Every impl task has a corresponding test task or explicit absence justification
```

**`docs/retros/checklists/code-v1.md`** — code verification checklist:
```markdown
# Code Evaluation Checklist v1

## Verification Gate
- [ ] CODE-VER-01: All task verification commands exit with code 0
- [ ] CODE-VER-02: Type checker exits 0 (if applicable)
- [ ] CODE-VER-03: Linter exits 0 (if applicable)

## Prohibited Patterns
- [ ] CODE-QUAL-01: No TODO/FIXME/placeholder comments in produced files
- [ ] CODE-QUAL-02: No stub function bodies (pass, ..., raise NotImplementedError)
- [ ] CODE-QUAL-03: No hardcoded return values substituting real logic
```

**`docs/retros/evolution-log.jsonl`** — append-only change log:
```jsonl
{"timestamp":"2026-04-10T09:15:00Z","event":"item_added","mode":"design","item_id":"SCEN-CONC-03","rationale":"Error scenarios missing concrete status codes in 3/4 plans","driving_plans":["2026-03-15-auth","2026-03-22-api","2026-04-01-notif"]}
{"timestamp":"2026-05-02T14:30:00Z","event":"item_removed","mode":"plan","item_id":"PLAN-GRAN-01","rationale":"0 failures across 12 plans; check never triggered in practice","driving_plans":[]}
```

**Best practices document** `docs/retros/{topic}.md` (written by `/superpowers:retrospective`):
```markdown
# Retrospective: 2026-04-03-auth-plan

## Failure Frequency

| Checklist Item | Failures | Plans |
|----------------|----------|-------|
| SCEN-CONC-01   | 3        | 2     |
| ARCH-01        | 1        | 1     |
| PLAN-COV-01    | 0        | —     |

## Plateau Task Analysis

| Task | Consecutive REWORK Rounds | Failing Check |
|------|---------------------------|---------------|
| 004  | 2                         | TASK-COMP-03: verification command is descriptive |

## Evolution Proposals (requires approval)

1. ADD design/SCEN-CONC-03: "Error scenarios must name specific HTTP status codes"
   Evidence: caught in tasks 002, 005 (auth-plan), task 007 (api-plan)
2. ADD plan/TASK-COMP-04: "Verification commands must begin with a binary name, not a description verb"
   Evidence: plateau task 004 (auth-plan) traced to this gap
```

**Evaluator output format** (all modes, replaces scores table):
```markdown
## Checklist Results

| Item ID       | Check                                      | Result | Evidence                                        |
|---------------|--------------------------------------------|--------|-------------------------------------------------|
| REQ-TRACE-01  | All requirements map to ≥1 scenario        | PASS   | 7/7 requirements traced                         |
| SCEN-CONC-01  | Given clauses use specific data            | FAIL   | bdd-specs.md:23 — "some valid user data"        |
| ARCH-01       | No inner→outer layer imports described     | PASS   | No violations found                             |

## Rework Items

| Item ID      | File          | Location | Issue                                                               |
|--------------|---------------|----------|---------------------------------------------------------------------|
| SCEN-CONC-01 | bdd-specs.md  | line 23  | Replace "some valid user data" with concrete field values (e.g., email, password) |

## Verdict: REWORK
1 item FAIL: SCEN-CONC-01
```

## File Structure

```
superpowers/
├── .claude-plugin/
│   └── plugin.json                       # add retrospective to commands
├── agents/
│   └── superpowers-evaluator.md          # UPDATED: binary checklists, no rubric scoring
└── skills/
    ├── retrospective/                    # NEW
    │   └── SKILL.md
    └── executing-plans/
        └── references/
            ├── evaluation-rubrics.md     # REMOVED
            └── evaluation-file-formats.md  # UPDATED: checklist format replaces scores table

docs/plans/YYYY-MM-DD-{topic}-plan/       # writing-plans output (unchanged)
  _index.md
  task-{ID}-{slug}-{type}.md

docs/plans/YYYY-MM-DD-{topic}-evals/      # NEW: executing-plans evaluation artifacts
  sprint-contract-batch-{N}.md
  evaluation-round-{N}-batch-{M}.md

docs/retros/                      # NEW: ALL /superpowers:retrospective output
  checklists/
    design-v1.md                          # NEW: binary design checklist
    plan-v1.md                            # NEW: binary plan checklist
    code-v1.md                            # NEW: code verification checklist
  evolution-log.jsonl                     # NEW: append-only change log
  {topic}.md                              # knowledge document per dominant failure pattern
```

## Rationale

**Why binary checks over rubric scores?**

Rubric scores drift because LLMs are sycophantic — the same artifact scored twice may get different results. Binary checks do not drift: "does this import cross a layer boundary?" is true or false regardless of what the model "thinks."

"Architecture Soundness: 3/5" gives the generator nothing concrete to fix. "[FAIL] architecture.md describes domain service importing from infra layer — domain must not depend on infra" gives the generator exactly what to change.

**Why retrospective over calibration?**

Calibration requires a stable human baseline created by manually scoring golden artifacts — which is expensive, goes stale when rubrics change, and encodes one person's biases as ground truth.

Retrospective evolves from actual execution outcomes. If a checklist item catches real problems in multiple plans, it earns its place. If it never fails, it may not be detecting genuine issues. This is the same logic that governs which tests survive in a mature test suite.

**Why this is simpler than the original design?**

Original design: 3 new agents + golden artifact directories + human-scores.json curation + calibration runs + run history management + rubric version tracking.

This design: 0 new agents + 1 new skill + 3 checklist files + evolution log.

**Why the Anthropic article validates this direction?**

The article's Playwright evaluator never asks "is this good?" — it asks "does this work?" Pass/fail is determined by user action completion, not by rubric scoring. The article explicitly states harness components are "load-bearing only until capability advances obsolete them." Checklist-based verification ages better than rubric calibration because tests that no longer trigger failures are simply removed — no recalibration required.

## Design Documents

- [BDD Specifications](./bdd-specs.md)
- [Architecture](./architecture.md)
- [Best Practices](./best-practices.md)
