# shadcn/ui Plugin

A Claude Code plugin for managing shadcn components and projects — adding, searching, fixing, debugging, styling, and composing UI.

## Features

- **Component Management**: Add, update, and remove shadcn/ui components
- **Project Context**: Automatically detects project configuration (framework, aliases, Tailwind version)
- **Critical Rules**: Enforces best practices for styling, forms, composition, and icons
- **CLI Integration**: Full reference for shadcn CLI commands and flags
- **Theming**: Customization via CSS variables and semantic tokens
- **MCP Server**: AI-assisted component search and installation

## Usage

This skill triggers automatically when working with:
- shadcn/ui projects
- Component registries (`@shadcn`, `@magicui`, etc.)
- Preset codes (`base-nova`, `radix-nova`, or base62 codes like `a2r6bw`)
- Projects with `components.json`

### Common Commands

```bash
# Initialize a new project
npx shadcn@latest init --preset base-nova

# Add components
npx shadcn@latest add button card dialog

# Search registries
npx shadcn@latest search @shadcn -q "sidebar"

# Get component docs
npx shadcn@latest docs button dialog

# Preview changes before adding
npx shadcn@latest add button --dry-run
npx shadcn@latest add button --diff button.tsx
```

## Project Context

When triggered, the skill automatically runs `npx shadcn@latest info --json` to get:
- Framework (Next.js, Vite, etc.)
- Tailwind version (v3 or v4)
- Component library (radix or base)
- Icon library (lucide, tabler, etc.)
- Import aliases (@/, ~/)
- Installed components

## Critical Rules

The skill enforces these rules with Incorrect/Correct code pairs:

| Category | Rule |
|----------|------|
| Styling | Use `className` for layout, not colors |
| Spacing | Use `gap-*` instead of `space-y-*` |
| Forms | Use `FieldGroup` + `Field` components |
| Icons | Use `data-icon` attribute, no sizing classes |
| Overlays | No manual `z-index` on Dialog/Sheet/Drawer |
| Composition | Items inside Group components |

See [rules/](skills/shadcn/rules/) for detailed references.

## File Structure

```
shadcn/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   └── shadcn/
│       ├── SKILL.md           # Main skill (triggers on shadcn)
│       ├── cli.md             # CLI command reference
│       ├── customization.md   # Theming guide
│       ├── mcp.md             # MCP server setup
│       ├── rules/
│       │   ├── styling.md
│       │   ├── forms.md
│       │   ├── composition.md
│       │   ├── icons.md
│       │   └── base-vs-radix.md
│       └── evals/
│           └── evals.json     # Test cases
└── README.md
```

## Requirements

- Node.js project with shadcn/ui initialized
- `components.json` file in project root

## License

MIT
