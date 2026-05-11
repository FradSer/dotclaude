# evaluation-design-round-2.md

**Design folder**: `docs/plans/2026-05-09-harness-evidence-channel-design/`
**Checklist**: `docs/retros/checklists/design-v2.md` (v2; v1 items retained + 5 new items)
**Round**: 2
**Date**: 2026-05-10
**Reason for re-evaluation**: round-1 passed under v1 checklist (`evaluation-design-round-1.md`), but a follow-on ultrathink review surfaced 8 concerns that v1 could not catch. The design was rewritten to address them; v2 checklist was authored to capture the 5 new failure modes structurally; this round re-evaluates the rewritten design against the new checklist.

## Checklist Results

### v1 items (retained)

| Item ID | Check | Result | Evidence |
|---|---|---|---|
| JUST-01 | `grep -nE "STATUS:.*NOT.JUSTIFIED\|DESIGN-NOT-YET-JUSTIFIED\|DESIGN-CONSIDERED-DEFERRED\|DO NOT IMPLEMENT" _index.md` | PASS | Zero matches (rc=1). Cross-references to the v3 retro's `DESIGN-CONSIDERED-DEFERRED` status remain about that *sibling* file, not this design's own status. |
| SCEN-CONC-01 | `grep -n "Given " bdd-specs.md \| grep -iE "\bsome\b\|\bvalid\b\|\bappropriate\b\|\brelevant\b"` | PASS | Zero matches (rc=1). All Givens use concrete values (`HARNESS_EVIDENCE_NOW="2027-05-09T00:00:00Z"`, `100 session_recap rows of which 6 have fallback=true` is gone post-pivot but the surviving Givens are equally concrete: `5 session_recap rows after T0`, `event="ad_hoc_capture"`, etc.). |
| REQ-TRACE-01 | Extract REQ-NNN from `_index.md`; verify each appears in `bdd-specs.md` | PASS | 12 IDs (REQ-001..REQ-012). All 12 trace to scenarios in `bdd-specs.md`. Coverage map at `bdd-specs.md:11-24`. |
| ARCH-01 | Inner-to-outer dependency grep | PASS | rc=1 on both `domain.*(infra...)` and `application.*(infra...)`. Architecture is pure shell/lib — Clean Architecture layer language not directly applicable. Hook-chain ordering `loop_phase → emit_session_recap → vet_phase` is sequential within Stop hook; no inner-to-outer violations. |
| RISK-02 | Vague-verb grep in mitigation cells | PASS | rc=1. Every mitigation row starts with a concrete verb: "prints a verbatim warning instructing user to add ... to `.gitignore`", "Reader falls back to 'process all rows'", "CI test asserts the allowlist constant by string equality", "Writer truncates to 500 bytes via `${var:0:500}`". |

### v2 new items

