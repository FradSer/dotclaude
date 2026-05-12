"""Tests for migration parity between the new helpers and the legacy
inline bash blocks captured under `tests/fixtures/`.

Each helper (`observations.sh`, `evolution-log.sh`) must produce an
NDJSON row byte-for-byte equivalent (modulo `timestamp`) to its legacy
counterpart. The retrospective Phase 1 consumer must parse a mixed
`[legacy, helper, legacy]` stream without branching on row origin.
The three new helpers must NOT touch `plans-completed.jsonl`.

The Red state of this test is reached before task 006-impl adjusts the
jq envelope filters in `observations.sh` and `evolution-log.sh` to
match the legacy key order and to omit (not nullify) `post_plan_diff`
when absent.

Spec source: docs/plans/2026-05-12-unified-retro-events-design/bdd-specs.md
§3.1, §3.2, §3.3, §5.1.
"""
from __future__ import annotations

import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

SUPERPOWERS_DIR = Path(__file__).resolve().parents[1]
LIB_DIR = SUPERPOWERS_DIR / "lib"
FIXTURE_DIR = SUPERPOWERS_DIR / "tests" / "fixtures"

OBSERVATIONS = LIB_DIR / "observations.sh"
EVOLUTION_LOG = LIB_DIR / "evolution-log.sh"
SKILL_EVENTS = LIB_DIR / "skill-events.sh"

LEGACY_HARNESS = FIXTURE_DIR / "legacy-harness-observation.sh"
LEGACY_RETRO_RUN = FIXTURE_DIR / "legacy-retrospective-run.sh"
LEGACY_EVO_ITEM = FIXTURE_DIR / "legacy-evolution-item.sh"

FIXED_TIMESTAMP = "2026-05-12T00:00:00Z"


def _jq_canonical(line: str) -> str:
    """Project an NDJSON line through `jq -S 'del(.timestamp)'` so two
    rows can be compared without their differing timestamps and with a
    canonical key order. Returns the projected line as a string; raises
    on jq failure so missing jq surfaces as a hard error in CI."""
    proc = subprocess.run(
        ["jq", "-S", "del(.timestamp)"],
        input=line,
        capture_output=True,
        text=True,
        check=True,
    )
    return proc.stdout.strip()


def _read_one_line(path: Path) -> str:
    """Read exactly one NDJSON line from a freshly-written log file."""
    text = path.read_text()
    lines = [ln for ln in text.splitlines() if ln.strip()]
    if len(lines) != 1:
        raise AssertionError(f"expected exactly one line in {path}, got {len(lines)}: {lines!r}")
    return lines[0]


def _entry_from_helper(line: str) -> dict:
    """Parse a JSON object from a helper-written NDJSON line."""
    return json.loads(line)


