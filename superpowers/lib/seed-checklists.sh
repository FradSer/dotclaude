#!/bin/bash
#
# lib/seed-checklists.sh — Single source of truth for v1 checklist templates.
#
# Replaces inline template duplication previously distributed across:
#   skills/retrospective/SKILL.md Phase 0
#   skills/brainstorming/SKILL.md auto-seed callout
#   skills/writing-plans/SKILL.md auto-seed callout
#   skills/executing-plans/SKILL.md auto-seed callout
#
# Usage:
#   seed-checklists.sh <design|plan|code> <output-path> [--force]
#
# By default the script REFUSES to overwrite an existing output file —
# the checklists evolve through retrospectives and clobbering a hand-curated
# 3.7K rubric with a starter stub is the worst data-loss vector in the plugin.
# Pass --force only when you genuinely want to reset (e.g., retrospective
# Phase 0 explicitly resetting after a major harness change).
#
# Exit codes:
#   0 — seed written
#   1 — invalid mode
#   2 — usage error (missing args)
#   3 — output file already exists (callers should treat this as "already seeded, proceed")

set -euo pipefail

MODE="${1:-}"
OUTPUT="${2:-}"
FORCE=0

# Parse optional --force after the two positional args. Keep this simple —
# only one flag is supported and only one ordering is documented.
if [[ "${3:-}" == "--force" ]]; then
  FORCE=1
fi

if [[ -z "$MODE" || -z "$OUTPUT" ]]; then
  echo "usage: $0 <design|plan|code> <output-path> [--force]" >&2
  exit 2
fi

# Existence guard — refuse to clobber an existing checklist unless --force.
# The four workflow skills all use "Auto-seed when missing" semantics; if
# the file exists, the seeding step is a no-op from their perspective and
# they should proceed with the existing file. Surfacing exit 3 lets callers
# distinguish "already seeded" from a real failure (disk error → exit 1/2).
if [[ -e "$OUTPUT" && "$FORCE" != "1" ]]; then
  echo "Refusing to overwrite existing $OUTPUT (use --force to reset)" >&2
  exit 3
fi

mkdir -p "$(dirname "$OUTPUT")"

case "$MODE" in
  design)
    cat > "$OUTPUT" <<'EOF'
# Design Checklist v1

- **Version:** v1
- **Mode:** design
- **Created:** auto-seeded

## Purpose

Binary PASS/FAIL checklist for evaluating design artifacts. Each item produces a deterministic or anchored result: two independent evaluators given the same artifacts should produce the same PASS/FAIL outcome. Every FAIL must include file-referenced evidence and a specific rework action.

## Artifacts Under Evaluation

- `_index.md` -- plan overview, requirements, risks
- `bdd-specs.md` -- Gherkin scenarios
- `architecture.md` -- system architecture and layer descriptions
- `best-practices.md` -- coding and design standards (when present)

---

## Checklist Items

### JUST-01 -- Design must not self-declare NOT-JUSTIFIED

**Description:** A design folder whose `_index.md` carries an explicit "not yet justified" / "do not implement" status declared by the maintainer or a prior brainstorming sub-agent must not pass evaluation. The design's own §0-style status is dispositive — content-quality items below cannot override it. This is the meta-check that prevents the v2.8.x add-bias pattern from being replicated at the design layer: a design folder can pass content-quality items while being self-declared as N=0-justified or activation-gated.

**Check method:**
```bash
grep -nE "STATUS:.*NOT.JUSTIFIED|DESIGN-NOT-YET-JUSTIFIED|DESIGN-CONSIDERED-DEFERRED|DO NOT IMPLEMENT" _index.md
```
Any match is a FAIL. Zero matches is PASS.

**Evidence format:** `_index.md:{line} -- "{matched line text}"`

**Rework format:** Either (a) remove the NOT-JUSTIFIED status from `_index.md` after addressing the underlying activation gate, or (b) move the design folder to `docs/retros/<date>-<topic>-considered-deferred.md` (single-file reject form).

