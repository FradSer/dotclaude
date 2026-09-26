"""Tests for scripts/antigravity.py.

Covered: the two credential paths (Vertex via ADC, or the Developer API with an API
key), request building for the options the Interactions API exposes, output
extraction from execution steps, worker liveness, and run-directory cleanup.

The resolver and builders are pure logic, so these tests import the script directly —
the script imports google-genai lazily inside the worker, so importing it needs neither
the SDK nor the network.
"""

from __future__ import annotations

import contextlib
import importlib.util
import io
import json
import os
import subprocess
import sys
import tempfile
import time
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

PLUGIN = Path(__file__).resolve().parents[1]
SCRIPT = PLUGIN / "scripts" / "antigravity.py"

CREDENTIAL_VARS = (
    "ANTIGRAVITY_AUTH",
    "ANTIGRAVITY_PROJECT",
    "ANTIGRAVITY_LOCATION",
    "GOOGLE_CLOUD_PROJECT",
    "GCLOUD_PROJECT",
    "GOOGLE_CLOUD_LOCATION",
    "GOOGLE_APPLICATION_CREDENTIALS",
    "GEMINI_API_KEY",
    "GOOGLE_API_KEY",
)


def read_json_with_retry(path: Path, attempts: int = 20) -> dict:
    """The detached worker also writes this file, so tolerate a torn read."""
    last: Exception | None = None
    for _ in range(attempts):
        try:
            return json.loads(path.read_text())
        except (OSError, json.JSONDecodeError) as exc:  # pragma: no cover - timing dependent
            last = exc
            time.sleep(0.05)
    raise AssertionError(f"could not read {path}: {last}")


def _load_module():
    spec = importlib.util.spec_from_file_location("antigravity_script", SCRIPT)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


mod = _load_module()


@contextlib.contextmanager
def cred_env(**overrides):
    """Run with every credential variable cleared, then apply overrides."""
    saved = {name: os.environ.get(name) for name in CREDENTIAL_VARS}
    try:
        for name in CREDENTIAL_VARS:
            os.environ.pop(name, None)
        for name, value in overrides.items():
            if value is not None:
                os.environ[name] = value
        yield
    finally:
        for name, value in saved.items():
            if value is None:
                os.environ.pop(name, None)
            else:
                os.environ[name] = value


@contextlib.contextmanager
def adc(present: bool):
    """Yield a GOOGLE_APPLICATION_CREDENTIALS path that does or does not exist."""
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "application_default_credentials.json"
        if present:
            path.write_text("{}")
        yield str(path)


