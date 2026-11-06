"""Regression tests for Denester.fix_local_links().

See features/local-link-fix.feature. Mirror syncs rebuild skills/ from upstream
and run denest; the link repair must live in that shared transform so it is
re-applied on every resync (a local hand-edit would be overwritten).
"""
import importlib.util
import tempfile
import unittest
from pathlib import Path


def _load():
    path = Path(__file__).resolve().parents[1] / "denest.py"
    spec = importlib.util.spec_from_file_location("denest", path)
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


class FixLocalLinksTests(unittest.TestCase):
    def setUp(self):
        self.denest = _load()

    def _tree(self, root: Path, files: dict[str, str]) -> Path:
        tree = root / "skills"
        for rel, content in files.items():
            p = tree / rel
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(content, encoding="utf-8")
        return tree

    def _fixed(self, tree: Path, rel: str) -> str:
        d = self.denest.Denester(tree)
        d.fix_local_links()
        return (tree / rel).read_text(encoding="utf-8")

    def test_double_nested_references_link_is_deduplicated(self):
        with tempfile.TemporaryDirectory() as tmp:
            tree = self._tree(Path(tmp), {
                "foo/references/X.md": "# X",
                "foo/references/send.md": "Read [X](references/X.md) first.\n",
                "foo/foo.md": "entry (denested)",
            })
            out = self._fixed(tree, "foo/references/send.md")
            self.assertIn("[X](X.md)", out)
            self.assertNotIn("references/X.md)", out)

    def test_sibling_subdir_link_gains_dotdot(self):
        with tempfile.TemporaryDirectory() as tmp:
            tree = self._tree(Path(tmp), {
                "foo/palettes/bold.md": "# bold",
                "foo/references/house.md": "See [bold](palettes/bold.md).\n",
                "foo/foo.md": "entry",
            })
            out = self._fixed(tree, "foo/references/house.md")
            self.assertIn("[bold](../palettes/bold.md)", out)

    def test_anchor_is_preserved(self):
        with tempfile.TemporaryDirectory() as tmp:
            tree = self._tree(Path(tmp), {
                "foo/references/X.md": "# X",
                "foo/references/send.md": "See [X](references/X.md#section).\n",
                "foo/foo.md": "entry",
            })
            out = self._fixed(tree, "foo/references/send.md")
            self.assertIn("[X](X.md#section)", out)

    def test_correct_link_untouched_and_idempotent(self):
        with tempfile.TemporaryDirectory() as tmp:
            tree = self._tree(Path(tmp), {
                "foo/references/X.md": "# X",
                "foo/references/send.md": "Read [X](X.md) first.\n",
                "foo/foo.md": "entry",
            })
            d = self.denest.Denester(tree)
            self.assertEqual(d.fix_local_links(), 0)
            self.assertIn("[X](X.md)", (tree / "foo/references/send.md").read_text())
            self.assertEqual(d.fix_local_links(), 0)

    def test_external_links_untouched(self):
        with tempfile.TemporaryDirectory() as tmp:
            tree = self._tree(Path(tmp), {
                "foo/references/X.md": "# X",
                "foo/references/send.md": "See [docs](https://example.com/x.md) and [abs](/x/y.md).\n",
                "foo/foo.md": "entry",
            })
            d = self.denest.Denester(tree)
            self.assertEqual(d.fix_local_links(), 0)


if __name__ == "__main__":
    unittest.main()