**Verdict precedence:** A JUST-01 FAIL produces REWORK regardless of how content-quality items resolve. Other items still run for completeness in the report, but no combination of content-quality PASS results can override a self-declared NOT-JUSTIFIED status.

`# Type: computational` -- grep against fixed-phrase list produces deterministic match.

---

### REQ-TRACE-01 -- Every requirement ID in _index.md appears in at least one scenario in bdd-specs.md

**Description:** Each requirement identifier (pattern: `REQ-NNN`) listed in the Requirements section of _index.md must be referenced by at least one scenario in bdd-specs.md.

**Check method:**
```bash
grep -oE "REQ-[0-9]+" _index.md | sort -u | while read -r id; do
  grep -q "$id" bdd-specs.md || echo "FAIL: $id absent from bdd-specs.md"
done
```
Any "FAIL" output line means REQ-TRACE-01 is FAIL. Empty output means PASS.

**Evidence format:** `requirement ID + absence note`

**Rework format:** "Add {ID} reference to an existing covering scenario or create a new scenario for {ID}: {requirement title}"

**Result:** PASS if every REQ-NNN appears in bdd-specs.md. FAIL otherwise.

`# Type: computational` -- grep for exact ID strings is deterministic.

---

### SCEN-CONC-01 -- All Given clauses use specific data values

**Description:** Every `Given` clause in bdd-specs.md must use concrete, specific data values. Vague placeholders such as "some", "valid", "appropriate", or "relevant" are not permitted.

**Check method:**
```bash
grep -n "Given " bdd-specs.md | grep -iE "\bsome\b|\bvalid\b|\bappropriate\b|\brelevant\b"
```
Any match is FAIL. Zero matches is PASS.

**Evidence format:** `bdd-specs.md:{line} -- "{clause text}"`

**Rework format:** "Replace '{vague phrase}' with concrete value at bdd-specs.md:{line}"

**Result:** PASS if zero matches. FAIL on any match.

`# Type: computational` -- grep against vague-word list produces deterministic match.

---

### ARCH-01 -- No inner-to-outer layer dependencies described

**Description:** architecture.md (or the Detailed Design section in _index.md) must not describe any dependency, import, or reference from an inner architectural layer (Domain, Application) to an outer layer (Infrastructure, Presentation/CLI).

**Check method:** Scan architecture.md for arrows or prose stating an inner layer imports from an outer layer. Patterns: `domain.*infrastructure`, `application.*infrastructure`, `domain.*presentation`. Confirm matches describe an actual dependency direction (not a prohibition such as "domain must NOT import infrastructure").

**Evidence format:** `{file}:{line} -- "{dependency description}"`

**Rework format:** "Invert dependency at {file}:{line}; define interface in inner layer."

**Result:** PASS if no inner-to-outer dependency is described. FAIL on any.

`# Type: inferential` -- grep narrows candidates; evaluator confirms direction vs. prohibition.

---

### RISK-02 -- Each risk mitigation specifies a concrete action

**Description:** Every risk mitigation entry in the Risks section of _index.md must specify a concrete, actionable measure. Vague verbs such as "monitor", "handle", "manage", "address", "deal with", "look into" indicate a non-concrete mitigation when used as the sole action.

**Check method:**
```bash
grep -n -iE "mitigation|mitigate" _index.md | grep -iE "\bmonitor\b|\bhandle\b|\bmanage\b|\baddress\b|\bdeal with\b|\blook into\b"
```
Confirm the flagged verb is the primary action (not a supplement to a concrete measure).

**Evidence format:** `_index.md -- risk "{title}" mitigation "{text}"`

**Rework format:** "Replace vague mitigation for risk '{title}' with concrete action (e.g., specific alert thresholds, retry policy, circuit breaker)."

**Result:** PASS if every mitigation describes a concrete action. FAIL on any vague-only mitigation.

