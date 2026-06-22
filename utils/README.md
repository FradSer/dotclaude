# Utils Plugin

**Version**: 0.2.1

General-purpose utility skills for documentation, writing, and project maintenance.

## Installation

```bash
claude plugin install utils@frad-dotclaude
```

## Skills

### `/utils:update-readme`

Synchronizes `README.md` and `README.zh-CN.md` with the current marketplace state. Regenerates plugin listings from `.claude-plugin/marketplace.json` and individual `plugin.json` files.

**When to use:**
- After adding, removing, or renaming a plugin
- After bumping plugin versions
- After changing plugin descriptions

### `/utils:update-changelog`

Generates and maintains a `CHANGELOG.md` following the [Keep a Changelog](https://keepachangelog.com/) format. Parses conventional commit history to produce categorized entries.

**When to use:**
- Before a release to generate changelog entries
- To keep an up-to-date record of changes

## License

MIT

## Author

Frad LEE (fradser@gmail.com)
