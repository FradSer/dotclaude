# Design Evaluation Report — Round 2 (checklist `design-v2.md`)

**Design folder:** `/Users/FradSer/Developer/FradSer/dotclaude/docs/plans/2026-07-04-superpowers-memory-layer-design/`
**Checklist:** `docs/retros/checklists/design-v2.md` (v2)
**Mode:** design

## Method notes

- Read all four artifacts fresh in full — did not reuse round 1's cached judgments.
- Ran every v1+v2 check method literally against the current artifacts (not just re-checked `REQ-TRACE-01`).
- Applied the refute-before-PASS red-team protocol to every inferential item.
- Specifically hunted for regressions the round-1→round-2 `bdd-specs.md` edit might have introduced elsewhere in the same file.

## Checklist Results

| Item ID | Check | Result | Evidence |
|---|---|---|---|
| JUST-01 | Design must not self-declare NOT-JUSTIFIED | PASS | Zero matches for NOT-JUSTIFIED-style markers. |
| SCEN-CONC-01 | All Given clauses use specific data values | **FAIL** | `bdd-specs.md:108` (round-1-fix version) — `Given the index contains one active memory entry relevant to the symptom` matched the vague qualifier `\brelevant\b`. Regression introduced by the round-1 fix's bail-out-skip scenario; its positive-path sibling correctly used a concrete table. |
| REQ-TRACE-01 | Every requirement in `_index.md` traces into `bdd-specs.md` | **FAIL** | Requirement #20 (read-before, all five skills) is now fully closed by Scenarios 2, 3, 3a-3c. But requirement #23 (Phase 3 promoting a Pre-Check-B-recalled global-memory prior into a memory file, citing the originating hook) had zero scenario coverage — Scenario 8 covers a disjoint mechanism (promoting retrospective's own ADD/MODIFY findings), not the Pre-Check-B bridge described only in `architecture.md` §4 prose. |
| ARCH-01 | No inner-to-outer dependency described | PASS | No Clean-Architecture layering to violate in this leaf-script extension. |
| RISK-02 | Each mitigation specifies concrete action | PASS | No dedicated Risks/mitigation section; vacuously satisfied. |
| PERF-01 | Sync LLM call on hot paths has measured p95 | PASS | All touchpoints are plain `bash docs-index.sh` calls inline in a skill's own turn. |
| DECOUPLE-01 | Shared env vars/flags are single-purpose | PASS | Only nominal grep hit is a false positive (filename substring); no genuine shared-guard candidate. |
| AUDIT-RUN-01 | Retract triggers have a non-retrospective entry point | PASS | No new trigger system; reuses the already-shipped `expired:<reason>` mechanism verbatim. |
| N0-NFR-01 | SC thresholds pending or anchored on N≥1 data | PASS | Every numeric criterion is a format constraint or a cited, reused existing threshold. |
| SCOPE-CREEP-01 | Bundled unrelated fixes get their own PR | PASS | The one bundled change (deleting stray `superpowers/docs/README.md`) is in the same subsystem this design extends. |

## Rework Items

| Item ID | File | Location | Issue | Rework Action |
|---|---|---|---|---|
| SCEN-CONC-01 | `bdd-specs.md` | Line 108 (pre-fix) | Vague "relevant to the symptom" Given clause in the systematic-debugging bail-out-skip scenario, unlike its positive-path sibling's concrete table. | Replace with a concrete path/kind/status table. |
| REQ-TRACE-01 | `bdd-specs.md` (missing scenario) | Requirement #23 / `architecture.md` §4 | The Pre-Check-B-recall-to-memory promotion bridge had no Gherkin scenario — documented only in prose. | Add a scenario distinct from Scenario 8, covering a Pre-Check-B-recalled hook being promoted into a memory file with provenance recorded, and a cross-project stance explicitly NOT promoted. |

## Verdict

**REWORK**

2 items FAIL: `SCEN-CONC-01` (regression introduced by the round-1 fix), `REQ-TRACE-01` (a distinct, previously-unflagged gap on requirement #23, separate from round 1's #20 gap which is now closed). All other 8 items PASS with evidence. `JUST-01` is clean, so this is two independent item-level FAILs, not the JUST-01 precedence override.

## Fixes applied (round 2 → round 3)

- `bdd-specs.md`: the systematic-debugging bail-out-skip scenario's Given clause now names a concrete `docs/memory/pitfall_repo-root-fallback-wrong-project.md` entry and a concrete `$ARGUMENTS` string, replacing "relevant to the symptom."
- `bdd-specs.md`: added "retrospective promotes a recalled global-memory prior into a project-local memory file" (Scenario 8a) — covers requirement #23's Pre-Check-B bridge with a concrete hook name/claim, the `## Why` provenance line, and an explicit negative case (a cross-project stance is NOT promoted).
