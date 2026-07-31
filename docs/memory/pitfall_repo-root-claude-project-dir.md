---
name: pitfall_repo-root-claude-project-dir
category: pitfall
summary: repo_root() silently targets parent repo when CLAUDE_PROJECT_DIR unset
source: commit:7ab43e0
created: 2026-08-01
updated: 2026-08-01
---

`repo_root()` (in `superpowers/lib/utils.sh`) resolves in the order
`${CLAUDE_PROJECT_DIR}` -> `git rev-parse --show-toplevel` -> `${PWD}`.

At skill runtime, `CLAUDE_PROJECT_DIR` points at the user's project, so `docs-index.sh`
correctly lands at the user's `docs/README.md`. But when developing the plugin itself
(running `lib/docs-index.sh` by hand from within `superpowers/`), `CLAUDE_PROJECT_DIR` is
typically unset and `git rev-parse --show-toplevel` resolves to the parent `dotclaude/`
repo — so a bare `bash lib/docs-index.sh rebuild` writes to `dotclaude/docs/README.md`,
NOT `superpowers/docs/README.md`.

**Why:** This caused real silent wrong-location writes during the 2026-07-04 docs-index
plan run. After Batch 6 committed, the main agent ran `set-status`/`upsert` to refresh the
index. Because `CLAUDE_PROJECT_DIR` was unset, every call silently targeted
`dotclaude/docs/README.md` (which was empty/absent), so: (a) `set-status` returned exit 3
("not in index") on paths that were clearly in `superpowers/docs/README.md`, and (b) the
retro `upsert` wrote a single-row index to `dotclaude/docs/README.md`, appearing to "lose"
the 3 existing rows — they were never read because the wrong file was opened. The user
caught this only when asking "did you update docs/README.md?" and the index still showed
`wip` everywhere. Not a `cmd_upsert`/`cmd_show` code bug — those correctly preserve/append
rows; the bug is `repo_root`'s fallback silently targeting the wrong project when the
plugin is a subdirectory of a larger git repo.

**How to apply:** When developing any `superpowers/lib/*.sh` script by hand from inside
the plugin directory, set `CLAUDE_PROJECT_DIR` explicitly first:

```
CLAUDE_PROJECT_DIR="$(pwd)" bash lib/docs-index.sh rebuild
```

The header comment block at `superpowers/lib/docs-index.sh` (lines 31-40) documents this
override. Any future plugin-subdirectory tool that calls `repo_root()` inherits the same
fallback — guard against it the same way. See related `docs/docs-index-status.md`.
