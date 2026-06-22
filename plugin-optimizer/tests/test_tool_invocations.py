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


class StructureSkillFolderTests(unittest.TestCase):
    """Skill folder content rules: only README.md/CHANGELOG.md are flagged.

    The official spec is permissive in practice — the skill-creator's own skill
    contains agents/, eval-viewer/, LICENSE.txt, and the official PDF example
    shows reference.md/examples.md/FORMS.md alongside scripts/ at the skill root.
    We only flag clearly auxiliary files (README.md, CHANGELOG.md).
    """

    def setUp(self):
        self.validator = _load_validator_module()

    def _write_min_plugin(self, root: Path) -> None:
        (root / ".claude-plugin").mkdir(parents=True, exist_ok=True)
        (root / ".claude-plugin" / "plugin.json").write_text(
            json.dumps({"name": "test-plugin", "version": "0.0.0"}),
            encoding="utf-8",
        )

    def _write_skill(self, root: Path, name: str = "example") -> Path:
        skill_dir = root / "skills" / name
        skill_dir.mkdir(parents=True)
        (skill_dir / "SKILL.md").write_text(
            """---\nname: example\ndescription: This skill should be used when testing directory rules.\n---\n\nbody\n""",
            encoding="utf-8",
        )
        return skill_dir

    def _should_messages(self, root: Path):
        result = self.validator.check_structure(root)
        return [i.message for i in result.issues if i.severity == "should"]

    def test_flags_readme_and_changelog_in_skill(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._write_min_plugin(root)
            skill_dir = self._write_skill(root)
            (skill_dir / "README.md").write_text("# readme", encoding="utf-8")
            (skill_dir / "CHANGELOG.md").write_text("# changelog", encoding="utf-8")

            messages = self._should_messages(root)
            self.assertIn("Auxiliary file in skill folder: README.md", messages)
            self.assertIn("Auxiliary file in skill folder: CHANGELOG.md", messages)

    def test_allows_non_standard_subdir(self):
        """Non-standard subdirs (config/, templates/) are NOT flagged — official
        skill-creator itself ships agents/ and eval-viewer/."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._write_min_plugin(root)
            skill_dir = self._write_skill(root)
            (skill_dir / "config").mkdir()
            (skill_dir / "templates").mkdir()

            messages = self._should_messages(root)
            for msg in messages:
                self.assertNotIn("Non-standard skill subdirectory", msg)

    def test_allows_loose_markdown_in_skill(self):
        """Loose .md docs (reference.md, examples.md) are NOT flagged — the
        official PDF example shows them alongside scripts/ at skill root."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._write_min_plugin(root)
            skill_dir = self._write_skill(root)
            (skill_dir / "reference.md").write_text("# ref", encoding="utf-8")
            (skill_dir / "examples.md").write_text("# ex", encoding="utf-8")

            messages = self._should_messages(root)
            for msg in messages:
                self.assertNotIn("Loose markdown file in skill folder", msg)

    def test_nested_skill_subdir_not_flagged(self):
        """Nested skills (subdir with its own SKILL.md, e.g. lark/lark-mail/)
        are a legitimate pattern and must not be flagged."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._write_min_plugin(root)
            skill_dir = self._write_skill(root)
            nested = skill_dir / "lark-mail"
            nested.mkdir()
            (nested / "SKILL.md").write_text(
                """---\nname: lark-mail\ndescription: nested skill.\n---\n\nbody\n""",
                encoding="utf-8",
            )

            messages = self._should_messages(root)
            for msg in messages:
                self.assertNotIn("Non-standard skill subdirectory: lark-mail", msg)


if __name__ == "__main__":
    unittest.main()
