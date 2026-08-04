---
description: Bump plugin version in plugin.json and marketplace.json
argument-hint: <plugin-name> [new-version]
allowed-tools: ["Read", "Edit", "Bash(python3:*)"]
---

Atomically update `<plugin-name>/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` to the same version.

**Arguments:** `$ARGUMENTS` — `[plugin-name] [new-version]`
- no arguments: auto-increment patch for **all** plugins
- `plugin-name` only: auto-increment patch for that plugin
- `plugin-name new-version`: set explicit version for that plugin

## Steps

### No arguments — update only plugins with changes

1. Read `.claude-plugin/marketplace.json` to get the full plugin list (all `"name"` entries).

2. For each plugin, determine whether it has updates since its last release:
   - `V` = version in `<PLUGIN>/.claude-plugin/plugin.json` at HEAD
   - Walk `git log --format=%H HEAD -- <PLUGIN>/.claude-plugin/plugin.json` newest→oldest. The era of `V` starts at the first commit whose version != `V`; if every commit has version == `V`, the era starts at the plugin's creation commit (the oldest commit in the walk).
   - Has updates iff `git diff --name-only <era-start>..HEAD -- <PLUGIN>/` shows any changed file other than `<PLUGIN>/.claude-plugin/plugin.json` — uncommitted working-tree changes (`git diff --name-only HEAD -- <PLUGIN>/`) count too.

3. Bump patch only for plugins with updates (run the single-plugin flow for each); skip plugins without updates.

4. Report: `plugin: old → new` for every updated plugin, and `plugin: unchanged (skipped)` for every skipped one.

### Single plugin

1. Parse `$ARGUMENTS` to extract `PLUGIN` and optional `VERSION`.

2. Read current version from `<PLUGIN>/.claude-plugin/plugin.json`:
   ```
   python3 -c "import json; d=json.load(open('<PLUGIN>/.claude-plugin/plugin.json')); print(d['version'])"
   ```

3. If `VERSION` not provided, compute patch increment:
   ```
   python3 -c "v='<current>'.split('.'); v[2]=str(int(v[2])+1); print('.'.join(v))"
   ```

4. Edit `<PLUGIN>/.claude-plugin/plugin.json` — replace `"version": "<current>"` with `"version": "<new>"`.

5. Edit `.claude-plugin/marketplace.json` — find the entry where `"name": "<PLUGIN>"` and replace its `"version"` using the surrounding `"name"` line as context to target the correct entry.

6. Report: `<PLUGIN>: <current> → <new>` confirmed in both files.
