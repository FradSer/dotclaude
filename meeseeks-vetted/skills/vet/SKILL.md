---
name: vet
description: This skill should be used when the user invokes /vet to manually surface the current session task and have Claude evaluate whether it is clear and complete.
user-invocable: true
---

Run `ls -t ~/.claude/projects/$(echo "$PWD" | tr '/' '-')/*.vetted.json 2>/dev/null | head -1` to find the most recent session state file for this project.

If no state file exists, report: "No task is being tracked in this session."

Otherwise read the file and extract:
- `task` — the active task description (synthesized from the session's prompts)
- `updated_at` — when it was last updated
- `modified_files` — files changed so far (if present)

Display the tracked task clearly, then evaluate two things:

**1. Clarity check**
Is the task specific enough to have unambiguous completion criteria? If not, call the AskUserQuestion tool and ask the user to clarify before proceeding.

**2. Completion check**
Based on what has been done in this conversation, is the task complete?
- If yes: confirm what was done and append `<verified>Fully Vetted.</verified>`.
- If no: list what remains undone and what the next step is. Do not mark verified.
- If indeterminate (discussion/planning only): state that and skip verification.
