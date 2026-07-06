# Design Evaluation Round 5

**Design folder:** `docs/plans/2026-07-06-agentbook-memory-design/`
**Checklist:** `docs/retros/checklists/design-v2.md` (extends `design-v1.md`)

## Checklist Results

| Item ID | Result | Evidence summary |
|---|---|---|
| JUST-01 | PASS | No NOT-JUSTIFIED marker. |
| SCEN-CONC-01 | PASS | No vague `Given` clauses. |
| REQ-TRACE-01 | **FAIL** | 13 of 21 requirements (#2, #4-#10, #12-#15, #17) covered only by topical scenario match, not explicit `(Req #N)` ID citation. |
| ARCH-01 | PASS | No Clean Architecture inversion applicable. |
| RISK-02 | **FAIL** | No dedicated `## Risks` section exists despite a real risk surface (credential leakage, malicious-recall execution, irrevocable CC0 publication, rate-limit exhaustion, dependency-resolution assumption) — individual mitigations exist as scattered MUST items but are not consolidated into an auditable risk register. |
| PERF-01 | PASS | No hook-critical-path LLM/network call. |
| DECOUPLE-01 | PASS | Env vars single-purpose. |
| AUDIT-RUN-01 | PASS | No retract-trigger system; publish gate is a one-way, human-confirmed forward gate, not a retract mechanism. |
| N0-NFR-01 | PASS | Numeric thresholds all externally sourced. |
| SCOPE-CREEP-01 | PASS | Touched subsystems are stated in-scope. |

## Rework Items

| Item ID | File | Location | Issue | Rework Action |
|---|---|---|---|---|
| REQ-TRACE-01 | bdd-specs.md | 13 scenario/feature titles | Explicit `(Req #N)` tags missing on scenarios covering requirements #2, #4-#10, #12-#15, #17. | Add `(Req #N)` tags to each covering Scenario/Scenario Outline/Feature title. |
| RISK-02 | _index.md | new `## Risks` section | No consolidated, auditable risk register exists. | Add a `## Risks` section pairing each concrete risk with its existing mitigation (most already exist as scattered MUST items). |

## Verdict: REWORK

2 items FAIL: REQ-TRACE-01, RISK-02. Note: `_index.md` never uses the literal `REQ-NNN` format the checklist's own mechanical grep script (`grep -oE "REQ-[0-9]+" _index.md`) assumes — applied literally, that script would find zero IDs and vacuously pass, matching two other shipped designs in this repo's precedent (`2026-07-04-superpowers-memory-layer-design`, `2026-07-04-docs-index-design`) that also use a plain numbered list. This round applies a stricter, ID-tag-based reading than that literal script or established precedent would require. The fixes below are applied regardless, since explicit ID tags and a consolidated risk register are genuine, low-cost readability/auditability improvements independent of whether they were strictly required.
