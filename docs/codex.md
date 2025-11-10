# Copilot / Codex Integration Guide

## Generated Assets

`pnpm build:prompts` outputs Markdown prompts ready for GitHub Copilot Chat and Copilot Workspace under `dist/codex/prompts/<plugin>-<slug>.md`.

## Usage Patterns

- **Reference Library**: Keep the prompts alongside your codebase and paste relevant sections into Copilot Chat when guidance is needed.
- **VS Code Snippets**: Convert a prompt into a keybinding by creating a snippet file that expands to the Markdown instructions.
- **Workspace Docs**: Check the files into a docs folder inside the repo to give Copilot additional context during conversations.

## Recommended Workflow

1. Open the desired prompt file (e.g. `dist/codex/prompts/review-hierarchical.md`).
2. Copy the sections that apply to your current review or refactor.
3. Paste into Copilot Chat, optionally appending repo-specific context or file references.
4. Iterate with Copilot; update the canonical YAML under `prompts/<plugin>/commands/` if the workflow evolves.

## Tips

- Prompts include summary and tool expectations up top to help Copilot stay aligned.
- Keep the Markdown lightweight—Copilot performs better with concise, well-structured instructions.
- For heavily customised workflows, consider duplicating the generated prompt and paraphrasing in your own words for clarity.
