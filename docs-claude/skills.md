This documentation outlines how to create and manage **Agent Skills** in Claude Code, which are specialized instructions and tools that extend Claude's capabilities.

### **Core Concept**
A **Skill** is a directory containing a `SKILL.md` file. It consists of **YAML metadata** (defining the skill's name and triggers) and **Markdown instructions** (telling Claude how to perform the task).

### **How Skills Work**
1.  **Discovery:** Claude loads skill descriptions at startup.
2.  **Activation:** Claude automatically suggests a skill when your request matches its `description`.
3.  **Execution:** Claude follows the instructions in `SKILL.md` and can run bundled scripts (Python, Node, Bash, etc.).

### **Where Skills Live**
| Location | Path | Scope |
| :--- | :--- | :--- |
| **Personal** | `~/.claude/skills/` | Across all your projects |
| **Project** | `.claude/skills/` | Specific to the repository |
| **Enterprise** | Managed paths | Organization-wide |

### **Creating a Skill (`SKILL.md`)**
The file must include a `name` and a keyword-rich `description` for auto-triggering.

```markdown
---
name: commit-helper
description: Generates commit messages from git diffs. Use when the user asks to commit changes.
allowed-tools: Read, Bash
---

# Instructions
1. Run `git diff --staged`.
2. Generate a summary under 50 characters.
3. Use present tense and explain "why," not "how."
```

### **Advanced Features**
*   **Progressive Disclosure:** Keep `SKILL.md` small (<500 lines) and link to supporting `.md` files or scripts in the same directory to save context tokens.
*   **Bundled Scripts:** Claude can execute scripts in your skill directory without reading their full source code into context.
*   **Allowed Tools:** Restrict Claude to specific tools (e.g., `allowed-tools: Read, Grep`) when the skill is active for security or focus.
*   **Isolated Context:** Use `context: fork` in metadata to run the skill in a separate subagent conversation.
*   **Visibility:** Use `user-invocable: false` to hide a skill from the `/` slash menu while still allowing Claude to find it automatically.

### **Troubleshooting**
*   **Not triggering:** Ensure the `description` includes specific terms the user is likely to say.
*   **Not loading:** Verify the file is exactly named `SKILL.md` and the YAML frontmatter starts on line 1.
*   **Conflicts:** If similar skills conflict, make their descriptions more distinct with specific keywords.