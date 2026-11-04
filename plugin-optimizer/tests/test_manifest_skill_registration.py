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


class ManifestSkillRegistrationTests(unittest.TestCase):
    """Skills in skills/ are auto-discovered; listing them under "commands"
    registers each SKILL.md twice. Visibility comes from frontmatter."""

    def setUp(self):
        self.validator = _load_validator_module()

    def _write_plugin(self, root: Path, extra: dict | None = None) -> None:
        (root / ".claude-plugin").mkdir(parents=True, exist_ok=True)
        manifest = {
            "name": "test-plugin",
            "version": "0.0.0",
            "description": "A plugin used to test manifest validation.",
            "author": {"name": "Test"},
            "keywords": ["test"],
        }
        manifest.update(extra or {})
        (root / ".claude-plugin" / "plugin.json").write_text(
            json.dumps(manifest), encoding="utf-8"
        )

    def _write_skill(self, root: Path, user_invocable: str = "false") -> None:
        skill_dir = root / "skills" / "commit"
        skill_dir.mkdir(parents=True)
        (skill_dir / "SKILL.md").write_text(
            "---\n"
            "name: commit\n"
            "description: This skill should be used when committing changes.\n"
            f"user-invocable: {user_invocable}\n"
            "---\n\nbody\n",
            encoding="utf-8",
        )

    def _write_command_file(self, root: Path) -> None:
        (root / "commands").mkdir(exist_ok=True)
        (root / "commands" / "status.md").write_text("# status", encoding="utf-8")

    def _check(self, root: Path):
        return self.validator.check_manifest(root)

    def test_manifest_without_commands_key_passes(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._write_plugin(root)
            self._write_skill(root)

            result = self._check(root)

            self.assertTrue(result.passed, [i.message for i in result.issues])

    def test_commands_pointing_into_skills_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._write_plugin(root, {"commands": ["./skills/commit/"]})
            self._write_skill(root)

            result = self._check(root)

            self.assertFalse(result.passed)
            self.assertIn(
                "Duplicate skill registration",
                [i.message for i in result.issues if i.severity == "must"],
            )

    def test_commands_object_map_pointing_into_skills_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._write_plugin(
                root,
                {"commands": {"commit": {"source": "./skills/commit/SKILL.md"}}},
            )
            self._write_skill(root)

            result = self._check(root)

            self.assertFalse(result.passed)
            self.assertIn(
                "Duplicate skill registration",
                [i.message for i in result.issues if i.severity == "must"],
            )

    def test_commands_string_pointing_into_skills_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._write_plugin(root, {"commands": "./skills/commit/"})
            self._write_skill(root)

            result = self._check(root)

            self.assertFalse(result.passed)
            self.assertIn(
                "Duplicate skill registration",
                [i.message for i in result.issues if i.severity == "must"],
            )

    def test_commands_naming_real_command_file_is_allowed(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._write_plugin(root, {"commands": ["./commands/status.md"]})
            self._write_command_file(root)

            result = self._check(root)

            self.assertTrue(result.passed, [i.message for i in result.issues])

    def test_user_invocable_skill_needs_no_commands_declaration(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._write_plugin(root)
            self._write_skill(root, user_invocable="true")

            result = self._check(root)

            self.assertTrue(result.passed, [i.message for i in result.issues])
            self.assertNotIn(
                "Undeclared user-invocable skill",
                [i.message for i in result.issues],
            )


if __name__ == "__main__":
    unittest.main()
