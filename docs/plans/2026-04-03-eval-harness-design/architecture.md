# Architecture

## System Overview

Three subsystems at different scopes. A and B run in-band during every plan execution. C runs out-of-band, user-triggered, across multiple completed plans.

```
Subsystem A: Verification-Based Evaluation  (per batch, Phase 3f)

  executing-plans Phase 3f (spawn context includes checklist path):
    → superpowers-evaluator (updated)
        design mode: read design checklist → apply each check → PASS/FAIL per item
        plan mode:   read plan checklist   → apply each check → PASS/FAIL per item
        code mode:   run verification commands → exit code 0 = PASS, non-zero = FAIL
    ← returns: checklist results table + rework items (no numeric scores)

Subsystem B: Intra-Plan Learning  (per batch, Phase 4 enhancement)

  executing-plans Phase 4 (after evaluator, before user confirmation):
    reads: all evaluation-round-*-batch-*.md written so far in current *-evals/
    identifies: checklist items failing across multiple batches in this plan
    injects: pattern context into next batch sprint contract and generator prompt
    surfaces: pattern summary in Phase 4 evidence block to user

Subsystem C: Cross-Plan Evolution  (out-of-band, user-triggered)

  /superpowers:retrospective [plan-path...]
    reads: *-evals/ from multiple completed plans
    reads: current checklists for never-failing item detection
    computes: per-item failure frequency across plans, plateau task patterns
    proposes: ADD / MODIFY / REMOVE per checklist item
    → AskUserQuestion: user approves/rejects each proposal
    → [approved] Edit checklist file (version increment) + Write evolution-log.jsonl entry
    → writes: docs/retros/{topic}.md (knowledge extracted from patterns)
```

## Component Specifications

### superpowers-evaluator (updated)

**What changes**: Rubric scoring (Steps 2-4 in design/plan mode, Step 4 in code mode) replaced by checklist execution. Output format changes: scores table removed, checklist results table added.

**What is unchanged**: Separate evaluator agent architecture, read-only enforcement, skeptical-by-default standard, all tool permissions, pivot flag logic (code mode), structural integrity checks (plan mode).

---

**Design mode process (updated)**:

1. Read design artifacts: `_index.md`, `bdd-specs.md`, `architecture.md`, `best-practices.md`
2. Read design checklist from path in spawn context (e.g., `superpowers/docs/retros/checklists/design-v1.md`)
3. For each checklist item:
   - Determine check method (grep pattern, structural cross-reference, or content scan)
   - Execute check against design artifacts
   - Record: item ID, PASS or FAIL, evidence (file:line or explicit absence note)
4. Produce rework items from all FAIL results: file path, location, exact issue
5. Verdict: PASS if all items PASS; REWORK if any item FAIL

**Plan mode process (updated)**:

1. Read `_index.md` and all task files
2. Read plan checklist from path in spawn context (e.g., `superpowers/docs/retros/checklists/plan-v1.md`)
3. For each checklist item:
   - Execute structural check (dependency graph walk, task field presence, command syntax scan)
   - Record: item ID, PASS or FAIL, evidence
4. Run structural integrity checks independently of checklist: cycle detection, orphan tasks, unmapped scenarios
5. Produce rework items from all FAIL results
6. Verdict: PASS if all items PASS; REWORK if any item FAIL

**Code mode process (updated)**:

1. Read sprint contract (unchanged)
2. Read produced artifacts (unchanged)
3. Run verification commands per task (unchanged) — exit codes determine task PASS/FAIL
4. Read code checklist from path in spawn context (e.g., `superpowers/docs/retros/checklists/code-v1.md`)
5. Apply prohibited pattern checks from code checklist against produced files
6. Produce rework items from: failed verification commands + FAIL code checklist items
7. Assess pivot flag (logic unchanged — see existing evaluator definition)
8. Write evaluation report to plan directory using updated format (no scores table)

**Updated output format (all modes)**:

```markdown
## Checklist Results

| Item ID       | Check                                   | Result | Evidence                                        |
|---------------|-----------------------------------------|--------|-------------------------------------------------|
| REQ-TRACE-01  | All requirements map to ≥1 scenario     | PASS   | 7/7 requirements traced                         |
| SCEN-CONC-01  | Given clauses use specific data         | FAIL   | bdd-specs.md:23 — "some valid user data"        |

## Rework Items

| Item ID      | File         | Location | Issue                                                                   |
|--------------|--------------|----------|-------------------------------------------------------------------------|
| SCEN-CONC-01 | bdd-specs.md | line 23  | Replace "some valid user data" with concrete values (email, password)   |

## Verdict: REWORK
1 item FAIL: SCEN-CONC-01
```

