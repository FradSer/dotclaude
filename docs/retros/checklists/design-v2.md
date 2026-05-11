# Design Checklist

- **Version:** v2
- **Mode:** design
- **Created:** 2026-05-10
- **Extends:** `design-v1.md` — v1 check methods retained inline; full Description / Anchor / Evidence / Rework prose stays in `design-v1.md`. v2 adds 5 new items (PERF-01, DECOUPLE-01, AUDIT-RUN-01, N0-NFR-01, SCOPE-CREEP-01) fully described below. Evaluators MUST read `design-v1.md` alongside this file for v1 items.

## Purpose

Binary PASS/FAIL checklist for evaluating design artifacts. Each item produces a deterministic or anchored result: two independent evaluators given the same artifacts should produce the same PASS/FAIL outcome. Every FAIL must include file-referenced evidence and a specific rework action.

## Origin of v2 additions

The five new items below (PERF-01, DECOUPLE-01, AUDIT-RUN-01, N0-NFR-01, SCOPE-CREEP-01) were added on 2026-05-10 after the harness-evidence channel design's round-1 evaluation passed v1 cleanly but a follow-on ultrathink review surfaced five concerns that v1 could not catch:

| New item | What v1 would have missed |
|---|---|
| PERF-01 | A 600-1500 ms LLM call on the Stop-hook critical path "deferred to telemetry" |
| DECOUPLE-01 | A shared `SUPERPOWERS_MERGE_SESSION=1` flag overloaded across multiple LLM-call types |
| AUDIT-RUN-01 | Retract triggers only fired inside retrospective Phase 1, a circular dependency |
| N0-NFR-01 | SC thresholds encoded with no N≥1 measurement, repeating v3 retro §1 NFR-01 |
| SCOPE-CREEP-01 | Four unrelated brainstorming SKILL.md fixes bundled into a single PR's audit trail |

Each new item exists to prevent re-occurrence of that specific blind spot.

## Artifacts Under Evaluation

- `_index.md` -- plan overview, requirements, risks
- `bdd-specs.md` -- Gherkin scenarios
- `architecture.md` -- system architecture and layer descriptions
- `best-practices.md` -- coding and design standards

---

## v1 Checklist Items (check methods inline; full descriptions in `design-v1.md`)

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

### REQ-TRACE-01: Every REQ-NNN in _index.md appears in bdd-specs.md

**Check method:**
```bash
grep -oE "REQ-[0-9]+" _index.md | sort -u > /tmp/req_ids.txt
while read -r req_id; do
  grep -q "$req_id" bdd-specs.md || echo "FAIL: $req_id absent"
done < /tmp/req_ids.txt
```
Any FAIL line → REWORK.

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

**Type designation:** JUST-01 and SCEN-CONC-01 are computational (deterministic grep). The remaining three v1 items and all five v2 items below are inferential (evaluator interprets matched lines in context).

---

## v2 New Items

### PERF-01: Synchronous LLM call on hot paths has measured p95, not estimated

**Description:** If `architecture.md` or `_index.md` describes any synchronous external-process call (LLM via `claude`, network round-trip, subprocess fork to a service) on a Stop-hook, UserPromptSubmit-hook, or PostToolUse-hook critical path, the design MUST cite a measured p95 latency number, not an estimate. The number must trace to a spike branch, a benchmark file, or an existing channel's measured behavior — never to ranges like "~600-1500 ms" with no anchor.

**Check method:**
```bash
# Step 1: extract any "stop hook" / "post tool" / "user prompt" + LLM-call lines
grep -niE "(stop[- ]hook|posttooluse|userpromptsubmit).*\b(claude|sonnet|haiku|llm|gpt)\b" architecture.md _index.md > /tmp/perf_candidates.txt

# Step 2: for each candidate line, the design must include either
#   (a) a "p95" measurement with a citation, or
#   (b) an explicit "no LLM on critical path" statement nearby, or
#   (c) a spike-branch reference (e.g., "see branch perf/foo-spike or benchmarks/foo.txt")
# Inferential — evaluator confirms the candidate line is gated correctly.
```
Any candidate line without (a), (b), or (c) within 10 lines of context → FAIL.

