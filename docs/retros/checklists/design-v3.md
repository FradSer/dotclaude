# Design Checklist

- **Version:** v3
- **Mode:** design
- **Created:** 2026-07-09
- **Extends:** `design-v2.md` — v1/v2 items retained inline (self-contained; the evaluator reads only this file). v3 modifies REQ-TRACE-01 (dual-format extraction + explicit citation + full-set scan) and retains all other v1/v2 items unchanged.
- **Provenance:** REQ-TRACE-01 MODIFY is retrospective-derived from multi-round plateaus on `2026-07-04-superpowers-memory-layer-design` (3 REWORK rounds) and `2026-07-06-agentbook-memory-design` (5 REWORK rounds). Driving report: `docs/retros/retro-2026-07-09-memory-layer-and-agentbook.md`.

## Purpose

Binary PASS/FAIL checklist for evaluating design artifacts. Each item produces a deterministic or anchored result: two independent evaluators given the same artifacts should produce the same PASS/FAIL outcome. Every FAIL must include file-referenced evidence and a specific rework action.

## Origin of v2 additions (retained)

The five v2 items (PERF-01, DECOUPLE-01, AUDIT-RUN-01, N0-NFR-01, SCOPE-CREEP-01) were added on 2026-05-10 after the harness-evidence channel design's round-1 evaluation passed v1 cleanly but a follow-on review surfaced five concerns v1 could not catch. See `design-v2.md` for the origin table.

## Origin of v3 change

REQ-TRACE-01's mechanical script grepped only `REQ-NNN`. Designs that use a plain numbered requirements list (`1.`, `#1`, `Requirement #20`) made the script vacuous-PASS (zero IDs extracted), after which independent evaluators improvised progressive stricter standards each round — topical match accepted, then "missing scenarios for N of M skills", then "architecture-only requirements need Traceability Notes", then "every scenario title needs `(Req #N)` tags". The same umbrella item therefore produced 3 consecutive REWORK rounds on memory-layer design and 5 consecutive REWORK rounds on agentbook design, each round finding a *new* gap rather than confirming the prior fix. v3 closes that thrash by (a) extracting both `REQ-NNN` and numbered-list IDs, (b) requiring an explicit citation form in `bdd-specs.md` on the first pass, and (c) mandating a full-set scan (not incremental gap-finding).

## Artifacts Under Evaluation

- `_index.md` -- plan overview, requirements, risks
- `bdd-specs.md` -- Gherkin scenarios
- `architecture.md` -- system architecture and layer descriptions
- `best-practices.md` -- coding and design standards

---

## v1 Checklist Items (check methods inline; full descriptions in `design-v1.md` except REQ-TRACE-01 which is fully restated below)

### JUST-01: Design must not self-declare NOT-JUSTIFIED

**Check method:**
```bash
grep -nE "STATUS:.*NOT.JUSTIFIED|DESIGN-NOT-YET-JUSTIFIED|DESIGN-CONSIDERED-DEFERRED|DO NOT IMPLEMENT" _index.md
```
Any match → FAIL. Zero matches → PASS.

**Verdict precedence:** JUST-01 FAIL ⇒ REWORK regardless of other items.

### SCEN-CONC-01: All Given clauses use specific data values

**Check method:**
```bash
grep -n "Given " bdd-specs.md | grep -iE "\bsome\b|\bvalid\b|\bappropriate\b|\brelevant\b"
```
Any match → FAIL.

### REQ-TRACE-01: Every requirement in `_index.md` is explicitly cited in `bdd-specs.md`

**Description:** Every requirement listed in the Requirements section of `_index.md` must be explicitly cited in `bdd-specs.md` by ID — either in a scenario/feature title, a Given/When/Then step, a comment, or a Traceability Notes block. Topical scenario naming alone is insufficient. Citation form depends on how `_index.md` labels requirements:

| `_index.md` form | Required citation in `bdd-specs.md` |
|---|---|
| `REQ-NNN` (e.g. `REQ-015`) | the literal `REQ-NNN` string |
| Numbered list (`1.`, `#1`, `Requirement #20`, `Item 12`) | `(Req #N)` or `Req #N` (N matching the number) |

Architecture-only / non-behavioral requirements that have no natural Given/When/Then shape may be cited in a Traceability Notes prose block rather than a scenario, but the ID string must still appear verbatim.

