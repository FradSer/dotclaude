import glob
import json
import os
import unittest
import yaml

GIT_PKG_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FORBIDDEN = "git" + "-agent"

class TestGitPackageDecoupling(unittest.TestCase):
    def test_zero_git_agent_references(self):
        """Ensure git package has zero occurrences of git-agent in code, docs, and skills."""
        for root, _, files in os.walk(GIT_PKG_DIR):
            if "__pycache__" in root or "tests" in root:
                continue
            for file in files:
                filepath = os.path.join(root, file)
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()
                    self.assertNotIn(
                        FORBIDDEN,
                        content,
                        f"Found forbidden reference in {filepath}"
                    )

    def test_plugin_json_validity(self):
        """Verify plugin.json exists and is valid JSON."""
        plugin_path = os.path.join(GIT_PKG_DIR, ".claude-plugin", "plugin.json")
        self.assertTrue(os.path.exists(plugin_path))
        with open(plugin_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        self.assertEqual(data["name"], "git")
        self.assertNotIn(
            "commands",
            data,
            "skills/ is auto-discovered; declaring skills under commands registers them twice",
        )

    def test_skills_frontmatter_validity(self):
        """Verify all SKILL.md frontmatters in git package parse cleanly."""
        skill_files = glob.glob(os.path.join(GIT_PKG_DIR, "skills", "**", "SKILL.md"), recursive=True)
        self.assertGreater(len(skill_files), 0, "No skills found in git package")
        for skill_file in skill_files:
            with open(skill_file, "r", encoding="utf-8") as f:
                content = f.read()
            parts = content.split("---", 2)
            self.assertGreaterEqual(len(parts), 3, f"Missing YAML frontmatter in {skill_file}")
            data = yaml.safe_load(parts[1])
            self.assertIn("name", data)
            self.assertIn("description", data)
            self.assertIn("allowed-tools", data)
            for tool in data["allowed-tools"]:
                self.assertNotIn(FORBIDDEN, tool)

if __name__ == "__main__":
    unittest.main()
