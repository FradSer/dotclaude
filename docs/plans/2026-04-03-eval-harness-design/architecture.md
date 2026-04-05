# Architecture

## System Overview

Two subsystems. A runs in-band during every plan execution. B enhances Phase 4 with learning and context management.

```
Subsystem A: Verification-Based Evaluation  (per batch, Phase 3f)

  executing-plans Phase 3f (spawn context includes checklist path):
    -> superpowers-evaluator (updated)
        design mode: read design checklist -> apply each check -> PASS/FAIL per item
        plan mode:   read plan checklist   -> apply each check -> PASS/FAIL per item
        code mode:   run verification commands -> exit code 0 = PASS, non-zero = FAIL
    <- returns: checklist results table + rework items (no numeric scores)

Subsystem B: Intra-Plan Learning  (per batch, Phase 4 enhancement)

  executing-plans Phase 4 (after evaluator, before user confirmation):
    reads: all evaluation-round-*-batch-*.md written so far in current *-evals/
    identifies: checklist items failing across multiple batches in this plan
    injects: pattern context into next batch sprint contract and generator prompt
    surfaces: pattern summary in Phase 4 evidence block to user
    emits: batch handoff summary for context pressure reduction
```

Checklist evolution is manual: edit files in `docs/retros/checklists/`, version via git.

## Component Specifications

### superpowers-evaluator (updated)

**What changes**: Rubric scoring (Steps 2-4 in design/plan mode, Step 4 in code mode) replaced by checklist execution. Output format changes: scores table removed, checklist results table added.

**What is unchanged**: Separate evaluator agent architecture, read-only enforcement, skeptical-by-default standard, all tool permissions, pivot flag logic (code mode), structural integrity checks (plan mode).

**Output responsibility protocol** (new): The evaluator agent remains read-only (no Write/Edit tools). It produces report content as structured text in its response. The parent agent (executing-plans, brainstorming, or writing-plans) is responsible for writing the evaluator's output to disk as the evaluation report file. Sprint contracts follow the same protocol. This separation ensures the evaluator cannot accidentally modify artifacts it is evaluating.

---

**Design mode process (updated)**:

1. Read design artifacts: `_index.md`, `bdd-specs.md`, `architecture.md`, `best-practices.md`
2. Read design checklist from path in spawn context (e.g., `docs/retros/checklists/design-v1.md`)
3. For each checklist item:
   - Determine check method (grep pattern, structural cross-reference, or content scan)
   - Execute check against design artifacts
   - Record: item ID, PASS or FAIL, evidence (file:line or explicit absence note)
4. Produce rework items from all FAIL results: file path, location, exact issue
5. Verdict: PASS if all items PASS; REWORK if any item FAIL

**Plan mode process (updated)**:

1. Read `_index.md` and all task files
2. Read plan checklist from path in spawn context (e.g., `docs/retros/checklists/plan-v1.md`)
3. For each checklist item:
   - Execute the check method specified in the item annotation (dependency graph walk, task field presence, command syntax scan, etc.)
   - Record: item ID, PASS or FAIL, evidence
   - Note: DEP-01 and DEP-02 perform cycle detection and ID resolution; PLAN-COV-01 detects unmapped scenarios -- no separate structural sweep is performed outside the checklist
4. Produce rework items from all FAIL results
5. Verdict: PASS if all items PASS; REWORK if any item FAIL

**Code mode process (updated)**:

1. Read sprint contract (unchanged)
2. Read produced artifacts (unchanged)
3. Run verification commands per task (unchanged) -- exit codes determine task PASS/FAIL
4. Read code checklist from path in spawn context (e.g., `docs/retros/checklists/code-v1.md`)
5. Apply prohibited pattern checks from code checklist against produced files
6. Produce rework items from: failed verification commands + FAIL code checklist items
7. Assess pivot flag (logic unchanged -- see existing evaluator definition)
8. Write evaluation report to plan directory using updated format (no scores table)

**Updated output format (all modes)**:

```markdown
## Checklist Results

| Item ID       | Check                                   | Result | Evidence                                        |
|---------------|-----------------------------------------|--------|-------------------------------------------------|
| REQ-TRACE-01  | All requirements map to >=1 scenario    | PASS   | 7/7 requirements traced                         |
| SCEN-CONC-01  | Given clauses use specific data         | FAIL   | bdd-specs.md:23 -- "some valid user data"       |

## Rework Items

| Item ID      | File         | Location | Issue                                                                   |
|--------------|--------------|----------|-------------------------------------------------------------------------|
| SCEN-CONC-01 | bdd-specs.md | line 23  | Replace "some valid user data" with concrete values (email, password)   |

## Verdict: REWORK
1 item FAIL: SCEN-CONC-01
```

---

### executing-plans skill (Phase 3f + Phase 4 updates)

**Phase 3f -- spawn context change** (minor):

The spawn context for `superpowers-evaluator` changes from rubric path to checklist path:

| Mode   | Checklist path                                         |
|--------|--------------------------------------------------------|
| design | `docs/retros/checklists/design-v{N}.md`   |
| plan   | `docs/retros/checklists/plan-v{N}.md`     |
| code   | `docs/retros/checklists/code-v{N}.md`     |

The skill reads the latest checklist version from the checklists directory before spawning. Version selection: scan `docs/retros/checklists/` for files matching `{mode}-v{N}.md` (e.g., `design-v1.md`, `design-v2.md`); extract the numeric suffix N from each matching filename; select the file with the highest N. Files not matching the pattern `{mode}-v\d+\.md` (drafts, backups, etc.) are ignored. No hardcoded version in the skill definition.