**Check method (full-set scan — run once per evaluation round, never incrementally):**
```bash
python3 - <<'PY'
from pathlib import Path
import re, sys

index = Path("_index.md").read_text()
bdd = Path("bdd-specs.md").read_text()

# 1. Prefer REQ-NNN when present.
req_nnn = sorted(set(re.findall(r"REQ-\d+", index)))
if req_nnn:
    missing = [r for r in req_nnn if r not in bdd]
    for r in missing:
        print(f"FAIL: {r} absent from bdd-specs.md")
    sys.exit(0 if not missing else 1)

# 2. Fall back to numbered requirements in a Requirements section.
#    Accept forms: "1.", "1)", "#1", "Requirement #1", "Req #1", "Item 1".
req_section = re.search(
    r"(?is)##+\s*Requirements?\b(.*?)(?=^##+\s|\Z)", index
)
body = req_section.group(1) if req_section else index
nums = sorted(set(
    int(n) for n in re.findall(
        r"(?m)^\s*(?:#{0,3}\s*)?(?:Requirement|Req|Item)?\s*#?(\d+)[\.:)\]]",
        body,
    )
))
if not nums:
    print("FAIL: no REQ-NNN and no numbered requirements extracted from _index.md")
    sys.exit(1)

missing = []
for n in nums:
    # Accept "(Req #N)", "Req #N", "REQ-N" zero-padded variants are NOT required.
    if not re.search(rf"(?i)(?:\(|\b)Req(?:uirement)?\s*#{n}\b", bdd) and f"REQ-{n:03d}" not in bdd and f"REQ-{n}" not in bdd:
        missing.append(n)
for n in missing:
    print(f"FAIL: requirement #{n} has no explicit citation in bdd-specs.md")
sys.exit(0 if not missing else 1)
PY
```
Any `FAIL:` line → item FAIL. Empty output + exit 0 → PASS.

**Anchor constraint:**
- Topical scenario match without an explicit ID citation is FAIL (the v3 change — do not accept "the scenario is obviously about requirement 15").
- A Traceability Notes block that lists `Req #N` for architecture-only requirements is PASS for those IDs.
- Evaluators MUST run the full-set scan above on every round. Finding one missing ID and stopping is a protocol violation that recreated the multi-round thrash this MODIFY closes — close every missing ID in one rework list.
- When `_index.md` mixes both forms, prefer the REQ-NNN branch (step 1) and additionally scan numbered-only items that lack a REQ-NNN alias.

**Evidence format:** `requirement ID + absence note`
Example: `requirement #15 has no explicit citation in bdd-specs.md (no "(Req #15)" / "Req #15" / "REQ-015")`

**Rework format:** "Add `(Req #15)` to the covering Scenario/Feature title, or add `Req #15` to the Traceability Notes block if the requirement is architecture-only. Re-run the full-set scan and fix every remaining missing ID in the same pass."

`# Type: computational` when IDs are well-formed and the script exits cleanly; falls to `# Type: inferential` only when the Requirements section is free-prose with no extractable IDs (that case is itself a FAIL — renumber or adopt REQ-NNN).

### ARCH-01: No inner-to-outer dependency described

**Check method:**
```bash
grep -n -iE "import|depend|require|reference|call" architecture.md > /tmp/arch_deps.txt
grep -iE "domain.*(infra|infrastructure|presentation|CLI|database|http|api|handler)" /tmp/arch_deps.txt
grep -iE "application.*(infra|infrastructure|presentation|CLI|database|http|handler)" /tmp/arch_deps.txt
```
Affirmative matches → FAIL. Negations/prohibitions → PASS.

### RISK-02: Each mitigation specifies concrete action

**Check method:**
```bash
grep -n -iE "mitigation|mitigate" _index.md | grep -iE "\bmonitor\b|\bhandle\b|\bmanage\b|\baddress\b|\bdeal with\b|\blook into\b|\btrack\b|\bensure\b"
```
Vague verb as the sole action → FAIL.

**Type designation:** JUST-01 and SCEN-CONC-01 are computational (deterministic grep). REQ-TRACE-01 is computational when IDs extract cleanly. ARCH-01, RISK-02, and all five v2 items below are inferential.

---

## v2 Items (retained unchanged)

### PERF-01: Synchronous LLM call on hot paths has measured p95, not estimated

**Description:** If `architecture.md` or `_index.md` describes any synchronous external-process call (LLM via `claude`, network round-trip, subprocess fork to a service) on a Stop-hook, UserPromptSubmit-hook, or PostToolUse-hook critical path, the design MUST cite a measured p95 latency number, not an estimate. The number must trace to a spike branch, a benchmark file, or an existing channel's measured behavior — never to ranges like "~600-1500 ms" with no anchor.

**Check method:**
```bash
grep -niE "(stop[- ]hook|posttooluse|userpromptsubmit).*\b(claude|sonnet|haiku|llm|gpt)\b" architecture.md _index.md > /tmp/perf_candidates.txt
```
Any candidate line without (a) a "p95" measurement with a citation, (b) an explicit "no LLM on critical path" statement nearby, or (c) a spike-branch reference within 10 lines → FAIL.

