"""Tests for lib/evolution-log.sh — the evolution-log NDJSON helper that
retrospective Phase 4 step 3 and Phase 6 closure will call.

Mirrors the three-mode structure of `tests/test_observations_sh.py`:
Executed / Sourced / Degradation TestCases, plus a per-event-type
schema TestCase covering the `retrospective_run` shape (the only event
whose envelope carries a nested sub-object). Until `lib/evolution-log.sh`
lands, these tests fail at the file-not-found stage — that is the
intended Red state for task 003-impl to turn Green.

Spec source: docs/plans/2026-05-12-unified-retro-events-design/bdd-specs.md
§1.4 (retrospective_run parity), §2 (best-effort degradation), §5.3
(existing rows never rewritten).
"""
from __future__ import annotations

import json
import os
import shutil
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path

SUPERPOWERS_DIR = Path(__file__).resolve().parents[1]
EVOLUTION_LOG = SUPERPOWERS_DIR / "lib" / "evolution-log.sh"

# The evolution-log envelope merges {event, timestamp} with the caller-
# supplied payload jq filter, producing a flat row that matches the
# existing `evolution-log.jsonl` schema (see evolution-protocol.md
# lines 85-170). Note: payload is MERGED, not nested — distinct from
# skill-events.sh.
ENVELOPE_KEYS = {"event", "timestamp"}

ISO_UTC_REGEX = r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$"