---

### retrospective skill

**Role**: Reads evaluation reports directly, performs pattern analysis, presents proposals, applies approved changes. No sub-agent spawning.

**Arguments**: `[plan-path...] [--across-all]`

**Process**:

1. Resolve evals folder: derive `YYYY-MM-DD-{topic}-evals/` from the given plan path (`YYYY-MM-DD-{topic}-plan/`); abort with setup error if evals folder does not exist or contains no `evaluation-round-*-batch-*.md` files
2. Read current checklist versions from `docs/retros/checklists/`
3. For each evals folder:
   - Read all `evaluation-round-{N}-batch-{M}.md` files
   - Extract per-report: checklist item results (PASS/FAIL), rework items, pivot flags
4. Aggregate across all plans:
   - Compute failure frequency per item: count of distinct plans where item FAILed
   - Identify plateau tasks: tasks in REWORK across 2+ consecutive rounds in any plan
   - Identify never-failing items: items with 0 failures across 10+ evaluation reports
5. Formulate evolution proposals (up to rate limit EVO-6: max 3 per mode):
   - ADD: failure source in ≥2 distinct plans with no existing checklist item
   - REMOVE: item with 0 failures across 10+ reports with explicit rationale
   - MODIFY: item producing false positives identifiable from rework analysis
6. Write best practices document to `docs/retros/{topic}.md`
   - Topic derived from the dominant failure pattern (e.g., `bdd-scenario-concreteness.md`, `async-error-coverage.md`)
   - Include: pattern description, evidence from plans, checklist items affected, actionable guidance
   - This file is the human-readable record of why the checklist evolved; it is produced by retrospective and attributed to it
7. For each proposal:
   - Present via AskUserQuestion with rationale and driving plan evidence
   - If approved: create new checklist version file, append event to evolution-log.jsonl
   - If rejected: record rejection in report; do not modify checklist
8. Report summary: N proposals approved, M rejected, checklists updated to version X

**Allowed tools**: Read, Glob, Grep, Write, Edit

---

### executing-plans skill (Phase 3f + Phase 4 updates)

**Phase 3f — spawn context change** (minor):

The spawn context for `superpowers-evaluator` changes from rubric path to checklist path:

| Mode   | Checklist path                                         |
|--------|--------------------------------------------------------|
| design | `superpowers/docs/retros/checklists/design-v{N}.md`   |
| plan   | `superpowers/docs/retros/checklists/plan-v{N}.md`     |
| code   | `superpowers/docs/retros/checklists/code-v{N}.md`     |

The skill reads the latest checklist version from the checklists directory before spawning. No hardcoded version in the skill definition.

---

**Phase 4 — intra-plan learning injection** (new):

After `superpowers-evaluator` writes its report and before the user confirmation AskUserQuestion, executing-plans performs a lightweight pattern scan:

1. Read all `evaluation-round-*-batch-*.md` files written so far in the current `*-evals/` directory
2. Identify checklist items that FAILed in 2+ distinct batches within this plan
3. If patterns found:
   - Inject a "Recurring failures" context block into the next batch's sprint contract preamble
   - Add a "Pattern detected" note to the Phase 4 evidence block presented to the user
4. If a pattern persists across 3+ batches for the same item: surface as a potential plan-level issue in the evidence block (not automatically a pivot — user decides)

**Context injection format** (added to next sprint contract preamble):

```
## Recurring Failure Patterns (from prior batches)

| Checklist Item | FAILed in batches | Issue seen |
|----------------|-------------------|------------|
| SCEN-CONC-01   | 1, 2              | Given clauses use vague placeholders |

Generator note: tasks in this batch must address the above patterns proactively.
```

This injection is additive — it does not modify task acceptance criteria, only provides context.

## Agent Interaction Diagram

