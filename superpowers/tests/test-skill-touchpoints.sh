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

echo "---"
echo "passed: $TESTS_PASSED"
echo "failed: $TESTS_FAILED"
if [[ "$TESTS_FAILED" -eq 0 ]]; then
  exit 0
else
  exit 1
fi