**Anchor constraint:** "~600-1500 ms (streaming)" or "approximately 1 s" without citation are FAIL. "≤ 20 ms p95 — upper-bounded by bail-log.sh's measured behavior, see commits abc1234" is PASS. "No LLM call on this path" is PASS.

**Evidence format:** `file:line -- quoted line + missing anchor type`

**Rework format:** "Either (a) measure the latency on a spike branch and record the p95 + citation in `architecture.md` line N, or (b) move the LLM call off the critical path (deferred to read-time / a background queue / etc) and add an explicit 'no LLM on critical path' assertion."

---

### DECOUPLE-01: Shared environment variables / state flags are single-purpose

**Description:** If `architecture.md` describes any environment variable, global state flag, or singleton used as a recursion guard / sub-session marker / mode toggle, that variable MUST either (a) have exactly one semantic meaning, or (b) the design must explicitly document the multi-purpose overloading AND name a per-purpose split path. A guard that means "I am inside a Haiku call OR a Sonnet call OR any LLM call" without per-purpose differentiation is overloaded and fails.

**Check method:**
```bash
# Candidate lines: env vars used as guards / markers
grep -niE "SUPERPOWERS_[A-Z_]+|export [A-Z_]+=|\\\$\\{[A-Z_]+:-\\}" architecture.md > /tmp/decouple_candidates.txt

# For each candidate, evaluator confirms it has a single named purpose or a documented per-purpose split.
```
Any candidate variable used at ≥2 disjoint call sites without a documented per-purpose split → FAIL.

**Anchor constraint:** A guard named `FOO_SESSION=1` set by `run_haiku_merge` and read by `_run_sonnet_call` to mean "any LLM sub-session" is overloaded. Either rename to a per-purpose flag or document an umbrella + per-purpose pair (e.g., `FOO_SUBSESSION` umbrella + `FOO_HAIKU_MERGE` + `FOO_SONNET_CALL`).

**Evidence format:** `file:line -- variable name + sites it is set/read`

**Rework format:** "Split `FOO_SESSION` into an umbrella `FOO_SUBSESSION` plus per-purpose flags; document the split in `architecture.md` near each affected call site."

---

### AUDIT-RUN-01: Retract triggers have a non-retrospective entry point

**Description:** If a design declares retract triggers (T1, T2, T3, ...) and the triggers are detected at retrospective read time only, the design MUST also expose an independent CLI / cron / hook entry point that fires the same trigger logic without depending on a retrospective being run. Otherwise the retract triggers cannot fire on projects where retrospectives are rarely or never run, which is exactly the failure mode the triggers exist to prevent.

**Check method:**
```bash
# Step 1: find any "retract trigger" or "T[1-9]" trigger declaration
grep -niE "retract.*trigger|T[1-9].*(trigger|calendar|read-rate|reliability)" _index.md architecture.md > /tmp/trigger_candidates.txt

# Step 2: for each design declaring triggers, search for an independent entry point
grep -niE "audit (CLI|subcommand)|cron|crontab|standalone (script|entry)" _index.md architecture.md best-practices.md > /tmp/audit_entries.txt
```
Triggers declared without any independent audit entry → FAIL.

**Anchor constraint:** "Retrospective Phase 1 step 8 checks T3, T4, T5" alone is FAIL. "`bash lib/foo.sh audit` CLI checks T3, T4, T5; retrospective Phase 1 step 8 calls the same CLI" is PASS.

**Evidence format:** `_index.md:line -- triggers declared, no independent entry found`

**Rework format:** "Add an `audit` CLI subcommand to `lib/<channel>.sh` that runs the same trigger logic and exits non-zero on any fire; have the retrospective Phase 1 step 8 reader shell out to it instead of duplicating logic."

---

### N0-NFR-01: Success criteria thresholds are pending or anchored on N≥1 data