class ResolveAuthTests(unittest.TestCase):
    def test_auto_prefers_vertex_when_adc_project_and_location_are_configured(self):
        with adc(True) as path, cred_env(
            GEMINI_API_KEY="key-123",
            ANTIGRAVITY_PROJECT="proj-a",
            ANTIGRAVITY_LOCATION="global",
            GOOGLE_APPLICATION_CREDENTIALS=path,
        ):
            auth = mod.resolve_auth()
        self.assertEqual(auth["mode"], "vertex")
        self.assertEqual(
            auth["client_kwargs"],
            {"vertexai": True, "project": "proj-a", "location": "global"},
        )
        self.assertNotIn("api_key", auth["client_kwargs"])

    def test_vertex_forces_background_because_vertex_rejects_synchronous_agents(self):
        with adc(True) as path, cred_env(
            ANTIGRAVITY_PROJECT="proj-a",
            ANTIGRAVITY_LOCATION="global",
            GOOGLE_APPLICATION_CREDENTIALS=path,
        ):
            auth = mod.resolve_auth()
        self.assertTrue(auth["background"])

    def test_auto_falls_back_to_api_key_without_adc(self):
        with adc(False) as path, cred_env(
            GEMINI_API_KEY="key-123",
            ANTIGRAVITY_PROJECT="proj-a",
            ANTIGRAVITY_LOCATION="global",
            GOOGLE_APPLICATION_CREDENTIALS=path,
        ):
            auth = mod.resolve_auth()
        self.assertEqual(auth["mode"], "api-key")
        self.assertEqual(auth["client_kwargs"], {"api_key": "key-123"})
        self.assertFalse(auth["background"])

    def test_google_api_key_is_accepted_as_the_developer_api_key(self):
        with cred_env(GOOGLE_API_KEY="key-google"):
            auth = mod.resolve_auth()
        self.assertEqual(auth["mode"], "api-key")
        self.assertEqual(auth["client_kwargs"], {"api_key": "key-google"})

    def test_auto_without_any_credentials_names_both_paths(self):
        with cred_env():
            with self.assertRaises(mod.AuthConfigError) as ctx:
                mod.resolve_auth()
        message = str(ctx.exception)
        self.assertIn("gcloud auth application-default login", message)
        self.assertIn("GEMINI_API_KEY", message)
        self.assertIn("ANTIGRAVITY_AUTH", message)

    def test_forced_vertex_reports_the_missing_location(self):
        with adc(True) as path, cred_env(
            ANTIGRAVITY_AUTH="vertex",
            ANTIGRAVITY_PROJECT="proj-a",
            GOOGLE_APPLICATION_CREDENTIALS=path,
        ):
            with self.assertRaises(mod.AuthConfigError) as ctx:
                mod.resolve_auth()
        self.assertIn("location", str(ctx.exception))

    def test_forced_vertex_reports_the_missing_project(self):
        with adc(True) as path, cred_env(
            ANTIGRAVITY_AUTH="vertex",
            ANTIGRAVITY_LOCATION="global",
            GOOGLE_APPLICATION_CREDENTIALS=path,
        ):
            with self.assertRaises(mod.AuthConfigError) as ctx:
                mod.resolve_auth()
        self.assertIn("project", str(ctx.exception))

    def test_forced_vertex_reports_missing_adc(self):
        with adc(False) as path, cred_env(
            ANTIGRAVITY_AUTH="vertex",
            ANTIGRAVITY_PROJECT="proj-a",
            ANTIGRAVITY_LOCATION="global",
            GEMINI_API_KEY="key-123",
            GOOGLE_APPLICATION_CREDENTIALS=path,
        ):
            with self.assertRaises(mod.AuthConfigError) as ctx:
                mod.resolve_auth()
        self.assertIn("application-default", str(ctx.exception))

    def test_api_key_can_be_forced_even_when_vertex_is_ready(self):
        with adc(True) as path, cred_env(
            ANTIGRAVITY_AUTH="api-key",
            GEMINI_API_KEY="key-123",
            ANTIGRAVITY_PROJECT="proj-a",
            ANTIGRAVITY_LOCATION="global",
            GOOGLE_APPLICATION_CREDENTIALS=path,
        ):
            auth = mod.resolve_auth()
        self.assertEqual(auth["mode"], "api-key")
        self.assertFalse(auth["background"])

    def test_forcing_api_key_without_a_key_fails(self):
        with cred_env(ANTIGRAVITY_AUTH="api-key"):
            with self.assertRaises(mod.AuthConfigError):
                mod.resolve_auth()

    def test_unknown_auth_value_is_rejected(self):
        with cred_env(ANTIGRAVITY_AUTH="vertex-ai", GEMINI_API_KEY="key-123"):
            with self.assertRaises(mod.AuthConfigError) as ctx:
                mod.resolve_auth()
        self.assertIn("ANTIGRAVITY_AUTH", str(ctx.exception))

    def test_project_precedence_plugin_then_google_cloud_then_gcloud(self):
        cases = (
            ({"ANTIGRAVITY_PROJECT": "a", "GOOGLE_CLOUD_PROJECT": "b", "GCLOUD_PROJECT": "c"}, "a"),
            ({"GOOGLE_CLOUD_PROJECT": "b", "GCLOUD_PROJECT": "c"}, "b"),
            ({"GCLOUD_PROJECT": "c"}, "c"),
        )
        for overrides, expected in cases:
            with adc(True) as path, cred_env(
                ANTIGRAVITY_LOCATION="global", GOOGLE_APPLICATION_CREDENTIALS=path, **overrides
            ):
                auth = mod.resolve_auth()
            self.assertEqual(auth["client_kwargs"]["project"], expected)

    def test_location_precedence_plugin_then_google_cloud(self):
        cases = (
            ({"ANTIGRAVITY_LOCATION": "us-central1", "GOOGLE_CLOUD_LOCATION": "europe-west1"}, "us-central1"),
            ({"GOOGLE_CLOUD_LOCATION": "europe-west1"}, "europe-west1"),
        )
        for overrides, expected in cases:
            with adc(True) as path, cred_env(
                ANTIGRAVITY_PROJECT="proj-a", GOOGLE_APPLICATION_CREDENTIALS=path, **overrides
            ):
                auth = mod.resolve_auth()
            self.assertEqual(auth["client_kwargs"]["location"], expected)


class CreateKwargsTests(unittest.TestCase):
    def meta(self, kind: str, background: bool) -> dict:
        return {
            "run_id": "r",
            "kind": kind,
            "agent": mod.ANTIGRAVITY_AGENT,
            "prompt": "do the thing",
            "tools": list(mod.DEFAULT_TOOLS),
            "network": "default",
            "repo": None,
            "environment_id": None,
            "previous_interaction_id": None,
            "background": background,
        }

    def test_vertex_delegate_asks_for_background_and_skips_the_long_timeout(self):
        kwargs = mod.build_create_kwargs(self.meta("delegate", background=True))
        self.assertIs(kwargs["background"], True)
        self.assertNotIn("timeout", kwargs)
        self.assertEqual(kwargs["tools"], [{"type": t} for t in mod.DEFAULT_TOOLS])
        self.assertEqual(kwargs["environment"], {"type": "remote"})

    def test_api_key_delegate_stays_synchronous_with_the_worker_deadline_timeout(self):
        kwargs = mod.build_create_kwargs(self.meta("delegate", background=False))
        self.assertNotIn("background", kwargs)
        self.assertEqual(kwargs["timeout"], mod.WORKER_DEADLINE)

    def test_research_is_background_on_both_paths(self):
        for background in (True, False):
            with self.subTest(background=background):
                kwargs = mod.build_create_kwargs(self.meta("research", background=background))
                self.assertIs(kwargs["background"], True)
                self.assertEqual(kwargs["agent_config"], {"type": "deep-research"})
                self.assertNotIn("timeout", kwargs)


