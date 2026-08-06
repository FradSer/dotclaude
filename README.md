# Frad's Claude Code Plugins ![](https://img.shields.io/badge/plugins-20-blue)

[![MIT License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-v0.6+-purple)](https://claude.ai/code)

**English** | [简体中文](README.zh-CN.md)

A curated collection of 20 plugins for Claude Code, providing specialized agents, skills, and automation tools for development and productivity workflows.

## Available Plugins

### [git](git/)

Conventional Git automation for commits and repository management with AI code quality checks, plus GitFlow workflow automation for feature, hotfix, and release branches with semantic versioning and post-finish cleanup.

**Installation:**
```bash
claude plugin install git@frad-dotclaude
```

---

### [github](github/)

GitHub project operations with quality gates, TDD workflows, comprehensive validation, and persistent PR review monitoring (/github:review-pr watches CI and triages reviewer comments).

**Installation:**
```bash
claude plugin install github@frad-dotclaude
```

---

### [superdev](superdev/)

BDD-first engineering skills forked from mattpocock/skills v1.2.0, with a self-improving checklist subsystem.

**Installation:**
```bash
claude plugin install superdev@frad-dotclaude
```

---

### [superpowers](superpowers/)

Advanced development workflow orchestration with BDD support and self-improving skills.

**Installation:**
```bash
claude plugin install superpowers@frad-dotclaude
```

---

### [refactor](refactor/)

Code simplification and refactoring with language-specific patterns and cross-file optimization.

**Installation:**
```bash
claude plugin install refactor@frad-dotclaude
```

---

### [swiftui](swiftui/)

SwiftUI Clean Architecture reviewer for iOS/macOS development with best practices enforcement.

**Installation:**
```bash
claude plugin install swiftui@frad-dotclaude
```

---

### [office](office/)

Patent application generation, Product Requirements Documents, image and video generation, agent-based browser automation, Remotion programmatic video authoring, and AI writing trope detection.

**Installation:**
```bash
claude plugin install office@frad-dotclaude
```

---

### [lark](lark/)

Feishu/Lark CLI skills, mirrored from larksuite/cli — docs, sheets, IM, calendar, approval, drive, wiki, contacts, and more.

**Installation:**
```bash
claude plugin install lark@frad-dotclaude
```

---

### [marketing](marketing/)

Marketing skills for AI agents, mirrored from coreyhaines31/marketingskills — CRO, copywriting, SEO, paid ads, ad creative, analytics, and growth.

**Installation:**
```bash
claude plugin install marketing@frad-dotclaude
```

---

### [hyperframes](hyperframes/)

HyperFrames HTML-based video authoring skills, mirrored from heygen-com/hyperframes — keyframes, animation, captions, motion graphics, and remotion-to-hyperframes conversion.

**Installation:**
```bash
claude plugin install hyperframes@frad-dotclaude
```

---

### [plugin-optimizer](plugin-optimizer/)

Validate and optimize Claude Code plugins against official best practices with agent-based fixes.

**Installation:**
```bash
claude plugin install plugin-optimizer@frad-dotclaude
```

---

### [autoresearch](autoresearch/)

Autonomous research loop inspired by karpathy/autoresearch — give it a plain-language goal; it infers a recommended contract (artifact, evaluator, bounds), then grills each decision with you one at a time before iterating: cheap sequential rounds that escalate to a parallel GAN tournament when they plateau. Works on any objective, not just ML training.

**Installation:**
```bash
claude plugin install autoresearch@frad-dotclaude
```

---

### [antigravity](antigravity/)

Delegate tasks and deep research to Google Gemini Managed Agents (Antigravity) running in a remote sandbox with code execution, Google Search, and URL reading, then read the results back. Runs asynchronously and polls for completion via the Monitor tool. Requires `GEMINI_API_KEY` and `uv`.

**Installation:**
```bash
claude plugin install antigravity@frad-dotclaude
```

---

### [storm](storm/)

Wikipedia-style long-form article generation via multi-perspective question asking and retrieval — a Claude-native port of Stanford STORM's two-stage research-to-article pipeline. Given a topic, it discovers research personas, runs simulated Q&A grounded in web search, then writes a cited article through outline → per-section → polish phases. Each phase is independently runnable and resumable.

**Installation:**
```bash
claude plugin install storm@frad-dotclaude
```

---

### [hardware](hardware/)

Hardware and EDA toolkit. `use-kicad-cli` drives KiCad 9.0's `kicad-cli` for schematic/PCB export, fabrication outputs (gerbers, drill, pick-and-place, BOM), 3D models, and ERC/DRC checks. `use-openscad` writes OpenSCAD code and drives the `openscad` CLI for parametric 3D/2D part design and STL/DXF/PNG output.

**Installation:**
```bash
claude plugin install hardware@frad-dotclaude
```

---

### [acpx](acpx/)

Knowledge base for acpx - a headless ACP CLI for agent-to-agent communication.

**Installation:**
```bash
claude plugin install acpx@frad-dotclaude
```

---

### [code-context](code-context/)

Five methods to retrieve code context: DeepWiki, Context7, Exa, git clone, and web search.

**Installation:**
```bash
claude plugin install code-context@frad-dotclaude
```

---

### [utils](utils/)

General-purpose utility skills for documentation, writing, and project maintenance.

**Installation:**
```bash
claude plugin install utils@frad-dotclaude
```

---

### [memory](memory/)

Consolidates a Claude Code project's memory — the private harness memory (~/.claude/projects/<escaped-cwd>/memory) and the repo-local memory (docs/memory/) — as one unlayered store, auto-consolidating on Stop with a 24h debounce and via a single no-argument skill.

**Installation:**
```bash
claude plugin install memory@frad-dotclaude
```

---

### [interfaces](interfaces/)

Agent skills for building great product interfaces, from typography and color to accessibility and UX writing. One skill, better-interface (orchestrator), with six domain reference packs: accessibility, layout, writing, typography, colors, and ui.

**Installation:**
```bash
claude plugin install interfaces@frad-dotclaude
```

---

## Adding a New Plugin

1. Create a plugin directory under `plugin-name/`.
2. Add `.claude-plugin/plugin.json` with required metadata.
3. Add the plugin entry to `.claude-plugin/marketplace.json`.
4. Run `/utils:update-readme` to sync both README files.

## License

[MIT](LICENSE)