`# Type: inferential` -- vague-verb match is computational; primary-vs-supplement distinction is judgment.

---

## Evaluation Protocol

1. Run each check method against the design artifacts in the plan folder.
2. Record PASS or FAIL for each item.
3. For each FAIL, capture evidence in the specified format and produce a rework item with file, line, and corrective instruction.
4. Verdict: all items PASS = **PASS**. Any item FAIL = **REWORK** with itemized rework list. JUST-01 has verdict precedence: a JUST-01 FAIL produces REWORK regardless of how the content-quality items resolve.
EOF
    ;;
  plan)
    cat > "$OUTPUT" <<'EOF'
# Plan Checklist v1

- **Version:** v1
- **Mode:** plan
- **Created:** auto-seeded

## Purpose

Binary PASS/FAIL checklist for evaluating an implementation plan folder against its source design folder. Each item produces a deterministic or anchored result.

## Artifacts Under Evaluation

- `_index.md` -- plan overview, sprint batching, depends-on graph
- `task-NNN-*.md` -- individual task files (impl + test pairs)
- Source design folder's `bdd-specs.md` -- scenarios the plan must cover

---

## Checklist Items

### PLAN-COV-01 -- Every design BDD scenario maps to at least one task

**Description:** Each `Scenario:` heading in the source design's bdd-specs.md must be covered by at least one task file (matched by scenario title in the task subject line or a BDD Scenario section in the task body).

**Check method:**
```bash
grep -E "^Scenario:" <design-folder>/bdd-specs.md | while read -r line; do
  title="${line#Scenario: }"
  grep -lq "$title" task-*.md || echo "FAIL: scenario '$title' uncovered"
done
```
Any "FAIL" output line means PLAN-COV-01 is FAIL.

**Evidence format:** `N/M scenarios covered; uncovered: {scenario titles}`

**Rework format:** "Add task for scenario: {scenario title}"

**Result:** PASS if every scenario is covered. FAIL otherwise.

`# Type: computational` -- grep for exact scenario titles is deterministic.

---

### DEP-01 -- No circular dependencies in the depends-on graph

**Description:** The depends-on graph defined in `_index.md` must be acyclic.

**Check method:** Walk the depends-on graph from `_index.md`; detect any cycle (task-A → task-B → ... → task-A).

**Evidence format:** `Cycle detected: task-{A} -> task-{B} -> ... -> task-{A}` or `No cycles`

**Rework format:** "Break cycle by removing dependency: task-{A} depends-on task-{B}"

**Result:** PASS if the graph is acyclic. FAIL on any cycle.

`# Type: computational` -- cycle detection on a finite graph is deterministic.

---

### DEP-02 -- All depends-on references resolve to existing task IDs

**Description:** For each `depends-on` entry in `_index.md`, a matching `task-{ID}-*.md` file must exist in the plan folder.

**Check method:**
```bash
grep -oE "task-[0-9]+" _index.md | sort -u | while read -r id; do
  ls "${id}"-*.md >/dev/null 2>&1 || echo "FAIL: $id unresolved"
done
```

**Evidence format:** `Unresolved: {ID list}` or `All resolved`

**Rework format:** "Fix depends-on reference {ID} in {task file} (typo or missing task file)"

**Result:** PASS if every depends-on resolves. FAIL on any unresolved reference.

`# Type: computational` -- file existence check is deterministic.

---

### TEST-01 -- Every impl task has a corresponding test task

**Description:** For each `task-NNN-{slug}-impl.md`, a matching `task-NNN-{slug}-test.md` must exist (BDD-driven TDD requires the RED test before GREEN code).

**Check method:**
```bash
ls task-*-impl.md | while read -r impl; do
  test_file="${impl%-impl.md}-test.md"
  [[ -f "$test_file" ]] || echo "FAIL: $impl missing $test_file"
done
```

**Evidence format:** `Unpaired impl tasks: {list}` or `All paired`