class RunMetaTests(unittest.TestCase):
    def _start(self, env: dict) -> tuple[dict, str]:
        with tempfile.TemporaryDirectory() as home:
            proc = subprocess.run(
                [sys.executable, str(SCRIPT), "delegate", "--prompt", "say ok"],
                capture_output=True,
                text=True,
                env={**os.environ, "ANTIGRAVITY_HOME": home, **env},
            )
            self.assertEqual(proc.returncode, 0, proc.stderr)
            runs = list((Path(home) / "runs").iterdir())
            self.assertEqual(len(runs), 1, "expected exactly one run directory")
            return read_json_with_retry(runs[0] / "meta.json"), proc.stdout

    def _clean(self, **overrides) -> dict:
        env = {name: "" for name in CREDENTIAL_VARS}
        env.update(overrides)
        return env

    def test_api_key_run_records_the_mode_without_writing_the_key_to_disk(self):
        meta, stdout = self._start(self._clean(GEMINI_API_KEY="secret-key-value"))
        self.assertEqual(meta["auth"], "api-key")
        self.assertIn("API key", meta["auth_label"])
        self.assertFalse(meta["background"])
        self.assertIn("API key", stdout)
        self.assertNotIn("secret-key-value", json.dumps(meta))

    def test_vertex_run_records_vertex_and_requests_background(self):
        with adc(True) as path:
            meta, stdout = self._start(
                self._clean(
                    ANTIGRAVITY_PROJECT="proj-a",
                    ANTIGRAVITY_LOCATION="global",
                    GOOGLE_APPLICATION_CREDENTIALS=path,
                )
            )
        self.assertEqual(meta["auth"], "vertex")
        self.assertIn("Vertex AI", meta["auth_label"])
        self.assertTrue(meta["background"])
        self.assertIn("Vertex AI", stdout)


class ResultExtractionTests(unittest.TestCase):
    """Step shapes captured live from Vertex (google-genai 2.25.0).

    Vertex reports every tool as a generic `function_call` carrying the tool name in
    `name`; the Developer API uses per-tool `*_call` step types. Both must render.
    """

    def step(self, type_: str, **kw):
        return SimpleNamespace(type=type_, **kw)

    def model_output(self, text: str):
        """ModelOutputStep.content is a list of Content models, not plain dicts."""
        return self.step("model_output", content=[SimpleNamespace(type="text", text=text)])

    def interaction(self, steps, status: str = "completed"):
        return SimpleNamespace(steps=steps, id="i", environment_id="e", status=status, usage=None)

    def test_summarize_steps_names_vertex_function_calls(self):
        lines, counts = mod.summarize_steps(
            [
                self.step(
                    "function_call",
                    name="run_command",
                    arguments={
                        "CommandLine": 'python3 -c "print(2**64)"',
                        "toolSummary": "Code execution",
                    },
                )
            ]
        )
        self.assertEqual(lines, ["[run_command] Code execution"])
        self.assertEqual(counts, {"function_call": 1})

    def test_summarize_steps_reads_function_call_arguments_as_objects_too(self):
        lines, _ = mod.summarize_steps(
            [
                self.step(
                    "function_call",
                    name="run_command",
                    arguments=SimpleNamespace(CommandLine="ffprobe -v quiet in.mp4", toolSummary=None),
                )
            ]
        )
        self.assertEqual(lines, ["[run_command] ffprobe -v quiet in.mp4"])

    def test_summarize_steps_keeps_developer_api_step_types(self):
        lines, counts = mod.summarize_steps(
            [
                self.step("code_execution_call", arguments=SimpleNamespace(code="print(1)\nprint(2)")),
                self.step("google_search_call", arguments={"queries": ["a", "b"]}),
                self.step("url_context_call", arguments={"urls": ["https://x.test"]}),
            ]
        )
        self.assertEqual(lines, ["[code] print(1)", "[search] a, b", "[url] https://x.test"])
        self.assertEqual(counts, {"code_execution_call": 1, "google_search_call": 1, "url_context_call": 1})

    def test_summarize_steps_counts_results_and_inputs(self):
        _, counts = mod.summarize_steps(
            [
                self.step("user_input"),
                self.step("function_result", name="run_command"),
                self.step("function_call", name="provision_sandbox", arguments={}),
            ]
        )
        self.assertEqual(counts, {"user_input": 1, "function_result": 1, "function_call": 1})

    def test_extract_result_joins_streaming_fragments_without_a_separator(self):
        """Live case: 2**64 arrived as two model_output steps and "\n\n" split it."""
        result = mod.extract_result(
            self.interaction([self.model_output("184467440737095516"), self.model_output("16")])
        )
        self.assertEqual(result["output_text"], "18446744073709551616")

    def test_extract_result_drops_the_consolidated_repeat(self):
        """Live case: deltas "I" + " will search x" are resent as the full sentence."""
        result = mod.extract_result(
            self.interaction(
                [
                    self.model_output("I"),
                    self.model_output(" will search x"),
                    self.model_output("I will search x"),
                ]
            )
        )
        self.assertEqual(result["output_text"], "I will search x")

    def test_extract_result_ignores_non_model_output_steps(self):
        result = mod.extract_result(
            self.interaction(
                [
                    self.step("user_input", content=[SimpleNamespace(type="text", text="prompt")]),
                    self.step("function_call", name="run_command", arguments={}),
                    self.model_output("answer"),
                ]
            )
        )
        self.assertEqual(result["output_text"], "answer")

    def test_extract_citations_collects_url_citations_in_order(self):
        """Live shape: text content carries `annotations` of type url_citation.

        A live deep-research report carried 43 of them while its body referenced
        `[cite: 1]`…`[cite: 9]`; without the list every marker pointed at nothing.
        """
        steps = [
            self.step(
                "model_output",
                content=[
                    SimpleNamespace(
                        type="text",
                        text="a",
                        annotations=[
                            SimpleNamespace(type="url_citation", title="First\nsite.com", url="https://a.test"),
                            {"type": "url_citation", "title": "Second", "url": "https://b.test"},
                            SimpleNamespace(type="url_citation", title="Duplicate", url="https://a.test"),
                            SimpleNamespace(type="other", title="ignored", url="https://c.test"),
                        ],
                    )
                ],
            ),
            self.step("user_input", content=[]),
        ]
        self.assertEqual(
            mod.extract_citations(steps),
            [
                {"title": "First site.com", "url": "https://a.test"},
                {"title": "Second", "url": "https://b.test"},
            ],
        )

    def test_extract_result_carries_citations(self):
        result = mod.extract_result(
            self.interaction(
                [
                    self.step(
                        "model_output",
                        content=[
                            SimpleNamespace(
                                type="text",
                                text="body",
                                annotations=[SimpleNamespace(type="url_citation", title="T", url="https://t.test")],
                            )
                        ],
                    )
                ]
            )
        )
        self.assertEqual(result["citations"], [{"title": "T", "url": "https://t.test"}])

    def test_render_markdown_lists_the_sources(self):
        meta = {"run_id": "r", "kind": "research", "agent": mod.DEEP_RESEARCH_AGENT}
        result = {
            "output_text": "body [cite: 1]",
            "citations": [{"title": "Example", "url": "https://example.test"}],
            "status": "completed",
        }
        markdown = mod.render_markdown(meta, result)
        self.assertIn("## Sources", markdown)
        self.assertIn("- [Example](https://example.test)", markdown)
        self.assertIn("- sources: 1", markdown)
        self.assertNotIn("## Sources", mod.render_markdown(meta, {**result, "citations": []}))

    def test_extract_result_spans_tool_calls_to_keep_a_multi_part_report(self):
        result = mod.extract_result(
            self.interaction(
                [
                    self.model_output("part one."),
                    self.step("function_call", name="run_command", arguments={}),
                    self.model_output(" part two."),
                ]
            )
        )
        self.assertEqual(result["output_text"], "part one. part two.")


