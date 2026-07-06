# Task 001: Setup — Script Skeleton, Test Harness, repo_root Sourcing

**depends-on**: (none — foundation task)

## BDD Scenario

```gherkin
Scenario: Script skeleton exists and sources repo_root
  Given the superpowers plugin is installed at a known root
  And lib/utils.sh exports a repo_root function
  When the file lib/docs-index.sh is created
  Then it has a shebang line #!/bin/bash
  And it has set -euo pipefail
  And it sources lib/utils.sh for repo_root
  And it has a Usage: header block listing all 5 subcommands
  And it has an Exit codes: header block documenting 0/1/2/3
  And invoking docs-index.sh with no args exits 2 with a usage message
  And invoking docs-index.sh with an unknown subcommand exits 2
```

## Interfaces

```bash
# Script: lib/docs-index.sh
# Sourcing: source "${CLAUDE_PLUGIN_ROOT}/lib/utils.sh"; ROOT=$(repo_root)
# Dispatcher: case "$1" in list|show|upsert|set-status|rebuild) ... ;; *) echo usage >&2; exit 2 ;; esac
# Test harness: tests/test-docs-index.bats (or tests/run-docs-index-tests.sh)
# All downstream subcommand tasks (002-013) plug into this dispatcher.
```

## Files

- `lib/docs-index.sh` (new — skeleton with dispatcher only; subcommand bodies added in tasks 003/005/007/009/011)
- `tests/test-docs-index.bats` (new — test harness; or `tests/run-docs-index-tests.sh` if bats unavailable)
- `tests/fixtures/` (new — empty dir for temp-repo test fixtures)

## Steps

1. Decide test harness: check whether `bats` is on PATH (`command -v bats`). If yes, use `tests/test-docs-index.bats`. If no, use a plain bash `tests/run-docs-index-tests.sh` that sources helper functions and uses `assert_exit`/`assert_output` patterns from a small `tests/test_helpers.sh`. Document the decision in the test file header.
2. Create `lib/docs-index.sh` with: `#!/bin/bash` shebang, `set -euo pipefail`, header comment block (purpose, Usage, Exit codes mirroring `lib/seed-checklists.sh` style), `source` of `lib/utils.sh`, a `usage()` function, and a dispatcher `case "$1"` that accepts `list|show|upsert|set-status|rebuild` (each stub exits 2 with "not yet implemented" for now — impl tasks fill them) and rejects anything else with exit 2.
3. Resolve the script's own dir for sourcing `utils.sh`: use `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` then `source "${SCRIPT_DIR}/utils.sh"`.
4. Create the test harness with a helper that creates a temp repo (`mktemp -d`), `cd` into it, seeds a `docs/` dir, and tears down on exit via `trap`.
5. Write tests for: no-args exits 2; unknown subcommand exits 2; script is executable (`-x` bit).

## Verification

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
bash tests/run-docs-index-tests.sh   # or: bats tests/test-docs-index.bats
bash lib/docs-index.sh                # no args → exit 2, usage to stderr
bash lib/docs-index.sh bogus-cmd      # → exit 2
shellcheck lib/docs-index.sh          # if shellcheck available
```
