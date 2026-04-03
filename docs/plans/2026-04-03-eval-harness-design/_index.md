# Eval Harness Design

## Context

**Original request**: Design a multi-round eval mechanism and optimization loop for the superpowers plugin, following the principles from Anthropic's harness design blog post (https://www.anthropic.com/engineering/harness-design-long-running-apps).

**Core problem**: The `superpowers-evaluator` agent has no calibration baseline — leniency bias goes undetected; executing-plans limits rework to 2 rounds without trend awareness; there is no mechanism to optimize rubrics when evaluator behavior drifts from human intent.

**Q&A history**:
- Trigger mode: fully automated closed loop (no human intervention during pipeline run)
- Golden artifacts: manually constructed known-good/bad artifacts with human-assigned baseline scores
- Architecture: pure agent pipeline (orchestrator → evaluator → bias-analyzer → rubric-optimizer)

## Discovery Results

**Existing eval infrastructure** (none in superpowers itself):
- `.research/superpowers/tests/` — skill-triggering and integration test patterns using `claude -p`
- `shadcn/evals/evals.json` — structured eval format with `{id, prompt, expected_output, expectations[]}`
- `plugin-optimizer/tests/` — Python unit tests for static validation

**Existing evaluation components in superpowers**:
- `agents/superpowers-evaluator.md` — read-only, 3 modes (design/plan/code), rubric-based 1-5 scoring
- Three separate rubric files: `brainstorming/references/evaluation-rubrics.md`, `writing-plans/references/evaluation-rubrics.md`, `executing-plans/references/evaluation-rubrics.md`
- `evaluation-round-{N}-batch-{M}.md` naming convention already established
- `sprint-contract-batch-{N}.md` contract format established
- Max 2 rework rounds enforced in executing-plans (no trend awareness)

**Gap summary**:
- No golden artifact test set
- No evaluator calibration pipeline
- No score trend tracking across rounds
- No rubric optimization feedback loop

## Requirements

### CAL — Evaluator Calibration

- **CAL-1**: Maintain golden artifacts: manually authored design/plan/code outputs with human baseline scores per rubric dimension
- **CAL-2**: Compare evaluator scores against human baseline; compute per-dimension score delta
- **CAL-3**: Absolute per-dimension delta > 1.0 = bias event (positive = leniency, negative = severity)
- **CAL-4**: Produce calibration report per run with per-artifact, per-dimension deltas and bias classification
- **CAL-5**: Detect systematic bias patterns (dimension consistently receiving higher/lower scores across all artifacts)
- **CAL-6**: Support all three evaluator modes independently; each has its own golden artifact set

### TRD — Score Trend Tracking

- **TRD-1**: Executing-plans rounds MUST persist per-task scores across rounds in `evaluation-history.json`
- **TRD-2**: Each entry records: round, batch, task ID, per-dimension scores, verdict, timestamp
- **TRD-3**: Compute trend per task after each round: `improving` / `plateau` / `declining`
- **TRD-4**: Surface trend data in Phase 4 feedback alongside verification evidence
- **TRD-5**: `plateau` on a REWORK task for 2 consecutive rounds triggers escalation (not a third rework)
- **TRD-6**: `evaluation-history.json` lives in the plan directory; NOT committed by default

### OPT — Rubric Optimization

- **OPT-1**: `eval-rubric-optimizer` reads calibration reports and proposes concrete rubric amendments
- **OPT-2**: Amendments are dimension-specific: may revise score descriptions, thresholds, example indicators
- **OPT-3**: All amendments MUST be presented to the user for approval before any rubric file is modified
- **OPT-4**: Optimizer records rationale for each amendment in calibration report
- **OPT-5**: Optimizer MUST NOT violate `fail-ceiling < rework-floor <= pass` threshold invariant
- **OPT-6**: Rubric optimization is advisory only — no auto-apply without user approval

### ART — Golden Artifact Structure

- **ART-1**: Store under `superpowers/eval-harness/golden/{design,plan,code}/`
- **ART-2**: Each artifact set: artifact files + co-located `human-scores.json`
- **ART-3**: Include both high-quality (expected PASS) and low-quality (expected REWORK/FAIL) examples per mode
- **ART-4**: `human-scores.json` is manually authored — never AI-generated
- **ART-5**: Content is synthetic — not derived from real project work
- **ART-6**: Each artifact directory includes `manifest.json` (name, mode, quality tier only); `expected_verdict` lives exclusively in `human-scores.json` — it is the authoritative source for verdict accuracy computation

### AGT — Agent Pipeline