**Description:** Any numeric success criterion (latency p95, error ratio, read-rate %, count threshold) MUST either (a) be marked "pending N=1 observation" with a target file path and start date, or (b) cite a specific measurement source (commit hash, benchmark file, prior retro). Numbers like "30 days × ≥3 projects × ≥1 row per project" with no underlying measurement are repeats of the v3 retro §1 NFR-01 failure mode (`docs/retros/2026-05-09-v3-considered-deferred.md` §1).

**Check method:**
```bash
# Step 1: extract SC / NFR lines with numeric thresholds
grep -niE "(SC|NFR|criteria|threshold|≥|≤|<|>|[0-9]+(%|ms|s|days|projects))" _index.md > /tmp/n0_candidates.txt

# Step 2: each candidate must have one of:
#   (a) "pending" / "to be set after" / "see evaluation-data-week-N.md"
#   (b) explicit citation: commit hash, file path, retro reference
#   (c) "upper-bounded by <existing measured channel>"
```
Numeric threshold without (a), (b), or (c) within 5 lines → FAIL.

**Anchor constraint:** "across ≥3 projects after 30 days of use" with no data source is FAIL. "after 7 days of N=1 dogfooding from implementation merge date, see `evaluation-data-week-1.md`" is PASS. "≤ 20 ms p95 — upper-bounded by bail-log.sh's measured behavior" is PASS.

**Evidence format:** `_index.md:line -- threshold cited with no source`

**Rework format:** "Mark this criterion pending N=1 observation in `evaluation-data-week-1.md` (target start date = implementation merge), OR cite the measurement source (commit / benchmark / channel)."

---

### SCOPE-CREEP-01: Discoveries during the design that fix unrelated subsystems get their own PR

**Description:** If the design's reconciliation work, architecture §D, or audit trail addendum bundles changes to subsystems outside this design's stated scope, those changes MUST be extracted into a sibling retro / plan / fix-PR. Bundling unrelated fixes into the same PR replicates the v3 retro §6 add-bias mode at the document layer ("the harness-evidence design also happened to fix four brainstorming bugs").

**Check method:**
```bash
# Step 1: scan §reconciliation / §audit-trail / §D sections for bundled fixes
grep -niE "follow-on|downstream consequence|while.*working on|surfaced during|also (fixed|updated|reworked)" _index.md architecture.md > /tmp/scope_candidates.txt

# Step 2: each candidate must either:
#   (a) link to a sibling retro / plan file that owns the bundled change, or
#   (b) the bundled change is in the same lib/skill as the primary design scope
```
Bundled cross-subsystem changes with no sibling-file extraction → FAIL.

**Anchor constraint:** "as a downstream consequence, `superpowers/skills/brainstorming/SKILL.md` was updated to (a) rename Phase 1.5..., (b) promote vocabulary reconciliation..., (c) document `state.prompt` immutability..., (d) reword the Phase 1 rejection branch..." inside a harness-evidence design is FAIL — the 4 changes belong to brainstorming, not harness-evidence. PASS state: "the four brainstorming SKILL.md changes are recorded in `docs/plans/2026-05-10-brainstorming-vocab-reform-retro.md`; this design's audit trail carries only a one-line cross-reference."

**Evidence format:** `architecture.md:line -- bundled change in subsystem X, no sibling extraction`

**Rework format:** "Create `docs/plans/<date>-<topic>-retro.md` (or equivalent) owning the unrelated change. Trim the bundled enumeration in this design to a one-line cross-reference."

---

## Evaluation Protocol

1. Run each check method (v1 + v2 = 10 items) against the design artifacts.
2. Record PASS or FAIL for each item.
3. For each FAIL, capture evidence in the specified format and produce a rework item.
4. For inferential items that produce a borderline result, note the ambiguity but still commit to PASS or FAIL.
5. Verdict: all items PASS = **PASS**. Any item FAIL = **REWORK** with itemized rework list.
6. JUST-01 retains verdict precedence: JUST-01 FAIL ⇒ REWORK regardless of others.
