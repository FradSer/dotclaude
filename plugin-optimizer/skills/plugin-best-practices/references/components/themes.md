# Themes Component Reference

Plugins can ship color themes that appear in `/theme` alongside the built-in presets and the user's local themes.

## Location

* `themes/<name>.json` files in the plugin root, OR
* `"themes"` key in `plugin.json` pointing at a custom file or directory

A custom `themes` value **replaces** the default `themes/` directory.

## Format

A theme is a JSON object with a `base` preset and a sparse `overrides` map of color tokens:

```json
{
  "name": "Dracula",
  "base": "dark",
  "overrides": {
    "claude": "#bd93f9",
    "error": "#ff5555",
    "success": "#50fa7b"
  }
}
```

## Required fields

| Field       | Description                                                  |
| :---------- | :----------------------------------------------------------- |
| `name`      | Display name shown in `/theme`.                              |
| `base`      | Base preset to inherit from (e.g. `"dark"`, `"light"`).      |
| `overrides` | Sparse map of color tokens to override.                      |

## Behavior

* Selecting a plugin theme persists `custom:<plugin-name>:<slug>` in the user's config
* Plugin themes are read-only — pressing `Ctrl+E` on one in `/theme` copies it to `~/.claude/themes/` so the user can edit the copy
* Multiple themes per plugin are supported; ship one JSON file per theme

## Best practices

* **Spare overrides**: only set tokens that diverge from the base preset. Sparse overrides keep themes readable and let upstream base updates flow through.
* **Sensible base**: pick `dark` or `light` so contrast stays correct when the user's terminal background changes.
* **Distinct names**: prefix theme `name` with the plugin's domain when the plugin ships multiple themes (e.g. `"Foo Vibrant"`, `"Foo Pastel"`) so they sort together in `/theme`.
