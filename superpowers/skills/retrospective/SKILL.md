---
name: retrospective
description: This skill should be used when the user wants to analyze evaluation patterns across completed plans and evolve checklists. Triggered by asking to "run a retrospective", "analyze evaluation patterns", "evolve checklists", or "/superpowers:retrospective".
argument-hint: <plan-path-1> [plan-path-2] [--across-all]
user-invocable: true
allowed-tools: ["Read", "Glob", "Grep", "Write", "Edit", "AskUserQuestion", "Bash(python3:*)"]
---

# Retrospective

Analyze evaluation patterns across completed plans, identify recurring failures, and propose checklist evolution with user approval.

**Chain position**: This skill is the downstream consumer of executing-plans Phase 4 "Checklist Evolution Candidates". It aggregates signals across plans and produces versioned checklist updates.

## Phase 0: Bootstrap (run only when no checklists exist)

Before Phase 1, check whether `docs/retros/checklists/` contains any `{mode}-v1.md` files.

If the directory is missing or empty, seed the initial v1 checklists:

1. Create `docs/retros/checklists/` if it does not exist
2. For each mode that lacks a v1 file, create a minimal starter checklist:

**`design-v1.md`** — minimum viable design checklist:
```markdown
# Design Checklist v1

### REQ-TRACE-01: All requirements map to at least one BDD scenario
**Check method:** `grep -c "Scenario:" bdd-specs.md` -- count must equal or exceed scenario count implied by requirements
**Evidence format:** N/M requirements traced
**Rework format:** Add missing scenario for requirement: {requirement}
# Type: inferential

### SCEN-CONC-01: Given clauses use specific, concrete data values
**Check method:** `grep -n "Given" bdd-specs.md` -- flag any clause containing "some", "a valid", "appropriate", or other vague qualifiers
**Evidence format:** bdd-specs.md:{line} -- "{clause text}"
**Rework format:** Replace "{vague phrase}" with concrete value at bdd-specs.md:{line}
# Type: computational

### ARCH-01: No inner-to-outer layer dependencies described
**Check method:** Scan architecture.md (or Detailed Design in _index.md) for any arrow or prose stating an inner layer (domain/application) imports from an outer layer (infrastructure/interfaces)
**Evidence format:** {file}:{line} -- "{dependency description}"
**Rework format:** Invert dependency at {file}:{line}; define interface in inner layer
# Type: inferential

### RISK-02: Each risk mitigation specifies a concrete action
**Check method:** For each risk listed in _index.md, confirm its mitigation names a specific mechanism (flag, retry policy, circuit breaker, etc.) rather than a vague verb like "monitor" or "handle carefully"
**Evidence format:** _index.md -- risk "{title}" mitigation "{text}"
**Rework format:** Replace vague mitigation for risk "{title}" with concrete action
# Type: inferential
```

**`plan-v1.md`** — minimum viable plan checklist:
```markdown
# Plan Checklist v1

### PLAN-COV-01: Every design BDD scenario maps to at least one task
**Check method:** Cross-reference scenario titles in bdd-specs.md against task subject lines and BDD Scenario sections in task files
**Evidence format:** N/M scenarios covered; uncovered: {scenario titles}
**Rework format:** Add task for scenario: {scenario title}
# Type: inferential

### DEP-01: No circular dependencies
**Check method:** Walk depends-on graph from _index.md; detect any cycle
**Evidence format:** Cycle detected: task-{A} -> task-{B} -> ... -> task-{A} | No cycles
**Rework format:** Break cycle by removing dependency: task-{A} depends-on task-{B}
# Type: computational

### DEP-02: All depends-on references resolve to existing task IDs
**Check method:** For each depends-on ID in _index.md, confirm a matching task-{ID}-*.md file exists
**Evidence format:** Unresolved: {ID list} | All resolved
**Rework format:** Fix depends-on reference {ID} in {task file}
# Type: computational

### TEST-01: Every impl task has a corresponding test task
**Check method:** For each task-{NNN}-*-impl.md, check for matching task-{NNN}-*-test.md
**Evidence format:** Unpaired impl tasks: {list} | All paired
**Rework format:** Add test task for: task-{NNN}-{slug}-impl.md
# Type: computational
```

