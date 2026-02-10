# Office Plugin

Specialized Claude Skill for patent application generation and intellectual property workflows.

## Installation

```bash
claude plugin install office@frad-dotclaude
```

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

### 2. Use the Patent Architect Skill

```bash
/patent-architect "Mobile Payment Authentication System"
```

The skill will:
1. Understand your technical invention
2. Search for prior art automatically
3. Generate a complete Chinese patent application form

## Skills

### `/office:patent-architect` (Command)

Generate Chinese patent application forms (专利申请表) from technical ideas.

**Usage:**
```bash
/office:patent-architect "INVENTION_DESCRIPTION"
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

### `/office:create-feishu-doc` (Command)

Automate the process of creating new documents in Feishu (Lark) workspace using browser automation.

**Usage:**
```bash
/office:create-feishu-doc
```

**Features:**
- Browser automation for Feishu UI navigation
- Auto-creation of blank documents
- Title and content entry
- Supports multiple Feishu workspaces

**Prerequisites:**
- Access to Feishu workspace
- Browser automation capability via agent-browser

### `/office:create-prd` (Command)

Generate comprehensive Chinese Product Requirements Documents (PRD) following 2026 best practices.

**Usage:**
```bash
/office:create-prd
```

**Features:**
- Two PRD types: full version and brief version
- Interactive information collection via AskUserQuestion
- SMART goal validation
- Data-driven problem statements
- Professional Chinese PRD generation

**Prerequisites:**
- None (interactive workflow)

### `agent-browser` (Reference Skill)

Browser automation command reference for agents and workflows.

**Source**: Synced from [browser-use/agent-browser](https://github.com/browser-use/agent-browser)

**Purpose**: Provides browser automation command reference for agents that need to interact with web pages.

**Sync**: Use `./scripts/sync-agent-browser.sh` to update from upstream

## Scripts

### `scripts/sync-agent-browser.sh`

同步上游 agent-browser skill 的脚本。

**Usage:**
```bash
# 检查是否有更新
./scripts/sync-agent-browser.sh --check

# 执行同步(会提示确认)
./scripts/sync-agent-browser.sh

# 强制同步,跳过确认
./scripts/sync-agent-browser.sh --force

# 同步但不创建备份
./scripts/sync-agent-browser.sh --no-backup
```

**Options:**
- `-h, --help` - 显示帮助信息
- `-c, --check` - 仅检查更新,不执行同步
- `-f, --force` - 强制同步,跳过备份
- `--no-backup` - 同步时不创建备份

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

## Architecture

```
office/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata
├── hooks/
│   ├── hooks.json           # Hook configuration
│   └── scripts/
│       └── check-keys.sh    # API key validation
├── lib/
│   └── utils.sh             # Shared utilities
├── scripts/
│   ├── search-patents.sh      # Patent search helper
│   └── sync-agent-browser.sh  # Agent-browser skill sync
└── skills/
    ├── patent-architect/      # Patent application generation skill
    │   ├── SKILL.md           # Skill definition
    │   ├── template.md        # Output template
    │   ├── reference.md       # API reference
    │   └── examples.md        # Usage examples
    └── agent-browser/         # Browser automation skill
        └── SKILL.md           # Skill definition
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
