# Claude Config Plugin

A comprehensive Claude Code plugin to generate personalized AI assistant configurations with intelligent environment detection and advanced customization options.

**Version**: 1.4.0

## Installation

```bash
claude plugin install claude-config@frad-dotclaude
```

## Features

- **AI-Driven Environment Detection**: Automatically detects installed languages, tools, and package manager options (Node.js, Python, Rust, Go, Java, Docker, etc.)
- **Deterministic Full Rendering**: Use one renderer script to assemble template, TDD fragments, developer profile, technology stacks, and optional memory section
- **Direct Target Write**: Renderer can write directly to the destination file, run length checks, and create backups before overwrite
- **Emoji Policy Toggle**: Renderer can emit emoji usage policy in generated CLAUDE.md via flag
- **TDD Flexibility**: Choose whether to include mandatory Test-Driven Development requirements via renderer flags
- **Local Best-Practices References**: Load stack constraints from local reference files with zero runtime web search
- **Lean Template**: Focuses on non-obvious constraints and avoids generic knowledge Claude already knows
- **Multi-file Sync**: Sync configurations to GEMINI.md and AGENTS.md with template-priority merge strategy
- **Smart Merging**: Preserves unique user content while maintaining consistency across AI configurations
- **Safe Operations**: Automatic backups before overwriting existing files

## Usage

Run the initialization command:

```bash
/init-config
```

The command guides you through a 10-phase interactive workflow:

1. **Environment Discovery** - Detects installed languages, tools, and package manager options
2. **Developer Profile** - Captures name and email
3. **TDD Preference** - Choose TDD inclusion
3.5. **Memory Management** - Optional memory update instructions
4. **Technology Stack Selection** - Select tools and package managers
5. **Renderer Input Preparation** - Normalize selected stacks into `language:::package_manager`
6. **Style Preference** - Choose emoji usage
7. **Assembly & Generation** - Render and write final configuration through one script
8. **Write Report** - Confirm target write and backup details

For detailed workflow steps, run `/init-config` and follow the interactive prompts.

## Structure

```
claude-config/
├── .claude-plugin/
│   └── plugin.json                  # Plugin manifest
├── skills/
│   └── init-config/
│       └── SKILL.md                 # User-invocable skill workflow
├── assets/
│   ├── claude-template-no-tdd.md   # Base template (TDD added dynamically)
│   ├── claude-template-tdd-core-principle.md  # TDD core principle fragment
│   ├── claude-template-tdd-testing-strategy.md  # TDD testing strategy fragment
│   └── technology-stack-rules.md    # Language -> one enforceable rule line
├── scripts/
│   ├── render-claude-config.sh      # Full CLAUDE.md renderer (template + options)

├── tests/
│   ├── fixtures/                    # Test fixtures
│   └── render-claude-config.test.sh # Renderer integration tests
└── README.md
```

## Configuration


1. **Progressive Workflow**: Each phase builds on previous results
2. **User Control**: Always asks before making significant decisions
3. **Safety**: Always backups existing files before overwriting
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
- Clean Architecture with 4-layer inward dependency rule
- Web search before planning

## Technology Stack

### Node.js
**Package Manager**: pnpm
- Keep server hot paths non-blocking with async I/O, move CPU-heavy work off the event loop, and treat unhandled promise rejections as production failures.

### Go
- Define small interfaces at the point of use, pass `context.Context` as the first parameter for request-scoped work, and return wrapped errors using `%w` with actionable context.
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

### Renderer Direct Write

Run the renderer directly if the interactive skill isn't available or you need scripted generation:

```bash
bash scripts/render-claude-config.sh \
  --target-file "$HOME/.claude/CLAUDE.md" \
  --include-tdd true \
  --include-memory true \
  --use-emojis false \
  --stack "Node.js:::pnpm" \
  --stack "Python:::uv"
```

## Version History

### 1.4.0
- Replaced runtime web search in `/init-config` with local stack reference loading
- Added `assets/technology-stack-rules.md` for enforceable one-line constraints
- Fixed Technology Stack contract: one rule per supported language, package-manager-only fallback for unsupported languages

### 1.3.0
- Lean template: removed generic knowledge Claude already knows (SOLID, DRY, etc.)
- Optional memory management phase for proactive CLAUDE.md updates
- Dropped RFC 2119 keywords for direct imperative style

### 1.0.0
- Added TDD flexibility, web search integration, multi-file sync (GEMINI.md, AGENTS.md), template-priority merge strategy

### 0.1.0
- Initial release with basic template generation

## License

MIT

## Author

Frad LEE (fradser@gmail.com)
