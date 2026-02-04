import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


def _load_validator_module():
    validator_path = Path(__file__).resolve().parents[1] / "scripts" / "validate-plugin.py"
    spec = importlib.util.spec_from_file_location("validate_plugin", validator_path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class ToolInvocationCheckTests(unittest.TestCase):
    def setUp(self):
        self.validator = _load_validator_module()

    def _write_min_plugin(self, root: Path) -> None:
        (root / ".claude-plugin").mkdir(parents=True, exist_ok=True)
        (root / ".claude-plugin" / "plugin.json").write_text(
            json.dumps({"name": "test-plugin", "version": "0.0.0"}),
            encoding="utf-8",
        )

    def test_flags_explicit_core_tool_reference_outside_fence(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._write_min_plugin(root)
            (root / "skills" / "example").mkdir(parents=True)
            (root / "skills" / "example" / "SKILL.md").write_text(
                """---\nname: example\ndescription: xxxxxxxxxx\n---\n\nUse Read tool to read each file.\n""",
                encoding="utf-8",
            )

            result = self.validator.check_tool_invocations(root)
            messages = [i.message for i in result.issues if i.severity == "should"]
            self.assertIn("Explicit core tool reference", messages)

    def test_flags_explicit_core_tool_reference_with_backticks(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._write_min_plugin(root)
            (root / "skills" / "example").mkdir(parents=True)
            (root / "skills" / "example" / "SKILL.md").write_text(
                """---\nname: example\ndescription: xxxxxxxxxx\n---\n\nUse `Read` tool to read each file.\n""",
                encoding="utf-8",
            )

            result = self.validator.check_tool_invocations(root)
            messages = [i.message for i in result.issues if i.severity == "should"]
            self.assertIn("Explicit core tool reference", messages)

    def test_does_not_flag_explicit_core_tool_reference_inside_fence(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._write_min_plugin(root)
            (root / "skills" / "example").mkdir(parents=True)
            (root / "skills" / "example" / "SKILL.md").write_text(
                """---\nname: example\ndescription: xxxxxxxxxx\n---\n\n```markdown\nUse Read tool to read each file.\nUse `AskUserQuestion` tool to ask for confirmation.\n```\n\nThis is fine.\n""",
                encoding="utf-8",
            )

            result = self.validator.check_tool_invocations(root)
            messages = [i.message for i in result.issues if i.severity == "should"]
            self.assertNotIn("Explicit core tool reference", messages)

    def test_allows_explicit_askuserquestion_outside_fence(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._write_min_plugin(root)
            (root / "skills" / "example").mkdir(parents=True)
            (root / "skills" / "example" / "SKILL.md").write_text(
                """---\nname: example\ndescription: xxxxxxxxxx\n---\n\nUse `AskUserQuestion` tool to ask one focused question.\n""",
                encoding="utf-8",
            )

            result = self.validator.check_tool_invocations(root)
            # If this ever starts failing, it means the checker got broadened and needs exceptions.
            for issue in result.issues:
                self.assertNotEqual(issue.message, "Explicit core tool reference")
                self.assertNotEqual(issue.message, "Explicit Bash tool reference")
                self.assertNotEqual(issue.message, "Explicit Task tool reference")


if __name__ == "__main__":
    unittest.main()