**`code-v1.md`** — minimum viable code checklist:
```markdown
# Code Checklist v1

### CODE-VER-01: All verification commands exit with code 0
**Check method:** Run each verification command from the task file; record exit code
**Evidence format:** Command: {cmd} | Exit: {code} | Output: {last 5 lines}
**Rework format:** Fix failing verification: {cmd} exits {code}; error: {output}
# Type: computational

### CODE-QUAL-01: No TODO/FIXME/NotImplementedError/pass-only patterns in produced files
**Check method:** `grep -rn "TODO\|FIXME\|NotImplementedError\|raise NotImplementedError" {files}`
**Evidence format:** {file}:{line} -- {match}
**Rework format:** Remove placeholder at {file}:{line}; implement real logic
# Type: computational

### CODE-QUAL-02: No hardcoded stubs, skeleton-only bodies, or placeholder implementations
**Check method:** For each produced file, check that at least one function/method contains a non-trivial body (not just `pass`, `...`, `return None`, or a hardcoded literal)
**Evidence format:** {file} -- all bodies are stubs
**Rework format:** Implement real logic in {file} function {name}
# Type: computational
```

3. Log one line per mode seeded: "Seeded initial checklist: {mode}-v1.md". If all three modes already have a v1 file, log "Phase 0: all checklists present, skipping seed."

Phase 0 runs per mode independently — only the modes missing a v{N} file are seeded. Do not skip the entire phase because one mode already has a checklist.

## Phase 1: Data Collection

1. **Resolve inputs**: Parse `$ARGUMENTS` for plan paths. If `--across-all`, scan `docs/plans/` for all `*-plan/` directories with evaluation reports.
2. **Resolve evals**: For each plan path, look for evaluation reports in the plan directory (`evaluation-round-*.md`, `evaluation-design-round-*.md`, `evaluation-plan-round-*.md`). If a sibling `*-evals/` directory exists, read from there instead.
3. **Read checklists**: Scan `docs/retros/checklists/` for latest versions of each mode (`{mode}-v{N}.md`, highest N).
4. **Read reports**: For each plan, read all evaluation report files. Extract per-item results (Item ID, Result, Evidence) and rework items.
5. **Minimum data check**: If only 1 plan provided, warn that ADD proposals require 2+ plans. If fewer than 10 reports per item, warn that REMOVE proposals require 10+ reports.

## Phase 2: Pattern Analysis

Aggregate data across all plans. See `./references/analysis-patterns.md` for detailed logic.

1. **Failure frequency**: Count distinct plans where each checklist item FAILed. Rank by frequency descending.
2. **Plateau tasks**: Identify tasks that were REWORK across 2+ consecutive evaluation rounds in any plan. Extract the root cause from rework items.
3. **Never-failing items**: Find items with 0 FAILs across 10+ evaluation reports. These are REMOVE candidates.
4. **Variety gaps**: From executing-plans completion summaries, find batches where all items PASS but 2+ rework rounds occurred -- the checklist missed the failure mode.

Output a structured analysis report with tables for each category.

## Phase 3: Evolution Proposals

Generate proposals from analysis results. See `./references/evolution-protocol.md` for thresholds and format.

| Type | Trigger | Threshold |
|------|---------|-----------|
| ADD | Failure pattern in 2+ plans with no covering item | 2+ distinct plans |
| REMOVE | 0 failures across sufficient reports | 10+ reports per item |
| MODIFY | Item produces false positives (FAIL overturned in rework) | 2+ false positives |
| PROMOTE | Capability item pass rate >80% across 3+ successive plans | 3+ plans trending |

**Rate limit (EVO-6)**: Max 3 proposals per mode per retrospective run. Defer excess with evidence for future runs.