- **AGT-1**: `eval-orchestrator` coordinates: load artifacts → invoke evaluator → collect scores → invoke bias-analyzer → conditionally invoke rubric-optimizer
- **AGT-2**: `superpowers-evaluator` reused unchanged; spawned against each golden artifact directory
- **AGT-3**: `eval-bias-analyzer` is a new read-only agent; reads `human-scores.json` + evaluator output, computes deltas
- **AGT-4**: `eval-rubric-optimizer` proposes amendments; gains Write access only after user approval
- **AGT-5**: Pipeline runs sequentially (evaluator → bias-analyzer → rubric-optimizer)
- **AGT-6**: Orchestrator supports `--mode` flag (`design` | `plan` | `code` | `all`)
- **AGT-7**: Orchestrator supports `--dry-run` flag (run through bias analysis, stop before optimization proposals)

### PLG — Plugin Integration

- **PLG-1**: Register `eval-harness` skill under `"commands"` in `plugin.json` → `/superpowers:eval-harness`
- **PLG-2**: Register `eval-orchestrator`, `eval-bias-analyzer`, `eval-rubric-optimizer` under `"agents"` in `plugin.json`
- **PLG-3**: Skill accepts: `[--mode design|plan|code|all] [--dry-run] [--apply-rubric-changes]`
- **PLG-4**: Validate golden artifact directories exist before starting; report clear setup error if missing
- **PLG-5**: Never modify existing skill/agent/rubric files without explicit user approval
- **PLG-6**: Write calibration artifacts to `eval-harness/runs/YYYY-MM-DD-HH-MM/` for audit history

### Constraints and Non-Goals

**Constraints (MUST)**:
- `superpowers-evaluator` is reused unchanged; the harness calibrates against it, not around it
- Human baseline scores in `human-scores.json` are immutable during a run
- The Superpower Loop is NOT used by `eval-harness` — it is a one-shot calibration command
- Golden artifacts are synthetic and manually curated — never AI-generated
- All file paths follow existing `docs/plans/` and `superpowers/` conventions

**Non-Goals** (explicitly out of scope):
- Automated generation of golden artifacts by AI
- CI/CD integration (no GitHub Actions, no scheduled runs)
- Cross-plugin eval infrastructure (superpowers-only)
- Real-time score adjustment during active executing-plans sessions
- Multi-user calibration consensus (single-human baseline only)
- Meta-evaluation of the eval-harness itself

## Rationale

**Why pure agent pipeline over shell + agent hybrid?**

Shell scripts add mechanical complexity that agents handle naturally: reading files, computing deltas, deciding thresholds. The `eval-bias-analyzer` needs to reason about which dimension descriptions cause leniency — that's a judgment call, not arithmetic. The `eval-rubric-optimizer` needs to propose natural language amendments — that's generative, not scripted.

Precedent: the existing `superpowers-evaluator` is already a pure agent with no shell dependencies. The new pipeline follows the same pattern.

**Why manually constructed golden artifacts over AI-generated?**

AI-generated baselines compound the problem: an AI calibrating another AI using AI-generated standards creates circular validation. Human-scored artifacts are the only ground truth. This is the "Judge or Prejudice?" research consensus: golden datasets for evaluator calibration must be human-annotated.

**Why separate modes (design/plan/code)?**

The three rubrics have completely different dimensions. A single calibration run mixing modes would obscure dimension-specific bias. The `--mode` flag enables targeted calibration after rubric changes.

## Detailed Design

### Component Overview

```
User
 │
 │ /superpowers:eval-harness [--mode X] [--dry-run]
 ▼
eval-harness skill (entry point)
 │
 │ spawns
 ▼
eval-orchestrator agent
 ├──1. reads golden artifacts (eval-harness/golden/{mode}/)
 │      ├── artifact files
 │      ├── human-scores.json
 │      └── manifest.json
 │
 ├──2. spawns (per artifact) → superpowers-evaluator (existing)
 │      └── returns: per-dimension scores + verdict
 │
 ├──3. spawns → eval-bias-analyzer
 │      reads: evaluator scores + human-scores.json
 │      computes: per-dimension deltas, bias classification
 │      returns: bias analysis + amendment triggers
 │
 ├──4. writes → runs/YYYY-MM-DD-HH-MM/calibration-report.json
 │
 └──5. [if bias detected AND NOT --dry-run]
        spawns → eval-rubric-optimizer
         reads: calibration-report.json + rubric files
         proposes: rubric amendments (no file writes yet)
         ─── AskUserQuestion: present amendments ───
         [user approves] → writes rubric files

Parallel track (executing-plans, augmented):
  Phase 3f: after each batch evaluation
    → appends to evaluation-history.json
    → computes trend per task
  Phase 4: surfaces trend in evidence block
    → plateau x2 on REWORK task → escalation
```

### Data Structures

**`human-scores.json`** — human baseline per artifact:
```json
{
  "artifact_id": "design-high-001",
  "mode": "design",
  "quality_tier": "high",
  "expected_verdict": "PASS",
  "scored_by": "Frad LEE",
  "scored_at": "2026-04-03T00:00:00Z",
  "scores": {
    "requirements_traceability": 5,
    "bdd_completeness": 4,
    "document_consistency": 5,
    "architecture_soundness": 4,
    "risk_coverage": 4
  },
  "notes": {
    "risk_coverage": "4 of 5 key risks documented with mitigations"
  }
}
```

