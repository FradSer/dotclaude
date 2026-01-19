# Office Plugin

Specialized Claude Skill for patent application generation and intellectual property workflows.

## Quick Start

### 1. Setup API Keys

```bash
export SERPAPI_KEY="your_serpapi_key"
export EXA_API_KEY="your_exa_api_key"
# Add to ~/.zshrc or ~/.bashrc for persistence
source ~/.zshrc
```

Get your API keys:
- **SERPAPI_KEY**: Sign up at [serpapi.com](https://serpapi.com)
- **EXA_API_KEY**: Get from [dashboard.exa.ai](https://dashboard.exa.ai)

### 2. Use the Patent Architect Command

```bash
/patent-architect "Mobile Payment Authentication System"
```

The command will:
1. Understand your technical invention
2. Search for prior art automatically
3. Generate a complete Chinese patent application form

## Commands

### `/patent-architect`

Generate Chinese patent application forms (专利申请表) from technical ideas.

**Usage:**
```bash
/patent-architect "INVENTION_DESCRIPTION"
```

**Workflow:**
```
用户输入技术想法 → 专利检索 (SerpAPI/Exa.ai) → 对比分析 → 生成申请表
```

**Features:**
- Dual search strategy (SerpAPI + Exa.ai)
- Automatic prior art search
- Chinese patent application form generation
- Patent terminology compliance
- Multiple embodiment generation (3+)

## Scripts

### `scripts/search-patents.sh`

Helper script for patent search with argument parsing.

**Usage:**
```bash
# SerpAPI search (default)
./scripts/search-patents.sh mobile payment authentication

# Exa.ai semantic search
./scripts/search-patents.sh "biometric verification" --engine exa --num 5

# Show help
./scripts/search-patents.sh --help
```

**Options:**
- `--engine <serpapi|exa>` - Search engine to use (default: serpapi)
- `--num <n>` - Number of results (default: 10)
- `-h, --help` - Show help message

## Requirements

### API Keys

| Key | Description | Get from |
|-----|-------------|----------|
| SERPAPI_KEY | Google Patents search | [serpapi.com](https://serpapi.com) |
| EXA_API_KEY | Semantic patent search | [dashboard.exa.ai](https://dashboard.exa.ai) |

## Architecture

```
office/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata
├── commands/
│   └── patent-architect.md  # Main command
├── hooks/
│   ├── hooks.json           # Hook configuration
│   └── scripts/
│       └── check-keys.sh    # API key validation
├── lib/
│   └── utils.sh             # Shared utilities
├── scripts/
│   └── search-patents.sh    # Patent search helper
└── skills/
    └── patent-architect/
        ├── SKILL.md         # Skill definition
        ├── template.md      # Output template
        ├── reference.md     # API reference
        └── examples.md      # Usage examples
```

## Troubleshooting

### API Keys Not Set

**Symptoms**: Error message "Missing API Keys for Office Plugin"

**Solution**:
```bash
export SERPAPI_KEY="your_key_here"
export EXA_API_KEY="your_key_here"
source ~/.zshrc
```

### Search Returns No Results

**Solutions**:
- Try different keyword combinations
- Use both technical terms and natural language
- Switch between `--engine serpapi` and `--engine exa`

## Author

Frad LEE (fradser@gmail.com)