def run_executed(
    cwd: Path,
    *args: str,
    env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess:
    """Invoke evolution-log.sh in executed mode."""
    return subprocess.run(
        ["bash", str(EVOLUTION_LOG), *args],
        cwd=str(cwd),
        capture_output=True,
        text=True,
        env=env,
    )


def run_sourced(
    cwd: Path,
    body: str,
    env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess:
    """Source evolution-log.sh under `set -euo pipefail` and run a body.
    Verifies sourcing does not perturb the caller's error-handling regime."""
    script = f"set -euo pipefail\nsource {EVOLUTION_LOG}\n{body}\n"
    return subprocess.run(
        ["bash", "-c", script],
        cwd=str(cwd),
        capture_output=True,
        text=True,
        env=env,
    )


def _log_path(cwd: Path) -> Path:
    return cwd / "docs" / "retros" / "evolution-log.jsonl"


class EvolutionLogExecutedTests(unittest.TestCase):
    """`bash lib/evolution-log.sh <event_type> <payload_filter> [args]` path.

    One assertion per event kind in `evolution-protocol.md` lines 85-170:
    item_added, item_removed, item_modified, item_promoted,
    retrospective_run, component_reinstated. Each case asserts exit 0,
    one new NDJSON line, and the envelope merges {event, timestamp} with
    the caller's payload object."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.cwd = Path(self.tmpdir.name)

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def _read_one(self) -> dict:
        log = _log_path(self.cwd)
        self.assertTrue(log.exists(), "evolution-log.jsonl was not created")
        lines = log.read_text().splitlines()
        self.assertEqual(len(lines), 1, msg=f"expected one row, got: {lines!r}")
        return json.loads(lines[0])

    def test_item_added_writes_full_envelope(self) -> None:
        """item_added carries mode/item_id/description/rationale/
        driving_plans/checklist_version/retrospective_report — all merged
        flat with {event, timestamp}."""
        result = run_executed(
            self.cwd,
            "item_added",
            "{mode: $mode, item_id: $id, description: $d, rationale: $r, "
            "driving_plans: $plans, checklist_version: $v, "
            "retrospective_report: $report}",
            "--arg", "mode", "design",
            "--arg", "id", "SCEN-CONC-03",
            "--arg", "d", "Error scenarios name status codes",
            "--arg", "r", "Failed in 3 plans",
            "--argjson", "plans", '["plan-a","plan-b"]',
            "--arg", "v", "design-v2.md",
            "--arg", "report", "docs/retros/r.md",
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        entry = self._read_one()
        self.assertEqual(entry["event"], "item_added")
        self.assertRegex(entry["timestamp"], ISO_UTC_REGEX)
        self.assertEqual(entry["mode"], "design")
        self.assertEqual(entry["item_id"], "SCEN-CONC-03")
        self.assertEqual(entry["description"], "Error scenarios name status codes")
        self.assertEqual(entry["rationale"], "Failed in 3 plans")
        self.assertEqual(entry["driving_plans"], ["plan-a", "plan-b"])
        self.assertEqual(entry["checklist_version"], "design-v2.md")
        self.assertEqual(entry["retrospective_report"], "docs/retros/r.md")

    def test_item_removed_writes_full_envelope(self) -> None:
        result = run_executed(
            self.cwd,
            "item_removed",
            "{mode: $mode, item_id: $id, description: $d, rationale: $r, "
            "driving_plans: $plans, checklist_version: $v, "
            "retrospective_report: $report}",
            "--arg", "mode", "design",
            "--arg", "id", "SCEN-CONC-03",
            "--arg", "d", "removed for low yield",
            "--arg", "r", "N=8 zero-failure reports",
            "--argjson", "plans", '["plan-c"]',
            "--arg", "v", "design-v3.md",
            "--arg", "report", "docs/retros/r2.md",
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        entry = self._read_one()
        self.assertEqual(entry["event"], "item_removed")
        self.assertEqual(entry["item_id"], "SCEN-CONC-03")

    def test_item_modified_writes_full_envelope(self) -> None:
        result = run_executed(
            self.cwd,
            "item_modified",
            "{mode: $mode, item_id: $id, description: $d, rationale: $r, "
            "driving_plans: $plans, checklist_version: $v, "
            "retrospective_report: $report}",
            "--arg", "mode", "plan",
            "--arg", "id", "ITEM-2",
            "--arg", "d", "tightened wording",
            "--arg", "r", "ambiguous",
            "--argjson", "plans", '["plan-x"]',
            "--arg", "v", "plan-v1.md",
            "--arg", "report", "docs/retros/r3.md",
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        entry = self._read_one()
        self.assertEqual(entry["event"], "item_modified")
        self.assertEqual(entry["mode"], "plan")

    def test_item_promoted_writes_full_envelope(self) -> None:
        result = run_executed(
            self.cwd,
            "item_promoted",
            "{mode: $mode, item_id: $id, description: $d, rationale: $r, "
            "driving_plans: $plans, checklist_version: $v, "
            "retrospective_report: $report}",
            "--arg", "mode", "code",
            "--arg", "id", "CODE-VER-01",
            "--arg", "d", "promoted to MUST",
            "--arg", "r", "trial passed",
            "--argjson", "plans", '["plan-y","plan-z"]',
            "--arg", "v", "code-v1.md",
            "--arg", "report", "docs/retros/r4.md",
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        entry = self._read_one()
        self.assertEqual(entry["event"], "item_promoted")
        self.assertEqual(entry["driving_plans"], ["plan-y", "plan-z"])

    def test_retrospective_run_writes_full_envelope(self) -> None:
        """retrospective_run carries plans_analyzed/report/proposals_*/
        disable_test/self_value — self_value is a nested sub-object."""
        self_value = json.dumps({
            "proposals_total": 3,
            "disable_test_set": True,
            "consecutive_zero_change": 0,
        })
        result = run_executed(
            self.cwd,
            "retrospective_run",
            "{plans_analyzed: $plans, report: $report, "
            "proposals_approved: $approved, proposals_rejected: $rejected, "
            "disable_test: $disable, self_value: $sv}",
            "--argjson", "plans", '["docs/plans/p1/","docs/plans/p2/"]',
            "--arg", "report", "docs/retros/r.md",
            "--argjson", "approved", "2",
            "--argjson", "rejected", "1",
            "--arg", "disable", "evaluator_per_batch",
            "--argjson", "sv", self_value,
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        entry = self._read_one()
        self.assertEqual(entry["event"], "retrospective_run")
        self.assertEqual(entry["plans_analyzed"], ["docs/plans/p1/", "docs/plans/p2/"])
        self.assertEqual(entry["proposals_approved"], 2)
        self.assertEqual(entry["proposals_rejected"], 1)
        self.assertEqual(entry["disable_test"], "evaluator_per_batch")
        self.assertEqual(entry["self_value"]["proposals_total"], 3)
        self.assertEqual(entry["self_value"]["disable_test_set"], True)
        self.assertEqual(entry["self_value"]["consecutive_zero_change"], 0)

    def test_component_reinstated_writes_full_envelope(self) -> None:
        """component_reinstated carries the evidence sub-object."""
        evidence = json.dumps({
            "feedback_commit_count": 5,
            "feedback_commit_shas": ["a7a62a6", "4891b49"],
            "missed_patterns": ["pattern-1", "pattern-2"],
        })
        result = run_executed(
            self.cwd,
            "component_reinstated",
            "{component: $c, previously_disabled_in: $pd, "
            "reinstatement_method: $rm, evidence: $ev, rationale: $r}",
            "--arg", "c", "recurring_failure_patterns",
            "--arg", "pd", "docs/retros/prev.md",
            "--arg", "rm", "post_plan_diff_veto",
            "--argjson", "ev", evidence,
            "--arg", "r", "post-plan signal found",
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        entry = self._read_one()
        self.assertEqual(entry["event"], "component_reinstated")
        self.assertEqual(entry["component"], "recurring_failure_patterns")
        self.assertEqual(entry["reinstatement_method"], "post_plan_diff_veto")
        self.assertEqual(entry["evidence"]["feedback_commit_count"], 5)
        self.assertEqual(entry["evidence"]["missed_patterns"], ["pattern-1", "pattern-2"])

    def test_appending_preserves_prior_row_byte_for_byte(self) -> None:
        """§5.3: append-only contract. An existing legacy row must be
        unchanged after the helper writes a second row."""
        log = _log_path(self.cwd)
        log.parent.mkdir(parents=True, exist_ok=True)
        legacy = (
            '{"event":"item_added","timestamp":"2026-04-01T12:00:00Z",'
            '"mode":"design","item_id":"LEGACY","description":"d","rationale":"r",'
            '"driving_plans":["p"],"checklist_version":"v","retrospective_report":"r.md"}\n'
        )
        log.write_bytes(legacy.encode())
        result = run_executed(
            self.cwd,
            "item_removed",
            "{mode: $mode, item_id: $id, description: $d, rationale: $r, "
            "driving_plans: $plans, checklist_version: $v, "
            "retrospective_report: $report}",
            "--arg", "mode", "design",
            "--arg", "id", "NEW",
            "--arg", "d", "second row",
            "--arg", "r", "r",
            "--argjson", "plans", '["p2"]',
            "--arg", "v", "v",
            "--arg", "report", "r.md",
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        raw = log.read_bytes()
        self.assertTrue(
            raw.startswith(legacy.encode()),
            msg=f"prior row mutated; got first bytes: {raw[: len(legacy)]!r}",
        )
        self.assertEqual(len(raw.decode().splitlines()), 2)


class EvolutionLogSourcedTests(unittest.TestCase):
    """`source lib/evolution-log.sh; log_evolution_event ...` path.
    Sourcing under `set -euo pipefail` must not perturb the caller."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.cwd = Path(self.tmpdir.name)

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def test_sourced_then_called_writes_entry(self) -> None:
        body = (
            "log_evolution_event item_added "
            "'{mode: $mode, item_id: $id, description: $d}' "
            '--arg mode "design" --arg id "FROM-SOURCE" --arg d "via source"'
        )
        result = run_sourced(self.cwd, body)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        log = _log_path(self.cwd)
        self.assertTrue(log.exists())
        entry = json.loads(log.read_text().strip())
        self.assertEqual(entry["event"], "item_added")
        self.assertEqual(entry["item_id"], "FROM-SOURCE")
        self.assertEqual(entry["description"], "via source")

    def test_sourcing_does_not_run_main(self) -> None:
        """BASH_SOURCE[0] != $0 when sourced → the trailing direct-exec
        branch must not fire, so no spurious entry shows up."""
        result = run_sourced(self.cwd, ": # noop after source")
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertFalse(_log_path(self.cwd).exists())

    def test_sourcing_under_set_e_does_not_abort_caller(self) -> None:
        """Empty/missing args must not crash the surrounding shell — the
        still-alive marker must reach stdout."""
        body = (
            "log_evolution_event \"\" \"\" || true\n"
            "echo still-alive"
        )
        result = run_sourced(self.cwd, body)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("still-alive", result.stdout)


class EvolutionLogDegradationTests(unittest.TestCase):
    """When the environment is hostile (no jq, read-only fs, no repo
    root, no `date`) the helper returns 0 silently. Same contract as
    `bail-log.sh` and `observations.sh`."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.cwd = Path(self.tmpdir.name)

    def tearDown(self) -> None:
        # Restore writable so cleanup succeeds even if a test chmod'd cwd.
        # Guard clause replaces try/except OSError: pass per CODE-QUAL-02.
        if self.cwd.exists():
            os.chmod(self.cwd, 0o700)
        self.tmpdir.cleanup()

    def test_silent_skip_when_jq_missing(self) -> None:
        """PATH stripped of jq. Helper must exit 0; on macOS where jq
        only lives in /opt/homebrew/bin, no log file appears. On Linux CI
        where /usr/bin/jq exists, the write may still succeed — both
        outcomes are valid degradation per `bail-log.sh` precedent."""
        result = subprocess.run(
            [
                "bash",
                str(EVOLUTION_LOG),
                "item_added",
                "{mode: $mode}",
                "--arg", "mode", "design",
            ],
            cwd=str(self.cwd),
            capture_output=True,
            text=True,
            env={"PATH": "/usr/bin:/bin"},
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        if not _jq_in(["/usr/bin", "/bin"]):
            self.assertFalse(
                _log_path(self.cwd).exists(),
                msg="log was written despite missing jq",
            )

    def test_returns_zero_when_docs_retros_unwritable(self) -> None:
        """`mkdir -p docs/retros` fails when cwd is read-only. The helper
        must return 0 and write nothing."""
        os.chmod(self.cwd, stat.S_IRUSR | stat.S_IXUSR)
        try:
            result = run_executed(
                self.cwd,
                "item_added",
                "{mode: $mode}",
                "--arg", "mode", "design",
            )
        finally:
            os.chmod(self.cwd, 0o700)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertFalse(_log_path(self.cwd).exists())

    def test_returns_zero_when_repo_root_empty(self) -> None:
        """With CLAUDE_PROJECT_DIR unset, PWD unset, and cwd not a git
        repo, `utils.sh::repo_root` returns empty. The helper must short-
        circuit before any file operation."""
        env = {
            "PATH": os.environ.get("PATH", "/usr/bin:/bin"),
        }
        result = subprocess.run(
            [
                "bash",
                str(EVOLUTION_LOG),
                "item_added",
                "{mode: $mode}",
                "--arg", "mode", "design",
            ],
            cwd="/",
            capture_output=True,
            text=True,
            env=env,
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertFalse(_log_path(self.cwd).exists())

    def test_returns_zero_when_date_fails(self) -> None:
        """A shimmed `date` that always exits non-zero must not crash the
        helper — `timestamp_or_skip` returns 1 and the helper returns 0."""
        shim_dir = Path(self.tmpdir.name) / "shim-bin"
        shim_dir.mkdir()
        date_shim = shim_dir / "date"
        date_shim.write_text("#!/usr/bin/env bash\nexit 1\n")
        date_shim.chmod(0o755)
        env = {
            "PATH": f"{shim_dir}:/usr/bin:/bin",
        }
        result = run_executed(
            self.cwd,
            "item_added",
            "{mode: $mode}",
            "--arg", "mode", "design",
            env=env,
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertFalse(_log_path(self.cwd).exists())


class EvolutionLogPayloadSchemaTests(unittest.TestCase):
    """Schema-shape assertions specific to `retrospective_run`:
    nested `self_value` key ordering, optional `post_plan_diff` omission
    versus inclusion. Verifies the §1.4 byte-equivalence contract."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.cwd = Path(self.tmpdir.name)

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def _emit_retrospective_run(self, include_post_plan_diff: bool) -> dict:
        self_value = json.dumps({
            "proposals_total": 3,
            "disable_test_set": True,
            "consecutive_zero_change": 0,
        })
        args = [
            "retrospective_run",
        ]
        if include_post_plan_diff:
            ppd = json.dumps({
                "window_hours_at_run": 48,
                "total": 9,
                "feedback": 5,
                "evolution": 4,
                "unknown": 0,
                "vetoed_disables": ["recurring_failure_patterns"],
                "greenfield_no_followup": False,
            })
            args.extend([
                "{plans_analyzed: $plans, report: $report, "
                "proposals_approved: $approved, proposals_rejected: $rejected, "
                "disable_test: $disable, self_value: $sv, "
                "post_plan_diff: $ppd}",
                "--argjson", "plans", '["docs/plans/p1/"]',
                "--arg", "report", "docs/retros/r.md",
                "--argjson", "approved", "2",
                "--argjson", "rejected", "1",
                "--arg", "disable", "evaluator_per_batch",
                "--argjson", "sv", self_value,
                "--argjson", "ppd", ppd,
            ])
        else:
            args.extend([
                "{plans_analyzed: $plans, report: $report, "
                "proposals_approved: $approved, proposals_rejected: $rejected, "
                "disable_test: $disable, self_value: $sv}",
                "--argjson", "plans", '["docs/plans/p1/"]',
                "--arg", "report", "docs/retros/r.md",
                "--argjson", "approved", "2",
                "--argjson", "rejected", "1",
                "--arg", "disable", "evaluator_per_batch",
                "--argjson", "sv", self_value,
            ])
        result = run_executed(self.cwd, *args)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        return json.loads(_log_path(self.cwd).read_text().strip())

    def test_retrospective_run_payload_includes_nested_self_value(self) -> None:
        """`self_value` is a nested object preserving its three keys in
        declared order under `jq -S` projection (jq -S sorts keys
        alphabetically, so the set match is the meaningful assertion)."""
        entry = self._emit_retrospective_run(include_post_plan_diff=False)
        self.assertIn("self_value", entry)
        self.assertIsInstance(entry["self_value"], dict)
        self.assertEqual(
            set(entry["self_value"].keys()),
            {"proposals_total", "disable_test_set", "consecutive_zero_change"},
        )
        # Verify the values were preserved exactly.
        self.assertEqual(entry["self_value"]["proposals_total"], 3)
        self.assertEqual(entry["self_value"]["disable_test_set"], True)
        self.assertEqual(entry["self_value"]["consecutive_zero_change"], 0)

    def test_retrospective_run_omits_post_plan_diff_when_absent(self) -> None:
        """§1.4: when no plan in plans_analyzed carries a
        completion_commit, `post_plan_diff` is omitted (not nullified).
        The key must NOT appear in the on-disk row."""
        entry = self._emit_retrospective_run(include_post_plan_diff=False)
        self.assertNotIn("post_plan_diff", entry)

    def test_retrospective_run_includes_post_plan_diff_when_provided(self) -> None:
        """Opposite case: when the caller passes a `post_plan_diff`
        argument, the key appears with the expected sub-object."""
        entry = self._emit_retrospective_run(include_post_plan_diff=True)
        self.assertIn("post_plan_diff", entry)
        self.assertEqual(entry["post_plan_diff"]["total"], 9)
        self.assertEqual(
            entry["post_plan_diff"]["vetoed_disables"],
            ["recurring_failure_patterns"],
        )


def _jq_in(dirs: list[str]) -> bool:
    """True iff `jq` is found in any of the given directories."""
    return any(shutil.which("jq", path=d) for d in dirs)


if __name__ == "__main__":
    unittest.main()
