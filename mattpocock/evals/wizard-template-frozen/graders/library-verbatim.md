---
type: llm
weight: 3
---

The wizard skill mandates: the library section ABOVE the `# STAGES` marker in scripts/setup-wizard.sh must be copied verbatim from the skill's template.sh (byte-identical, never hand-edited); the author edits only below the marker.

The template's library (for comparison) has this structure: shebang + header comments referencing the STAGES marker, `set -euo pipefail`, colour/TOTAL_STAGES state vars, helpers (_clear, banner, stage, say, step, note, warn, open_url, ask, ask_secret, pause, confirm, _existing, write_env, set_secret, set_var, finish), and ends at the `# STAGES: author this section` divider. Below that divider the template opens a `run_wizard() {` wrapper, contains the example stages and `finish`, then closes with `}` and `run_wizard "$@"; exit`. The wrapper is part of the frozen template, not an author edit.

PASS only if:
1. scripts/setup-wizard.sh contains the `# STAGES: author this section` divider, AND everything above that divider equals the template's library (the trace should show the template was read, and the file's head should match it line-for-line — no paraphrased helper names or invented helpers above the marker).
2. Below the marker the wizard keeps the `run_wizard() {` wrapper and the closing `finish`, `}`, `run_wizard "$@"; exit` lines, and defines 3 stages covering: Stripe keys -> .env (with ask_secret for the secret key), D1 id -> wrangler.toml, webhook signing secret -> .env + STRIPE_WEBHOOK_SECRET via gh.
3. `bash -n scripts/setup-wizard.sh` was actually run in the trace (and the report shows its outcome; shellcheck absence was acknowledged, not faked).

FAIL if the above-marker section was hand-written (differs structurally from template helpers), the `run_wizard` wrapper or its closing lines were removed, or the wizard was executed rather than statically traced.
