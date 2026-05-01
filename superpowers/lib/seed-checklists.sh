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
#   seed-checklists.sh <design|plan|code> <output-path>
#
# Exit codes:
#   0 — seed written
#   1 — invalid mode
#   2 — usage error (missing args)

set -euo pipefail

MODE="${1:-}"
OUTPUT="${2:-}"

if [[ -z "$MODE" || -z "$OUTPUT" ]]; then
  echo "usage: $0 <design|plan|code> <output-path>" >&2
  exit 2
fi

mkdir -p "$(dirname "$OUTPUT")"

case "$MODE" in
  design)
    cat > "$OUTPUT" <<'EOF'
# Design Checklist v1

### REQ-TRACE-01: All requirements map to at least one BDD scenario
**Check method:** `grep -c "Scenario:" bdd-specs.md` -- count must equal or exceed scenario count implied by requirements
**Evidence format:** N/M requirements traced
**Rework format:** Add missing scenario for requirement: {requirement}

### SCEN-CONC-01: Given clauses use specific, concrete data values
**Check method:** `grep -n "Given" bdd-specs.md` -- flag any clause containing "some", "a valid", "appropriate", or other vague qualifiers
**Evidence format:** bdd-specs.md:{line} -- "{clause text}"
**Rework format:** Replace "{vague phrase}" with concrete value at bdd-specs.md:{line}

### ARCH-01: No inner-to-outer layer dependencies described
**Check method:** Scan architecture.md (or Detailed Design in _index.md) for any arrow or prose stating an inner layer (domain/application) imports from an outer layer (infrastructure/interfaces)
**Evidence format:** {file}:{line} -- "{dependency description}"
**Rework format:** Invert dependency at {file}:{line}; define interface in inner layer

### RISK-02: Each risk mitigation specifies a concrete action
**Check method:** For each risk listed in _index.md, confirm its mitigation names a specific mechanism (flag, retry policy, circuit breaker, etc.) rather than a vague verb like "monitor" or "handle carefully"
**Evidence format:** _index.md -- risk "{title}" mitigation "{text}"
**Rework format:** Replace vague mitigation for risk "{title}" with concrete action
EOF
    ;;
  plan)
    cat > "$OUTPUT" <<'EOF'
# Plan Checklist v1

### PLAN-COV-01: Every design BDD scenario maps to at least one task
**Check method:** Cross-reference scenario titles in bdd-specs.md against task subject lines and BDD Scenario sections in task files
**Evidence format:** N/M scenarios covered; uncovered: {scenario titles}
**Rework format:** Add task for scenario: {scenario title}

### DEP-01: No circular dependencies
**Check method:** Walk depends-on graph from _index.md; detect any cycle
**Evidence format:** Cycle detected: task-{A} -> task-{B} -> ... -> task-{A} | No cycles
**Rework format:** Break cycle by removing dependency: task-{A} depends-on task-{B}

### DEP-02: All depends-on references resolve to existing task IDs
**Check method:** For each depends-on ID in _index.md, confirm a matching task-{ID}-*.md file exists
**Evidence format:** Unresolved: {ID list} | All resolved
**Rework format:** Fix depends-on reference {ID} in {task file}

### TEST-01: Every impl task has a corresponding test task
**Check method:** For each task-{NNN}-*-impl.md, check for matching task-{NNN}-*-test.md
**Evidence format:** Unpaired impl tasks: {list} | All paired
**Rework format:** Add test task for: task-{NNN}-{slug}-impl.md
EOF
    ;;
  code)
    cat > "$OUTPUT" <<'EOF'
# Code Checklist v1

### CODE-VER-01: All verification commands exit with code 0
**Check method:** Run each verification command from the task file; record exit code
**Evidence format:** Command: {cmd} | Exit: {code} | Output: {last 5 lines}
**Rework format:** Fix failing verification: {cmd} exits {code}; error: {output}

### CODE-QUAL-01: No TODO/FIXME/NotImplementedError/pass-only patterns in produced files
**Check method:** `grep -rn "TODO\|FIXME\|NotImplementedError\|raise NotImplementedError" {files}`
**Evidence format:** {file}:{line} -- {match}
**Rework format:** Remove placeholder at {file}:{line}; implement real logic

### CODE-QUAL-02: No hardcoded stubs, skeleton-only bodies, or placeholder implementations
**Check method:** For each produced file, check that at least one function/method contains a non-trivial body (not just `pass`, `...`, `return None`, or a hardcoded literal)
**Evidence format:** {file} -- all bodies are stubs
**Rework format:** Implement real logic in {file} function {name}
EOF
    ;;
  *)
    echo "unknown mode: $MODE (expected design|plan|code)" >&2
    exit 1
    ;;
esac

echo "Seeded ${MODE}-v1.md at ${OUTPUT}"
