# Evaluation Report — Design Round 1

**Design folder:** `/Users/FradSer/Developer/FradSer/dotclaude/docs/plans/2026-05-09-knowledge-platform-design/`
**Checklist:** `/Users/FradSer/Developer/FradSer/dotclaude/docs/retros/checklists/design-v1.md`
**Artifacts evaluated:** `_index.md`, `architecture.md`, `bdd-specs.md`, `best-practices.md`
**Evaluator:** `superpowers:superpowers-evaluator` (design mode) + main-agent inline cross-check

## Checklist Results

| Item ID | Check | Result | Evidence |
|---|---|---|---|
| SCEN-CONC-01 | All Given clauses use specific data values | **PASS** | `grep -n "Given " bdd-specs.md \| grep -iE "\bsome\b\|\bvalid\b\|\bappropriate\b\|\brelevant\b"` returns zero matches. Spot-verified Given clauses use concrete values: `bdd-specs.md:24` "Given the most recent plans-completed.jsonl entry is older than 1h"; `bdd-specs.md:33` "Given the user is on a branch matching pattern \"exp/*\""; `bdd-specs.md:60` "Given Phase 1 retract gate has passed (≥1 read per Phase 1 component across N=3 projects)"; `bdd-specs.md:97` "pattern_id=\"PAT-007\", privacy_tier=\"cross-project\""; `bdd-specs.md:255` "Given a Source B row contains \"AWS_SECRET_ACCESS_KEY=AKIA...\"". All 25 scenarios use concrete identifiers, file paths, counts, and timestamps. |
| REQ-TRACE-01 | Every requirement ID in _index.md appears in at least one scenario in bdd-specs.md | **FAIL** | `grep -oE "REQ-[0-9]+" _index.md` returns empty (no `REQ-NNN` IDs are used; the design uses `FR-NN`/`NFR-NN`/`SC-NN`). Treating those as the design's actual requirement IDs: _index.md defines 28 IDs (FR-01..FR-15, NFR-01..NFR-08, SC-01..SC-05); bdd-specs.md only references 4 by literal ID string (`FR-10`, `FR-15`, `NFR-04`, `SC-05`). 24 requirement IDs (FR-01..09, FR-11..14, NFR-01..03, NFR-05..08, SC-01..04) have no verbatim ID reference in any scenario. Per the checklist's anchor constraint ("requirements must be explicitly traceable by ID, not inferred by topic"), topical coverage is insufficient — emit FAIL. |
| ARCH-01 | No imports or dependencies described from inner layer to outer layer | **PASS** | `grep -iE "domain.*(infra\|infrastructure\|presentation\|CLI\|database\|http\|api\|handler)"` returns zero matches; `grep -iE "application.*(infra\|infrastructure\|presentation\|CLI\|database\|http\|handler)"` returns one candidate at `architecture.md:206` ("Personal Knowledge Graphs in AI RAG-powered Applications with libSQL"), which is a Sources hyperlink title, not a dependency description. Architecture explicitly classifies the knowledge layer as infrastructure with skills depending on a narrow port (`best-practices.md:98-105`). No inner-to-outer dependency described. |
| RISK-02 | Each risk mitigation in _index.md specifies a concrete action | **PASS** | `grep -n -iE "mitigation\|mitigate" _index.md` returns zero matches; _index.md contains no Risks/Mitigations section. The literal check method is satisfied with zero matches → PASS. Note: absence of a dedicated risks section is a structural observation (the design embeds risk-handling in §Rationale Path A/C rejections and the three architectural laws), but the checklist as written only fires when vague mitigation verbs are present. |

## Rework Items

