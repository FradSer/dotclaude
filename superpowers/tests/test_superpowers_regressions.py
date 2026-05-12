import shlex
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SUPERPOWERS = ROOT / "superpowers"


def call_bash_function(function_name: str, argument: str) -> str:
    utils = SUPERPOWERS / "lib" / "utils.sh"
    command = f"source {shlex.quote(str(utils))}; {function_name} {shlex.quote(argument)}"
    result = subprocess.run(
        ["bash", "-lc", command],
        check=True,
        text=True,
        capture_output=True,
    )
    return result.stdout.strip()


def extract_executable_check(markdown: str, heading: str) -> str:
    start = markdown.index(heading)
    executable = markdown.index("**Executable check:**", start)
    fence_start = markdown.index("```", executable)
    command_start = markdown.index("\n", fence_start) + 1
    fence_end = markdown.index("```", command_start)
    return markdown[command_start:fence_end].strip()


class SuperpowersRegressionTests(unittest.TestCase):
    def test_plan_checklist_uses_plan_root_task_files(self) -> None:
        checklist = (ROOT / "docs" / "retros" / "checklists" / "plan-v1.md").read_text()

        self.assertNotIn("tasks/*.md", checklist)
        self.assertNotIn("tasks/", checklist)
        self.assertIn("task-*.md", checklist)

    def test_plan_checklist_does_not_print_success_when_impl_tests_are_missing(self) -> None:
        checklist = (ROOT / "docs" / "retros" / "checklists" / "plan-v1.md").read_text()

        self.assertNotIn("all(False for _ in [])", checklist)
        self.assertIn("missing", checklist)
        self.assertIn("if not missing", checklist)

    def test_plan_checklist_test_01_command_reports_missing_test_counterparts(self) -> None:
        checklist = (ROOT / "docs" / "retros" / "checklists" / "plan-v1.md").read_text()
        command = extract_executable_check(checklist, "### TEST-01")

        with tempfile.TemporaryDirectory() as tmp:
            plan_dir = Path(tmp)
            (plan_dir / "task-001-widget-impl.md").write_text("## Description\nBuild widget.\n")

            result = subprocess.run(
                ["bash", "-lc", command],
                cwd=plan_dir,
                text=True,
                capture_output=True,
                check=False,
            )

        self.assertIn("missing test counterpart", result.stdout)
        self.assertNotIn("all impl tasks have test counterparts or justifications", result.stdout)

    def test_plan_checklist_test_01_command_accepts_explicit_test_justification(self) -> None:
        checklist = (ROOT / "docs" / "retros" / "checklists" / "plan-v1.md").read_text()
        command = extract_executable_check(checklist, "### TEST-01")

        with tempfile.TemporaryDirectory() as tmp:
            plan_dir = Path(tmp)
            (plan_dir / "task-001-widget-impl.md").write_text(
                "## Description\nBuild widget.\n\nNo test needed because this task updates static docs only.\n"
            )

            result = subprocess.run(
                ["bash", "-lc", command],
                cwd=plan_dir,
                text=True,
                capture_output=True,
                check=False,
            )

        self.assertIn("all impl tasks have test counterparts or justifications", result.stdout)
        self.assertNotIn("missing test counterpart", result.stdout)

    def test_code_checklist_uses_macos_portable_commands(self) -> None:
        checklist = (ROOT / "docs" / "retros" / "checklists" / "code-v1.md").read_text()

        self.assertNotIn("grep -P", checklist)

    def test_promise_text_requires_final_standalone_tag(self) -> None:
        self.assertEqual(
            "PLAN_COMPLETE",
            call_bash_function(
                "extract_promise_text",
                "Plan complete.\n<promise>PLAN_COMPLETE</promise>",
            ),
        )
        self.assertEqual(
            "",
            call_bash_function(
                "extract_promise_text",
                "<promise>PLAN_COMPLETE</promise>\nExtra text after the tag.",
            ),
        )
        self.assertEqual(
            "",
            call_bash_function(
                "extract_promise_text",
                "Mentioning <promise>PLAN_COMPLETE</promise> inline is not completion.",
            ),
        )

if __name__ == "__main__":
    unittest.main()