class WorkerLivenessTests(unittest.TestCase):
    """A run must never sit non-terminal forever after its worker dies.

    Two holes are covered: a worker that dies before writing worker.pid (nothing to
    check), and a recorded pid recycled by an unrelated process (a naive liveness
    probe says "alive" forever).
    """

    RUN_ID = "20990101-000000-abcdef"

    def make_run(self, tmp: str, *, created_at: str | None = None, pid: int | None = None, status="running"):
        runs = Path(tmp) / "runs"
        d = runs / self.RUN_ID
        d.mkdir(parents=True)
        (d / "status").write_text(status + "\n")
        (d / "meta.json").write_text(
            json.dumps({"run_id": self.RUN_ID, "kind": "delegate", "created_at": created_at or mod.now()})
        )
        if pid is not None:
            (d / "worker.pid").write_text(f"{pid}\n")
        return runs

    def print_status(self, runs: Path) -> str:
        with mock.patch.object(mod, "RUNS_DIR", runs), contextlib.redirect_stdout(io.StringIO()) as out:
            mod.print_status(self.RUN_ID, full=False)
        return out.getvalue()

    def recorded_status(self, runs: Path) -> str:
        return (runs / self.RUN_ID / "status").read_text().strip()

    def test_live_pid_that_is_not_our_worker_is_declared_dead(self):
        """os.getpid() is alive but its command line is not this run's worker."""
        with tempfile.TemporaryDirectory() as tmp:
            runs = self.make_run(tmp, pid=os.getpid())
            out = self.print_status(runs)
            self.assertIn("marking as failed", out)
            self.assertEqual(self.recorded_status(runs), "failed")

    def test_live_pid_that_is_this_runs_worker_stays_running(self):
        with tempfile.TemporaryDirectory() as tmp:
            # Shaped like the real worker argv: <python> ... <run_id>, and long-lived.
            proc = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(30)", self.RUN_ID])
            self.addCleanup(proc.terminate)
            self.assertIn(self.RUN_ID, mod.pid_command_line(proc.pid) or "")
            runs = self.make_run(tmp, pid=proc.pid)
            out = self.print_status(runs)
            self.assertIn("still running", out)
            self.assertEqual(self.recorded_status(runs), "running")

    def test_missing_pid_past_the_grace_window_is_declared_dead(self):
        with tempfile.TemporaryDirectory() as tmp:
            old = datetime.now(timezone.utc) - timedelta(seconds=mod.WORKER_START_GRACE + 60)
            runs = self.make_run(tmp, created_at=old.isoformat())
            out = self.print_status(runs)
            self.assertIn("marking as failed", out)
            self.assertEqual(self.recorded_status(runs), "failed")

    def test_missing_pid_inside_the_grace_window_stays_running(self):
        with tempfile.TemporaryDirectory() as tmp:
            runs = self.make_run(tmp)
            out = self.print_status(runs)
            self.assertIn("still running", out)
            self.assertEqual(self.recorded_status(runs), "running")

    def test_wait_stops_instead_of_hanging_when_the_worker_never_started(self):
        with tempfile.TemporaryDirectory() as tmp:
            old = datetime.now(timezone.utc) - timedelta(seconds=mod.WORKER_START_GRACE + 60)
            runs = self.make_run(tmp, created_at=old.isoformat())
            with mock.patch.object(mod, "RUNS_DIR", runs), contextlib.redirect_stdout(io.StringIO()) as out:
                mod.cmd_wait(self.RUN_ID, interval=0, timeout=30)
            self.assertIn(f"antigravity run {self.RUN_ID}: failed", out.getvalue())