Each proposal includes: type, target checklist, item ID, description, rationale with plan evidence.

## Phase 4: User Approval and Apply

For each proposal (ordered by priority: regression breaks first, then by frequency):

1. Present via AskUserQuestion with: proposal type, item ID, description, rationale, driving plan evidence
2. **Approved**: Queue for checklist update
3. **Rejected**: Record rejection in retrospective report; no file change

After all proposals reviewed:

1. **Pre-edit snapshot**: Write current checklist content to the retrospective report under "Pre-Edit Snapshot" with rollback instructions
2. **Create new version**: Write `{mode}-v{N+1}.md` with all approved changes applied. Version increments once per run (not per proposal). Original version preserved unchanged.
3. **Log evolution**: Append one JSON object per approved proposal to `docs/retros/evolution-log.jsonl`. See `./references/evolution-protocol.md` for schema.

## Phase 5: Harness Health and Load-Bearing Audit

Assess whether each harness component still earns its cost as models improve. Every harness piece encodes an assumption about model limitations; as those limitations change, some components become pure overhead (see Anthropic harness-design blog: "assumption testing"). All output in this phase is advisory — **never auto-remove components**. The retrospective report (Phase 6) surfaces candidates; the user approves changes in Phase 4 of the *next* retrospective run, not this one.

### 5a. Usage-Driven Recommendations

See `./references/analysis-patterns.md` for criteria.

- If all tasks in recent plans pass on first round (no REWORK), recommend reducing evaluation frequency
- If "Recurring Failure Patterns" injections never improve outcomes, recommend revising intra-plan learning
- If a mode's checklist has only regression items all passing consistently, recommend spot-check mode (every 3rd batch)

### 5b. Load-Bearing Candidate Identification

Flag a component as a **removal candidate** when it satisfies any of the following across **≥3 consecutive plans**:

| Component | Removal-candidate trigger | Signal source |
|-----------|---------------------------|---------------|
| Evaluator at current intensity | Zero rework items produced | evaluation reports in plan dirs |
| Superpower Loop | Loop iterated ≤2 times (retry unused) | state file `iteration` field or plan handoff |
| Sprint contract Evaluation Criteria Preview | First-pass output PASSes every preview item | per-batch evaluation reports |
| Per-batch "Recurring Failure Patterns" injection | Empty across all batches | sprint contract preambles |
| Auto-downgrade to `light` intensity | Triggered for ≥3 consecutive plans | executing-plans handoff log |

Checklist items with zero failures are covered by Phase 3 REMOVE proposals — cross-reference here, do not duplicate.

### 5c. One-At-A-Time Disable Protocol

Select **at most one** candidate from 5b for the next plan run as a live assumption test. Disabling multiple components at once confounds cause-and-effect. Record in the retrospective report:

- Which component will be disabled
- Plan context (mode, expected task count, complexity)
- Quality delta thresholds: what outcome proves the component stays (e.g., ≥2 rework items evaluator would have caught) vs. what proves it can be permanently removed (zero missed issues across ≥3 follow-up plans)

The next retrospective reads this record in Phase 1 data collection and judges whether to promote the disable into a permanent config change (via standard ADD/REMOVE/MODIFY proposals in Phase 3).

## Phase 6: Output

Write the retrospective report to `docs/retros/retro-{date}-{topic}.md`:

1. Analysis tables (failure frequency, plateaus, never-failing, variety gaps)
2. Proposals with approval status
3. Checklist versions updated (if any)
4. Harness Health section:
   - 5a usage-driven recommendations
   - 5b load-bearing candidates table
   - 5c selected one-at-a-time disable test (if any), with quality delta thresholds
5. Summary: N proposals approved, M rejected, checklists updated to version X, harness component disabled for next run (if any)

## References

- `./references/analysis-patterns.md` - Failure frequency, plateau detection, never-failing analysis, harness health criteria
- `./references/evolution-protocol.md` - Proposal types, thresholds, version management, evolution log schema, pre-edit snapshot
