# Design Checklist

- **Version:** v1
- **Mode:** design
- **Created:** 2026-04-04

## Purpose

Binary PASS/FAIL checklist for evaluating design artifacts. Each item produces a deterministic or anchored result: two independent evaluators given the same artifacts should produce the same PASS/FAIL outcome. Every FAIL must include file-referenced evidence and a specific rework action.

## Artifacts Under Evaluation

- `_index.md` -- plan overview, requirements, risks
- `bdd-specs.md` -- Gherkin scenarios
- `architecture.md` -- system architecture and layer descriptions
- `best-practices.md` -- coding and design standards

---

## Checklist Items

### JUST-01: Design must not self-declare NOT-JUSTIFIED

**Description:** A design folder whose `_index.md` carries an explicit "not yet justified" / "do not implement" status declared by the maintainer or a prior brainstorming sub-agent must not pass evaluation. The design's own §0-style status is dispositive — content-quality items below cannot override it. This is the meta-check that prevents the v2.8.x add-bias pattern (see `docs/retros/meta-retro-2026-05-08-superpowers-v2.8.x.md` and `docs/retros/2026-05-09-v3-considered-deferred.md`) from being replicated at the design layer: a design folder can pass SCEN-CONC-01 / REQ-TRACE-01 / ARCH-01 / RISK-02 while being self-declared as N=0-justified or activation-gated.

**Check method:**
```bash
grep -nE "STATUS:.*NOT.JUSTIFIED|DESIGN-NOT-YET-JUSTIFIED|DESIGN-CONSIDERED-DEFERRED|DO NOT IMPLEMENT" _index.md
```
Any match is a FAIL. Zero matches is PASS.

**Anchor constraint:** The grep is case-sensitive and pattern-anchored. A match on any of the four canonical phrases is sufficient to FAIL — the maintainer using any one of these forms is signalling the same intent. Do not interpret a match away ("but the rest of the document looks ready") — that interpretation is exactly the failure mode this item exists to block.

**Evidence format:** `_index.md:{line} -- "{matched line text}"`
Example: `_index.md:4 -- "**Status**: ⚠ DESIGN-NOT-YET-JUSTIFIED"`

**Rework format:** "Either (a) remove the NOT-JUSTIFIED status from `_index.md` line {N} after addressing the underlying activation gate, or (b) move the design folder to `docs/retros/<date>-<topic>-considered-deferred.md` (single-file reject form, see `docs/retros/2026-05-09-v3-considered-deferred.md` for template) and stop attempting to advance it through `superpowers:writing-plans`."

**Verdict precedence:** If JUST-01 fails, the verdict is **REWORK** regardless of other items. The remaining items still run for completeness so the user sees full content-quality state, but a JUST-01 FAIL cannot be overridden by other items passing.

`# Type: computational` -- grep against fixed-phrase list produces deterministic match.

---

### SCEN-CONC-01: All Given clauses use specific data values

**Description:** Every `Given` clause in bdd-specs.md must use concrete, specific data values. Vague placeholders such as "some", "valid", "appropriate", or "relevant" are not permitted.

**Check method:**
```bash
grep -n "Given " bdd-specs.md | grep -iE "\bsome\b|\bvalid\b|\bappropriate\b|\brelevant\b"
```
Any match is a FAIL. Zero matches is PASS.

**Evidence format:** `file:line -- quoted text`
Example: `bdd-specs.md:23 -- 'Given some valid user data' contains vague placeholder 'some valid'`

**Rework format:** Specify the exact line and replacement instruction: "bdd-specs.md line N: replace 'some valid user data' with concrete field values (e.g., email='test@example.com', role='admin')"

`# Type: computational` -- grep pattern produces deterministic result; any match against the word list is an unambiguous FAIL.

---

### REQ-TRACE-01: Every requirement ID in _index.md appears in at least one scenario in bdd-specs.md

**Description:** Each requirement identifier (pattern: `REQ-NNN`) listed in the Requirements section of _index.md must be referenced by at least one scenario in bdd-specs.md -- either in the scenario name, Given/When/Then steps, or a comment.

**Check method:**
```bash
# Step 1: Extract requirement IDs from _index.md
grep -oE "REQ-[0-9]+" _index.md | sort -u > /tmp/req_ids.txt

# Step 2: For each ID, verify it appears in bdd-specs.md
while read -r req_id; do
  if ! grep -q "$req_id" bdd-specs.md; then
    echo "FAIL: $req_id absent from bdd-specs.md"
  fi
done < /tmp/req_ids.txt
```
Any "FAIL" output line means REQ-TRACE-01 is FAIL. Empty output means PASS.

**Anchor constraint:** The grep for the requirement ID string (e.g., `REQ-005`) in bdd-specs.md is deterministic. However, if a requirement is covered by a scenario that does not explicitly mention the ID, the evaluator must note this as a borderline case and still mark FAIL -- requirements must be explicitly traceable by ID, not inferred by topic.