class RequestOptionTests(unittest.TestCase):
    """The Interactions API exposes cost, model, and steering knobs the plugin forwards."""

    def meta(self, kind: str = "delegate", **overrides) -> dict:
        meta = {
            "run_id": "r",
            "kind": kind,
            "agent": mod.ANTIGRAVITY_AGENT if kind == "delegate" else mod.DEEP_RESEARCH_AGENT,
            "prompt": "do the thing",
            "tools": list(mod.DEFAULT_TOOLS),
            "network": "default",
            "repo": None,
            "environment_id": None,
            "previous_interaction_id": None,
            "background": kind == "research",
            "system_instruction": mod.DEFAULT_SYSTEM_INSTRUCTION,
            "service_tier": None,
            "labels": None,
            "images": None,
            "agent_config": None,
            "response_format": None,
        }
        meta.update(overrides)
        return meta

    def test_delegate_sends_no_agent_config_when_nothing_is_configured(self):
        kwargs = mod.build_create_kwargs(self.meta())
        self.assertNotIn("agent_config", kwargs)

    def test_delegate_agent_config_carries_budget_and_model(self):
        kwargs = mod.build_create_kwargs(
            self.meta(agent_config={"type": "antigravity", "model": "gemini-3.8-flash", "max_total_tokens": 250000})
        )
        self.assertEqual(
            kwargs["agent_config"],
            {"type": "antigravity", "model": "gemini-3.8-flash", "max_total_tokens": 250000},
        )

    def test_research_agent_config_carries_deep_research_options(self):
        kwargs = mod.build_create_kwargs(
            self.meta(
                "research",
                agent_config={
                    "type": "deep-research",
                    "collaborative_planning": True,
                    "visualization": "auto",
                    "thinking_summaries": "auto",
                    "enable_bigquery_tool": True,
                },
            )
        )
        self.assertTrue(kwargs["background"])
        self.assertEqual(kwargs["agent_config"]["type"], "deep-research")
        self.assertIs(kwargs["agent_config"]["collaborative_planning"], True)
        self.assertEqual(kwargs["agent_config"]["visualization"], "auto")
        self.assertNotIn("max_total_tokens", kwargs["agent_config"])

    def test_default_system_instruction_is_sent(self):
        kwargs = mod.build_create_kwargs(self.meta())
        self.assertEqual(kwargs["system_instruction"], mod.DEFAULT_SYSTEM_INSTRUCTION)
        self.assertIn("never", kwargs["system_instruction"].lower())

    def test_system_instruction_override_replaces_the_default(self):
        kwargs = mod.build_create_kwargs(self.meta(system_instruction="be terse"))
        self.assertEqual(kwargs["system_instruction"], "be terse")

    def test_empty_system_instruction_disables_it(self):
        kwargs = mod.build_create_kwargs(self.meta(system_instruction=""))
        self.assertNotIn("system_instruction", kwargs)

    def test_labels_and_service_tier_are_forwarded(self):
        kwargs = mod.build_create_kwargs(self.meta(labels={"origin": "pi"}, service_tier="flex"))
        self.assertEqual(kwargs["labels"], {"origin": "pi"})
        self.assertEqual(kwargs["service_tier"], "flex")

    def test_images_become_a_multimodal_input_list(self):
        kwargs = mod.build_create_kwargs(self.meta(images=["/tmp/chart.png"]), images_loader=lambda paths: [
            {"type": "image", "data": "BASE64", "mime_type": "image/png"}
        ])
        self.assertEqual(
            kwargs["input"],
            [
                {"type": "text", "text": "do the thing"},
                {"type": "image", "data": "BASE64", "mime_type": "image/png"},
            ],
        )

    def test_plain_prompt_stays_a_string(self):
        kwargs = mod.build_create_kwargs(self.meta())
        self.assertEqual(kwargs["input"], "do the thing")

    def test_json_output_sets_response_format_and_never_response_mime_type(self):
        """Live API rejects responseMimeType unless responseFormat is also set, so the
        format alone is the working form (verified: a live run returned parseable JSON)."""
        kwargs = mod.build_create_kwargs(
            self.meta(response_format={"type": "text", "mime_type": "application/json"})
        )
        self.assertEqual(kwargs["response_format"], {"type": "text", "mime_type": "application/json"})
        self.assertNotIn("response_mime_type", kwargs)

    def test_previous_interaction_id_is_forwarded_with_the_environment(self):
        """Chaining managed-agent turns requires both ids in the same request."""
        kwargs = mod.build_create_kwargs(self.meta(previous_interaction_id="prev-1", environment_id="env-1"))
        self.assertEqual(kwargs["previous_interaction_id"], "prev-1")
        self.assertEqual(kwargs["environment"], "env-1")

    def test_environment_reuse_is_a_bare_id(self):
        """Regression: only the bare-string form reuses a sandbox.

        A config object carrying the id (with either `id` or `environment_id`) is accepted
        and then provisions a fresh sandbox, so reuse looked like it worked while every
        file was gone. Verified live: the bare id came back unchanged and the file written
        in the earlier sandbox was still readable.
        """
        self.assertEqual(mod.build_environment("default", None, "env-abc"), "env-abc")
        self.assertEqual(mod.build_environment("default", None, None), {"type": "remote"})
        self.assertEqual(
            mod.build_environment("none", "https://github.com/o/r", None),
            {
                "type": "remote",
                "network": "disabled",
                "sources": [
                    {"type": "repository", "source": "https://github.com/o/r", "target": "/workspace/repo"}
                ],
            },
        )

    def test_reuse_rejects_options_it_would_have_to_drop(self):
        base = {
            "tools": list(mod.DEFAULT_TOOLS),
            "network": "default",
            "environment_id": "env-abc",
            "repo": "https://github.com/o/r",
        }
        with self.assertRaises(mod.OptionError) as ctx:
            mod.prepare_options("delegate", base)
        self.assertIn("--environment-id", str(ctx.exception))
        with self.assertRaises(mod.OptionError):
            mod.prepare_options("delegate", {**base, "repo": None, "network": "none"})
        prepared = mod.prepare_options("delegate", {**base, "repo": None})
        self.assertEqual(prepared["environment_id"], "env-abc")

    def test_agent_config_builder_for_the_antigravity_agent(self):
        self.assertEqual(mod.build_agent_config("delegate", None, None), None)
        self.assertEqual(
            mod.build_agent_config("delegate", "gemini-3.8-flash", 1000),
            {"type": "antigravity", "model": "gemini-3.8-flash", "max_total_tokens": 1000},
        )
        self.assertEqual(mod.build_agent_config("delegate", None, 1000), {"type": "antigravity", "max_total_tokens": 1000})

    def test_agent_config_builder_for_deep_research_rejects_token_caps(self):
        """DeepResearchAgentConfig has no max_total_tokens / model field, so research cost
        cannot be capped and the plugin must not pretend otherwise."""
        self.assertEqual(
            mod.build_agent_config("research", None, None, {}),
            {"type": "deep-research"},
        )
        self.assertNotIn("max_total_tokens", mod.build_agent_config("research", None, None, {"visualization": "auto"}))

    def test_research_never_carries_a_system_instruction(self):
        """Regression: the deep-research agent rejects system_instruction outright.

        A live research run failed with 400 "The 'system_instruction' parameter is not
        supported for the deep-research-preview-04-2026 agent", so the default must not
        leak into research and an explicit --system must be refused rather than folded
        into the query (which would silently change what the report is about).
        """
        default = mod.prepare_options("research", {"tools": [], "network": "default"})
        self.assertIsNone(default["system_instruction"])
        self.assertNotIn("system_instruction", mod.build_create_kwargs(self.meta("research", system_instruction=None)))
        with self.assertRaises(mod.OptionError) as ctx:
            mod.prepare_options("research", {"tools": [], "network": "default", "system": "be terse"})
        self.assertIn("system instruction", str(ctx.exception))
        # The delegate path keeps its default.
        delegate = mod.prepare_options("delegate", {"tools": list(mod.DEFAULT_TOOLS), "network": "default"})
        self.assertEqual(delegate["system_instruction"], mod.DEFAULT_SYSTEM_INSTRUCTION)

    def test_parse_labels(self):
        self.assertEqual(mod.parse_labels(["a=1", "b=two"]), {"a": "1", "b": "two"})
        self.assertEqual(mod.parse_labels([]), None)

    def test_parse_labels_rejects_bad_syntax(self):
        for bad in (["novalue"], ["=value"], ["  "]):
            with self.subTest(bad=bad):
                with self.assertRaises(mod.OptionError):
                    mod.parse_labels(bad)

    def test_image_mime_type_by_extension(self):
        self.assertEqual(mod.image_mime_type("chart.PNG"), "image/png")
        self.assertEqual(mod.image_mime_type("shot.jpeg"), "image/jpeg")
        with self.assertRaises(mod.OptionError):
            mod.image_mime_type("notes.txt")

    def test_load_images_reports_a_missing_file(self):
        with self.assertRaises(mod.OptionError) as ctx:
            mod.load_images(["/definitely/missing.png"])
        self.assertIn("missing.png", str(ctx.exception))


