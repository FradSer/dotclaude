"""Regression scenarios for frontmatter trigger-phrase detection and the
denested-layout token check. See features/validator-quality-checks.feature.

These protect against two false-positive / blind-spot classes:
  - Legitimate trigger phrasing (Chinese "当...时使用", "Use before ...",
    "Use this skill whenever ...") was reported as "missing trigger phrases".
  - Denested mirror layouts (skills/<name>/<name>.md, no SKILL.md) were
    skipped entirely by the token-budget check ("No skills found").
"""
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


class TriggerPhraseTests(unittest.TestCase):
    def setUp(self):
        self.validator = _load_validator_module()

    def _plugin_with_skill(self, root: Path, description: str) -> Path:
        (root / ".claude-plugin").mkdir(parents=True, exist_ok=True)
        (root / ".claude-plugin" / "plugin.json").write_text(
            json.dumps({"name": "test-plugin", "version": "0.0.0"}), encoding="utf-8"
        )
        skill = root / "skills" / "example"
        skill.mkdir(parents=True)
        (skill / "SKILL.md").write_text(
            "---\nname: example\ndescription: " + description + "\n---\n\nDo the work.\n",
            encoding="utf-8",
        )
        return root

    def _missing_trigger(self, root: Path) -> bool:
        result = self.validator.check_frontmatter(root)
        return any(
            "missing trigger phrases" in i.message.lower()
            for i in result.issues
            if i.severity in ("must", "should", "may")
        )

    def test_chinese_trigger_phrasing_is_accepted(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = self._plugin_with_skill(
                Path(tmp),
                '"当用户需要创建或编辑幻灯片、读取或修改单个页面时使用。"',
            )
            self.assertFalse(self._missing_trigger(root))

    def test_chinese_shiyong_applicable_is_accepted(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = self._plugin_with_skill(
                Path(tmp), '"汇总指定时间范围的会议纪要并生成报告。适用于了解今天的安排。"'
            )
            self.assertFalse(self._missing_trigger(root))

    def test_use_before_is_accepted(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = self._plugin_with_skill(
                Path(tmp),
                "Mines git history for coupled code. Use before making changes or running tests.",
            )
            self.assertFalse(self._missing_trigger(root))

    def test_use_this_skill_whenever_is_accepted(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = self._plugin_with_skill(
                Path(tmp),
                'Updates the README. Use this skill whenever the user asks to "update the README".',
            )
            self.assertFalse(self._missing_trigger(root))

    def test_no_scenario_is_still_flagged(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = self._plugin_with_skill(
                Path(tmp),
                "Creates atomic conventional git commits and pushes changes to the remote.",
            )
            self.assertTrue(self._missing_trigger(root))


class DenestedTokenCheckTests(unittest.TestCase):
    def setUp(self):
        self.validator = _load_validator_module()

    def test_denested_entry_files_are_token_checked(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / ".claude-plugin").mkdir(parents=True)
            (root / ".claude-plugin" / "plugin.json").write_text(
                json.dumps({"name": "mirror-plugin", "version": "0.0.0"}), encoding="utf-8"
            )
            skill = root / "skills" / "denested-skill"
            skill.mkdir(parents=True)
            # Denested layout: <name>.md instead of SKILL.md
            (skill / "denested-skill.md").write_text(
                "---\nname: denested-skill\ndescription: Reads a plugin. Use when reading plugins.\n---\n\n"
                + "Long body line with enough content to be counted.\n" * 30,
                encoding="utf-8",
            )
            result = self.validator.check_tokens(root)
            messages = [i.message for i in result.issues]
            self.assertFalse(
                any("No skills found" in m for m in messages),
                "denested entry files must not be skipped by the token check",
            )
            # The check must have actually analyzed the body (verbose ok line or
            # a real issue). At minimum it must not report the empty-skill may.
            self.assertTrue(
                any("token" in m.lower() for m in messages) or not messages,
                "expected token analysis output or a clean check",
            )


if __name__ == "__main__":
    unittest.main()