**Evidence format:** `requirement ID + absence note`
Example: `REQ-005 appears in _index.md Requirements section but no scenario in bdd-specs.md references REQ-005`

**Rework format:** "Add REQ-005 reference to an existing covering scenario or create a new scenario for REQ-005: Rate limiting on login attempts"

`# Type: inferential` -- the grep for the ID string is deterministic, but deciding whether a scenario "covers" a requirement when the ID is absent requires semantic understanding. The anchor (explicit ID match) minimizes interpretive freedom by requiring the ID string to be present verbatim.

---

### ARCH-01: No imports or dependencies described from inner layer to outer layer

**Description:** The architecture.md file must not describe any dependency, import, or reference from an inner architectural layer to an outer layer. Clean Architecture layer order (inner to outer): Domain -> Application -> Infrastructure -> Presentation/CLI.

**Check method:**
```bash
# Step 1: Scan for import/dependency language patterns
grep -n -iE "import|depend|require|reference|call" architecture.md > /tmp/arch_deps.txt

# Step 2: Flag lines where an inner layer references an outer layer
# Inner-to-outer violations to detect:
#   domain -> application, infrastructure, presentation
#   application -> infrastructure, presentation
grep -iE "domain.*(infra|infrastructure|presentation|CLI|database|http|api|handler)" /tmp/arch_deps.txt
grep -iE "application.*(infra|infrastructure|presentation|CLI|database|http|handler)" /tmp/arch_deps.txt
```
Any match is a candidate violation requiring evaluator confirmation of context. Zero matches across all patterns is PASS.

**Anchor constraint:** The grep patterns identify candidate lines. The evaluator must confirm the matched line actually describes a dependency direction (not a prohibition or a negation such as "domain must NOT import infrastructure"). Lines that describe a rule against the dependency are not violations.

**Evidence format:** `file:line -- dependency description`
Example: `architecture.md:47 -- 'domain service imports from ../../infra/database' describes inner-to-outer dependency`

**Rework format:** "architecture.md line N: reverse the dependency direction or introduce an interface in the inner layer that the outer layer implements"

`# Type: inferential` -- layer boundary identification requires architectural context. The grep anchors narrow candidates to specific lines, but confirming a violation requires understanding whether the line describes an actual dependency vs. a prohibition. Evaluator must treat affirmative dependency statements as FAIL and negations/prohibitions as PASS.

---

### RISK-02: Each risk mitigation in _index.md specifies a concrete action

**Description:** Every risk mitigation entry in the Risks section of _index.md must specify a concrete, actionable measure. Vague verbs that do not specify what action to take -- such as "monitor", "handle", "manage", "address", "deal with", "look into" -- indicate a non-concrete mitigation.

**Check method:**
```bash
# Extract mitigation text and scan for vague verbs
grep -n -iE "mitigation|mitigate" _index.md | grep -iE "\bmonitor\b|\bhandle\b|\bmanage\b|\baddress\b|\bdeal with\b|\blook into\b|\btrack\b|\bensure\b"
```
Any match is a candidate FAIL. Zero matches is PASS.

**Anchor constraint:** The grep patterns flag lines containing both mitigation context and vague verbs. The evaluator must confirm the flagged verb is the primary action of the mitigation (not a subordinate clause). A mitigation such as "implement circuit breaker and monitor response times" contains "monitor" but the primary action is "implement circuit breaker" -- this is PASS. A mitigation consisting solely of "monitor closely" is FAIL.

**Evidence format:** `file -- quoted mitigation text`
Example: `_index.md -- mitigation 'monitor closely' specifies no concrete action`

**Rework format:** "Replace vague mitigation with specific action: instead of 'monitor closely', specify 'configure PagerDuty alert on 5xx rate exceeding 2% over 5-minute window'"

`# Type: inferential` -- "concrete action" is a judgment call. The grep anchors narrow candidates to lines with vague verbs, but the evaluator must assess whether the flagged verb is the sole action or a supplement to a concrete measure. When the vague verb is the only action described, mark FAIL. When it accompanies a specific action, mark PASS.

---

## Evaluation Protocol

1. Run each check method against the design artifacts in the plan folder.
2. Record PASS or FAIL for each item.
3. For each FAIL, capture evidence in the specified format and produce a rework item with file, line, and corrective instruction.
4. For inferential items that produce a borderline result, note the ambiguity in the evidence field but still commit to PASS or FAIL -- do not leave items unresolved.
5. Verdict: all items PASS = **PASS**. Any item FAIL = **REWORK** with itemized rework list. JUST-01 has verdict precedence: a JUST-01 FAIL produces REWORK regardless of how the content-quality items resolve — the remaining items still run for completeness so the maintainer sees full state, but no combination of content-quality PASS results can override a self-declared NOT-JUSTIFIED status.