class WorkerWaitTests(unittest.TestCase):
    """The wait loop polls for truth and streams progress best-effort."""

    class FakeInteractions:
        def __init__(self, statuses, stream_error=True):
            self.statuses = list(statuses)
            self.stream_error = stream_error
            self.polls = 0
            self.stream_calls = 0

        def get(self, interaction_id, **kwargs):
            if kwargs.get("stream"):
                self.stream_calls += 1
                if self.stream_error:
                    raise RuntimeError("stream unavailable")
                return []
            self.polls += 1
            status = self.statuses[min(self.polls - 1, len(self.statuses) - 1)]
            return SimpleNamespace(id=interaction_id, status=status, steps=[], usage=None)

    def test_wait_polls_until_a_terminal_status(self):
        client = SimpleNamespace(interactions=self.FakeInteractions(["in_progress", "in_progress", "completed"]))
        with tempfile.TemporaryDirectory() as tmp:
            with mock.patch.object(mod, "POLL_INTERVAL", 0):
                result = mod.wait_for_terminal(client, "iid", Path(tmp), time.monotonic() + 30)
        self.assertEqual(result.status, "completed")
        self.assertGreaterEqual(client.interactions.polls, 3)

    def test_wait_fails_fast_when_the_agent_requires_a_client_call(self):
        client = SimpleNamespace(interactions=self.FakeInteractions(["requires_action"]))
        with tempfile.TemporaryDirectory() as tmp:
            with mock.patch.object(mod, "POLL_INTERVAL", 0):
                with self.assertRaises(RuntimeError) as ctx:
                    mod.wait_for_terminal(client, "iid", Path(tmp), time.monotonic() + 30)
        self.assertIn("function call", str(ctx.exception))

    def test_wait_times_out_at_the_deadline(self):
        client = SimpleNamespace(interactions=self.FakeInteractions(["in_progress"]))
        with tempfile.TemporaryDirectory() as tmp:
            with mock.patch.object(mod, "POLL_INTERVAL", 0):
                with self.assertRaises(TimeoutError):
                    mod.wait_for_terminal(client, "iid", Path(tmp), time.monotonic() - 1)

    def test_wait_survives_a_broken_progress_stream(self):
        client = SimpleNamespace(interactions=self.FakeInteractions(["completed"], stream_error=True))
        with tempfile.TemporaryDirectory() as tmp:
            with mock.patch.object(mod, "POLL_INTERVAL", 0):
                result = mod.wait_for_terminal(client, "iid", Path(tmp), time.monotonic() + 30)
        self.assertEqual(result.status, "completed")
        self.assertGreaterEqual(client.interactions.stream_calls, 1)

    def test_terminal_status_blocker_only_flags_requires_action(self):
        self.assertIsNone(mod.terminal_status_blocker("in_progress"))
        self.assertIsNone(mod.terminal_status_blocker("completed"))
        self.assertIn("function call", mod.terminal_status_blocker("requires_action") or "")

    def test_progress_lines_are_capped(self):
        with tempfile.TemporaryDirectory() as tmp:
            d = Path(tmp)
            with mock.patch.object(mod, "MAX_PROGRESS_LINES", 5):
                for n in range(12):
                    mod.append_progress(d, f"line {n}")
            lines = (d / "progress.log").read_text().splitlines()
        self.assertLessEqual(len(lines), 6)
        self.assertIn("line 11", lines[-1])