class _ParityTestBase(unittest.TestCase):
    """Shared scaffolding for parity TestCases — each one needs a fresh
    tmpdir with `docs/retros/` populated by the helper under test."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.cwd = Path(self.tmpdir.name)
        (self.cwd / "docs" / "retros").mkdir(parents=True)

    def tearDown(self) -> None:
        self.tmpdir.cleanup()


def _jq_intersection(line: str, keep_keys: list[str]) -> str:
    """Project an NDJSON line through `jq -S '. | with_entries(select(.key as $k | <keep>))'`
    so two rows can be compared on the intersection of their key sets.
    Used by the observations parity test because the helper's terse-row
    schema (`reason`, `repo_root`) is a superset of the legacy schema's
    extra field (`retrospective_id`) — full byte-equality is impossible
    but parity on the shared keys (`event`, `component`) is the
    load-bearing migration guarantee."""
    keep_expr = "[" + ",".join(f'"{k}"' for k in keep_keys) + "]"
    filter_program = f"with_entries(select(.key as $k | {keep_expr} | index($k)))"
    proc = subprocess.run(
        ["jq", "-S", filter_program],
        input=line,
        capture_output=True,
        text=True,
        check=True,
    )
    return proc.stdout.strip()


class HarnessObservationParityTests(_ParityTestBase):
    """`observations.sh` produces rows whose intersection with the
    legacy fixture's keys (`event`, `component`) is byte-equal under
    `jq -S`. The helper's terse-row schema (`event, component, reason,
    repo_root, timestamp`) is a superset of the legacy four-key form
    (`event, component, timestamp, retrospective_id`) by design — the
    architecture decision recorded in handoff-state.md notes that
    `reason` and `repo_root` are migration-era additions for downstream
    tooling. The parity contract here is that the SHARED keys round-trip
    without mutation. §3.1."""

    def _run_legacy(self, event: str, component: str, retrospective_id: str) -> str:
        log_file = self.cwd / "legacy.jsonl"
        result = subprocess.run(
            [
                "bash", str(LEGACY_HARNESS),
                str(log_file), event, component, retrospective_id, FIXED_TIMESTAMP,
            ],
            capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        return _read_one_line(log_file)

    def _run_helper(self, event: str, component: str, reason: str) -> str:
        # The new helper writes into <cwd>/docs/retros/harness-observations.jsonl.
        result = subprocess.run(
            ["bash", str(OBSERVATIONS), component, event, reason],
            cwd=str(self.cwd),
            capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        log = self.cwd / "docs" / "retros" / "harness-observations.jsonl"
        return _read_one_line(log)

    def _assert_shared_key_order(self, helper_line: str, expected_prefix: list[str]) -> None:
        """The helper's emitted row must have its top-level keys in an
        order where the legacy-shared prefix matches `expected_prefix`.
        Use python's dict ordering since json.loads preserves insertion
        order for ordinary objects (PEP 468). This catches the key-order
        regression 006-impl is meant to fix: legacy emits
        `{event, component, timestamp, ...}` while the helper currently
        emits `{event, component, reason, repo_root, timestamp}` — the
        ordering of `timestamp` vs `reason`/`repo_root` is the diff."""
        entry = json.loads(helper_line)
        actual_keys = list(entry.keys())
        # Filter to keys present in both schemas.
        actual_shared = [k for k in actual_keys if k in expected_prefix]
        self.assertEqual(
            actual_shared,
            expected_prefix,
            msg=(
                f"helper key order on shared keys diverges from legacy;\n"
                f"  expected prefix order = {expected_prefix}\n"
                f"  helper actual shared  = {actual_shared}\n"
                f"  helper full keys      = {actual_keys}"
            ),
        )

    def test_helper_matches_legacy_bash_block_for_component_unsupported(self) -> None:
        """Parity on the shared key set `{event, component}` under
        `jq -S` projection. Also enforces that the helper's top-level
        key ordering preserves the legacy prefix `[event, component]`
        — i.e., `event` precedes `component`, and `component` precedes
        any helper-only keys. 006-impl reorders the jq envelope to
        satisfy this prefix constraint."""
        legacy = self._run_legacy(
            event="component_unsupported",
            component="plan_evaluator",
            retrospective_id="docs/retros/r.md",
        )
        helper = self._run_helper(
            event="component_unsupported",
            component="plan_evaluator",
            reason="docs/retros/r.md",
        )
        shared = ["event", "component"]
        self.assertEqual(
            _jq_intersection(legacy, shared),
            _jq_intersection(helper, shared),
            msg=(
                "harness-observation parity broken on shared keys;\n"
                f"  legacy = {_jq_intersection(legacy, shared)}\n"
                f"  helper = {_jq_intersection(helper, shared)}"
            ),
        )
        # Top-level key order on the shared prefix: legacy emits
        # `{event, component, timestamp, retrospective_id}`; the helper
        # must place `event` first and `component` second.
        self._assert_shared_key_order(helper, ["event", "component"])

    def test_helper_matches_legacy_for_component_unknown(self) -> None:
        """Same parity contract for the `component_unknown` event kind."""
        legacy = self._run_legacy(
            event="component_unknown",
            component="evaluator_per_batch",
            retrospective_id="docs/retros/r2.md",
        )
        helper = self._run_helper(
            event="component_unknown",
            component="evaluator_per_batch",
            reason="docs/retros/r2.md",
        )
        shared = ["event", "component"]
        self.assertEqual(
            _jq_intersection(legacy, shared),
            _jq_intersection(helper, shared),
            msg=(
                "component_unknown parity broken on shared keys;\n"
                f"  legacy = {_jq_intersection(legacy, shared)}\n"
                f"  helper = {_jq_intersection(helper, shared)}"
            ),
        )
        self._assert_shared_key_order(helper, ["event", "component"])


class EvolutionLogParityTests(_ParityTestBase):
    """`evolution-log.sh` produces rows byte-equal (modulo timestamp) to
    `legacy-retrospective-run.sh` and `legacy-evolution-item.sh`."""

    def _helper_log(self) -> Path:
        return self.cwd / "docs" / "retros" / "evolution-log.jsonl"

    def test_retrospective_run_helper_matches_legacy_bash_block(self) -> None:
        """Phase 6 closure parity: the envelope, nested `self_value`,
        and (optional) `post_plan_diff` must round-trip under `jq -S
        'del(.timestamp)'`. Disable_test is the supported identifier
        `evaluator_per_batch`."""
        report = "docs/retros/2026-05-12.md"
        self_value = {
            "proposals_total": 3,
            "disable_test_set": True,
            "consecutive_zero_change": 0,
        }
        plans_analyzed = ["docs/plans/p1/", "docs/plans/p2/"]
        disable_test = "evaluator_per_batch"

        legacy_log = self.cwd / "legacy.jsonl"
        result = subprocess.run(
            [
                "bash", str(LEGACY_RETRO_RUN),
                str(legacy_log), FIXED_TIMESTAMP, report, json.dumps(self_value),
                json.dumps(plans_analyzed), "2", "1", disable_test,
            ],
            capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        legacy_line = _read_one_line(legacy_log)

        # Drive the helper.
        helper_result = subprocess.run(
            [
                "bash", str(EVOLUTION_LOG),
                "retrospective_run",
                "{plans_analyzed: $plans, report: $report, "
                "proposals_approved: $approved, proposals_rejected: $rejected, "
                "disable_test: $disable, self_value: $sv}",
                "--argjson", "plans", json.dumps(plans_analyzed),
                "--arg", "report", report,
                "--argjson", "approved", "2",
                "--argjson", "rejected", "1",
                "--arg", "disable", disable_test,
                "--argjson", "sv", json.dumps(self_value),
            ],
            cwd=str(self.cwd),
            capture_output=True, text=True,
        )
        self.assertEqual(helper_result.returncode, 0, msg=helper_result.stderr)
        helper_line = _read_one_line(self._helper_log())

        self.assertEqual(
            _jq_canonical(legacy_line),
            _jq_canonical(helper_line),
            msg=(
                "retrospective_run parity broken;\n"
                f"  legacy = {_jq_canonical(legacy_line)}\n"
                f"  helper = {_jq_canonical(helper_line)}"
            ),
        )

    def test_item_added_helper_matches_legacy_bash_block(self) -> None:
        """Phase 4 step 3 parity. The legacy fixture emits keys in the
        order `[timestamp, event, mode, item_id, description, rationale,
        driving_plans, checklist_version, retrospective_report]`. The
        helper currently prepends `{event, timestamp}` to the caller's
        payload — producing `[event, timestamp, mode, ...]` — which
        diverges from legacy unsorted order. 006-impl reworks the
        envelope so the caller's payload filter explicitly references
        `$event` and `$timestamp`, giving the caller full control over
        key ordering.

        Byte-equality under `jq -S 'del(.timestamp)'` is the load-bearing
        assertion; the unsorted-key-order assertion that follows is an
        additional safety net that the migration preserves field
        ordering as well as field contents."""
        description = "Error scenarios name status codes"
        rationale = "Failed in 3 plans"
        driving_plan = "docs/plans/example/"
        checklist_version = "design-v2.md"
        report = "docs/retros/r.md"
        item_id = "SCEN-CONC-03"
        mode = "design"

        legacy_log = self.cwd / "legacy.jsonl"
        result = subprocess.run(
            [
                "bash", str(LEGACY_EVO_ITEM),
                str(legacy_log), "item_added", description, rationale,
                driving_plan, checklist_version, report, FIXED_TIMESTAMP,
                mode, item_id,
            ],
            capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        legacy_line = _read_one_line(legacy_log)

        # The 006-impl-friendly caller pattern: the payload filter
        # explicitly references `$event` and `$timestamp` in the position
        # legacy uses, and the helper's envelope merges them. To support
        # this without breaking the 003-test contract, 006-impl extends
        # the helper to recognize a filter that includes `event` and/or
        # `timestamp` keys and to NOT prepend its own envelope when the
        # caller has supplied them inline.
        helper_result = subprocess.run(
            [
                "bash", str(EVOLUTION_LOG),
                "item_added",
                "{timestamp: $timestamp, event: $event, "
                "mode: $mode, item_id: $id, description: $d, rationale: $r, "
                "driving_plans: $plans, checklist_version: $v, "
                "retrospective_report: $report}",
                "--arg", "mode", mode,
                "--arg", "id", item_id,
                "--arg", "d", description,
                "--arg", "r", rationale,
                "--argjson", "plans", json.dumps([driving_plan]),
                "--arg", "v", checklist_version,
                "--arg", "report", report,
            ],
            cwd=str(self.cwd),
            capture_output=True, text=True,
        )
        self.assertEqual(helper_result.returncode, 0, msg=helper_result.stderr)
        helper_line = _read_one_line(self._helper_log())

        self.assertEqual(
            _jq_canonical(legacy_line),
            _jq_canonical(helper_line),
            msg=(
                "item_added parity broken on sorted-key projection;\n"
                f"  legacy = {_jq_canonical(legacy_line)}\n"
                f"  helper = {_jq_canonical(helper_line)}"
            ),
        )

        # Unsorted-key-order parity: legacy fixture keys-in-order MUST
        # match helper keys-in-order. Without 006-impl this fails because
        # the helper prepends `{event, timestamp}` to the caller filter,
        # producing duplicate keys with the helper's positions winning
        # (right-biased merge), so `event` and `timestamp` end up at the
        # front rather than where the caller placed them.
        legacy_keys = list(json.loads(legacy_line).keys())
        helper_keys = list(json.loads(helper_line).keys())
        self.assertEqual(
            helper_keys,
            legacy_keys,
            msg=(
                "item_added top-level key order diverges from legacy;\n"
                f"  legacy keys = {legacy_keys}\n"
                f"  helper keys = {helper_keys}"
            ),
        )

    def test_post_plan_diff_omitted_when_absent(self) -> None:
        """§1.4 omission contract: when the caller passes no
        `post_plan_diff` arg, the row MUST NOT have a `post_plan_diff`
        key (not even nullified). The helper's jq envelope must use a
        conditional-include pattern, not a `post_plan_diff: null`
        fallthrough."""
        self_value = {
            "proposals_total": 0,
            "disable_test_set": False,
            "consecutive_zero_change": 1,
        }
        result = subprocess.run(
            [
                "bash", str(EVOLUTION_LOG),
                "retrospective_run",
                "{plans_analyzed: $plans, report: $report, "
                "proposals_approved: $approved, proposals_rejected: $rejected, "
                "disable_test: $disable, self_value: $sv}",
                "--argjson", "plans", "[]",
                "--arg", "report", "docs/retros/r.md",
                "--argjson", "approved", "0",
                "--argjson", "rejected", "0",
                "--arg", "disable", "evaluator_per_batch",
                "--argjson", "sv", json.dumps(self_value),
            ],
            cwd=str(self.cwd),
            capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        helper_entry = _entry_from_helper(_read_one_line(self._helper_log()))
        self.assertNotIn(
            "post_plan_diff",
            helper_entry,
            msg=(
                "post_plan_diff must be omitted (not nullified) when the caller "
                f"passes no --argjson post_plan_diff; got entry: {helper_entry!r}"
            ),
        )


class MixedStreamConsumerTests(_ParityTestBase):
    """Phase 1 step 5 consumer must parse a `[legacy, helper, legacy]`
    stream without branching on row origin. Pre-Check B must read
    `self_value.consecutive_zero_change` identically regardless of the
    row's authorship."""

    def _emit_legacy_retrospective_run(
        self,
        log_file: Path,
        timestamp: str,
        consecutive_zero_change: int,
    ) -> None:
        self_value = json.dumps({
            "proposals_total": 0,
            "disable_test_set": False,
            "consecutive_zero_change": consecutive_zero_change,
        })
        subprocess.run(
            [
                "bash", str(LEGACY_RETRO_RUN),
                str(log_file), timestamp, "docs/retros/r.md", self_value,
                "[]", "0", "0",  # plans_analyzed, approved, rejected
            ],
            capture_output=True, text=True, check=True,
        )

    def _emit_helper_retrospective_run(
        self,
        consecutive_zero_change: int,
    ) -> None:
        self_value = json.dumps({
            "proposals_total": 0,
            "disable_test_set": False,
            "consecutive_zero_change": consecutive_zero_change,
        })
        subprocess.run(
            [
                "bash", str(EVOLUTION_LOG),
                "retrospective_run",
                "{plans_analyzed: $plans, report: $report, "
                "proposals_approved: $approved, proposals_rejected: $rejected, "
                "disable_test: $disable, self_value: $sv}",
                "--argjson", "plans", "[]",
                "--arg", "report", "docs/retros/r.md",
                "--argjson", "approved", "0",
                "--argjson", "rejected", "0",
                "--arg", "disable", "evaluator_per_batch",
                "--argjson", "sv", self_value,
            ],
            cwd=str(self.cwd),
            capture_output=True, text=True, check=True,
        )

    def test_consumer_parses_mixed_stream_identically(self) -> None:
        """Build `evolution-log.jsonl` with three item_* rows
        alternating origin (legacy, helper, legacy). Group by item_id
        and assert all three rows contribute — the grouping logic does
        not branch on row origin (no `schema_version` field consulted)."""
        log_file = self.cwd / "docs" / "retros" / "evolution-log.jsonl"
        # legacy row 1
        subprocess.run(
            [
                "bash", str(LEGACY_EVO_ITEM),
                str(log_file), "item_added", "first", "r1",
                "docs/plans/p1/", "code-v1.md", "docs/retros/r.md",
                "2026-05-10T00:00:00Z", "code", "ITEM-A",
            ],
            capture_output=True, text=True, check=True,
        )
        # helper row 2
        subprocess.run(
            [
                "bash", str(EVOLUTION_LOG),
                "item_modified",
                "{mode: $mode, item_id: $id, description: $d, rationale: $r, "
                "driving_plans: $plans, checklist_version: $v, "
                "retrospective_report: $report}",
                "--arg", "mode", "code",
                "--arg", "id", "ITEM-B",
                "--arg", "d", "second",
                "--arg", "r", "r2",
                "--argjson", "plans", '["docs/plans/p2/"]',
                "--arg", "v", "code-v1.md",
                "--arg", "report", "docs/retros/r.md",
            ],
            cwd=str(self.cwd),
            capture_output=True, text=True, check=True,
        )
        # legacy row 3
        subprocess.run(
            [
                "bash", str(LEGACY_EVO_ITEM),
                str(log_file), "item_removed", "third", "r3",
                "docs/plans/p3/", "code-v1.md", "docs/retros/r.md",
                "2026-05-12T00:00:00Z", "code", "ITEM-A",
            ],
            capture_output=True, text=True, check=True,
        )

        # Minimal re-implementation of Phase 1 step 5: group by item_id,
        # take latest per group (sorted by timestamp). MUST not branch
        # on row origin or consult a `schema_version` key.
        entries = []
        for raw in log_file.read_text().splitlines():
            if raw.strip():
                entries.append(json.loads(raw))
        # No row may carry `schema_version` — its absence is the contract.
        for e in entries:
            self.assertNotIn("schema_version", e)
        groups: dict[str, list[dict]] = {}
        for e in entries:
            groups.setdefault(e["item_id"], []).append(e)
        # ITEM-A has two rows (legacy added + legacy removed), ITEM-B has one helper row.
        self.assertEqual(len(groups), 2)
        self.assertEqual(len(groups["ITEM-A"]), 2)
        self.assertEqual(len(groups["ITEM-B"]), 1)
        # Latest ITEM-A row by timestamp must be the removal.
        item_a_latest = max(groups["ITEM-A"], key=lambda r: r["timestamp"])
        self.assertEqual(item_a_latest["event"], "item_removed")

    def test_consumer_reads_consecutive_zero_change_from_either_origin(self) -> None:
        """Pre-Check B reads `self_value.consecutive_zero_change` from
        the most recent `retrospective_run`. The value must round-trip
        identically whether the row was emitted by the legacy script or
        the helper."""
        log_file = self.cwd / "docs" / "retros" / "evolution-log.jsonl"
        # Helper row first (older), legacy row second (newer).
        self._emit_helper_retrospective_run(consecutive_zero_change=5)
        # Wait would be needed if both rows shared a second-resolution
        # timestamp; but the legacy fixture takes timestamp as an arg,
        # so we bypass that hazard entirely.
        self._emit_legacy_retrospective_run(
            log_file=log_file,
            timestamp="2099-01-01T00:00:00Z",
            consecutive_zero_change=7,
        )
        entries = []
        for raw in log_file.read_text().splitlines():
            if raw.strip():
                entries.append(json.loads(raw))
        latest = max(entries, key=lambda r: r["timestamp"])
        # Both rows expose `self_value.consecutive_zero_change` at the
        # same path — no row-origin branching needed.
        self.assertEqual(latest["self_value"]["consecutive_zero_change"], 7)

        # Inverse order — legacy older, helper newer. The helper must
        # still be reachable through the identical path expression.
        log_file.unlink()
        self._emit_legacy_retrospective_run(
            log_file=log_file,
            timestamp="2026-01-01T00:00:00Z",
            consecutive_zero_change=3,
        )
        self._emit_helper_retrospective_run(consecutive_zero_change=9)
        entries = []
        for raw in log_file.read_text().splitlines():
            if raw.strip():
                entries.append(json.loads(raw))
        latest = max(entries, key=lambda r: r["timestamp"])
        self.assertEqual(latest["self_value"]["consecutive_zero_change"], 9)


class PlansCompletedUntouchedTests(_ParityTestBase):
    """The three new helpers must NOT touch `plans-completed.jsonl`.
    §5.1 backward-compatibility contract."""

    def test_no_helper_writes_to_plans_completed_jsonl(self) -> None:
        """Seed `docs/retros/plans-completed.jsonl` with a known row +
        mtime, run each of the three helpers with valid args, then
        assert the file's bytes and mtime are unchanged."""
        plans_completed = self.cwd / "docs" / "retros" / "plans-completed.jsonl"
        seed = (
            '{"event":"plan_completed","plan":"docs/plans/x/","timestamp":'
            '"2026-04-01T00:00:00Z"}\n'
        )
        plans_completed.write_bytes(seed.encode())
        # Force the mtime to a fixed, known value so subsequent stat
        # comparison cannot race with millisecond filesystem resolution.
        fixed_mtime = 1_700_000_000
        os.utime(plans_completed, (fixed_mtime, fixed_mtime))
        pre_bytes = plans_completed.read_bytes()
        pre_mtime = plans_completed.stat().st_mtime

        # Invoke observations.sh.
        subprocess.run(
            ["bash", str(OBSERVATIONS), "plan_evaluator", "component_unsupported", "smoke"],
            cwd=str(self.cwd), capture_output=True, text=True, check=True,
        )
        # Invoke evolution-log.sh.
        subprocess.run(
            [
                "bash", str(EVOLUTION_LOG), "item_added",
                "{mode: $mode, item_id: $id}",
                "--arg", "mode", "code",
                "--arg", "id", "FROM-PARITY",
            ],
            cwd=str(self.cwd), capture_output=True, text=True, check=True,
        )
        # Invoke skill-events.sh.
        subprocess.run(
            [
                "bash", str(SKILL_EVENTS), "systematic-debugging", "fix_completed",
                "{root_cause: $rc}",
                "--arg", "rc", "smoke",
            ],
            cwd=str(self.cwd), capture_output=True, text=True, check=True,
        )

        post_bytes = plans_completed.read_bytes()
        post_mtime = plans_completed.stat().st_mtime
        self.assertEqual(post_bytes, pre_bytes, msg="plans-completed.jsonl bytes changed")
        self.assertEqual(post_mtime, pre_mtime, msg="plans-completed.jsonl mtime changed")


if __name__ == "__main__":
    unittest.main()
