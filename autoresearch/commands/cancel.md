---
description: "Cancel active autoresearch loop"
allowed-tools: ["Bash(test -f .claude/autoresearch.local.md:*)", "Bash(rm .claude/autoresearch.local.md)", "Read(.claude/autoresearch.local.md)"]
disable-model-invocation: true
---

# Cancel Autoresearch

Run this from a **separate** Claude Code session in the same project directory — the looping session is busy being re-prompted by the stop hook and cannot run this itself. Removing the state file makes the loop's next stop-hook fire find no state and exit cleanly.

To cancel the autoresearch loop:

1. Check if `.claude/autoresearch.local.md` exists: run `test -f .claude/autoresearch.local.md && echo "EXISTS" || echo "NOT_FOUND"`

2. If NOT_FOUND: report "No active autoresearch loop found."

3. If EXISTS:
   - Read `.claude/autoresearch.local.md` to get `iteration:` (experiment count), `run_tag:`, and `worktree_dir:` from the frontmatter
   - Remove the file: run `rm .claude/autoresearch.local.md` (the loop's next stop-hook fire then exits cleanly)
   - Do NOT delete the worktree automatically — it may hold an unconfirmed result. Report:
     "Cancelled autoresearch loop for run tag '<tag>' (was at experiment N). The result is in the isolated worktree `<worktree_dir>` on branch `autoresearch/<tag>`. To land it: cd there, review, `git reset --soft <baseline>` then `/git:commit`. To discard it: `git worktree remove --force <worktree_dir>` and `git branch -D autoresearch/<tag>`."
