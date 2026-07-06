#!/bin/bash
#
# tests/run-docs-index-tests.sh — Plain-bash test harness for lib/docs-index.sh.
#
# Harness decision (task 001): `bats` is NOT on PATH in this environment, so we
# use a plain bash runner that sources ./test_helpers.sh for assert_* helpers
# and a tmp-repo fixture (mktemp -d + git init + CLAUDE_PROJECT_DIR override so
# repo_root resolves to the temp repo). Each test sets up its own tmp repo via
# run_test <name> <fn>; the trap in test_helpers.sh cleans up on exit.
#
# Run: bash tests/run-docs-index-tests.sh
# Exit: 0 if all PASS, 1 if any FAIL.

set -u

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
case "$SCRIPT_DIR" in
  /*) : ;;
  *) SCRIPT_DIR="$PWD/$SCRIPT_DIR" ;;
esac
# shellcheck source=test_helpers.sh
source "${SCRIPT_DIR}/test_helpers.sh"

# ---------------------------------------------------------------------------
# Task 001: skeleton / harness tests
# ---------------------------------------------------------------------------

test_no_args_exits_2() {
  assert_exit 2 bash "$DOCS_INDEX_SH"
}

test_unknown_subcommand_exits_2() {
  assert_exit 2 bash "$DOCS_INDEX_SH" bogus-cmd
}

test_script_is_executable() {
  if [[ -x "$DOCS_INDEX_SH" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: $DOCS_INDEX_SH is not executable" >&2
  fi
}

# ---------------------------------------------------------------------------
# Task 002: list subcommand tests (RED — stub exits 2)
# ---------------------------------------------------------------------------

ROW_DESIGN_1="docs/plans/2026-07-01-auth-design/ | design | active | First design | 2026-07-01"
ROW_PLAN_1="docs/plans/2026-07-04-auth-plan/ | plan | wip | Plan | 2026-07-04"
ROW_RETRO_1="docs/retros/retro-2026-07-04.md | retro | reference | Retro | 2026-07-04"
ROW_IMPLEMENTED="docs/plans/2026-07-04-X-plan/ | plan | implemented:abc1234 | Done | 2026-07-04"

test_list_no_filter_prints_all_rows() {
  make_index "$ROW_DESIGN_1" "$ROW_PLAN_1" "$ROW_RETRO_1"
  assert_stdout_line_count 3 bash "$DOCS_INDEX_SH" list
  assert_stdout_contains "design" bash "$DOCS_INDEX_SH" list
  assert_stdout_contains "plan" bash "$DOCS_INDEX_SH" list
  assert_stdout_contains "retro" bash "$DOCS_INDEX_SH" list
}

test_list_kind_design_filters() {
  make_index "$ROW_DESIGN_1" "$ROW_PLAN_1" "$ROW_RETRO_1"
  assert_stdout_line_count 1 bash "$DOCS_INDEX_SH" list --kind design
  assert_stdout_contains "design" bash "$DOCS_INDEX_SH" list --kind design
}

test_list_status_implemented_prefix_matches() {
  make_index "$ROW_DESIGN_1" "$ROW_IMPLEMENTED"
  assert_stdout_line_count 1 bash "$DOCS_INDEX_SH" list --status implemented
  assert_stdout_contains "implemented:abc1234" bash "$DOCS_INDEX_SH" list --status implemented
}

test_list_empty_index_prints_nothing() {
  make_empty_index
  assert_no_stdout bash "$DOCS_INDEX_SH" list
  assert_exit 0 bash "$DOCS_INDEX_SH" list
}

# ---------------------------------------------------------------------------
# Task 004: show subcommand tests (RED — stub exits 2)
# ---------------------------------------------------------------------------

test_show_tracked_path_prints_one_row() {
  make_index "$ROW_DESIGN_1"
  assert_exit 0 bash "$DOCS_INDEX_SH" show docs/plans/2026-07-01-auth-design/
  assert_stdout_line_count 1 bash "$DOCS_INDEX_SH" show docs/plans/2026-07-01-auth-design/
  assert_stdout_contains "docs/plans/2026-07-01-auth-design/" bash "$DOCS_INDEX_SH" show docs/plans/2026-07-01-auth-design/
}

test_show_absent_path_exits_3() {
  make_index "$ROW_DESIGN_1"
  assert_exit 3 bash "$DOCS_INDEX_SH" show docs/plans/never-seen-design/
  assert_no_stdout bash "$DOCS_INDEX_SH" show docs/plans/never-seen-design/
}

# ---------------------------------------------------------------------------
# Task 006: upsert subcommand tests (RED — stub exits 2)
# ---------------------------------------------------------------------------

test_upsert_cold_start_creates_index() {
  # Ensure no docs/README.md exists.
  rm -f docs/README.md
  assert_exit 0 bash "$DOCS_INDEX_SH" upsert design docs/plans/2026-07-04-X-design/ --status active --summary "Token rotation"
  assert_file_contains docs/README.md "| path |"
  assert_file_contains docs/README.md "docs/plans/2026-07-04-X-design/"
  assert_file_contains docs/README.md "design"
  assert_file_contains docs/README.md "active"
}

test_upsert_idempotent_same_path_updates_no_duplicates() {
  make_index "$ROW_DESIGN_1"
  assert_exit 0 bash "$DOCS_INDEX_SH" upsert design docs/plans/2026-07-01-auth-design/ --status wip --summary "revised"
  assert_exit 0 bash "$DOCS_INDEX_SH" upsert design docs/plans/2026-07-01-auth-design/ --status wip --summary "revised"
  # Exactly one occurrence of the path.
  local count
  count=$(grep -c "docs/plans/2026-07-01-auth-design/" docs/README.md || true)
  if [[ "$count" -eq 1 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: expected 1 row for path, got $count" >&2
  fi
  assert_file_contains docs/README.md "wip"
  assert_file_contains docs/README.md "revised"
}

test_upsert_bad_status_done_rejected() {
  make_index "$ROW_DESIGN_1"
  local before
  before="$(cat docs/README.md)"
  assert_exit 2 bash "$DOCS_INDEX_SH" upsert design docs/plans/x-design/ --status done --summary "x"
  assert_stderr_not_contains "not yet implemented"
  # File unchanged.
  if [[ "$(cat docs/README.md)" == "$before" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: index modified on rejected status" >&2
  fi
}

test_upsert_bad_status_complete_rejected() {
  make_index "$ROW_DESIGN_1"
  assert_exit 2 bash "$DOCS_INDEX_SH" upsert design docs/plans/x-design/ --status complete --summary "x"
  assert_stderr_not_contains "not yet implemented"
}

test_upsert_bad_status_wrong_separator_rejected() {
  make_index "$ROW_DESIGN_1"
  assert_exit 2 bash "$DOCS_INDEX_SH" upsert design docs/plans/x-design/ --status implemented-abc1234 --summary "x"
  assert_stderr_not_contains "not yet implemented"
}

test_upsert_bad_status_draft_rejected() {
  make_index "$ROW_DESIGN_1"
  assert_exit 2 bash "$DOCS_INDEX_SH" upsert design docs/plans/x-design/ --status draft --summary "x"
  assert_stderr_not_contains "not yet implemented"
}

test_upsert_bad_kind_feature_rejected() {
  make_index "$ROW_DESIGN_1"
  assert_exit 2 bash "$DOCS_INDEX_SH" upsert feature docs/plans/x-design/ --status active --summary "x"
  assert_stderr_not_contains "not yet implemented"
}

test_upsert_bad_kind_spec_rejected() {
  make_index "$ROW_DESIGN_1"
  assert_exit 2 bash "$DOCS_INDEX_SH" upsert spec docs/plans/x-design/ --status active --summary "x"
  assert_stderr_not_contains "not yet implemented"
}

test_upsert_bad_kind_type_rejected() {
  make_index "$ROW_DESIGN_1"
  assert_exit 2 bash "$DOCS_INDEX_SH" upsert type docs/plans/x-design/ --status active --summary "x"
  assert_stderr_not_contains "not yet implemented"
}

test_upsert_default_status_wip_for_design() {
  make_empty_index
  assert_exit 0 bash "$DOCS_INDEX_SH" upsert design docs/plans/2026-07-04-Y-design/ --summary "no status flag"
  assert_file_contains docs/README.md "wip"
}

test_upsert_default_status_active_for_retro() {
  make_empty_index
  assert_exit 0 bash "$DOCS_INDEX_SH" upsert retro docs/retros/retro-2026-07-04.md --summary "no status flag"
  assert_file_contains docs/README.md "active"
}

# ---------------------------------------------------------------------------
# Task 008: set-status subcommand tests (RED — stub exits 2)
# ---------------------------------------------------------------------------

# Transition matrix from task-008's Scenario Outline (14 rows).
# Format: "<from>\t<to>\t<expected_exit>" — 0 for allowed, 2 for rejected.
SET_STATUS_MATRIX=(
  "wip\tactive\t0"
  "active\timplemented:abc1234\t0"
  "active\tsuperseded-by:docs/plans/x-design/\t0"
  "active\texpired:retro-2026-07-04:reason\t0"
  "active\twip\t0"
  "wip\texpired:retro-2026-07-04:reason\t0"
  "implemented:abc1234\twip\t0"
  "implemented:abc1234\texpired:retro-2026-07-04:reason\t2"
  "implemented:abc1234\tsuperseded-by:docs/plans/x-design/\t2"
  "expired:x\tactive\t2"
  "expired:x\tsuperseded-by:docs/plans/y-design/\t2"
  "reference\texpired:x\t2"
  "reference\tsuperseded-by:docs/plans/y-design/\t2"
  "superseded-by:y\tactive\t2"
)

# Helper: set up a single entry with the given `from` status at a known path,
# then invoke set-status with the `to` value and check the exit code.
# Usage: run_set_status_case <from> <to> <expected_exit>
run_set_status_case() {
  local from="$1" to="$2" expected="$3"
  local path="docs/plans/2026-07-04-X-design/"
  make_index "${path} | design | ${from} | orig-summary | 2026-07-01"
  _run bash "$DOCS_INDEX_SH" set-status "$path" "$to"
  if [[ "$LAST_EXIT" -eq "$expected" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: set-status from='${from}' to='${to}' expected exit ${expected}, got ${LAST_EXIT}" >&2
    echo "  stderr: $LAST_STDERR" >&2
  fi
}

test_set_status_transition_matrix_wip_to_active() {
  run_set_status_case "wip" "active" 0
}
test_set_status_transition_matrix_active_to_implemented() {
  run_set_status_case "active" "implemented:abc1234" 0
}
test_set_status_transition_matrix_active_to_superseded() {
  run_set_status_case "active" "superseded-by:docs/plans/x-design/" 0
}
test_set_status_transition_matrix_active_to_expired() {
  run_set_status_case "active" "expired:retro-2026-07-04:reason" 0
}
test_set_status_transition_matrix_active_to_wip() {
  run_set_status_case "active" "wip" 0
}
test_set_status_transition_matrix_wip_to_expired() {
  run_set_status_case "wip" "expired:retro-2026-07-04:reason" 0
}
test_set_status_transition_matrix_implemented_to_wip() {
  run_set_status_case "implemented:abc1234" "wip" 0
}
test_set_status_transition_matrix_implemented_to_expired_rejected() {
  run_set_status_case "implemented:abc1234" "expired:retro-2026-07-04:reason" 2
}
test_set_status_transition_matrix_implemented_to_superseded_rejected() {
  run_set_status_case "implemented:abc1234" "superseded-by:docs/plans/x-design/" 2
}
test_set_status_transition_matrix_expired_to_active_rejected() {
  run_set_status_case "expired:x" "active" 2
}
test_set_status_transition_matrix_expired_to_superseded_rejected() {
  run_set_status_case "expired:x" "superseded-by:docs/plans/y-design/" 2
}
test_set_status_transition_matrix_reference_to_expired_rejected() {
  run_set_status_case "reference" "expired:x" 2
}
test_set_status_transition_matrix_reference_to_superseded_rejected() {
  run_set_status_case "reference" "superseded-by:docs/plans/y-design/" 2
}
test_set_status_transition_matrix_superseded_to_active_rejected() {
  run_set_status_case "superseded-by:y" "active" 2
}

test_set_status_rejected_leaves_index_byte_identical() {
  local path="docs/plans/2026-07-04-X-design/"
  make_index "${path} | design | implemented:abc1234 | orig-summary | 2026-07-01"
  local before
  before="$(cat docs/README.md)"
  _run bash "$DOCS_INDEX_SH" set-status "$path" "expired:retro-2026-07-04:reason"
  if [[ "$LAST_EXIT" -ne 2 ]]; then
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: expected exit 2 for rejected transition, got $LAST_EXIT" >&2
    return
  fi
  # Status column unchanged.
  if grep -q "implemented:abc1234" docs/README.md && ! grep -q "expired:retro-2026-07-04:reason" docs/README.md; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: status column changed after rejected transition" >&2
  fi
  # Summary column unchanged.
  if grep -q "orig-summary" docs/README.md; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: summary column changed after rejected transition" >&2
  fi
  # Byte-identical.
  if [[ "$(cat docs/README.md)" == "$before" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: index not byte-identical after rejected transition" >&2
  fi
}

test_set_status_absent_path_exits_3() {
  make_index "docs/plans/2026-07-01-other-design/ | design | active | Other | 2026-07-01"
  local before
  before="$(cat docs/README.md)"
  _run bash "$DOCS_INDEX_SH" set-status "docs/plans/never-seen/" "active"
  if [[ "$LAST_EXIT" -eq 3 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: expected exit 3 for absent path, got $LAST_EXIT" >&2
  fi
  if [[ "$(cat docs/README.md)" == "$before" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: index modified on absent-path set-status" >&2
  fi
}

test_set_status_bad_status_rejected_exit_2() {
  local path="docs/plans/2026-07-04-X-design/"
  make_index "${path} | design | active | orig | 2026-07-01"
  _run bash "$DOCS_INDEX_SH" set-status "$path" "done"
  if [[ "$LAST_EXIT" -eq 2 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: expected exit 2 for bad status, got $LAST_EXIT" >&2
  fi
  assert_stderr_not_contains "not yet implemented"
}

test_set_status_allowed_flips_status_and_date() {
  local path="docs/plans/2026-07-04-X-design/"
  make_index "${path} | design | wip | orig | 2026-07-01"
  _run bash "$DOCS_INDEX_SH" set-status "$path" "active"
  if [[ "$LAST_EXIT" -eq 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: expected exit 0 for allowed transition, got $LAST_EXIT" >&2
  fi
  assert_file_contains docs/README.md "active"
  assert_file_not_contains docs/README.md "wip"
}

# ---------------------------------------------------------------------------
# Task 010: rebuild subcommand tests (RED — stub exits 2)
# ---------------------------------------------------------------------------

# make_folders <count> <suffix>
# Creates <count> design folders under docs/plans/ with a _index.md inside.
# Folder names: docs/plans/2026-01-<NN>-topic-<suffix>/  (NN zero-padded)
make_folders() {
  local count="$1" suffix="${2:-design}"
  local i name
  for ((i = 1; i <= count; i++)); do
    name="$(printf 'docs/plans/2026-01-%02d-topic-%s' "$i" "$suffix")"
    mkdir -p "$name"
    : > "${name}/_index.md"
  done
}

test_rebuild_regenerates_from_filesystem_truth() {
  # Create one design folder, one plan folder, one retro file.
  mkdir -p docs/plans/2026-07-04-X-design/
  : > docs/plans/2026-07-04-X-design/_index.md
  mkdir -p docs/plans/2026-07-04-Y-plan/
  : > docs/plans/2026-07-04-Y-plan/_index.md
  mkdir -p docs/retros
  : > docs/retros/retro-2026-07-04.md
  # Start with an empty (header-only) index.
  make_empty_index
  _run bash "$DOCS_INDEX_SH" rebuild
  if [[ "$LAST_EXIT" -eq 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: rebuild expected exit 0, got $LAST_EXIT" >&2
  fi
  # Three data rows.
  assert_file_contains docs/README.md "docs/plans/2026-07-04-X-design/"
  assert_file_contains docs/README.md "docs/plans/2026-07-04-Y-plan/"
  assert_file_contains docs/README.md "docs/retros/retro-2026-07-04.md"
  # Kind assignment: design → design, plan → plan, retro file → retro.
  # Check by grepping the full row.
  if grep -q "docs/plans/2026-07-04-X-design/ | design |" docs/README.md; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: design folder not kind=design" >&2
  fi
  if grep -q "docs/plans/2026-07-04-Y-plan/ | plan |" docs/README.md; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: plan folder not kind=plan" >&2
  fi
  if grep -q "docs/retros/retro-2026-07-04.md | retro |" docs/README.md; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: retro file not kind=retro" >&2
  fi
  # Row count printed to stderr.
  if printf '%s' "$LAST_STDERR" | grep -qE '[0-9]+' ; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: rebuild did not print row count to stderr (got: $LAST_STDERR)" >&2
  fi
}

test_rebuild_preserves_existing_statuses() {
  mkdir -p docs/plans/2026-07-04-X-design/
  : > docs/plans/2026-07-04-X-design/_index.md
  # Pre-existing index with a non-default status.
  make_index "docs/plans/2026-07-04-X-design/ | design | implemented:abc1234 | orig | 2026-07-01"
  _run bash "$DOCS_INDEX_SH" rebuild
  if [[ "$LAST_EXIT" -eq 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: rebuild expected exit 0, got $LAST_EXIT" >&2
  fi
  if grep -q "implemented:abc1234" docs/README.md; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: rebuild did not preserve existing status" >&2
  fi
}

test_rebuild_drops_absent_paths() {
  mkdir -p docs/plans/2026-07-04-X-design/
  : > docs/plans/2026-07-04-X-design/_index.md
  # Pre-existing index has a row for a folder that no longer exists.
  make_index \
    "docs/plans/2026-07-04-X-design/ | design | active | live | 2026-07-04" \
    "docs/plans/2026-07-04-gone-design/ | design | active | gone | 2026-07-04"
  _run bash "$DOCS_INDEX_SH" rebuild
  if [[ "$LAST_EXIT" -eq 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: rebuild expected exit 0, got $LAST_EXIT" >&2
  fi
  assert_file_contains docs/README.md "docs/plans/2026-07-04-X-design/"
  assert_file_not_contains docs/README.md "docs/plans/2026-07-04-gone-design/"
}

test_rebuild_seeds_writing_skills_as_reference() {
  mkdir -p docs/plans/2026-07-04-X-design/
  : > docs/plans/2026-07-04-X-design/_index.md
  mkdir -p docs/writing-skills/
  : > docs/writing-skills/README.md
  make_empty_index
  _run bash "$DOCS_INDEX_SH" rebuild
  if [[ "$LAST_EXIT" -eq 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: rebuild expected exit 0, got $LAST_EXIT" >&2
  fi
  if grep -q "docs/writing-skills/ | retro | reference |" docs/README.md; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: rebuild did not seed docs/writing-skills/ as retro/reference" >&2
  fi
}

test_rebuild_applies_60_line_collapse() {
  # Create 65 design folders all sharing the topic "topic" — exceeds the
  # 60-row ceiling. Pre-seed the index with implemented status for all 65 so
  # the collapse rule (groups of >=3 implemented sharing a topic prefix) fires.
  make_folders 65 design
  local rows=() i name
  for ((i = 1; i <= 65; i++)); do
    name="$(printf 'docs/plans/2026-01-%02d-topic-design' "$i")"
    rows+=("${name}/ | design | implemented:abc1234 | orig | 2026-07-01")
  done
  make_index "${rows[@]}"
  _run bash "$DOCS_INDEX_SH" rebuild
  if [[ "$LAST_EXIT" -eq 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: rebuild expected exit 0, got $LAST_EXIT" >&2
  fi
  # Count data rows (lines starting with "| docs/" but not the header/separator).
  local data_rows
  data_rows=$(grep -c '^| docs/' docs/README.md || true)
  if [[ "$data_rows" -le 60 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: rebuild produced $data_rows data rows, expected <= 60" >&2
  fi
}

test_rebuild_never_collapses_active_wip_superseded() {
  # 3 active + 3 wip + 3 superseded folders, all sharing a topic. None should
  # be collapsed even though they form groups of 3 — collapse only targets
  # implemented/expired.
  local rows=() i name
  for ((i = 1; i <= 3; i++)); do
    name="$(printf 'docs/plans/2026-01-%02d-topic-design' "$i")"
    mkdir -p "$name"; : > "${name}/_index.md"
    rows+=("${name}/ | design | active | a | 2026-07-01")
  done
  for ((i = 4; i <= 6; i++)); do
    name="$(printf 'docs/plans/2026-01-%02d-topic-design' "$i")"
    mkdir -p "$name"; : > "${name}/_index.md"
    rows+=("${name}/ | design | wip | w | 2026-07-01")
  done
  for ((i = 7; i <= 9; i++)); do
    name="$(printf 'docs/plans/2026-01-%02d-topic-design' "$i")"
    mkdir -p "$name"; : > "${name}/_index.md"
    rows+=("${name}/ | design | superseded-by:docs/plans/z-design/ | s | 2026-07-01")
  done
  make_index "${rows[@]}"
  _run bash "$DOCS_INDEX_SH" rebuild
  if [[ "$LAST_EXIT" -eq 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: rebuild expected exit 0, got $LAST_EXIT" >&2
  fi
  # All 9 rows survive (none collapsed).
  local data_rows
  data_rows=$(grep -c '^| docs/' docs/README.md || true)
  if [[ "$data_rows" -eq 9 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: rebuild produced $data_rows data rows, expected 9 (no collapse)" >&2
  fi
}

test_rebuild_idempotent() {
  mkdir -p docs/plans/2026-07-04-X-design/
  : > docs/plans/2026-07-04-X-design/_index.md
  mkdir -p docs/plans/2026-07-04-Y-plan/
  : > docs/plans/2026-07-04-Y-plan/_index.md
  make_empty_index
  bash "$DOCS_INDEX_SH" rebuild
  local first
  first="$(cat docs/README.md)"
  _run bash "$DOCS_INDEX_SH" rebuild
  if [[ "$LAST_EXIT" -eq 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: second rebuild expected exit 0, got $LAST_EXIT" >&2
  fi
  if [[ "$(cat docs/README.md)" == "$first" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: rebuild not idempotent" >&2
  fi
}

# ---------------------------------------------------------------------------
# Task 012: edge cases (RED expected — validation not yet implemented)
# ---------------------------------------------------------------------------

# Write a docs/README.md that is free-form prose, not a pipe-delimited table.
make_prose_index() {
  cat > docs/README.md <<'EOF'
# Project Notes

This is just some free-form prose describing the project.
There is no table here. Move along.
EOF
}

test_list_on_malformed_index_exits_2() {
  make_prose_index
  _run bash "$DOCS_INDEX_SH" list
  if [[ "$LAST_EXIT" -eq 2 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: list on malformed index expected exit 2, got $LAST_EXIT" >&2
  fi
  if printf '%s' "$LAST_STDERR" | grep -qF "docs/README.md is not a valid index table"; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: expected diagnostic 'docs/README.md is not a valid index table', got: $LAST_STDERR" >&2
  fi
}

test_upsert_rejects_leading_slash_path() {
  make_index "$ROW_DESIGN_1"
  local before
  before="$(cat docs/README.md)"
  _run bash "$DOCS_INDEX_SH" upsert design /etc/passwd --status active
  if [[ "$LAST_EXIT" -eq 2 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: upsert with leading-slash path expected exit 2, got $LAST_EXIT" >&2
  fi
  if [[ "$(cat docs/README.md)" == "$before" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: index mutated by rejected upsert" >&2
  fi
}

test_upsert_rejects_parent_traversal_path() {
  make_index "$ROW_DESIGN_1"
  local before
  before="$(cat docs/README.md)"
  _run bash "$DOCS_INDEX_SH" upsert design ../etc/passwd --status active
  if [[ "$LAST_EXIT" -eq 2 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: upsert with parent-traversal path expected exit 2, got $LAST_EXIT" >&2
  fi
  if [[ "$(cat docs/README.md)" == "$before" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: index mutated by rejected upsert" >&2
  fi
}

test_rebuild_recovers_from_malformed_index() {
  make_prose_index
  # Seed a real design folder so rebuild has something to regenerate from.
  mkdir -p docs/plans/2026-07-04-X-design/
  : > docs/plans/2026-07-04-X-design/_index.md
  _run bash "$DOCS_INDEX_SH" rebuild
  if [[ "$LAST_EXIT" -eq 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: rebuild on malformed index expected exit 0, got $LAST_EXIT" >&2
    echo "  stderr: $LAST_STDERR" >&2
  fi
  assert_file_contains docs/README.md "| path |"
  assert_file_contains docs/README.md "docs/plans/2026-07-04-X-design/"
}

# ---------------------------------------------------------------------------
# Task 001: memory kind vocabulary tests (RED — kind vocabulary is still
# design|plan|retro only; `memory` is unknown until lib/docs-index.sh is
# extended). test_memory_kind_accepted_by_upsert and
# test_memory_default_status_is_active pass `--category pitfall` up front even
# though the flag does not exist yet, so these two tests stay isolated to the
# kind gate once the category gate (task 003/004) lands — until then they
# fail on the (still correct, still exit-2) unrecognized-flag path rather than
# the kind gate itself.
# ---------------------------------------------------------------------------

ROW_MEMORY_1="docs/memory/pitfall_x.md | memory | active | Some prior mistake | 2026-07-04"

test_memory_kind_accepted_by_upsert() {
  make_empty_index
  assert_exit 0 bash "$DOCS_INDEX_SH" upsert memory docs/memory/pitfall_x.md --status active --summary "x" --category pitfall
  assert_file_contains docs/README.md "docs/memory/pitfall_x.md"
  assert_file_contains docs/README.md "| memory |"
}

test_memory_kind_accepted_by_list_filter() {
  make_index "$ROW_DESIGN_1" "$ROW_PLAN_1" "$ROW_RETRO_1" "$ROW_MEMORY_1"
  assert_stdout_line_count 1 bash "$DOCS_INDEX_SH" list --kind memory
  assert_stdout_contains "memory" bash "$DOCS_INDEX_SH" list --kind memory
}

test_memory_kind_rejected_message_mentions_memory() {
  make_index "$ROW_DESIGN_1"
  _run bash "$DOCS_INDEX_SH" upsert bogus-kind docs/plans/x-design/ --status active --summary "x"
  if [[ "$LAST_EXIT" -eq 2 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: expected exit 2 for bogus kind, got $LAST_EXIT" >&2
  fi
  if printf '%s' "$LAST_STDERR" | grep -qF "design|plan|retro|memory"; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: expected stderr to enumerate design|plan|retro|memory, got: $LAST_STDERR" >&2
  fi
}

test_memory_default_status_is_active() {
  make_empty_index
  assert_exit 0 bash "$DOCS_INDEX_SH" upsert memory docs/memory/pitfall_y.md --summary "no status flag" --category pitfall
  assert_file_contains docs/README.md "| active |"
}

# ---------------------------------------------------------------------------
# Task 003: memory status restriction + category flag tests (RED — no
# kind-aware status restriction and no --category flag exist yet). The
# category-value tests (type/kind/reference, and the two upsert-time status
# tests) additionally assert stderr does NOT say "unknown argument" — without
# that check they would spuriously pass today for the wrong reason (the flag
# being entirely unrecognized), rather than the real validation path task 004
# is expected to add.
# ---------------------------------------------------------------------------

test_memory_upsert_rejects_wip_status() {
  make_empty_index
  assert_exit 2 bash "$DOCS_INDEX_SH" upsert memory docs/memory/pitfall_x.md --status wip --summary "x" --category pitfall
  assert_stderr_not_contains "unknown argument"
}

test_memory_upsert_rejects_implemented_status() {
  make_empty_index
  assert_exit 2 bash "$DOCS_INDEX_SH" upsert memory docs/memory/pitfall_x.md --status implemented:abc1234 --summary "x" --category pitfall
  assert_stderr_not_contains "unknown argument"
}

test_memory_setstatus_rejects_superseded_by() {
  make_index "docs/memory/pitfall_x.md | memory | active | orig | 2026-07-01"
  assert_exit 2 bash "$DOCS_INDEX_SH" set-status docs/memory/pitfall_x.md "superseded-by:docs/memory/pitfall_other.md"
}

test_memory_setstatus_rejects_reference() {
  make_index "docs/memory/pitfall_x.md | memory | active | orig | 2026-07-01"
  assert_exit 2 bash "$DOCS_INDEX_SH" set-status docs/memory/pitfall_x.md "reference"
}

test_memory_setstatus_allows_expired() {
  make_index "docs/memory/pitfall_x.md | memory | active | orig | 2026-07-01"
  assert_exit 0 bash "$DOCS_INDEX_SH" set-status docs/memory/pitfall_x.md "expired:retro-2026-07-04:superseded"
}

test_memory_upsert_requires_category_flag() {
  make_empty_index
  assert_exit 2 bash "$DOCS_INDEX_SH" upsert memory docs/memory/pitfall_x.md --status active --summary "x"
}

test_memory_upsert_rejects_category_type() {
  make_empty_index
  assert_exit 2 bash "$DOCS_INDEX_SH" upsert memory docs/memory/pitfall_x.md --status active --summary "x" --category type
  assert_stderr_not_contains "unknown argument"
}

test_memory_upsert_rejects_category_kind() {
  make_empty_index
  assert_exit 2 bash "$DOCS_INDEX_SH" upsert memory docs/memory/pitfall_x.md --status active --summary "x" --category kind
  assert_stderr_not_contains "unknown argument"
}

test_memory_upsert_rejects_category_reference() {
  make_empty_index
  assert_exit 2 bash "$DOCS_INDEX_SH" upsert memory docs/memory/pitfall_x.md --status active --summary "x" --category reference
  assert_stderr_not_contains "unknown argument"
}

test_memory_upsert_accepts_all_four_categories() {
  make_empty_index
  assert_exit 0 bash "$DOCS_INDEX_SH" upsert memory docs/memory/convention_x.md --status active --summary "x" --category convention
  assert_exit 0 bash "$DOCS_INDEX_SH" upsert memory docs/memory/pitfall_x.md --status active --summary "x" --category pitfall
  assert_exit 0 bash "$DOCS_INDEX_SH" upsert memory docs/memory/decision_x.md --status active --summary "x" --category decision
  assert_exit 0 bash "$DOCS_INDEX_SH" upsert memory docs/memory/preference_x.md --status active --summary "x" --category preference
}

test_design_upsert_rejects_category_flag() {
  make_empty_index
  assert_exit 2 bash "$DOCS_INDEX_SH" upsert design docs/plans/2026-07-04-x-design/ --status active --summary "x" --category pitfall
  assert_stderr_not_contains "unknown argument"
}

# Regression test (PR #20 review): a literal " | " in a --summary value must
# not be able to shift the status/updated columns when downstream readers
# split the row on " | " (existing_status_map, cmd_show, cmd_list all do
# this). truncate_summary() escapes "|" to "\|" (GFM's own table-cell
# escape) before the row is written.
test_upsert_escapes_pipe_in_summary() {
  make_empty_index
  assert_exit 0 bash "$DOCS_INDEX_SH" upsert memory docs/memory/pitfall_x.md --status active --summary "alpha | beta gamma" --category pitfall
  assert_file_contains docs/README.md "alpha \\| beta gamma"
  assert_stdout_contains "memory | active | alpha \\| beta gamma" bash "$DOCS_INDEX_SH" show docs/memory/pitfall_x.md
}

# ---------------------------------------------------------------------------
# Task 005: memory scan + rebuild tests (RED — scan_folders() has no memory
# loop yet, so rebuild produces zero memory rows regardless of what's on disk
# under docs/memory/).
# ---------------------------------------------------------------------------

test_rebuild_discovers_memory_files() {
  mkdir -p docs/memory
  cat > docs/memory/pitfall_x.md <<'EOF'
---
name: x
category: pitfall
summary: some prior mistake
---
EOF
  make_empty_index
  _run bash "$DOCS_INDEX_SH" rebuild
  if [[ "$LAST_EXIT" -eq 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: rebuild expected exit 0, got $LAST_EXIT" >&2
  fi
  local data_rows
  data_rows=$(grep -c '^| docs/' docs/README.md || true)
  if [[ "$data_rows" -eq 1 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: rebuild produced $data_rows data rows, expected 1 for a single memory file" >&2
  fi
  if grep -q "docs/memory/pitfall_x.md | memory | active |" docs/README.md; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: rebuild did not produce a kind=memory status=active row for docs/memory/pitfall_x.md" >&2
  fi
}

test_rebuild_extracts_summary_from_memory_frontmatter() {
  mkdir -p docs/memory
  cat > docs/memory/pitfall_x.md <<'EOF'
---
name: x
category: pitfall
summary: foo bar
---
EOF
  make_empty_index
  _run bash "$DOCS_INDEX_SH" rebuild
  if [[ "$LAST_EXIT" -eq 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: rebuild expected exit 0, got $LAST_EXIT" >&2
  fi
  if grep -q "docs/memory/pitfall_x.md | memory | active | foo bar |" docs/README.md; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: rebuild did not extract 'foo bar' as the summary from the memory file's frontmatter" >&2
  fi
}

# Regression test (PR #20 review): the rebuild path's frontmatter-extracted
# summary (a separate injection point from cmd_upsert's truncate_summary())
# must also escape a literal "|" before it enters a row.
test_rebuild_escapes_pipe_in_memory_frontmatter_summary() {
  mkdir -p docs/memory
  cat > docs/memory/pitfall_x.md <<'EOF'
---
name: x
category: pitfall
summary: alpha | beta gamma
---
EOF
  make_empty_index
  assert_exit 0 bash "$DOCS_INDEX_SH" rebuild
  assert_file_contains docs/README.md "alpha \\| beta gamma"
}

test_rebuild_ignores_memory_archive_subdir() {
  # A live file and an archived sibling — the non-recursive docs/memory/*.md
  # glob must pick up the former and never descend into archive/ for the
  # latter.
  mkdir -p docs/memory/archive
  cat > docs/memory/pitfall_x.md <<'EOF'
---
name: x
category: pitfall
summary: a live mistake
---
EOF
  cat > docs/memory/archive/pitfall_old.md <<'EOF'
---
name: old
category: pitfall
summary: an archived mistake
---
EOF
  make_empty_index
  _run bash "$DOCS_INDEX_SH" rebuild
  if [[ "$LAST_EXIT" -eq 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: rebuild expected exit 0, got $LAST_EXIT" >&2
  fi
  assert_file_contains docs/README.md "docs/memory/pitfall_x.md"
  assert_file_not_contains docs/README.md "docs/memory/archive/pitfall_old.md"
  local data_rows
  data_rows=$(grep -c '^| docs/' docs/README.md || true)
  if [[ "$data_rows" -eq 1 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: rebuild produced $data_rows data rows, expected exactly 1 (the archived file must not produce a row)" >&2
  fi
}

test_rebuild_preserves_existing_memory_status() {
  # Reuses the existing existing_status_map merge behavior (no memory-specific
  # change needed there) — but only once scan_folders() actually includes the
  # path in the scanned set; asserted here so a future edit can't silently
  # break it.
  mkdir -p docs/memory
  cat > docs/memory/pitfall_x.md <<'EOF'
---
name: x
category: pitfall
summary: some prior mistake
---
EOF
  make_index "docs/memory/pitfall_x.md | memory | expired:retro-2026-07-04:superseded | orig | 2026-07-01"
  _run bash "$DOCS_INDEX_SH" rebuild
  if [[ "$LAST_EXIT" -eq 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: rebuild expected exit 0, got $LAST_EXIT" >&2
  fi
  if grep -q "expired:retro-2026-07-04:superseded" docs/README.md; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: rebuild did not preserve the existing expired status for the memory row" >&2
  fi
}

# ---------------------------------------------------------------------------
# Task 007: memory collapse grouping + archive tests (RED — topic_of_path()
# has no memory branch yet, so 3+ memory rows never share a (topic, cat) key
# and never collapse; no archive-move logic exists anywhere yet).
# ---------------------------------------------------------------------------

test_topic_of_path_groups_memory_by_category() {
  # Direct unit test of the bare function: source the script (via a no-op
  # `list` subcommand so the unconditional CLI dispatch at the bottom of the
  # file completes without exiting) into a subshell, then call topic_of_path
  # directly. The path is passed via an env var, not a positional argument,
  # since `source file arg...` would otherwise clobber $1 for the sourced
  # dispatch itself.
  local out1 out2
  out1="$(TOPIC_TEST_PATH="docs/memory/pitfall_foo.md" bash -c 'source "$DOCS_INDEX_SH" list >/dev/null 2>&1; topic_of_path "$TOPIC_TEST_PATH"')"
  out2="$(TOPIC_TEST_PATH="docs/memory/pitfall_bar.md" bash -c 'source "$DOCS_INDEX_SH" list >/dev/null 2>&1; topic_of_path "$TOPIC_TEST_PATH"')"
  if [[ "$out1" == "pitfall" && "$out2" == "pitfall" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: expected topic_of_path to return 'pitfall' for both memory paths, got '$out1' and '$out2'" >&2
  fi
}

test_collapse_groups_three_expired_memory_rows_by_category() {
  # 58 boilerplate design folders (implemented, sharing topic "topic") plus 3
  # real memory files (expired, category=pitfall) — 61 total scanned rows,
  # exceeding the 60-row ceiling so stage-1 collapse fires.
  make_folders 58 design
  local rows=() i name m
  for ((i = 1; i <= 58; i++)); do
    name="$(printf 'docs/plans/2026-01-%02d-topic-design' "$i")"
    rows+=("${name}/ | design | implemented:abc1234 | orig | 2026-07-01")
  done
  mkdir -p docs/memory
  for m in a b c; do
    cat > "docs/memory/pitfall_${m}.md" <<EOF
---
name: ${m}
category: pitfall
summary: mistake ${m}
---
EOF
    rows+=("docs/memory/pitfall_${m}.md | memory | expired:retro-2026-07-04:superseded | mistake ${m} | 2026-07-01")
  done
  make_index "${rows[@]}"
  _run bash "$DOCS_INDEX_SH" rebuild
  if [[ "$LAST_EXIT" -eq 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: rebuild expected exit 0, got $LAST_EXIT" >&2
  fi
  # The 3 expired pitfall memory rows collapse into exactly one summary row.
  local memory_rows
  memory_rows=$(grep -c '^| docs/memory/pitfall_' docs/README.md || true)
  if [[ "$memory_rows" -eq 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: expected the 3 individual pitfall memory rows to collapse away, found $memory_rows" >&2
  fi
  if grep -q "and 3 prior expired entries (topic: pitfall)" docs/README.md; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: expected a collapsed summary line for 3 prior expired pitfall memory entries" >&2
  fi
  # Stage-1 collapse folds the row into a summary line — it must NOT trigger
  # the stage-2 archive-on-drop side effect. The 3 backing files stay at
  # their original path, not docs/memory/archive/.
  local files_at_original files_archived
  files_at_original=$(ls docs/memory/pitfall_a.md docs/memory/pitfall_b.md docs/memory/pitfall_c.md 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$files_at_original" -eq 3 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: expected all 3 stage-1-collapsed memory files to remain at their original path, found $files_at_original" >&2
  fi
  files_archived=$(ls docs/memory/archive/ 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$files_archived" -eq 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: stage-1-collapsed memory files must not be archived, found $files_archived file(s) in docs/memory/archive/" >&2
  fi
}

test_collapse_never_collapses_active_memory_rows() {
  # 55 boilerplate design folders (implemented, sharing topic "topic") plus 3
  # active + 3 expired memory rows sharing category=pitfall — 61 total
  # scanned rows, exceeding the ceiling so stage-1 collapse fires. Active
  # memory rows must never enter the collapse candidate set (same rule
  # already applies to active design/plan/retro rows), even while the
  # sibling expired group does collapse.
  make_folders 55 design
  local rows=() i name m
  for ((i = 1; i <= 55; i++)); do
    name="$(printf 'docs/plans/2026-01-%02d-topic-design' "$i")"
    rows+=("${name}/ | design | implemented:abc1234 | orig | 2026-07-01")
  done
  mkdir -p docs/memory
  for m in 1 2 3; do
    cat > "docs/memory/pitfall_active${m}.md" <<EOF
---
name: active${m}
category: pitfall
summary: active memory ${m}
---
EOF
    rows+=("docs/memory/pitfall_active${m}.md | memory | active | active memory ${m} | 2026-07-01")
  done
  for m in 1 2 3; do
    cat > "docs/memory/pitfall_exp${m}.md" <<EOF
---
name: exp${m}
category: pitfall
summary: expired memory ${m}
---
EOF
    rows+=("docs/memory/pitfall_exp${m}.md | memory | expired:retro-2026-07-04:superseded | expired memory ${m} | 2026-07-01")
  done
  make_index "${rows[@]}"
  _run bash "$DOCS_INDEX_SH" rebuild
  if [[ "$LAST_EXIT" -eq 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: rebuild expected exit 0, got $LAST_EXIT" >&2
  fi
  # The 3 active rows survive individually (never collapse candidates).
  local active_rows
  active_rows=$(grep -c '^| docs/memory/pitfall_active[0-9]*\.md | memory | active |' docs/README.md || true)
  if [[ "$active_rows" -eq 3 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: expected 3 individual active memory rows to survive, found $active_rows" >&2
  fi
  # The 3 sibling expired rows collapse into one summary line — proves the
  # active exclusion is isolated from the sibling expired group's grouping.
  local expired_rows
  expired_rows=$(grep -c '^| docs/memory/pitfall_exp[0-9]*\.md ' docs/README.md || true)
  if [[ "$expired_rows" -eq 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: expected the 3 expired pitfall memory rows to collapse away, found $expired_rows" >&2
  fi
}

test_rebuild_archives_dropped_expired_memory_file() {
  # 60 active design folders (never collapse candidates, holding the count at
  # 60) plus 1 expired memory file — 61 total scanned rows. Stage 1 leaves
  # the lone expired memory row ungrouped (count=1 < 3); stage 2's "drop
  # expired entirely" rule then fires because the index is still over 60,
  # dropping that row — and its backing file must be archived, not left
  # orphaned with no index row pointing at it.
  make_folders 60 design
  local rows=() i name
  for ((i = 1; i <= 60; i++)); do
    name="$(printf 'docs/plans/2026-01-%02d-topic-design' "$i")"
    rows+=("${name}/ | design | active | a | 2026-07-01")
  done
  mkdir -p docs/memory
  cat > docs/memory/pitfall_stale.md <<'EOF'
---
name: stale
category: pitfall
summary: a stale mistake
---
EOF
  rows+=("docs/memory/pitfall_stale.md | memory | expired:retro-2026-07-04:superseded | a stale mistake | 2026-07-01")
  make_index "${rows[@]}"
  _run bash "$DOCS_INDEX_SH" rebuild
  if [[ "$LAST_EXIT" -eq 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: rebuild expected exit 0, got $LAST_EXIT" >&2
  fi
  assert_file_not_contains docs/README.md "docs/memory/pitfall_stale.md"
  if [[ -f docs/memory/archive/pitfall_stale.md ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: expected docs/memory/pitfall_stale.md to be moved to docs/memory/archive/" >&2
  fi
  if [[ -f docs/memory/pitfall_stale.md ]]; then
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: docs/memory/pitfall_stale.md still present at its original location" >&2
  else
    TESTS_PASSED=$((TESTS_PASSED + 1))
  fi
}

test_rebuild_does_not_archive_kept_rows() {
  # 59 active design folders plus 1 implemented design folder (the lone
  # implemented row keeps collapse_rows()'s candidate set non-empty without
  # reaching the >=3 grouping threshold, so it stays an individual row) plus
  # 1 active memory row — none are drop candidates (active is never dropped;
  # a singleton candidate is under the collapse threshold), so the memory
  # row's file must never be moved to docs/memory/archive/.
  make_folders 59 design
  local rows=() i name
  for ((i = 1; i <= 59; i++)); do
    name="$(printf 'docs/plans/2026-01-%02d-topic-design' "$i")"
    rows+=("${name}/ | design | active | a | 2026-07-01")
  done
  mkdir -p docs/plans/2026-01-99-topic-design
  : > docs/plans/2026-01-99-topic-design/_index.md
  rows+=("docs/plans/2026-01-99-topic-design/ | design | implemented:abc1234 | orig | 2026-07-01")
  mkdir -p docs/memory
  cat > docs/memory/pitfall_kept.md <<'EOF'
---
name: kept
category: pitfall
summary: a kept fact
---
EOF
  rows+=("docs/memory/pitfall_kept.md | memory | active | a kept fact | 2026-07-01")
  make_index "${rows[@]}"
  _run bash "$DOCS_INDEX_SH" rebuild
  if [[ "$LAST_EXIT" -eq 0 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: rebuild expected exit 0, got $LAST_EXIT" >&2
  fi
  assert_file_contains docs/README.md "docs/memory/pitfall_kept.md"
  if [[ -f docs/memory/pitfall_kept.md ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: docs/memory/pitfall_kept.md was moved away from its original location" >&2
  fi
  if [[ ! -f docs/memory/archive/pitfall_kept.md ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: docs/memory/pitfall_kept.md was unexpectedly archived" >&2
  fi
}

# ---------------------------------------------------------------------------
# Run all tests
# ---------------------------------------------------------------------------

echo "== Task 001: skeleton =="
run_test "no_args_exits_2"              test_no_args_exits_2
run_test "unknown_subcommand_exits_2"   test_unknown_subcommand_exits_2
run_test "script_is_executable"         test_script_is_executable

echo "== Task 002: list (RED expected) =="
run_test "list_no_filter_prints_all_rows"        test_list_no_filter_prints_all_rows
run_test "list_kind_design_filters"              test_list_kind_design_filters
run_test "list_status_implemented_prefix_matches" test_list_status_implemented_prefix_matches
run_test "list_empty_index_prints_nothing"       test_list_empty_index_prints_nothing

echo "== Task 004: show (RED expected) =="
run_test "show_tracked_path_prints_one_row"  test_show_tracked_path_prints_one_row
run_test "show_absent_path_exits_3"          test_show_absent_path_exits_3

echo "== Task 006: upsert (RED expected) =="
run_test "upsert_cold_start_creates_index"                  test_upsert_cold_start_creates_index
run_test "upsert_idempotent_same_path_updates_no_duplicates" test_upsert_idempotent_same_path_updates_no_duplicates
run_test "upsert_bad_status_done_rejected"                  test_upsert_bad_status_done_rejected
run_test "upsert_bad_status_complete_rejected"              test_upsert_bad_status_complete_rejected
run_test "upsert_bad_status_wrong_separator_rejected"       test_upsert_bad_status_wrong_separator_rejected
run_test "upsert_bad_status_draft_rejected"                 test_upsert_bad_status_draft_rejected
run_test "upsert_bad_kind_feature_rejected"                 test_upsert_bad_kind_feature_rejected
run_test "upsert_bad_kind_spec_rejected"                    test_upsert_bad_kind_spec_rejected
run_test "upsert_bad_kind_type_rejected"                    test_upsert_bad_kind_type_rejected
run_test "upsert_default_status_wip_for_design"             test_upsert_default_status_wip_for_design
run_test "upsert_default_status_active_for_retro"           test_upsert_default_status_active_for_retro

echo "== Task 008: set-status (RED expected) =="
run_test "set_status_transition_matrix_wip_to_active"                  test_set_status_transition_matrix_wip_to_active
run_test "set_status_transition_matrix_active_to_implemented"          test_set_status_transition_matrix_active_to_implemented
run_test "set_status_transition_matrix_active_to_superseded"           test_set_status_transition_matrix_active_to_superseded
run_test "set_status_transition_matrix_active_to_expired"              test_set_status_transition_matrix_active_to_expired
run_test "set_status_transition_matrix_active_to_wip"                  test_set_status_transition_matrix_active_to_wip
run_test "set_status_transition_matrix_wip_to_expired"                test_set_status_transition_matrix_wip_to_expired
run_test "set_status_transition_matrix_implemented_to_wip"             test_set_status_transition_matrix_implemented_to_wip
run_test "set_status_transition_matrix_implemented_to_expired_rejected" test_set_status_transition_matrix_implemented_to_expired_rejected
run_test "set_status_transition_matrix_implemented_to_superseded_rejected" test_set_status_transition_matrix_implemented_to_superseded_rejected
run_test "set_status_transition_matrix_expired_to_active_rejected"     test_set_status_transition_matrix_expired_to_active_rejected
run_test "set_status_transition_matrix_expired_to_superseded_rejected" test_set_status_transition_matrix_expired_to_superseded_rejected
run_test "set_status_transition_matrix_reference_to_expired_rejected"  test_set_status_transition_matrix_reference_to_expired_rejected
run_test "set_status_transition_matrix_reference_to_superseded_rejected" test_set_status_transition_matrix_reference_to_superseded_rejected
run_test "set_status_transition_matrix_superseded_to_active_rejected"  test_set_status_transition_matrix_superseded_to_active_rejected
run_test "set_status_rejected_leaves_index_byte_identical"            test_set_status_rejected_leaves_index_byte_identical
run_test "set_status_absent_path_exits_3"                             test_set_status_absent_path_exits_3
run_test "set_status_bad_status_rejected_exit_2"                      test_set_status_bad_status_rejected_exit_2
run_test "set_status_allowed_flips_status_and_date"                   test_set_status_allowed_flips_status_and_date

echo "== Task 010: rebuild (RED expected) =="
run_test "rebuild_regenerates_from_filesystem_truth"   test_rebuild_regenerates_from_filesystem_truth
run_test "rebuild_preserves_existing_statuses"         test_rebuild_preserves_existing_statuses
run_test "rebuild_drops_absent_paths"                  test_rebuild_drops_absent_paths
run_test "rebuild_seeds_writing_skills_as_reference"   test_rebuild_seeds_writing_skills_as_reference
run_test "rebuild_applies_60_line_collapse"            test_rebuild_applies_60_line_collapse
run_test "rebuild_never_collapses_active_wip_superseded" test_rebuild_never_collapses_active_wip_superseded
run_test "rebuild_idempotent"                          test_rebuild_idempotent

echo "== Task 012: edge cases (RED expected) =="
run_test "list_on_malformed_index_exits_2"             test_list_on_malformed_index_exits_2
run_test "upsert_rejects_leading_slash_path"           test_upsert_rejects_leading_slash_path
run_test "upsert_rejects_parent_traversal_path"        test_upsert_rejects_parent_traversal_path
run_test "rebuild_recovers_from_malformed_index"       test_rebuild_recovers_from_malformed_index

echo "== Memory-layer task 001: kind vocabulary (RED expected) =="
run_test "memory_kind_accepted_by_upsert"              test_memory_kind_accepted_by_upsert
run_test "memory_kind_accepted_by_list_filter"         test_memory_kind_accepted_by_list_filter
run_test "memory_kind_rejected_message_mentions_memory" test_memory_kind_rejected_message_mentions_memory
run_test "memory_default_status_is_active"             test_memory_default_status_is_active

echo "== Memory-layer task 003: status restriction + category flag (RED expected) =="
run_test "memory_upsert_rejects_wip_status"            test_memory_upsert_rejects_wip_status
run_test "memory_upsert_rejects_implemented_status"    test_memory_upsert_rejects_implemented_status
run_test "memory_setstatus_rejects_superseded_by"      test_memory_setstatus_rejects_superseded_by
run_test "memory_setstatus_rejects_reference"          test_memory_setstatus_rejects_reference
run_test "memory_setstatus_allows_expired"             test_memory_setstatus_allows_expired
run_test "memory_upsert_requires_category_flag"        test_memory_upsert_requires_category_flag
run_test "memory_upsert_rejects_category_type"         test_memory_upsert_rejects_category_type
run_test "memory_upsert_rejects_category_kind"         test_memory_upsert_rejects_category_kind
run_test "memory_upsert_rejects_category_reference"    test_memory_upsert_rejects_category_reference
run_test "memory_upsert_accepts_all_four_categories"   test_memory_upsert_accepts_all_four_categories
run_test "design_upsert_rejects_category_flag"         test_design_upsert_rejects_category_flag
run_test "upsert_escapes_pipe_in_summary"              test_upsert_escapes_pipe_in_summary

echo "== Memory-layer task 005: memory scan + rebuild (RED expected) =="
run_test "rebuild_discovers_memory_files"                     test_rebuild_discovers_memory_files
run_test "rebuild_extracts_summary_from_memory_frontmatter"   test_rebuild_extracts_summary_from_memory_frontmatter
run_test "rebuild_escapes_pipe_in_memory_frontmatter_summary" test_rebuild_escapes_pipe_in_memory_frontmatter_summary
run_test "rebuild_ignores_memory_archive_subdir"              test_rebuild_ignores_memory_archive_subdir
run_test "rebuild_preserves_existing_memory_status"           test_rebuild_preserves_existing_memory_status

echo "== Memory-layer task 007: collapse grouping + archive-on-drop (RED expected) =="
run_test "topic_of_path_groups_memory_by_category"           test_topic_of_path_groups_memory_by_category
run_test "collapse_groups_three_expired_memory_rows_by_category" test_collapse_groups_three_expired_memory_rows_by_category
run_test "collapse_never_collapses_active_memory_rows"       test_collapse_never_collapses_active_memory_rows
run_test "rebuild_archives_dropped_expired_memory_file"      test_rebuild_archives_dropped_expired_memory_file
run_test "rebuild_does_not_archive_kept_rows"                test_rebuild_does_not_archive_kept_rows

summarize
