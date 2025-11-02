# Gemini Code Assist Integration Guide

## Generated Assets

After running `pnpm build:prompts`:

- Command TOML files land in `dist/gemini/commands/<namespace>/<filename>.toml`.

## Installation

1. Copy TOML files into your Gemini commands directory, e.g. `cp dist/gemini/commands/review/*.toml ~/.gemini/commands/review/`.
2. Restart Gemini Code Assist (or reload the extension) so it picks up new commands.
3. Use the Gemini palette to trigger the command by description (e.g. "Hierarchical Review").

## Customisation

- Update the `namespace` and `filename` fields in `prompts/<plugin>/commands/` to change the command folder or name.
- The generator removes Claude-specific `!\`` syntax and preserves Markdown headings for readability inside Gemini.
- Edit the generated Markdown docs to capture team-specific notes, then link them from Gemini conversations.

## Troubleshooting

- If Gemini fails to parse the TOML, ensure the file remains wrapped in triple quotes and does not exceed the prompt length noted in `config/platforms/gemini.yaml`.
- Delete stale files from `~/.gemini/commands` to avoid duplicate entries in the palette.