| Item ID | File | Location | What failed | Corrective action |
|---|---|---|---|---|
| REQ-TRACE-01 | bdd-specs.md | All scenarios across §1-§8 | 24 of 28 requirement IDs (FR-01..09, FR-11..14, NFR-01..03, NFR-05..08, SC-01..04) declared in `_index.md` are not referenced verbatim by any scenario in `bdd-specs.md`. Topical coverage exists (e.g. FR-13 read_count semantics is described in §1 capture scenarios; NFR-02 sanitizer is in §7) but no scenario carries the literal ID string. | For each unreferenced ID: either add a `# Covers: FR-NN` comment line to the scenario whose Given/When/Then steps implement it, or extend the scenario name (e.g. `Scenario: [FR-09, NFR-02] ...`). For NFRs without a current covering scenario (NFR-01 Stop-hook latency, NFR-03 backward-compat schema, NFR-07 zero-cost default, NFR-08 schema_version drift), add new scenarios. Alternatively, normalize the requirement ID scheme to `REQ-NNN` and update both `_index.md` and `bdd-specs.md` so the checklist's literal grep matches. |

## Verdict: **REWORK**

**FAIL count:** 1 (REQ-TRACE-01)
**Failed item IDs:** REQ-TRACE-01

## Focused Observations

### Compliance with the three hard architecture rules (Path 3)

- **Rule 1 — Meta-recursive calibration**: Implemented concretely in `architecture.md` Law 1 and §5 Per-Component Retract Gates with explicit T1-T4 per component, and exercised by `bdd-specs.md` §5 Rule 1 scenarios. Scenarios explicitly assert "NEVER auto-disabled per meta-retro R1" and only surface candidates via `AskUserQuestion`. **Compliant.**
- **Rule 2 — Privacy tier explicit**: `architecture.md` §6 provides a 4×4 source/target tier matrix with `auto`/`opt-in`/`block` cells, plus explicit architectural blocks (B→local-only, D→cross-project). `bdd-specs.md` §5 Rule 2 codifies opt-in flows; `best-practices.md` §1 requires physical separation on disk. **Compliant.**
- **Rule 3 — Phase-gated rollout**: `architecture.md` §4 defines per-phase retract gates with concrete T1-T4 thresholds; `bdd-specs.md` §5 Rule 3 codifies `phase_advance_refused` / `phase_advanced` events. `_index.md` §Detailed Design declares Phase 0..3 cumulative structure with each gate keyed to ≥3-project read-rate evidence. **Compliant.**

All three Path-3 anchors are respected and traceable into BDD scenarios. The architecture is structurally consistent with the v2.8.x meta-retro lessons it cites.

### Risk of repeating v2.8.x add-bias failure

Structural defenses internalized:

- `best-practices.md` §3 proposes a hard PR rule for inserted:deleted ratio >10:1 in `superpowers/`.
- `best-practices.md` §4 mandates ≥1 real-project dogfood between superpowers commits.
- `best-practices.md` §5 enforces "at most one level of meta" — guard against calibration-of-calibration recursion.
- `architecture.md` §7 Q-RETRACT-OF-PLATFORM contemplates platform-level retraction if ≥3 Phase 1 components trip simultaneously.
- `_index.md` §Rationale explicitly maps each Path-3 architectural rule to a v2.8.x failure mode it neutralizes.

Residual risk:

- **Scope size**: ~3-5 new skills + ~3-5 new lib scripts + ~3 new jsonl channels + ~2-3 new schemas. v2.8.x meta-retro identified ~1,479 net inserted lines as the failure scale; v3.x's projected delta is comparable in line count even with rigorous gating. Phase-gate enforcement is the load-bearing brake.
- **Open Questions count**: 5 open Qs in architecture.md + 4 in bdd-specs.md. Each unresolved Q is a future opportunity for add-bias if resolved by "let's add a config field". Recommend resolving Q-CAPTURE-MODE, Q-CONSENT-UI, Q-KG-SCHEMA in the writing-plans phase before any code lands.
- **REQ-TRACE-01 FAIL itself is mild add-bias risk**: 28 requirements with only 4 referenced verbatim in scenarios suggests requirements may exist that no scenario actually tests; uncovered requirements drift toward "implement and hope" — a classic add-bias entry point. Fixing the traceability gap is the highest-leverage rework action.

The design is structurally well-defended; the FAIL is a documentation/traceability gap, not a Path-3 rule violation. After REQ-TRACE-01 rework, the design appears unlikely to repeat the v2.8.x spiral.