---

**Phase 4 -- intra-plan learning injection** (new):

After `superpowers-evaluator` writes its report and before the user confirmation AskUserQuestion, executing-plans performs a lightweight pattern scan:

1. Read all `evaluation-round-*-batch-*.md` files written so far in the current `*-evals/` directory
2. Identify checklist items that FAILed in 2+ distinct batches within this plan
3. If patterns found:
   - Inject a "Recurring failures" context block into the next batch's sprint contract preamble
   - Add a "Pattern detected" note to the Phase 4 evidence block presented to the user
4. If a pattern persists across 3+ batches for the same item: elevate to the first item in the Phase 4 user confirmation AskUserQuestion with an explicit recommendation to pause execution and review the task specification before proceeding -- execution is not auto-blocked, but the prompt makes the escalation prominent so it cannot be easily dismissed

**Context injection format** (added to next sprint contract preamble):

```
## Recurring Failure Patterns (from prior batches)

| Checklist Item | FAILed in batches | Issue seen |
|----------------|-------------------|------------|
| SCEN-CONC-01   | 1, 2              | Given clauses use vague placeholders |

Generator note: tasks in this batch must address the above patterns proactively.
```

This injection is additive -- it does not modify task acceptance criteria, only provides context.

---

### Batch-Boundary Context Management

**Motivation**: Anthropic's harness design article states "context resets outperform context compaction." The Superpower Loop is context compaction -- same session, growing context window. For long plan executions, this creates "context anxiety" (premature completion as perceived context limits approach).

**Approach**: Pragmatic middle ground that doesn't break the Superpower Loop architecture.

After each batch completes (all tasks verified, before user confirmation in Phase 4), emit a structured batch handoff to conversation context:

```markdown
## Batch {N} Handoff

**Progress**: {completed}/{total} tasks complete
**This batch**: tasks {IDs} -- all PASS
**Recurring patterns**: {pattern list or "none detected"}
**Modified files**: {file list}
**Next batch**: tasks {IDs} -- {brief scope}
```

This serves as a compressed checkpoint. The model can reference the handoff rather than retaining full details of prior batches in working memory. The existing full handoff summary mechanism (16+ tasks, every 3 batches) remains unchanged.

---

### Cost Tracking

**Motivation**: Anthropic's article compares "solo agent 20 min/$9 vs full harness $200/6hr." Without cost data, we cannot assess whether evaluator overhead is justified.

Each evaluation report includes a "Run Metrics" section:

```markdown
## Run Metrics

| Metric | Value |
|--------|-------|
| Evaluator input tokens | {N} |
| Evaluator output tokens | {N} |
| Evaluation duration | {N}s |
| Checklist version | {mode}-v{N} |
```

Token counts are best-effort: extracted from the API response `usage` field if available (may not be accessible in all Claude Code spawning contexts). Metrics are informational only -- they never affect verdicts. Absence of token data does not block evaluation.

## File Layout

```
superpowers/
├── .claude-plugin/
│   └── plugin.json                           # unchanged
├── agents/
│   └── superpowers-evaluator.md              # UPDATED: checklist format, output protocol
└── skills/
    ├── brainstorming/
    │   ├── SKILL.md                          # UPDATED: evaluator refs -> checklist
    │   └── references/
    │       └── evaluation-rubrics.md         # UPDATED: checklist approach
    ├── writing-plans/
    │   ├── SKILL.md                          # UPDATED: evaluator refs -> checklist
    │   └── references/
    │       └── evaluation-rubrics.md         # UPDATED: checklist approach
    └── executing-plans/
        └── references/
            ├── evaluation-rubrics.md         # REMOVED
            └── evaluation-file-formats.md    # UPDATED: checklist + cost tracking

docs/plans/YYYY-MM-DD-{topic}-plan/           # writing-plans output (unchanged)
  _index.md
  task-{ID}-{slug}-{type}.md

docs/plans/YYYY-MM-DD-{topic}-evals/          # NEW: evaluation artifacts
  sprint-contract-batch-{N}.md
  evaluation-round-{N}-batch-{M}.md

docs/retros/                                  # NEW: checklist storage
  checklists/
    design-v1.md                              # binary design checklist
    plan-v1.md                                # binary plan checklist
    code-v1.md                                # code verification checklist
```

**Directories eliminated vs. original design**:
- `eval-harness/golden/` -- no golden artifacts
- `eval-harness/runs/` -- no calibration run history
- `eval-harness/` -- no data files inside the plugin; all output lives in `docs/`

## Plugin.json Changes

No changes to plugin.json commands array.

```json
{
  "commands": [
    "./skills/brainstorming/",
    "./skills/writing-plans/",
    "./skills/executing-plans/",
    "./skills/need-vet/"
  ],
  "agents": [
    "./agents/superpowers-evaluator.md"
  ]
}
```

## Dependency Map

```
superpowers-evaluator (updated)
  └── reads: checklists/{mode}-v{N}.md (path from spawn context)
  └── runs: verification commands in task files (code mode, unchanged)
  └── outputs: sprint contract content + evaluation report content (parent writes to disk)

executing-plans skill (Phase 3f + Phase 4 update)
  └── spawns: superpowers-evaluator with checklist path (Phase 3f)
  └── writes: sprint contract and evaluation report files from evaluator output
  └── reads: docs/plans/{topic}-evals/evaluation-round-*-batch-*.md (Phase 4 pattern scan)
  └── injects: recurring failure context into next sprint contract preamble (Phase 4)
  └── emits: batch handoff summary to conversation context (Phase 4)
```
