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

The command will guide you through an 8-phase workflow:

### Phase 1: Environment Discovery
Automatically detects your installed tools and languages without asking basic questions.

### Phase 2: TDD Preference
Choose whether to include Test-Driven Development requirements:
- **Include TDD**: Adds mandatory RED → GREEN → REFACTOR workflow
- **Exclude TDD**: Generates configuration without TDD requirements

### Phase 3: Technology Stack Selection
Select which technology stacks to include (multi-select):
- Discovered tools are marked as "Recommended"
- AI automatically generates configurations for all selected technologies

### Phase 4: Best Practices Research
Optionally enable web search to find latest best practices:
- **Search and append**: Searches for "2026 best practices" and adds 2-3 sentence summaries
- **Skip search**: Uses only base template

### Phase 5: Assembly & Generation
Assembles the final configuration from:
- Base template (with or without TDD)
- AI-generated technology stack sections
- Web search summaries (if enabled)

### Phase 6: Length Validation
Validates that the generated configuration meets best practices:
- **Optimal**: 1,500-3,000 words
- **Too Long**: Offers auto-trim or manual review options
- **Too Short**: Shows info message but proceeds

### Phase 7: Multi-file Sync
Choose which additional AI configuration files to sync:
- **GEMINI.md**: Google Gemini configuration
- **AGENTS.md**: General agents configuration
- Uses template-priority merge: keeps unique sections from existing files

### Phase 8: Write CLAUDE.md
Writes the final configuration with comprehensive success report.

## Structure

```
claude-config/
├── .claude-plugin/
│   └── plugin.json           # Plugin manifest
├── commands/
│   └── init-config.md        # Main command with 8-phase workflow
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

This plugin is provided as-is for use with Claude Code.
