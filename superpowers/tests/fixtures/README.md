# Test fixtures — legacy NDJSON emission capture

These bash scripts are byte-for-byte captures of the pre-migration inline
`jq -nc` blocks that `retrospective/SKILL.md` uses to write to
`docs/retros/harness-observations.jsonl` and `docs/retros/evolution-log.jsonl`.
They are the golden inputs for the migration-parity test in task 006: each
script's output is compared against the new helper's output (under a
deterministic timestamp) to prove the cut-over is invisible to downstream
readers.

## Why self-contained scripts

Each script:

- Has no `source` of any file under `superpowers/lib/`. The point is to
  preserve the pre-migration write surface exactly as Claude would
  construct it from the SKILL.md template, without any new helper layer.
- Takes the timestamp as an explicit argument so parity tests can
  substitute a fixed value and assert byte-equality on the resulting
  NDJSON line.
- Appends to its `<log_file>` argument and exits 0. The `mkdir -p` of
  the parent directory is included so the script can run inside a fresh
  `tempfile.TemporaryDirectory` project root.

## Source line numbers in `retrospective/SKILL.md`

| Script | SKILL.md location | Reference template |
|--------|-------------------|--------------------|
| `legacy-harness-observation.sh` | Phase 5c refusal gate, line 146 | `bdd-specs.md` §1 "log_harness_observation produces a row indistinguishable from the legacy Phase 5c bash block" |
| `legacy-retrospective-run.sh` | Phase 6 closure, lines 176-191 | `references/evolution-protocol.md` lines 101-125 |
| `legacy-evolution-item.sh` | Phase 4 step 3, line 104 | `references/evolution-protocol.md` lines 83-97 |

`SKILL.md` describes these `jq -nc` invocations in prose rather than as
literal bash; the line ranges above identify the prose passage and the
schema reference that together specify the legacy form. The scripts
capture the canonical bash that satisfies both.

## Regeneration procedure

If the underlying schema or `jq -nc` invocation changes in `SKILL.md` or
`evolution-protocol.md`, regenerate the fixture by:

1. Re-read the SKILL.md prose and the referenced schema template.
2. Translate the schema into a single `jq -nc --arg ... --argjson ...
   '{field: $arg, ...}'` invocation, keeping `--arg` order and field
   order identical to the schema template.
3. Re-run the smoke commands below; confirm `jq -e .` returns 0 on every
   output line.

## Smoke commands (verification)

```bash
cd superpowers
mkdir -p /tmp/retro-fixture-smoke

# harness-observations row (component_unsupported sentinel)
bash tests/fixtures/legacy-harness-observation.sh \
  /tmp/retro-fixture-smoke/harness.jsonl \
  component_unsupported plan_evaluator docs/retros/test.md \
  2026-05-12T00:00:00Z
jq -e . /tmp/retro-fixture-smoke/harness.jsonl

# evolution-log retrospective_run row
bash tests/fixtures/legacy-retrospective-run.sh \
  /tmp/retro-fixture-smoke/evolution.jsonl \
  2026-05-12T00:00:00Z 'docs/retros/x.md' \
  '{"proposals_total":0,"disable_test_set":false,"consecutive_zero_change":1}'
jq -e . /tmp/retro-fixture-smoke/evolution.jsonl

# evolution-log item_added row (handles item_removed / _modified / _promoted via $2)
bash tests/fixtures/legacy-evolution-item.sh \
  /tmp/retro-fixture-smoke/evolution.jsonl \
  item_added 'add design folder' 'rationale' 'docs/plans/x' \
  code-v2.md 'docs/retros/r.md' \
  2026-05-12T00:00:00Z

jq -e . /tmp/retro-fixture-smoke/evolution.jsonl

rm -rf /tmp/retro-fixture-smoke
```

A passing smoke run means every emitted line is a valid one-line NDJSON
object. Byte-equality with the helper output is asserted by task 006.
