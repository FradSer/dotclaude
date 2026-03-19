# Frad's Claude Code Plugins ![](https://img.shields.io/badge/plugins-15+-blue)

[![MIT License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-v0.6+-purple)](https://claude.ai/code)

**English** | [简体中文](README.zh-CN.md)

A curated collection of 15 plugins for Claude Code, providing specialized agents, skills, and automation tools for development and productivity workflows.

## Available Plugins

### [git](git/)

Conventional Git automation for commits and repository management with AI code quality checks.

**Installation:**
```bash
claude plugin install git@frad-dotclaude
```

---

### [gitflow](gitflow/)

GitFlow workflow automation for feature, hotfix, and release branches with semantic versioning.

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

### [review](review/)

Multi-agent code review system with specialized reviewers for code quality, security, architecture, and UX.

**Installation:**
```bash
claude plugin install review@frad-dotclaude
```

---

### [superpowers](superpowers/)

Advanced development workflow orchestration with BDD support and Agent Team execution for complex projects.

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

### [claude-config](claude-config/)

Generate comprehensive CLAUDE.md configuration files with environment detection and interactive workflow.

**Installation:**
```bash
claude plugin install claude-config@frad-dotclaude
```

---

### [office](office/)

Patent application generation, Feishu document creation, and Product Requirements Documents.

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

### [next-devtools](next-devtools/)

Next.js development tools integration via MCP server for routing, components, and API analysis.

**Installation:**
```bash
claude plugin install next-devtools@frad-dotclaude
```

---

### [acpx](acpx/)

Knowledge base for acpx - a headless ACP CLI for agent-to-agent communication.

**Installation:**
```bash
claude plugin install acpx@frad-dotclaude
```

---

### [shadcn](shadcn/)

Manages shadcn components - adding, searching, fixing, debugging, styling, and composing UI.

**Installation:**
```bash
claude plugin install shadcn@frad-dotclaude
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
