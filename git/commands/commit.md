---
allowed-tools: ["Bash(git:*)", "Read", "Write", "Glob", "AskUserQuestion", "Skill"]
description: Create atomic conventional git commit
argument-hint: "[no arguments needed]"
model: haiku
---

## Your Task

1. **Verify configuration exists**: Check if `.claude/git.local.md` exists. If NOT found, STOP and inform user: "Configuration required. Run `/git:config` to set up project-specific settings."

2. **Load the conventional-commits skill using the Skill tool** to access conventional commit capabilities.

3. **Perform safety checks** on pending changes (see Safety Protocol in plugin README):
   - Detect sensitive files (credentials, secrets, .env files)
   - Warn about large files (>1MB) and large commits (>500 lines)
   - Request user confirmation if issues found

4. **Analyze pending changes** to identify coherent logical units of work.

5. **For each logical unit**:
   a. Draft the commit message following conventional commits format
   b. **Validate the message** against the "Core Rules" defined in the `conventional-commits` skill.
   c. Stage the relevant files
   d. Create the commit with the validated message
   e. **IMPORTANT**: A PreToolUse hook will automatically validate the commit message format BEFORE execution. If validation fails, the hook will BLOCK the commit and provide error details. Ensure your message is correct to avoid blocked commits.

6. **Repeat** until every change is committed.
