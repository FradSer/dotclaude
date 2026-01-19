---
description: Generate Chinese patent application forms from technical ideas
argument-hint: "INVENTION_IDEA"
---

## Your Task

1. **Load the `patent-architect` skill** using the `Skill` tool to access patent drafting capabilities, templates, and reference materials.
2. **Understand the Invention**: Analyze the user's input to extract the technical field, technical problem, technical solution, and technical effects.
3. **Prior Art Search (Mandatory)**: Execute the search procedures defined in the skill (using `${CLAUDE_PLUGIN_ROOT}/office/scripts/search-patents.sh` or API calls) to ensure novelty.
4. **Draft Application Form**: Generate the patent application following the structure in `template.md` and using the terminology in `reference.md` (loaded via the skill).
5. **Save Output**: Write the final patent application to `docs/YYYY-MM-DD-ShortName.md` (create the directory if needed).