class CleanupTests(unittest.TestCase):
    class FakeInteractions:
        def __init__(self, error: Exception | None = None):
            self.error = error
            self.deleted: list[str] = []

        def delete(self, id: str, **kwargs):
            if self.error is not None:
                raise self.error
            self.deleted.append(id)

    def fake_client(self, error: Exception | None = None):
        interactions = self.FakeInteractions(error)
        return SimpleNamespace(interactions=interactions), interactions

    def test_cleanup_treats_an_already_deleted_interaction_as_done(self):
        """A 404 means the stored interaction is already gone (retention, or an earlier
        cleanup). Counting it as a failure kept the run directory forever and retried a
        delete that could never succeed."""
        with tempfile.TemporaryDirectory() as tmp:
            runs = Path(tmp)
            self.make_run(runs, "old", "completed", age_days=30, interaction_id="gone")
            client, _ = self.fake_client(RuntimeError("Error code: 404 - not found"))
            with mock.patch.object(mod, "RUNS_DIR", runs), contextlib.redirect_stdout(io.StringIO()) as out:
                mod.cmd_cleanup(older_than_days=7, dry_run=False, remote=True, client=client)
            self.assertIn("1 interactions", out.getvalue())
            self.assertFalse((runs / "old").exists())

    def test_cleanup_keeps_a_run_whose_interaction_cannot_be_deleted_yet(self):
        with tempfile.TemporaryDirectory() as tmp:
            runs = Path(tmp)
            self.make_run(runs, "old", "completed", age_days=30, interaction_id="fresh")
            client, _ = self.fake_client(RuntimeError("400 cannot be deleted in its current state"))
            with mock.patch.object(mod, "RUNS_DIR", runs), contextlib.redirect_stdout(io.StringIO()) as out:
                mod.cmd_cleanup(older_than_days=7, dry_run=False, remote=True, client=client)
            self.assertIn("keeping old", out.getvalue())
            self.assertTrue((runs / "old").exists())

    def test_interaction_missing_only_matches_absence(self):
        self.assertTrue(mod.interaction_missing(RuntimeError("Error code: 404")))
        self.assertTrue(mod.interaction_missing(RuntimeError("Requested entity was not found")))
        self.assertFalse(mod.interaction_missing(RuntimeError("400 cannot be deleted in its current state")))
        self.assertFalse(mod.interaction_missing(RuntimeError("TransportError: connection reset")))

    def make_run(self, runs: Path, run_id: str, status: str, age_days: float, interaction_id: str | None = "iid"):
        d = runs / run_id
        d.mkdir(parents=True)
        (d / "status").write_text(status + "\n")
        finished = datetime.now(timezone.utc) - timedelta(days=age_days)
        meta = {"run_id": run_id, "kind": "delegate", "created_at": finished.isoformat(), "finished_at": finished.isoformat()}
        if interaction_id:
            meta["interaction_id"] = interaction_id
        (d / "meta.json").write_text(json.dumps(meta))
        return d

    def test_prunable_runs_selects_terminal_runs_past_the_threshold(self):
        with tempfile.TemporaryDirectory() as tmp:
            runs = Path(tmp)
            self.make_run(runs, "old", "completed", age_days=10)
            self.make_run(runs, "fresh", "completed", age_days=1)
            self.make_run(runs, "running", "running", age_days=10)
            with mock.patch.object(mod, "RUNS_DIR", runs):
                selected = dict(mod.prunable_runs(7))
        self.assertEqual(list(selected), ["old"])
        self.assertEqual(selected["old"], "iid")

    def test_prunable_runs_falls_back_to_the_status_file_mtime(self):
        """A run whose meta.json is unreadable is still prunable, using the status mtime."""
        with tempfile.TemporaryDirectory() as tmp:
            runs = Path(tmp)
            d = runs / "broken"
            d.mkdir(parents=True)
            (d / "status").write_text("completed\n")
            with mock.patch.object(mod, "RUNS_DIR", runs):
                self.assertEqual(mod.prunable_runs(0), [("broken", None)])
                self.assertEqual(mod.prunable_runs(7), [])

    def test_cleanup_dry_run_removes_nothing(self):
        with tempfile.TemporaryDirectory() as tmp:
            runs = Path(tmp)
            self.make_run(runs, "old", "completed", age_days=30)
            with mock.patch.object(mod, "RUNS_DIR", runs), contextlib.redirect_stdout(io.StringIO()) as out:
                mod.cmd_cleanup(older_than_days=7, dry_run=True, remote=False)
            self.assertTrue((runs / "old").exists())
            self.assertIn("old", out.getvalue())

    def test_cleanup_removes_old_terminal_runs_and_keeps_the_rest(self):
        with tempfile.TemporaryDirectory() as tmp:
            runs = Path(tmp)
            self.make_run(runs, "old", "completed", age_days=30)
            self.make_run(runs, "fresh", "completed", age_days=1)
            self.make_run(runs, "running", "running", age_days=30)
            with mock.patch.object(mod, "RUNS_DIR", runs), contextlib.redirect_stdout(io.StringIO()):
                mod.cmd_cleanup(older_than_days=7, dry_run=False, remote=False)
            self.assertFalse((runs / "old").exists())
            self.assertTrue((runs / "fresh").exists())
            self.assertTrue((runs / "running").exists())


