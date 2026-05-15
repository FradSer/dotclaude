# Harness Config Reference

Operationalizes retrospective Phase 5c's **one-at-a-time disable protocol** so
that a selected harness component is *actually* skipped by the next plan run,
instead of being a recommendation that no downstream skill reads.

## File

Path: `docs/retros/harness-config.json`

Written by: `retrospective` skill (Phase 5c)
Read by: `executing-plans` skill (Phase 1, Phase 3 step 0, Phase 4 step 2), `brainstorming` skill (Phase 1.5)

This file is the **only** place where a harness component can be non-default.
Skills that do not find the file fall back to the standard (all-components-on)
configuration — the file is not required to exist.

## Schema

```json
{
  "version": 1,
  "disabled_components": [
    {
      "component": "evaluator_per_batch",
      "started_at": "2026-04-24T10:00:00Z",
      "retrospective_id": "docs/retros/retro-2026-04-24-evaluator-cost.md",
      "rationale": "Zero rework items across 4 consecutive plans; testing removal per Phase 5b load-bearing criteria",
      "reinstate_conditions": "≥1 missed issue in any follow-up plan, verified against the current code-v{N}.md checklist"
    }
  ]
}
```

### Field semantics

| Field | Type | Notes |
|-------|------|-------|
| `version` | integer | Currently `1`. Bump on schema break. |
| `disabled_components[]` | array | Empty or missing = all components on (default). |
| `component` | string | Identifier below. |
| `started_at` | ISO 8601 | When the disable test began (retrospective timestamp). |
| `retrospective_id` | path | The retrospective report that authorized the disable. |
| `rationale` | string | Why (Phase 5b evidence). |
| `reinstate_conditions` | string | What outcome would roll the test back before next retrospective. Used by next retrospective's Reader. |

### Supported component identifiers

| Identifier | Effect when listed | Consumer (file + step) |
|-----------|---------------------|----------|
| `evaluator_per_batch` | executing-plans Phase 3 skips the superpowers-evaluator (Code mode) spawn. Sprint contract and verification gate still run. | `executing-plans/SKILL.md` Phase 1 step 4 + Phase 3 step 2 (Spawn Batch Coordinator, item 8 — Evaluator instruction) |
| `sprint_contract_preview` | executing-plans omits the "Evaluation Criteria Preview" section from sprint contracts. | `executing-plans/SKILL.md` Phase 3 step 0 |
| `recurring_failure_patterns` | executing-plans Phase 4 skips the pattern-scan injection into the next sprint contract preamble. | `executing-plans/SKILL.md` Phase 4 step 2 |
| `design_evaluator` | brainstorming Phase 2 skips the superpowers-evaluator (design mode). Sub-agent research still runs. | `brainstorming/SKILL.md` Phase 1.5 + Phase 2 Step 2 |

Every supported identifier above MUST have a corresponding `if-disabled` branch in its consumer; new identifiers cannot be added to this table without landing the consumer-side check first.

**Removed / deferred identifiers (do NOT propose):**

| Identifier | Why removed |
|-----------|---|
| `context_reset_coordinator` | The "main agent runs batches directly" alt-path was too large to land safely (would require inlining the entire batch-execution-playbook into the main agent). Re-introduce only after a dedicated design pass. Retrospective Phase 5c MUST refuse this identifier; if selected, log an observation `component_unsupported` and rewrite `harness-config.json` with an empty `disabled_components[]`. |
| `plan_evaluator` | Plan-mode evaluator was permanently removed in 2.6.0. writing-plans Phase 4 sub-agent reflection covers the same structural checks (BDD coverage, dependency graph, task completeness); unaddressed sub-agent FAILs are fixed in Phase 4 step 3 before the Phase 5 commit. Retrospective Phase 5c MUST refuse this identifier; if selected, log `component_unsupported` and rewrite `harness-config.json` with an empty `disabled_components[]`. |

Any identifier not in the supported table is treated as unknown — the consuming skill
logs an observation (`component_unknown`) and proceeds with the full pipeline.

## Lifecycle

```
Retrospective run R_k
  └─► Phase 5b identifies removal candidate
        └─► Phase 5c writes harness-config.json with one entry
              │
              ▼
Plan P_{n+1} runs
  └─► Consuming skill reads harness-config.json
        ├─► Disables the named component
        └─► Appends a harness_observation entry to
            docs/retros/harness-observations.jsonl
              │
              ▼
Plan P_{n+2}, P_{n+3}, ... (if user runs more before next retrospective)
  └─► Same disable still in effect; more observations accumulate
              │
              ▼
Retrospective run R_{k+1}
  └─► Phase 1 reads observations for the disabled component
        └─► Phase 3 proposes:
              ├─► REMOVE (promote) if no reinstate condition hit
              └─► REINSTATE if reinstate condition hit
        └─► Phase 5c overwrites harness-config.json
              (empty disabled_components = fully reset)
```

## Constraints

- **At most one entry** in `disabled_components[]`. The protocol is deliberately
  one-at-a-time so cause-and-effect is not confounded. Retrospective Phase 5c
  refuses to write more than one entry in a single run.
- **Overwrite, never append.** Each retrospective Phase 5c rewrites the file
  from scratch. There is no history in this file — history lives in
  `evolution-log.jsonl` and retrospective reports.
- **Empty = default.** An empty `disabled_components[]` array is equivalent to
  the file not existing. Retrospective Phase 5c writes an empty array to
  signal "test complete, all components on again".
- **Never read this file to modify checklists.** Checklist changes go through
  the standard ADD/REMOVE/MODIFY proposal flow in Phase 3.

## Writing the file

From the retrospective skill (Phase 5c):

```bash
mkdir -p docs/retros
cat > docs/retros/harness-config.json <<'JSON'
{
  "version": 1,
  "disabled_components": [
    {
      "component": "<identifier>",
      "started_at": "<ISO 8601 UTC>",
      "retrospective_id": "<path to retro report>",
      "rationale": "<why>",
      "reinstate_conditions": "<what rolls this back>"
    }
  ]
}
JSON
```

Write an empty disable test as:

```json
{"version":1,"disabled_components":[]}
```

## Reading the file

Consuming skills use this check (no component listed = no disable):

```bash
if [[ -f docs/retros/harness-config.json ]]; then
  disabled=$(jq -r \
    --arg c evaluator_per_batch \
    '.disabled_components[]? | select(.component == $c) | .component' \
    docs/retros/harness-config.json 2>/dev/null)
fi
```

If `$disabled` is non-empty, the skill skips the corresponding step AND appends
a `harness_observation` entry (see
`../../executing-plans/references/intra-plan-learning.md`).
