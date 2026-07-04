# Design Evaluation Report — Round 1 (checklist `design-v2.md`)

**Design folder:** `/Users/FradSer/Developer/FradSer/dotclaude/docs/plans/2026-07-04-superpowers-memory-layer-design/`
**Checklist:** `docs/retros/checklists/design-v2.md` (v2)
**Mode:** design

## Method notes

- Read all four artifacts (`_index.md`, `bdd-specs.md`, `architecture.md`, `best-practices.md`) in full.
- Ran every v1+v2 check method literally (bash/grep) against the artifacts.
- Cross-checked the design's factual claims against the actual shipped `superpowers/lib/docs-index.sh` and the five skills' real `SKILL.md` files (and the sibling design's shipped `best-practices.md`) for factual accuracy, not just internal consistency.
- Applied the refute-before-PASS red-team protocol to every inferential item (all except JUST-01, SCEN-CONC-01 per the checklist's own Type designation).

## Factual cross-check (not a formal item, informs inferential judgments)

Verified against `superpowers/lib/docs-index.sh`: `validate_kind()` currently accepts only `design|plan|retro` (line 128), `default_status_for_kind()` currently maps `retro→active`/else `wip` (line 203-206), `cmd_list()`'s inline `--kind` case only allows `design|plan|retro` (line 235), `validate_status()`/`transition_allowed()`/`collapse_rows()`/`status_category()` are genuinely kind-agnostic (operate on status strings only), and `scan_folders()` has no memory loop today. All of this matches architecture.md's diff-level claims exactly. Spot-checked ~15 `SKILL.md:line` citations across all five skills — every citation lands on the correct or near-exact line, substance matches verbatim. The design's factual grounding is high-fidelity; no citation-accuracy defect found.

## Checklist Results

| Item ID | Check | Result | Evidence |
|---|---|---|---|
| JUST-01 | Design must not self-declare NOT-JUSTIFIED | PASS | `grep -nE "STATUS:.*NOT.JUSTIFIED\|DESIGN-NOT-YET-JUSTIFIED\|DESIGN-CONSIDERED-DEFERRED\|DO NOT IMPLEMENT" _index.md` → zero matches. |
| SCEN-CONC-01 | All Given clauses use specific data values | PASS | `grep -n "Given " bdd-specs.md \| grep -iE "\bsome\b\|\bvalid\b\|\bappropriate\b\|\brelevant\b"` → zero matches. Given clauses use concrete paths/statuses throughout. |
| REQ-TRACE-01 | Every requirement in `_index.md` traces into `bdd-specs.md` | **FAIL** | Requirement #20 ("MUST add a read-before step to the entry point of all five skills") is scenario-tested for only 2 of 5 skills (writing-plans Scenario 2, brainstorming Scenario 3). No scenario demonstrates the read-before step for systematic-debugging, executing-plans, or retrospective. |
| ARCH-01 | No inner-to-outer dependency described | PASS | No Clean-Architecture layering in this leaf-script extension for a dependency direction to violate; confirmed kind-agnostic status handling in the real script. |
| RISK-02 | Each mitigation specifies concrete action | PASS | No dedicated Risks/mitigation section (vacuously satisfied, same shape as the sibling design's accepted precedent for this item). |
| PERF-01 | Sync LLM call on hot paths has measured p95 | PASS | All read/write touchpoints are plain `bash docs-index.sh` calls executed inline within a skill's own turn, never a hook-spawned subprocess LLM call. |
| DECOUPLE-01 | Shared env vars/flags are single-purpose | PASS | No new guard/flag variable introduced; `CLAUDE_PROJECT_DIR`/`CLAUDE_PLUGIN_ROOT` reused unchanged for their existing single purposes. |
| AUDIT-RUN-01 | Retract triggers have a non-retrospective entry point | PASS | No new T1-style trigger system declared; memory-fact invalidation reuses the already-shipped `expired:<reason>`/retrospective-only mechanism verbatim (inherited, not newly introduced). |
| N0-NFR-01 | SC thresholds pending or anchored on N≥1 data | PASS | All numeric criteria are either pure format constraints or reused, already-cited existing thresholds (2+ REWORK rounds, 3+ failed fixes, 60-line ceiling) — no freshly-invented uncited criterion. |
| SCOPE-CREEP-01 | Bundled unrelated fixes get their own PR | PASS | The one bundled change (deleting the stray untracked `superpowers/docs/README.md`) falls under the checklist's own exception: it's in the exact same subsystem (docs-index convention) this design centrally extends. |

## Rework Items

| Item ID | File | Location | Issue | Rework Action |
|---|---|---|---|---|
| REQ-TRACE-01 | `bdd-specs.md` | Whole-file gap (no scenario counterpart to Scenarios 2/3 for 3 of 5 skills) | Requirement #20 mandates a memory read-before step at the entry point of all five skills, but only writing-plans and brainstorming have a dedicated Given/When/Then scenario exercising it. systematic-debugging, executing-plans, and retrospective's read-before steps are asserted only in Background prose and in `architecture.md`'s touchpoint table, never exercised by a scenario — a BDD-first gap. | Add 3 Gherkin scenarios demonstrating the memory read-before step firing for systematic-debugging, executing-plans, and retrospective, mirroring Scenarios 2/3. |

## Verdict

**REWORK**

1 item FAIL: `REQ-TRACE-01`. All other 9 items resolve to PASS with evidence, each surviving the refute-before-PASS red-team protocol on the inferential items. JUST-01 itself is clean, so this is a normal single-item FAIL, not the JUST-01 precedence override.