**Rework format:** "Add test task for: task-{NNN}-{slug}-impl.md"

**Result:** PASS if every impl has its test pair. FAIL on any unpaired impl.

`# Type: computational` -- file existence pairing is deterministic.

---

## Evaluation Protocol

1. Run each check method against the plan folder (and its source design folder where indicated).
2. Record PASS or FAIL for each item.
3. For each FAIL, capture evidence in the specified format and produce a rework item.
4. Verdict: all items PASS = **PASS**. Any item FAIL = **REWORK** with itemized rework list.
EOF
    ;;
  code)
    cat > "$OUTPUT" <<'EOF'
# Code Checklist v1

- **Version:** v1
- **Mode:** code
- **Created:** auto-seeded

## Purpose

Binary PASS/FAIL checklist for evaluating produced code artifacts at the end of a sprint batch. Each item produces a deterministic result: re-running the check against the same files yields the same outcome.

## Artifacts Under Evaluation

- Files created or modified by the batch (per sprint contract `Produced` list)
- Verification commands listed in each task file

---

## Checklist Items

### CODE-VER-01 -- All verification commands exit with code 0

**Description:** Every verification command listed in a task file must be executed independently in a fresh shell and exit with code 0. Do not chain commands with `&&` (a failure in one would mask later results).

**Check method:**
1. Extract every verification command from each task file produced in the batch.
2. Run each command independently in a clean shell.
3. Capture the exit code of each command.
4. PASS only if every command returns exit code 0.

**Evidence format:** For each verification command, record `command`, `exit_code`, and `output_tail` (last 10 lines of combined stdout/stderr).

**Rework format:** "Fix failing verification: {cmd} exits {code}; error: {output}"

**Result:** PASS if all exit codes are 0. FAIL if any exit code is non-zero.

`# Type: computational` -- exit code is deterministic ground truth.

---

### CODE-QUAL-01 -- No TODO/FIXME/HACK/XXX/STUB markers in produced files

**Description:** Files created or modified by the batch must be free of placeholder markers that indicate incomplete or deferred work.

**Check method:**
```bash
grep -rn -E '(TODO|FIXME|HACK|XXX|STUB|stub\b)' <produced-files>
```
Patterns are case-sensitive except `stub` which matches case-insensitively via the `\b` word boundary.

**Evidence format:** `{file}:{line} -- {match}`

**Rework format:** "Remove placeholder at {file}:{line}; implement real logic."

**Result:** PASS if grep returns no matches. FAIL on any match.

`# Type: computational` -- grep for exact strings is deterministic.

---

### CODE-QUAL-02 -- No stub implementations (NotImplementedError, pass-only, ellipsis-only bodies)

**Description:** Functions and methods in produced files must contain real implementations, not placeholder bodies.

**Check method:**
```bash
grep -rn 'NotImplementedError' <produced-files>
grep -rn -E '^[[:space:]]+pass[[:space:]]*$' <produced-files>
grep -rn -E '^[[:space:]]+\.\.\.[[:space:]]*$' <produced-files>
```
Each grep is run independently; any match from any grep is a failure.

**Evidence format:** `{file}:{line} -- {stub pattern}`

**Rework format:** "Implement real logic in {file} function {name}."

**Result:** PASS if all three greps return no matches. FAIL on any match.

`# Type: computational` -- grep for exact patterns is deterministic.

---

## Evaluation Protocol

1. Run all checks against the set of files created or modified by the batch, not the entire repository.
2. Each check is independent and produces a binary PASS/FAIL result.
3. Evidence must be captured verbatim from command output, not summarized or paraphrased.
4. Verdict: all items PASS = **PASS**. Any item FAIL = **REWORK** with itemized rework list.
EOF
    ;;
  *)
    echo "unknown mode: $MODE (expected design|plan|code)" >&2
    exit 1
    ;;
esac

echo "Seeded ${MODE}-v1.md at ${OUTPUT}"
