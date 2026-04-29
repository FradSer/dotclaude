# Output Styles Component Reference

Plugins can bundle output styles that adjust Claude's response formatting (terseness, structure, verbosity). Output styles surface in `/output-style` once the plugin is enabled.

## Location

* `output-styles/<name>.md` files in the plugin root, OR
* `"outputStyles"` key in `plugin.json` pointing at a custom file or directory

A custom `outputStyles` value **replaces** the default `output-styles/` directory.

## Format

Markdown file with frontmatter:

```markdown
---
name: terse
description: Short, direct answers. Skip explanations unless asked.
---

Answer in the fewest words that convey the result. Skip preambles like
"Sure, I'll" — go straight to the answer or the diff.

Use bullet lists only when there are 3+ peer items. Otherwise prose.
```

## Required frontmatter fields

| Field         | Description                                                       |
| :------------ | :---------------------------------------------------------------- |
| `name`        | Identifier shown in `/output-style`. Kebab-case recommended.      |
| `description` | One-line summary of the style.                                    |

## Best practices

* **Behavioral, not aesthetic**: focus the body on *what to say and when*, not on color/formatting markup
* **Layer with skills**: output styles modulate Claude's response shape; skills carry domain knowledge. Don't duplicate skill content in a style.
* **Composability**: assume the user may switch styles mid-session — keep instructions self-contained
