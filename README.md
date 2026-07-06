# Frad's Claude Code Plugins ![](https://img.shields.io/badge/plugins-16-blue)

[![MIT License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-v0.6+-purple)](https://claude.ai/code)

**English** | [简体中文](README.zh-CN.md)

A curated collection of 16 plugins for Claude Code, providing specialized agents, skills, and automation tools for development and productivity workflows.

## Available Plugins

### [git](git/)

Conventional Git automation for commits and repository management with AI code quality checks.

**Installation:**
```bash
claude plugin install git@frad-dotclaude
```

---

### [gitflow](gitflow/)

GitFlow workflow automation for feature, hotfix, and release branches with semantic versioning and post-finish cleanup.

**Installation:**
```bash
claude plugin install gitflow@frad-dotclaude
```

---

### [github](github/)

GitHub project operations with quality gates, TDD workflows, and comprehensive validation.

**Installation:**
```bash
claude plugin install github@frad-dotclaude
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

Patent application generation, Product Requirements Documents, image and video generation, Feishu document creation, agent-based browser automation, Lark/Feishu CLI operations, and AI writing trope detection.

**Installation:**
```bash
claude plugin install office@frad-dotclaude
```

---

### [plugin-optimizer](plugin-optimizer/)

Validate and optimize Claude Code plugins against official best practices with agent-based fixes.

**Installation:**
```bash
claude plugin install plugin-optimizer@frad-dotclaude
```

---

### [frontend](frontend/)

Web frontend development toolkit — shadcn/ui, Next.js DevTools, React best practices, Supabase, DESIGN.md design system spec, and impeccable design skills.

**Installation:**
```bash
claude plugin install frontend@frad-dotclaude
```

---

### [autoresearch](autoresearch/)

Autonomous research loop inspired by karpathy/autoresearch — you supply an editable artifact, a scorer that prints one number, and an optimization direction; it runs bounded experiments, keeps a change only if the score improves, logs to results.tsv, and iterates via a stop hook. Works on any objective, not just ML training.

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

## Adding a New Plugin

1. Create a plugin directory under `plugin-name/`.
2. Add `.claude-plugin/plugin.json` with required metadata.
3. Add the plugin entry to `.claude-plugin/marketplace.json`.
4. Run `/utils:update-readme` to sync both README files.

## License

[MIT](LICENSE)