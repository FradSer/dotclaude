# Skills Component Reference

Plugins can provide Agent Skills that extend Claude's capabilities. Skills are model-invoked—Claude autonomously decides when to use them based on the task context.

**Location**: `skills/` directory in plugin root

**File format**: Directories containing `SKILL.md` files with frontmatter

## Skill structure

```
skills/
├── pdf-processor/
│   ├── SKILL.md
│   ├── reference.md (optional)
│   └── scripts/ (optional)
└── code-reviewer/
    └── SKILL.md
```

## Integration behavior

* Plugin Skills are automatically discovered when the plugin is installed
* Claude autonomously invokes Skills based on matching task context
* Skills can include supporting files alongside SKILL.md

## Best Practices

### Must Do
- **Use Imperative Style**: Write SKILL.md bodies using verb-first instructions ("Parse the file...", "Validate the input...") rather than "You should...".
- **Third-Person Descriptions**: Write frontmatter descriptions in the third person ("This skill should be used when...").
- **Structure Correctly**: Place the `SKILL.md` file inside a subdirectory (e.g., `skills/my-skill/SKILL.md`).
- **Script Executability**: If a skill includes scripts, ensure they are executable (`chmod +x`), have shebang lines, and use `${CLAUDE_PLUGIN_ROOT}` in paths

### Should Do
- **Keep Lean**: Keep SKILL.md lean (1,500-2,000 words). Move detailed docs to `references/` to save context window.
- **Configuration**: Use `user-invocable: false` for agent-only skills and `context: fork` for complex analysis to isolate context.

### Avoid
- **Monolithic Files**: Don't dump 5000+ words into `SKILL.md`. It bloats the context window.
- **Duplication**: Do not repeat information between `SKILL.md` and reference files.
