import json
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SUPERPOWERS = ROOT / "superpowers"


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

    def test_executing_plans_goal_section_forbids_per_batch_commit_condition(self) -> None:
        skill = (SUPERPOWERS / "skills/executing-plans/SKILL.md").read_text()
        self.assertIn("batch-progress.sh", skill)
        self.assertIn("per-batch commit", skill.lower())
        self.assertIn("do not phrase", skill.lower())
        self.assertIn("Plan execution complete", skill)

    def test_executing_plans_references_phase_extracts(self) -> None:
        skill = (SUPERPOWERS / "skills/executing-plans/SKILL.md").read_text()
        self.assertIn("./references/phase-2-task-creation.md", skill)
        self.assertIn("./references/definition-of-done.md", skill)

    # --- Invocation-only contract (v3.8.0): superpowers must be user-manual ---
    # The model must NOT be able to proactively/auto-dispatch any superpowers
    # skill. This guards the removal of the SessionStart routing hook and the
    # using-superpowers dispatcher; regressing either reintroduces model
    # auto-invocation. See feedback memory feedback_skill_invocation_bypass.

    def test_plugin_manifest_has_no_sessionstart_hook(self) -> None:
        """The SessionStart routing-injection hook was removed in v3.8.0.
        Its presence would re-arm the model's proactive dispatch path."""
        manifest = json.loads(
            (SUPERPOWERS / ".claude-plugin/plugin.json").read_text()
        )
        self.assertNotIn("SessionStart", manifest.get("hooks", {}),
                         "SessionStart hook reintroduces model auto-dispatch")

    def test_plugin_manifest_has_no_using_superpowers_skill(self) -> None:
        """The using-superpowers dispatcher skill was removed in v3.8.0.
        Its presence would let the model auto-route to other superpowers
        skills via description trigger phrases."""
        manifest = json.loads(
            (SUPERPOWERS / ".claude-plugin/plugin.json").read_text()
        )
        skills = manifest.get("skills", [])
        for entry in skills:
            self.assertNotIn("using-superpowers", entry,
                             "using-superpowers dispatcher reintroduces model auto-dispatch")

    def test_using_superpowers_skill_dir_is_absent(self) -> None:
        """No residual dispatcher directory on disk."""
        self.assertFalse(
            (SUPERPOWERS / "skills/using-superpowers").exists(),
            "skills/using-superpowers/ should have been deleted in v3.8.0",
        )

    def test_session_start_hook_script_is_absent(self) -> None:
        """No residual SessionStart hook script on disk."""
        self.assertFalse(
            (SUPERPOWERS / "hooks/session-start.sh").exists(),
            "hooks/session-start.sh should have been deleted in v3.8.0",
        )

    def test_manifest_keeps_five_user_commands_and_three_internal_skills(self) -> None:
        """Removal must not have dropped the 5 user-invocable commands or the
        3 internal helper skills loaded within user-invoked flows."""
        manifest = json.loads(
            (SUPERPOWERS / ".claude-plugin/plugin.json").read_text()
        )
        commands = manifest.get("commands", [])
        skills = manifest.get("skills", [])
        self.assertEqual(len(commands), 5,
                         f"expected 5 user commands, got {len(commands)}: {commands}")
        self.assertEqual(len(skills), 3,
                         f"expected 3 internal skills, got {len(skills)}: {skills}")
        for name in (
            "behavior-driven-development",
            "verification-before-completion",
            "receiving-code-review",
        ):
            self.assertTrue(
                any(name in s for s in skills),
                f"internal skill {name} missing from manifest",
            )


if __name__ == "__main__":
    unittest.main()
