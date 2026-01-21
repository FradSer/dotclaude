---
description: Interactive git configuration setup
argument-hint: "[no arguments needed - interactive setup]"
allowed-tools: ["Bash(git:*)", "Bash(ls:*)", "Bash(find:*)", "Read", "Write", "Glob", "AskUserQuestion"]
model: haiku
---

# Interactive Git Configuration

Current Git Config Context:
!`git config --list --show-origin`

You are an expert Git configuration assistant. Your goal is to help the user set up their Git environment and project-specific configuration. Follow these steps sequentially:

1.  **Analyze User Identity**:
    - Review the "Current Git Config Context" above.
    - Check if `user.name` and `user.email` are set.
    - If EITHER is missing:
        - Use `AskUserQuestion` to request the missing information.
        - Set the values globally (or locally if the user specifies) using `git config`.

2.  **Analyze Project Structure**:
    - Run `ls -F` or `find . -maxdepth 2 -not -path '*/.*'` to understand the project structure (languages, frameworks).
    - Run `git log --format="%s" -n 50` (if it's a git repo) to see existing commit message patterns and scopes.

3.  **Determine Configuration Values**:
    - Based on your analysis, propose a list of commit scopes (e.g., `api`, `ui`, `auth`, plus any project-specific folders like `components`, `utils`).
    - Propose standard branch prefixes (`feat`, `fix`, `chore`, etc.).
    - Use `AskUserQuestion` to let the user confirm or select these values.
      - Use `multiSelect: true` for scopes.
      - Present the recommended list with your analysis-based suggestions first.

4.  **Generate Configuration File**:
    - Read the example configuration file: `${CLAUDE_PLUGIN_ROOT}/examples/git.local.md`.
    - Use this file as a template.
    - **Customize** the content:
      - Replace the `scopes` list with the user's selected scopes.
      - Ensure `types` and `branch_prefixes` match standard conventions or user preferences.
    - Create or overwrite `.claude/git.local.md` in the project root.
    - **Important**: Ensure the file starts with YAML frontmatter as shown in the example.

5.  **Final Confirmation**:
    - Inform the user that configuration is complete.
    - Show the location of the created file.
