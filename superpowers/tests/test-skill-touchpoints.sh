#!/bin/bash
#
# tests/test-skill-touchpoints.sh — grep-based assertions that the writer
# skills (brainstorming, writing-plans, executing-plans, retrospective)
# document their docs-index consult-before / upsert-after directives and
# expose the docs-index.sh scope in their allowed-tools frontmatter.
#
# Run: bash tests/test-skill-touchpoints.sh
# Exit: 0 if all assertions PASS, 1 if any FAIL.

set -u

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
case "$SCRIPT_DIR" in
  /*) : ;;
  *) SCRIPT_DIR="$PWD/$SCRIPT_DIR" ;;
esac
SKILLS_DIR="$(dirname "$SCRIPT_DIR")/skills"

TESTS_PASSED=0
TESTS_FAILED=0

# assert_grep <file> <description> <needle>
assert_grep() {
  local file="$1" desc="$2" needle="$3"
  if grep -qF -- "$needle" "$file" 2>/dev/null; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "PASS: $desc"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: $desc"
    echo "  file: $file"
    echo "  needle: $needle"
  fi
}

echo "== Brainstorming touchpoints =="

BS_SKILL="${SKILLS_DIR}/brainstorming/SKILL.md"

# (a) allowed-tools entry for docs-index.sh
assert_grep "$BS_SKILL" \
  "brainstorming allowed-tools includes docs-index.sh scope" \
  "Bash(\${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh:*)"

# (b) consult-before directive in Initialization
assert_grep "$BS_SKILL" \
  "brainstorming Initialization consults list --kind design" \
  "list --kind design"

assert_grep "$BS_SKILL" \
  "brainstorming Initialization consults --status expired" \
  "--status expired"

assert_grep "$BS_SKILL" \
  "brainstorming treats expired: conclusions as non-authoritative" \
  "expired"

# (c) upsert-after directive in Phase 3 Wrap-up
assert_grep "$BS_SKILL" \
  "brainstorming Phase 3 upserts design" \
  "upsert design"

assert_grep "$BS_SKILL" \
  "brainstorming Phase 3 set-status for superseded-by" \
  "superseded-by:"

# (d) same-day folder-name collision disambiguation
assert_grep "$BS_SKILL" \
  "brainstorming documents -design-2/ disambiguation rule" \
  "-design-2/"

echo "== Brainstorming memory touchpoints =="

# (a) memory read-before step in Initialization
assert_grep "$BS_SKILL" \
  "brainstorming Initialization consults list --kind memory" \
  "list --kind memory --status active"

# (b) conditional memory-write step in Phase 3 Wrap-up
assert_grep "$BS_SKILL" \
  "brainstorming Phase 3 has a conditional memory-write step gated on REWORK 2+ rounds" \
  "upsert memory docs/memory/"

# (c) the gate language is explicit, not unconditional
assert_grep "$BS_SKILL" \
  "brainstorming's memory-write step is explicitly conditional, not unconditional" \
  "Conditional memory-write step, gated on REWORK 2+ rounds"

echo "== Writing-Plans touchpoints =="

WP_SKILL="${SKILLS_DIR}/writing-plans/SKILL.md"

# (a) allowed-tools entry for docs-index.sh
assert_grep "$WP_SKILL" \
  "writing-plans allowed-tools includes docs-index.sh scope" \
  "Bash(\${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh:*)"

# (b) consult-before directive in Initialization step 1
assert_grep "$WP_SKILL" \
  "writing-plans Initialization consults show <design-path>" \
  "show <design-path>"

# (c) refuse-on-expired directive in Initialization step 1
assert_grep "$WP_SKILL" \
  "writing-plans Initialization refuses on expired design status" \
  "expired:"

# (d) upsert-after directive in Phase 5 step 0
assert_grep "$WP_SKILL" \
  "writing-plans Phase 5 upserts plan" \
  "upsert plan"

echo "== Writing-Plans memory touchpoints =="

# (a) memory read-before step in Initialization
assert_grep "$WP_SKILL" \
  "writing-plans Initialization consults list --kind memory" \
  "list --kind memory --status active"

# (b) conditional memory-write step in Phase 5
assert_grep "$WP_SKILL" \
  "writing-plans Phase 5 has a conditional memory-write step gated on Phase 4 FAIL" \
  "upsert memory docs/memory/"

# (c) the gate condition names the FAIL/rework trigger
assert_grep "$WP_SKILL" \
  "writing-plans's memory-write step names the FAIL/rework gate" \
  "Conditional memory-write step, gated on a Phase 4 sub-agent FAIL"

echo "== Executing-Plans touchpoints =="

EP_SKILL="${SKILLS_DIR}/executing-plans/SKILL.md"

# (a) allowed-tools entry for docs-index.sh
assert_grep "$EP_SKILL" \
  "executing-plans allowed-tools includes docs-index.sh scope" \
  "Bash(\${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh:*)"

# (b) consult-before directive (show <plan-path>)
assert_grep "$EP_SKILL" \
  "executing-plans consults show <plan-path>" \
  "show <plan-path>"

# (c) refuse-on-expired directive
assert_grep "$EP_SKILL" \
  "executing-plans refuses on expired plan status" \
  "expired:"

# (d) rework-flip-to-wip before batch 1
assert_grep "$EP_SKILL" \
  "executing-plans flips implemented:<old-sha> to wip before batch 1" \
  "implemented:"

assert_grep "$EP_SKILL" \
  "executing-plans rework-flip references wip" \
  "wip"

# (e) set-status implemented flip in Phase 5
assert_grep "$EP_SKILL" \
  "executing-plans Phase 5 calls set-status for implemented" \
  "set-status"

# (f) the no---amend rule (dedicated index commit)
assert_grep "$EP_SKILL" \
  "executing-plans forbids --amend for index commit" \
  "--amend"

echo "== Executing-Plans memory touchpoints =="

# (a) memory read-before step in Initialization
assert_grep "$EP_SKILL" \
  "executing-plans Initialization consults list --kind memory" \
  "list --kind memory --status active"

# (b) conditional memory-write step in Phase 5, gated on the variety-gap signal
assert_grep "$EP_SKILL" \
  "executing-plans Phase 5 has a conditional memory-write step gated on the variety-gap signal" \
  "intra-plan-learning.md:54"

# (c) the variety-gap trigger is explicitly distinguished from the hard-abort cap
assert_grep "$EP_SKILL" \
  "executing-plans distinguishes the variety-gap trigger from the batch-execution-playbook hard-abort cap" \
  "batch-execution-playbook.md:165 (max 2 rework rounds before escalation), which is NOT a memory-write trigger"

echo "== Retrospective touchpoints =="

RT_SKILL="${SKILLS_DIR}/retrospective/SKILL.md"

# (a) allowed-tools entry for docs-index.sh
assert_grep "$RT_SKILL" \
  "retrospective allowed-tools includes docs-index.sh scope" \
  "Bash(\${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh:*)"

# (b) consult-before: list --kind plan --status implemented
assert_grep "$RT_SKILL" \
  "retrospective consults list --kind plan --status implemented" \
  "list --kind plan --status implemented"

# (c) upsert-after: upsert retro
assert_grep "$RT_SKILL" \
  "retrospective upserts retro report" \
  "upsert retro"

# (d) invalidates: grep directive in step 7
assert_grep "$RT_SKILL" \
  "retrospective greps invalidates: lines from retro report" \
  "invalidates:"

# (e) REMOVE does NOT invalidate boundary statement
assert_grep "$RT_SKILL" \
  "retrospective states REMOVE does NOT invalidate a design" \
  "REMOVE does NOT invalidate"

# (f) exit-3-skip-with-warning handling
assert_grep "$RT_SKILL" \
  "retrospective handles exit 3 as skip-with-warning" \
  "exit 3"

echo "== Retrospective memory touchpoints =="

# (a) memory read-before step in Phase 1 Data Collection
assert_grep "$RT_SKILL" \
  "retrospective Phase 1 consults list --kind memory" \
  "list --kind memory --status active"

# (b) Phase 4 step 3.5 drafts a memory file for applied ADD/MODIFY proposals
assert_grep "$RT_SKILL" \
  "retrospective Phase 4 drafts a memory file for applied ADD/MODIFY proposals" \
  "upsert memory docs/memory/"

# (c) REMOVE/PROMOTE are explicitly excluded from the memory write-gate
assert_grep "$RT_SKILL" \
  "retrospective explicitly excludes REMOVE/PROMOTE from the memory write-gate" \
  "REMOVE and PROMOTE proposals, even if applied, do NOT trigger this step"

# (d) Pre-Check B promotion bridge
assert_grep "$RT_SKILL" \
  "retrospective documents the Pre-Check-B promotion bridge" \
  "Promoted from private assistant memory hook"

# (e) memory-file consolidation via set-status expired:superseded-by-consolidation
assert_grep "$RT_SKILL" \
  "retrospective documents memory-file consolidation via set-status expired:superseded-by-consolidation" \
  "expired:superseded-by-consolidation"

echo "== Systematic-Debugging touchpoints =="

SD_SKILL="${SKILLS_DIR}/systematic-debugging/SKILL.md"

# (a) allowed-tools entry for docs-index.sh
assert_grep "$SD_SKILL" \
  "systematic-debugging allowed-tools includes docs-index.sh scope" \
  "Bash(\${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh:*)"

# (b) new step 0 in Phase 1 consults list --kind memory
assert_grep "$SD_SKILL" \
  "systematic-debugging new step 0 consults list --kind memory before Phase 1" \
  "list --kind memory --status active"

# (c) the memory read is skipped on the bail-out path
assert_grep "$SD_SKILL" \
  "systematic-debugging's memory read is skipped on the bail-out path" \
  "memory read-before step is skipped whenever the Bail-Out Check fires"

# (d) the memory-write step reuses the existing 3+ failed-fixes trigger
assert_grep "$SD_SKILL" \
  "systematic-debugging's memory-write step reuses the existing 3+ failed-fixes trigger" \
  "3+ failed fixes trigger as its primary gate: firing that trigger runs upsert memory"

# (e) the memory-write is the ONLY docs/ touchpoint, not a new phase
assert_grep "$SD_SKILL" \
  "systematic-debugging's memory-write is its ONLY docs/ touchpoint, not a new phase" \
  "not a new phase"

echo "---"
echo "passed: $TESTS_PASSED"
echo "failed: $TESTS_FAILED"
if [[ "$TESTS_FAILED" -eq 0 ]]; then
  exit 0
else
  exit 1
fi