**Evidence format:** `file:line -- quoted line + missing anchor type`

**Rework format:** "Either (a) measure the latency on a spike branch and record the p95 + citation in `architecture.md` line N, or (b) move the LLM call off the critical path and add an explicit 'no LLM on critical path' assertion."

---

### DECOUPLE-01: Shared environment variables / state flags are single-purpose

**Description:** If `architecture.md` describes any environment variable, global state flag, or singleton used as a recursion guard / sub-session marker / mode toggle, that variable MUST either (a) have exactly one semantic meaning, or (b) the design must explicitly document the multi-purpose overloading AND name a per-purpose split path.

**Check method:**
```bash
grep -niE "SUPERPOWERS_[A-Z_]+|export [A-Z_]+=|\\\$\\{[A-Z_]+:-\\}" architecture.md > /tmp/decouple_candidates.txt
```
Any candidate variable used at ≥2 disjoint call sites without a documented per-purpose split → FAIL.

**Evidence format:** `file:line -- variable name + sites it is set/read`

**Rework format:** "Split `FOO_SESSION` into an umbrella `FOO_SUBSESSION` plus per-purpose flags; document the split in `architecture.md` near each affected call site."

---

### AUDIT-RUN-01: Retract triggers have a non-retrospective entry point

**Description:** If a design declares retract triggers (T1, T2, T3, ...) and the triggers are detected at retrospective read time only, the design MUST also expose an independent CLI / cron / hook entry point that fires the same trigger logic without depending on a retrospective being run.

**Check method:**
```bash
grep -niE "retract.*trigger|T[1-9].*(trigger|calendar|read-rate|reliability)" _index.md architecture.md > /tmp/trigger_candidates.txt
grep -niE "audit (CLI|subcommand)|cron|crontab|standalone (script|entry)" _index.md architecture.md best-practices.md > /tmp/audit_entries.txt
```
Triggers declared without any independent audit entry → FAIL. No triggers declared → vacuous PASS.

**Evidence format:** `_index.md:line -- triggers declared, no independent entry found`

**Rework format:** "Add an `audit` CLI subcommand that runs the same trigger logic; have the retrospective reader shell out to it."

---

### N0-NFR-01: Success criteria thresholds are pending or anchored on N≥1 data

**Description:** Any numeric success criterion (latency p95, error ratio, read-rate %, count threshold) MUST either (a) be marked "pending N=1 observation" with a target file path and start date, or (b) cite a specific measurement source (commit hash, benchmark file, prior retro).

**Check method:**
```bash
grep -niE "(SC|NFR|criteria|threshold|≥|≤|<|>|[0-9]+(%|ms|s|days|projects))" _index.md > /tmp/n0_candidates.txt
```
Numeric threshold without (a) pending marker, (b) explicit citation, or (c) "upper-bounded by <existing measured channel>" within 5 lines → FAIL.

**Evidence format:** `_index.md:line -- threshold cited with no source`

**Rework format:** "Mark this criterion pending N=1 observation, OR cite the measurement source."

---

### SCOPE-CREEP-01: Discoveries during the design that fix unrelated subsystems get their own PR

**Description:** If the design's reconciliation work, architecture §D, or audit trail addendum bundles changes to subsystems outside this design's stated scope, those changes MUST be extracted into a sibling retro / plan / fix-PR.

**Check method:**
```bash
grep -niE "follow-on|downstream consequence|while.*working on|surfaced during|also (fixed|updated|reworked)" _index.md architecture.md > /tmp/scope_candidates.txt
```
Bundled cross-subsystem changes with no sibling-file extraction → FAIL. No such candidates → vacuous PASS.

**Evidence format:** `architecture.md:line -- bundled change in subsystem X, no sibling extraction`

**Rework format:** "Create a sibling retro/plan owning the unrelated change. Trim the bundled enumeration here to a one-line cross-reference."

---

## Evaluation Protocol

1. Run each check method (v1 + v2 = 10 items; REQ-TRACE-01 uses the v3 full-set scan) against the design artifacts.
2. Record PASS or FAIL for each item.
3. For each FAIL, capture evidence in the specified format and produce a rework item.
4. For inferential items that produce a borderline result, note the ambiguity but still commit to PASS or FAIL.
5. Verdict: all items PASS = **PASS**. Any item FAIL = **REWORK** with itemized rework list.
6. JUST-01 retains verdict precedence: JUST-01 FAIL ⇒ REWORK regardless of others.
7. **REQ-TRACE-01 full-set rule:** a REWORK list for REQ-TRACE-01 MUST enumerate every missing ID from the full-set scan in one pass. Do not ship a single-ID fix and re-enter evaluation hoping the next round is clean — that is the thrash pattern v3 eliminates.
