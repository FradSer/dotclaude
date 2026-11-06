# Office Plugin

Office productivity skills for patent applications, PRD generation, video generation, Remotion programmatic video authoring, and AI writing trope detection.

**Version**: 0.7.4
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
export ARK_API_KEY="your_ark_key"        # generate-video
# Add to ~/.zshrc or ~/.bashrc for persistence
source ~/.zshrc
```

Get your API keys:
- **SERPAPI_KEY**: Sign up at [serpapi.com](https://serpapi.com)
- **EXA_API_KEY**: Get from [dashboard.exa.ai](https://dashboard.exa.ai)
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

### `/office:patent-architect` (Slash-Invocable Skill)

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

### `/office:create-prd` (Slash-Invocable Skill)

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

### `/office:generate-video` (Slash-Invocable Skill)

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

### `/office:remotion` (Slash-Invocable Skill)

Programmatic video creation in React with Remotion. This skill is a router: it reads the matching sub-skill entry file `<name>/<name>.md` based on user intent before executing (there is no sub-skill `SKILL.md` — the sync denests them). The sub-skills are upstream content kept verbatim (re-sync from upstream rather than editing them).

**Usage:**
```bash
/office:remotion
```

**Sub-skills** (loaded through the router, not standalone slash commands):

| Sub-skill | Use When |
|-----------|----------|
| `remotion-create` | Scaffold a new Remotion project (`npx create-video`), design a video, start the Studio preview |
| `remotion-markup` | Writing Remotion React markup — animations, media, sequences, timing, fonts, effects, maps, Lottie, DOM measurement, transitions, trimming |
| `remotion-render` | Rendering videos and stills (`npx remotion render/still`), transparent videos |
| `remotion-captions` | Transcribing, importing SRT, and displaying captions/subtitles |
| `remotion-interactivity` | Making animations editable in Remotion Studio Visual Mode |
| `remotion-saas` | Building video apps — `<Player>`, rendering on Lambda/Vercel/Cloudflare/Node, client-side rendering, choosing a framework |
| `mediabunny` | Multimedia handling in the browser — get audio/video duration, get video dimensions |

**Prerequisites:** Node.js and `npx` (Remotion tooling).

### `tropes` (Internal Skill)

Automatically-applied domain knowledge (`user-invocable: false`) — not a slash command. AI writing trope detection scans generated text for common AI patterns that make content sound artificial or formulaic.

**Source**: [tropes.fyi](https://tropes.fyi) by [ossama.is](https://ossama.is)

**References:**
- `references/professional-balance.md` — balancing formal and casual tone
- `references/sentence-structure.md` — avoiding repetitive sentence patterns
- `references/tone.md` — maintaining natural, varied tone
- `references/word-choice.md` — eliminating formulaic word patterns

**Usage**: Automatically loaded when generating text content, documentation, code comments, or reviewing writing style.

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

## Architecture

```
office/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata (displayName: Office)
├── lib/
│   ├── utils.sh             # Shared shell utilities
│   └── progressive_env.py   # Progressive config resolver (flag → env → .env → default)
├── scripts/
│   └── search-patents.sh      # Patent search helper
└── skills/
    ├── patent-architect/      # Patent application generation (slash-invocable skill)
    │   ├── SKILL.md
    │   ├── template.md
    │   ├── reference.md
    │   └── examples.md
    ├── create-prd/            # PRD generation (slash-invocable skill)
    │   └── SKILL.md
    ├── generate-video/        # Video generation (slash-invocable skill, Seedance / Ark)
    │   ├── SKILL.md
    │   ├── scripts/generate_video.py
    │   └── references/prompting.md
    ├── remotion/              # Programmatic video: router + 7 sub-skills (slash-invocable skill)
    │   ├── SKILL.md           # Router / sub-skill index
    │   ├── remotion-create/   # New Project
    │   ├── remotion-markup/   # React Markup
    │   ├── remotion-render/   # Rendering
    │   ├── remotion-captions/ # Captions
    │   ├── remotion-interactivity/ # Interactivity
    │   ├── remotion-saas/     # SaaS / Apps
    │   └── mediabunny/        # Mediabunny
    └── tropes/                # AI writing trope detection (internal, auto-applied)
        ├── SKILL.md
        └── references/
            ├── professional-balance.md
            ├── sentence-structure.md
            ├── tone.md
            └── word-choice.md
```

## Troubleshooting

### Search Returns No Results

**Solutions**:
- Try different keyword combinations
- Use both technical terms and natural language
- Switch between `--engine serpapi` and `--engine exa`

## Author

Frad LEE (fradser@gmail.com)

## License

MIT