```
User: /superpowers:retrospective docs/plans/2026-04-01-auth-plan/ docs/plans/2026-03-22-api-plan/
  │
  ▼
retrospective skill
  resolves: 2026-04-01-auth-plan/ → 2026-04-01-auth-evals/
  resolves: 2026-03-22-api-plan/ → 2026-03-22-api-evals/
  reads: evaluation-round-*-batch-*.md from each evals/ folder
  reads: docs/retros/checklists/design-v1.md (for never-failing detection)
  computes: SCEN-CONC-01 failed in 2 plans; PLAN-GRAN-01 never failed in 8 reports
  writes: docs/retros/bdd-scenario-concreteness.md
  │
  │ proposal 1:
  ▼
AskUserQuestion:
  "ADD design/SCEN-CONC-03: Error scenarios must name specific HTTP status codes
   Evidence: auth-plan tasks 002, 005 — api-plan task 007
   All failed with vague error conditions in Given clauses.
   Approve? (yes/no)"
  │ approved
  ▼
retrospective skill
  creates: docs/retros/checklists/design-v2.md (copy of v1 + new item)
  appends: evolution-log.jsonl entry {event:"item_added", item_id:"SCEN-CONC-03", ...}
  │
  │ proposal 2:
  ▼
AskUserQuestion:
  "REMOVE plan/PLAN-GRAN-01: 0 failures across 8 evaluation reports
   This item has never detected a real issue. Remove?
   (The item will be preserved in plan-v1.md if rejected)"
  │ rejected
  ▼
retrospective skill
  records rejection in retrospective report
  no checklist file modification
  │
  ▼
summary: "1 proposal approved (design-v2.md created), 1 rejected"
```

## File Layout

```
superpowers/
├── .claude-plugin/
│   └── plugin.json                           # +retrospective in commands
├── agents/
│   └── superpowers-evaluator.md              # UPDATED: checklist format, no rubric scoring
└── skills/
    ├── retrospective/                        # NEW
    │   └── SKILL.md
    └── executing-plans/
        └── references/
            ├── evaluation-rubrics.md         # REMOVED
            └── evaluation-file-formats.md   # UPDATED: checklist format replaces scores table

docs/plans/YYYY-MM-DD-{topic}-plan/           # writing-plans output (unchanged)
  _index.md
  task-{ID}-{slug}-{type}.md

docs/plans/YYYY-MM-DD-{topic}-evals/          # NEW: executing-plans evaluation artifacts
  sprint-contract-batch-{N}.md
  evaluation-round-{N}-batch-{M}.md           # format updated (no scores table)

docs/retros/                          # NEW: ALL /superpowers:retrospective output
  checklists/
    design-v1.md                              # NEW: initial binary design checklist
    plan-v1.md                                # NEW: initial binary plan checklist
    code-v1.md                                # NEW: code verification checklist
  evolution-log.jsonl                         # NEW: append-only change log
  {topic}.md                                  # knowledge document per dominant failure pattern
```

**Directories eliminated vs. original v1 design**:
- `eval-harness/golden/` — no golden artifacts
- `eval-harness/runs/` — no calibration run history
- `eval-harness/` — no data files inside the plugin; all output lives in `docs/`

## Plugin.json Changes

```json
{
  "commands": [
    "./skills/brainstorming/",
    "./skills/writing-plans/",
    "./skills/executing-plans/",
    "./skills/need-vet/",
    "./skills/retrospective/"
  ],
  "agents": [
    "./agents/superpowers-evaluator.md"
  ]
}
```

## Dependency Map

```
retrospective skill
  └── reads: docs/retros/checklists/ (current versions)
  └── reads: docs/plans/{topic}-evals/evaluation-round-*-batch-*.md (multiple plans)
  └── writes: docs/retros/{topic}.md (knowledge layer — attributed to this skill)
  └── appends: docs/retros/evolution-log.jsonl
  └── edits: docs/retros/checklists/ (creates new version file on approval)

superpowers-evaluator (updated)
  └── reads: checklists/{mode}-v{N}.md (path from spawn context)
  └── runs: verification commands in task files (code mode, unchanged)
  └── writes: docs/plans/{topic}-evals/sprint-contract-batch-{N}.md
  └── writes: docs/plans/{topic}-evals/evaluation-round-{N}-batch-{M}.md (updated format)

executing-plans skill (Phase 3f + Phase 4 update)
  └── spawns: superpowers-evaluator with checklist path (Phase 3f)
  └── reads: docs/plans/{topic}-evals/evaluation-round-*-batch-*.md (Phase 4 pattern scan)
  └── injects: recurring failure context into next sprint contract preamble (Phase 4)
```