| Item ID | Check | Result | Evidence |
|---|---|---|---|
| PERF-01 | Stop-hook / hot-path LLM call must have measured p95, "no LLM" assertion, or spike-branch reference | PASS | 8 candidate lines found across `_index.md` and `architecture.md`. Each candidate is gated by one of: (a) "No LLM call" assertion within 3 lines (`_index.md:11`, `_index.md:74`, `architecture.md:158`); (b) explicit "upper-bounded by `bail-log.sh`'s measured behavior" citation (`_index.md:85`, `architecture.md:158`); (c) historical reference inside Rationale row C-v0 documenting the rejection of the round-1 Sonnet@stop-hook design — explicitly a rejected option, not a current claim. The post-pivot writer makes zero LLM calls at write-time. |
| DECOUPLE-01 | Shared env-var guards must be single-purpose or have documented split | PASS | `SUPERPOWERS_SUBSESSION` (umbrella) and `SUPERPOWERS_MERGE_SESSION` (per-purpose Haiku-merge, legacy compat) are explicitly named with their roles. `architecture.md:13` documents the umbrella choice; `best-practices.md:127` documents the pair and the backward-compat window; `superpowers/TODO-v3.md` T-003 owns the migration deadline. |
| AUDIT-RUN-01 | Retract triggers must have independent CLI/cron entry point | PASS | `bash superpowers/lib/harness-evidence.sh audit` is the dedicated entry (REQ-009 in `_index.md:87`; full spec in `architecture.md:75-95`; gherkin coverage in `bdd-specs.md` Feature: Audit CLI section). Retrospective Phase 1 step 8 shells out to it rather than duplicating logic (`architecture.md:173`). T5 (writer-reliability) explicitly retired because the writer has no fallible LLM path. |
| N0-NFR-01 | Numeric thresholds must be pending or anchored on N≥1 data | PASS | REQ-010 explicitly marked "pending N=1 observation" with target file `evaluation-data-week-1.md` and start date = implementation-merge (`_index.md:91`). REQ-007 ≤ 20 ms p95 is "upper-bounded by `bail-log.sh`'s measured behavior, not a new estimate" (`_index.md:85`). REQ-008 sizing estimates (~13 KB/day, ~5 MB/year, 50 MB rotation trigger) are operational rotation thresholds anchored by YAGNI rationale ("revisit only if a project hits 50 MB"), not SC thresholds. T3 calendar date (2027-05-09) is anchored 1 year from the design date as documented in v3 retro §6 T3 row, matching the established trigger calendar. |
| SCOPE-CREEP-01 | Discoveries fixing unrelated subsystems must extract to sibling PR | PASS | The four brainstorming SKILL.md changes are recorded in `docs/plans/2026-05-10-brainstorming-vocab-reform-retro.md` (sibling file owns them). Both `_index.md:150` and `architecture.md:215` carry one-line cross-references rather than enumerated lists. The v3 retro reconciliation patches (`architecture.md` §D) are in-scope because they patch the file that explicitly references this design's deliverable — same-subsystem coupling, not creep. |

## Rework Items

(none)

## Verdict

**PASS** — 10/10 items pass. Zero FAIL count.

The design is ready to proceed to implementation under the v2 checklist. The post-round-1 pivot (Sonnet out of Stop-hook critical path, audit CLI, writer-side allowlist enforcement) and the v2 checklist additions (PERF-01, DECOUPLE-01, AUDIT-RUN-01, N0-NFR-01, SCOPE-CREEP-01) together neutralize the five blind spots that round 1 missed. `superpowers:writing-plans` can begin.

## Notes for downstream

- **Implementation plan must cite `evaluation-data-week-1.md`** as a tracked artifact. REQ-010 is unmet by construction until that file exists at week 1 of N=1 dogfooding.
- **Implementation plan must include the audit CLI test fixture** (`bash harness-evidence.sh audit` with mocked `HARNESS_EVIDENCE_NOW`) — without it, AUDIT-RUN-01 is structurally satisfied but operationally untested.
- **Implementation plan must NOT bundle the bail-log $PWD→git_root unification** — `superpowers/TODO-v3.md` T-001 owns that debt.
- **Implementation plan must NOT bundle the manual-write channel promotion** (`harness-observations.jsonl`, `evolution-log.jsonl`) — `superpowers/TODO-v3.md` T-002 owns it.

## Audit trail

- 2026-05-09: round-1 PASS under v1 checklist (`evaluation-design-round-1.md`)
- 2026-05-10: ultrathink review surfaced 8 concerns v1 missed; user authorized "执行 all" rework plan covering P0/P1/P2/P3 items
- 2026-05-10: design rewritten across `_index.md` / `architecture.md` / `bdd-specs.md` / `best-practices.md`; recursion guard split landed in `superpowers/lib/utils.sh` + 4 hook scripts; sibling artifacts created (`superpowers/TODO-v3.md`, `docs/plans/2026-05-10-brainstorming-vocab-reform-retro.md`, `docs/retros/checklists/design-v2.md`); v3 retro §7 ownership table filled
- 2026-05-10: this evaluation (round 2 under v2 checklist) — PASS