**`calibration-report.json`** — per-run results:
```json
{
  "run_id": "2026-04-03T14-32-00",
  "mode": "design",
  "summary": {
    "total_artifacts": 3,
    "agreement_rate": 0.867,
    "bias_detected": true,
    "dominant_bias": "leniency"
  },
  "artifacts": [...],
  "bias_analysis": {
    "by_dimension": {
      "risk_coverage": { "mean_delta": 1.5, "classification": "leniency" }
    }
  },
  "rubric_amendment_proposals": [...]
}
```

**`evaluation-history.json`** — score tracking across executing-plans rounds:
```json
{
  "plan_id": "2026-04-01-auth-feature-plan",
  "rounds": [
    {
      "round": 1, "batch": 2,
      "tasks": [
        {
          "task_id": "003",
          "scores": { "correctness": 3, "completeness": 4 },
          "verdict": "REWORK",
          "trend": null
        }
      ]
    },
    {
      "round": 2, "batch": 2,
      "tasks": [
        {
          "task_id": "003",
          "scores": { "correctness": 4, "completeness": 4 },
          "verdict": "PASS",
          "trend": "improving"
        }
      ]
    }
  ],
  "escalated_tasks": []
}
```

**Bias thresholds** (defined in eval-harness skill frontmatter):
```yaml
bias_thresholds:
  leniency_trigger: 1.0
  severity_trigger: -1.0
  agreement_floor: 0.85
  verdict_accuracy_floor: 0.90
```

### File Structure

```
superpowers/
├── agents/
│   ├── superpowers-evaluator.md     # existing, unchanged
│   ├── eval-orchestrator.md         # NEW: pipeline coordinator
│   ├── eval-bias-analyzer.md        # NEW: read-only bias detection
│   └── eval-rubric-optimizer.md     # NEW: rubric amendment proposal
├── eval-harness/
│   ├── golden/
│   │   ├── design/
│   │   │   ├── design-high-001/     # known-good design
│   │   │   │   ├── _index.md
│   │   │   │   ├── bdd-specs.md
│   │   │   │   ├── architecture.md
│   │   │   │   ├── best-practices.md
│   │   │   │   ├── human-scores.json
│   │   │   │   └── manifest.json
│   │   │   └── design-low-001/      # known-bad design
│   │   │       └── ...
│   │   ├── plan/
│   │   │   ├── plan-high-001/
│   │   │   └── plan-low-001/
│   │   └── code/
│   │       ├── code-high-001/
│   │       └── code-low-001/
│   └── runs/
│       └── 2026-04-03T14-32-00/     # per-run calibration artifacts
│           └── calibration-report.json
└── skills/
    ├── eval-harness/
    │   ├── SKILL.md                 # NEW: /superpowers:eval-harness entry point
    │   └── references/
    │       └── calibration-protocol.md
    └── executing-plans/
        └── references/
            └── evaluation-file-formats.md  # augmented: add evaluation-history.json format
```

### Trend Classification Rules

Computed after each evaluation round for each task, comparing against the immediately prior round:

| Label | Condition |
|-------|-----------|
| `improving` | At least one dimension score increased by >= 1; no dimension decreased; OR task switches from REWORK to PASS |
| `plateau` | All scored dimensions identical to prior round |
| `declining` | At least one dimension score decreased vs. prior round |
| `null` | Round 1 (no prior data available) |

Escalation trigger: `plateau` on a REWORK task for **2 consecutive rounds** → invoke escalation per `blocker-and-escalation.md`.

### Success Criteria

1. Evaluator verdict agreement with human baseline >= 90% on discrimination test (PASS for high-quality, REWORK for low-quality)
2. Per-dimension absolute delta <= 1.0 for >= 85% of (artifact × dimension) pairs
3. Bias detection correctly identifies leniency/severity when mean_delta > 1.0
4. Each rubric amendment cites specific calibration evidence (artifact ID + dimension + delta)
5. Trend labels match manual inspection: improving/plateau/declining classified correctly in 100% of test cases
6. Plateau escalation triggers in 100% of cases (no silent pass-through)
7. Zero regression: post-optimization rubrics pass all existing golden artifact verdicts unchanged
8. Full `--mode all` calibration (12 artifacts minimum, per best-practices.md §Minimum viable golden set) completes within a single session without context limit

## Design Documents

- [BDD Specifications](./bdd-specs.md) - Behavior scenarios and testing strategy
- [Architecture](./architecture.md) - System architecture and component details
- [Best Practices](./best-practices.md) - Security, performance, and code quality guidelines
