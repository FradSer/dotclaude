---
description: "Cancel active autoresearch loop"
allowed-tools: ["Bash(test -f .claude/autoresearch.local.md:*)", "Bash(rm .claude/autoresearch.local.md)", "Read(.claude/autoresearch.local.md)"]
hide-from-slash-command-tool: "true"
---

# Cancel Autoresearch

To cancel the autoresearch loop:

1. Check if `.claude/autoresearch.local.md` exists: run `test -f .claude/autoresearch.local.md && echo "EXISTS" || echo "NOT_FOUND"`

2. If NOT_FOUND: report "No active autoresearch loop found."

3. If EXISTS:
   - Read `.claude/autoresearch.local.md` to get `iteration:` (experiment count) and `run_tag:` fields from the frontmatter
   - Remove the file: run `rm .claude/autoresearch.local.md`
   - Report: "Cancelled autoresearch loop for run tag '<tag>' (was at experiment N)"
