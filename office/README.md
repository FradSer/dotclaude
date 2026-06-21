# Office Plugin

Office productivity skills for patent applications, PRD generation, Feishu document creation, browser automation, Lark/Feishu CLI operations, and AI writing trope detection.

**Version**: 0.4.4
**Display Name**: Office

## Installation

```bash
claude plugin install office@frad-dotclaude
```

## Quick Start

### 1. Setup API Keys

```bash
export SERPAPI_KEY="your_serpapi_key"   # patent-architect
export EXA_API_KEY="your_exa_api_key"    # patent-architect
export GEMINI_API_KEY="your_gemini_key"  # generate-image
export ARK_API_KEY="your_ark_key"        # generate-video
# Add to ~/.zshrc or ~/.bashrc for persistence
source ~/.zshrc
```

Get your API keys:
- **SERPAPI_KEY**: Sign up at [serpapi.com](https://serpapi.com)
- **EXA_API_KEY**: Get from [dashboard.exa.ai](https://dashboard.exa.ai)
- **GEMINI_API_KEY**: Get from [aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)
- **ARK_API_KEY**: Get from [console.volcengine.com/ark](https://console.volcengine.com/ark)

Each generation skill resolves its key progressively — a shell `export`, a `.env` file, or a
`--api-key` flag all work, so only the skills you actually use need a key set.

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

### `/office:generate-image` (Command)

Generate or edit images from a text prompt using Google's `gemini-3-pro-image` model.

**Usage:**
```bash
/office:generate-image "RayNeo AR glasses product hero shot" -o hero.png --aspect-ratio 16:9 --size 2K
/office:generate-image "swap the sky to a sunset, keep everything else" -i street.png -o street_sunset.png
```

**Features:**
- Text-to-image and image editing/composition (one or more `-i` reference images)
- Aspect ratio (`1:1` … `21:9`), resolution tier (`1K`/`2K`/`4K`), multiple candidates
- Progressive configuration — key/model resolved via flag → env → `.env` → default

**Prerequisites:** `uv`, and `GEMINI_API_KEY` ([aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)).

### `/office:generate-video` (Command)

Generate short videos from text or stills using ByteDance Seedance on Volcengine Ark (火山方舟).

**Usage:**
```bash
/office:generate-video "drone shot rising over a misty forest at sunrise" --resolution 1080p --duration 5
/office:generate-video "gently animate this panel, keep the line-art style" --first-frame panel.png -o panel.mp4
```

**Features:**
- Text-to-video, image-to-video (first frame), and first→last-frame morph
- Ratio / duration / resolution control; watermark off by default
- Async submit + poll + download, handled by the script
- Progressive configuration — key/model/base-URL resolved via flag → env → `.env` → default
  (switch model version with `SEEDANCE_MODEL`, region with `ARK_BASE_URL`, no code change)

**Prerequisites:** `uv`, and `ARK_API_KEY` ([console.volcengine.com/ark](https://console.volcengine.com/ark)).

### `agent-browser` (Reference Skill)

Browser automation command reference for agents and workflows.

**Source**: Synced from [browser-use/agent-browser](https://github.com/browser-use/agent-browser)

**Purpose**: Provides browser automation command reference for agents that need to interact with web pages.

**Sync**: Use `./scripts/sync-agent-browser.sh` to update from upstream

### `lark` (Internal Skill)

Lark/Feishu CLI skills for operating Lark workspace resources via `lark-cli`. Covers docs, markdown, sheets, base, calendar, IM, mail, tasks, OKR, drive, wiki, slides, whiteboard, apps, approval, attendance, contact, VC, minutes, and events.

**Source**: Synced from [larksuite/cli](https://github.com/larksuite/cli) skills/

**Sub-skills**: 27 specialized sub-skills covering the full Lark/Feishu API surface. See `skills/lark/SKILL.md` for the complete index.

**Sync**: Use `./scripts/sync-lark.sh` to update from upstream. `SYNC.md` tracks the current `lark-cli` version.

### `tropes` (Internal Skill)

AI writing trope detection — scans generated text for common AI patterns that make content sound artificial or formulaic.

**Source**: [tropes.fyi](https://tropes.fyi) by [ossama.is](https://ossama.is)

**References:**
- `references/professional-balance.md` — balancing formal and casual tone
- `references/sentence-structure.md` — avoiding repetitive sentence patterns
- `references/tone.md` — maintaining natural, varied tone
- `references/word-choice.md` — eliminating formulaic word patterns

**Usage**: Automatically loaded when generating text content, documentation, code comments, or reviewing writing style.

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

### `scripts/sync-lark.sh`

同步上游 larksuite/cli skills 的脚本。

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
│   └── plugin.json          # Plugin metadata (displayName: Office)
├── hooks/
│   ├── hooks.json           # Hook configuration
│   └── scripts/
│       └── check-keys.sh    # API key validation
├── lib/
│   ├── utils.sh             # Shared shell utilities
│   └── progressive_env.py   # Progressive config resolver (flag → env → .env → default)
├── scripts/
│   ├── search-patents.sh      # Patent search helper
│   ├── sync-agent-browser.sh  # Agent-browser skill sync
│   └── sync-lark.sh           # Lark CLI skills sync
└── skills/
    ├── patent-architect/      # Patent application generation (command)
    │   ├── SKILL.md
    │   ├── template.md
    │   ├── reference.md
    │   └── examples.md
    ├── create-prd/            # PRD generation (command)
    │   └── SKILL.md
    ├── generate-image/        # Image generation (command, gemini-3-pro-image)
    │   ├── SKILL.md
    │   ├── scripts/generate_image.py
    │   └── references/prompting.md
    ├── generate-video/        # Video generation (command, Seedance / Ark)
    │   ├── SKILL.md
    │   ├── scripts/generate_video.py
    │   └── references/prompting.md
    ├── agent-browser/         # Browser automation (internal)
    │   └── SKILL.md
    ├── lark/                  # Lark/Feishu CLI operations (internal)
    │   ├── SKILL.md           # Router for 27 sub-skills
    │   ├── lark-shared/       # Auth, identity, permissions
    │   ├── lark-doc/          # Documents
    │   ├── lark-sheets/       # Spreadsheets
    │   ├── lark-base/         # Multidimensional tables
    │   ├── lark-calendar/     # Calendar & meetings
    │   ├── lark-im/           # Instant messaging
    │   ├── lark-mail/         # Email
    │   ├── lark-task/         # Tasks & reminders
    │   ├── lark-okr/          # OKR management
    │   ├── lark-drive/        # File management
    │   └── ...                # 16 more sub-skills
    └── tropes/                # AI writing trope detection (internal)
        ├── SKILL.md
        └── references/
            ├── professional-balance.md
            ├── sentence-structure.md
            ├── tone.md
            └── word-choice.md
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

## License

MIT
