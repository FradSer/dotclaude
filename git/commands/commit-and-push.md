---
allowed-tools: ["Bash(git:*)", "Read", "Write", "Glob", "AskUserQuestion", "Skill"]
description: Create atomic conventional git commit and push to remote
argument-hint: "[no arguments needed]"
model: haiku
---

## Your Task

1. **Verify configuration exists**: Check if `.claude/git.local.md` exists. If NOT found, automatically invoke the `/git:config` command to set up project-specific settings before proceeding.

2. **Load the conventional-commits skill using the Skill tool** to access conventional commit capabilities.

3. **Perform safety checks** on pending changes (see Safety Protocol in plugin README):
   - Detect sensitive files (credentials, secrets, .env files)
   - Warn about large files (>1MB) and large commits (>500 lines)
   - Request user confirmation if issues found

4. **Prepare Commits**:
   a. Analyze pending changes to identify coherent logical units of work
   b. For each logical unit:
      - Draft the commit message following conventional commits format
      - **Check for new scopes**: If the commit message contains a scope that is not defined in `.claude/git.local.md`, automatically invoke the `/git:config` command to add the new scope to the configuration.
      - **Validate the message** against the "Core Rules" defined in the `conventional-commits` skill.
      - Stage the relevant files
      - Create the commit with the validated message
      - **IMPORTANT**: The conventional-commits skill defines a PreToolUse hook that automatically validates commit message format BEFORE execution. If validation fails, the hook will BLOCK the commit and provide error details.
   c. Repeat until every change is committed

5. **Push to Remote**:
   - Once all commits are created, push the current branch to the remote repository.
   - Use `git push` (add `-u origin <branch>` if upstream is not set).
