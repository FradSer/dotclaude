#!/bin/bash
# Shared helpers for the docs-index test runner.
#
# Sourced by tests/run-docs-index-tests.sh. Provides:
#   - TESTS_PASSED, TESTS_FAILED counters
#   - assert_exit <expected> <cmd...>          run a command, check exit code
#   - assert_output <expected> <cmd...>        run, check stdout equals (literal)
#   - assert_output_contains <needle> <cmd...> run, check stdout contains
#   - assert_no_stdout <cmd...>                run, check stdout is empty
#   - make_index [rows...]                     write docs/README.md with rows
#   - make_empty_index                         write header-only docs/README.md
#   - setup_tmp_repo                           mktemp -d, cd, seed docs/, trap cleanup
#   - run_test <name> <fn>                     run a test function, count results

TESTS_PASSED=0
TESTS_FAILED=0

# Path to the script under test (absolute).
_DOCS_HELPERS_DIR="$(dirname "${BASH_SOURCE[0]}")"
# Resolve to absolute without relying on `cd` (zsh `cd` prints the path, which
# corrupts command substitution in this environment).
case "$_DOCS_HELPERS_DIR" in
  /*) : ;;
  *) _DOCS_HELPERS_DIR="$PWD/$_DOCS_HELPERS_DIR" ;;
esac
DOCS_INDEX_SH="$_DOCS_HELPERS_DIR/../lib/docs-index.sh"
export DOCS_INDEX_SH

TMP_REPO=""

setup_tmp_repo() {
  TMP_REPO="$(mktemp -d)"
  # zsh `cd` prints the target dir; redirect so it doesn't corrupt stdout.
  cd "$TMP_REPO" >/dev/null 2>&1
  mkdir -p docs
  # Initialize as a git repo so repo_root's git fallback resolves.
  git init -q 2>/dev/null || true
  # CLAUDE_PROJECT_DIR takes precedence in repo_root; point it at the tmp repo
  # so the script writes to docs/ under $TMP_REPO regardless of cwd drift.
  export CLAUDE_PROJECT_DIR="$TMP_REPO"
}

teardown_tmp_repo() {
  if [[ -n "${TMP_REPO:-}" && -d "${TMP_REPO:-}" ]]; then
    rm -rf "$TMP_REPO"
  fi
}

trap teardown_tmp_repo EXIT

# make_index [row1 row2 ...]
# Each row is a single pipe-delimited line (5 fields, no leading/trailing pipes
# needed — we add them). Example:
#   make_index \
#     "docs/plans/2026-07-01-auth-design/ | design | active | First design | 2026-07-01" \
#     "docs/plans/2026-07-04-auth-plan/ | plan | wip | Plan | 2026-07-04"
make_index() {
  local rows=("$@")
  {
    cat <<'EOF'
# Docs Index

> Auto-maintained by `lib/docs-index.sh`. One row per design/plan/retro folder.
> Last rebuild: 2026-07-04

| path | kind | status | summary | updated |
|---|---|---|---|---|
EOF
    local row
    for row in "${rows[@]}"; do
      printf '| %s |\n' "$row"
    done
  } > docs/README.md
}

make_empty_index() {
  cat > docs/README.md <<'EOF'
# Docs Index

> Auto-maintained by `lib/docs-index.sh`. One row per design/plan/retro folder.
> Last rebuild: 2026-07-04

| path | kind | status | summary | updated |
|---|---|---|---|---|
EOF
}

# Run a command and capture stdout/stderr/exit.
_run() {
  local out err rc
  out="$("$@" 2>/tmp/di-err.$$)"; rc=$?
  err="$(cat /tmp/di-err.$$ 2>/dev/null || true)"
  rm -f /tmp/di-err.$$
  LAST_STDOUT="$out"
  LAST_STDERR="$err"
  LAST_EXIT=$rc
}

assert_exit() {
  local expected="$1"; shift
  _run "$@"
  if [[ "$LAST_EXIT" -eq "$expected" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: expected exit $expected, got $LAST_EXIT — cmd: $*" >&2
    echo "  stderr: $LAST_STDERR" >&2
  fi
}

assert_output() {
  local expected="$1"; shift
  _run "$@"
  if [[ "$LAST_STDOUT" == "$expected" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: expected stdout to equal:" >&2
    printf '%s\n' "$expected" | sed 's/^/    /' >&2
    echo "  got:" >&2
    printf '%s\n' "$LAST_STDOUT" | sed 's/^/    /' >&2
  fi
}

assert_no_stdout() {
  _run "$@"
  if [[ -z "$LAST_STDOUT" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: expected empty stdout, got: $LAST_STDOUT" >&2
  fi
}

assert_stdout_line_count() {
  local expected="$1"; shift
  _run "$@"
  local actual
  actual=$(printf '%s' "$LAST_STDOUT" | grep -c '' || true)
  if [[ -z "$LAST_STDOUT" ]]; then
    actual=0
  fi
  if [[ "$actual" -eq "$expected" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: expected $expected stdout lines, got $actual — cmd: $*" >&2
    printf '%s\n' "$LAST_STDOUT" | sed 's/^/    /' >&2
  fi
}

assert_stdout_contains() {
  local needle="$1"; shift
  _run "$@"
  if printf '%s' "$LAST_STDOUT" | grep -qF -- "$needle"; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: stdout does not contain: $needle — cmd: $*" >&2
    printf '%s\n' "$LAST_STDOUT" | sed 's/^/    /' >&2
  fi
}

assert_file_contains() {
  local file="$1" needle="$2"
  if grep -qF -- "$needle" "$file" 2>/dev/null; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: $file does not contain: $needle" >&2
  fi
}

assert_file_not_contains() {
  local file="$1" needle="$2"
  if grep -qF -- "$needle" "$file" 2>/dev/null; then
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: $file unexpectedly contains: $needle" >&2
  else
    TESTS_PASSED=$((TESTS_PASSED + 1))
  fi
}

# Assert the LAST_STDERR does NOT contain <needle>. Used by rejection tests so
# they only PASS once real validation (not the not-yet-implemented stub) drives
# the exit-2 — guards against spurious passes while the stub is in place.
assert_stderr_not_contains() {
  local needle="$1"
  if printf '%s' "$LAST_STDERR" | grep -qF -- "$needle"; then
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: stderr unexpectedly contains: $needle" >&2
  else
    TESTS_PASSED=$((TESTS_PASSED + 1))
  fi
}

run_test() {
  local name="$1" fn="$2"
  setup_tmp_repo
  "$fn"
}

summarize() {
  echo "---"
  echo "passed: $TESTS_PASSED"
  echo "failed: $TESTS_FAILED"
  if [[ "$TESTS_FAILED" -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}