class CliFailureTests(unittest.TestCase):
    def run_cli(self, *args: str, env: dict) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(SCRIPT), *args],
            capture_output=True,
            text=True,
            env={**os.environ, **env},
        )

    def _clean(self, **overrides) -> dict:
        env = {name: "" for name in CREDENTIAL_VARS}
        env.update(overrides)
        return env

    def test_delegate_without_credentials_fails_with_guidance(self):
        proc = self.run_cli("delegate", "--prompt", "x", env=self._clean())
        self.assertNotEqual(proc.returncode, 0)
        self.assertIn("gcloud auth application-default login", proc.stderr)
        self.assertIn("GEMINI_API_KEY", proc.stderr)

    def test_forced_vertex_without_location_fails_before_creating_a_run(self):
        with adc(True) as path, tempfile.TemporaryDirectory() as home:
            proc = self.run_cli(
                "delegate",
                "--prompt",
                "x",
                env=self._clean(
                    ANTIGRAVITY_AUTH="vertex",
                    ANTIGRAVITY_PROJECT="proj-a",
                    GOOGLE_APPLICATION_CREDENTIALS=path,
                    ANTIGRAVITY_HOME=home,
                ),
            )
            self.assertNotEqual(proc.returncode, 0)
            self.assertIn("location", proc.stderr)
            self.assertFalse((Path(home) / "runs").exists() and list((Path(home) / "runs").iterdir()))


if __name__ == "__main__":
    unittest.main()