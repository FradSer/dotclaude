# Claude Config Plugin

A comprehensive Claude Code plugin to generate personalized AI assistant configurations with intelligent environment detection and advanced customization options.

## Features

- **AI-Driven Environment Detection**: Automatically detects installed languages and tools (Node.js, Python, Rust, Go, Java, Docker, etc.)
- **TDD Flexibility**: Choose whether to include mandatory Test-Driven Development requirements
- **Best Practices Research**: Optionally search for latest 2026 best practices and append summaries to your configuration
- **Length Validation**: Ensures generated configuration meets optimal word count (1,500-3,000 words) for context efficiency
- **Multi-file Sync**: Sync configurations to GEMINI.md and AGENTS.md with template-priority merge strategy
- **Smart Merging**: Preserves unique user content while maintaining consistency across AI configurations
- **Safe Operations**: Automatic backups before overwriting existing files

## Installation

1. Copy this plugin to your Claude plugins directory:
   ```bash
   cp -r claude-config ~/.claude/plugins/
   ```

2. Or use it locally with the `--plugin-dir` flag:
   ```bash
   claude --plugin-dir /path/to/claude-config
   ```

## Usage

Run the initialization command:

```bash
/init-config
```

The command guides you through a 10-phase interactive workflow:

1. **Environment Discovery** - Detects installed languages and tools
2. **Developer Profile** - Captures name and email
3. **TDD Preference** - Choose TDD inclusion
4. **Technology Stack Selection** - Select tools and package managers
5. **Best Practices Research** - Optional web search for 2026 best practices
6. **Style Preference** - Choose emoji usage
7. **Assembly & Generation** - Build final configuration
8. **Length Validation** - Ensure optimal word count (1,500-3,000 words)
9. **Multi-file Sync** - Optionally sync to GEMINI.md/AGENTS.md
10. **Write CLAUDE.md** - Save with comprehensive report

For detailed workflow steps, run `/init-config` and follow the interactive prompts.

## Structure

```
claude-config/
├── .claude-plugin/
│   └── plugin.json           # Plugin manifest
├── commands/
│   └── init-config.md        # Main command with 10-phase workflow
├── assets/
│   ├── claude-template.md    # Base template with TDD
│   └── claude-template-no-tdd.md  # Base template without TDD
├── scripts/
│   └── validate-length.sh    # Length validation utility
└── README.md
```

## Configuration

### Length Validation Ranges

The validation script uses these thresholds:
- **Minimum**: 800 words
- **Optimal Range**: 1,500-3,000 words
- **Maximum**: 5,000 words

## Best Practices

1. **Progressive Workflow**: Each phase builds on previous results
2. **User Control**: Always asks before making significant decisions
3. **Validation**: Checks length before writing to ensure quality
4. **Safety**: Always backups existing files before overwriting
5. **Template-Priority Merge**: Maintains consistency while preserving unique content

## Examples

### Generated CLAUDE.md Structure

```markdown
# Claude Development Guidelines

## Developer Profile
- **Name**: Frad LEE
- **Email**: fradlee@qq.com

## Core Principles
[TDD requirements if enabled]
- MANDATORY Clean Architecture
- Research-driven workflow

## Documentation Standards
...

## Technology Stack

### Node.js (pnpm)
[AI-generated configuration]

#### Latest Best Practices (2026)
[Web search summary if enabled]

### Python (uv)
[AI-generated configuration]

#### Latest Best Practices (2026)
[Web search summary if enabled]
```

### Template-Priority Merge Example

**Existing GEMINI.md**:
```markdown
## My Custom Section
Custom content here

## My Unique Workflow
User-specific workflow
```

**Result after sync**:
- CLAUDE.md content (base + tech stacks)
- `## My Custom Section` (preserved from GEMINI.md)
- `## My Unique Workflow` (preserved from GEMINI.md)

## Troubleshooting

### Configuration Too Long
If you get a "TOO_LONG" warning:
1. Choose "Auto-trim" to remove web search summaries first
2. Or choose "Manual review" to select specific sections to remove

### Validation Script Fails
Ensure the script is executable:
```bash
chmod +x scripts/validate-length.sh
```

## Version History

### 1.1.1
- Added keywords for better plugin discoverability
- Optimized README structure to reduce redundancy
- Improved documentation clarity

### 1.1.0
- Enhanced multi-file sync capabilities

### 1.0.0
- Added TDD flexibility (include/exclude option)
- Added web search integration for latest best practices
- Added length validation with auto-trim options
- Added multi-file sync (GEMINI.md, AGENTS.md)
- Added template-priority merge strategy
- Enhanced environment detection
- Improved backup safety

### 0.1.0
- Initial release with basic template generation

## License

MIT License - see [LICENSE](LICENSE) file for details.
