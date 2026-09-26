# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **antigravity** — Vertex AI credential path alongside the existing API-key path. `ANTIGRAVITY_AUTH` selects `vertex` (Application Default Credentials plus project and location) or `api-key`, and `auto` prefers Vertex whenever it is fully configured so an ambient key cannot silently redirect billing. Vertex forces `background=true` because the API rejects synchronous agent interactions there.
- **antigravity** — Cost, model and steering options on `delegate`: `--max-tokens` (`agent_config.max_total_tokens`, the only real cap on an autonomous loop), `--model`, `--system` (with an anti-fabrication default), `--tier` (`service_tier`, including the cheap `flex` tier), `--label`, `--image` (inline base64 multimodal input) and `--json` (`response_format`). Research gains `--collaborative-planning`, `--visualization`, `--thinking-summaries` and `--bigquery`.
- **antigravity** — `status --progress` prints the tail of a new `progress.log`, which the worker fills from the interaction's server-sent event stream (best-effort; polling still decides run state).
- **antigravity** — `cleanup [--older-than-days N] [--remote] [--dry-run]` prunes finished run directories and, with `--remote`, deletes the stored interactions.

### Changed

- **antigravity** — `google-genai` floor raised to `>=2.25.0` (the version whose interactions module routes Vertex requests), and the resolved credential path is now printed on start and recorded in `meta.json` as `auth` / `auth_label`.
- **antigravity** — Delegate now sends a default `system_instruction` forbidding claims about content no tool actually retrieved, after live runs showed the agent answering from memory and describing an empty fetch as a successful read. `--system ""` disables it.

### Fixed

- **antigravity** — Deep research was broken: the plugin sent its default `system_instruction` on every run, and the deep-research agent rejects that parameter outright (`400 ... not supported for the deep-research-preview-04-2026 agent`). Research never sends one now, and an explicit `--system` is refused with a pointer to `--query` instead of silently rewriting the question.
- **antigravity** — Report citations were dropped. Text content carries `url_citation` annotations (the live research run had 43, deduping to 9 sources) that the report's inline `[cite: N]` markers refer to; `output.md` now renders them under `## Sources`, `output.json` carries them as `citations`, and the header records the count.
- **antigravity** — `cleanup --remote` treated an already-deleted interaction as a failure, so the run directory was kept forever while retrying a delete that could never succeed. A `404` (retention, or an earlier cleanup) now counts as done; only a genuine refusal keeps the run for a later retry.
- **antigravity** — `--environment-id` never reused a sandbox: the plugin sent the id inside a config object and the server ignored it, silently provisioning a fresh sandbox with none of the files. Reuse is the bare environment id, which was verified live to return the same environment with its files intact. The plugin now also refuses to combine reuse with `--repo` or `--network none` rather than dropping them.
- **antigravity** — Chaining with only `--previous-interaction-id` started a fresh sandbox, because managed-agent chaining requires the environment in the same request. The worker now reads the previous interaction's `environment_id` and reuses it, and since the configured `--max-tokens` / `--model` go into `agent_config` the request also carries the budget it claims to.
- **antigravity** — A run waiting on `requires_action` was treated as "still working" and polled until the 2-hour worker deadline. It now fails immediately, explaining that the agent asked for a client-side function call this plugin cannot serve.
- **antigravity** — The tool trace was always empty against `google-genai` 2.25.0: Vertex reports every tool as a generic `function_call` (`step.name` plus dict arguments) instead of the per-tool `code_execution_call` / `google_search_call` / `url_context_call` step types, so `summarize_steps` matched nothing. Both shapes now render.
- **antigravity** — Model output was joined with a blank line between `model_output` steps, splitting text that streams across steps (a live run turned `2**64` into `184467440737095516` + `16`) and duplicating the consolidated message the server re-sends after a run of deltas. Fragments now concatenate with no separator, and only an exact re-send of the text accumulated since the last non-model_output step is dropped.
- **antigravity** — A dead worker could leave a run non-terminal forever: the liveness check skipped runs with no `worker.pid` yet (a worker killed before it wrote its pid), and trusted a recorded pid that an unrelated process had recycled. Worker identity is now confirmed against the run id in the process command line, and a run with no pid past `WORKER_START_GRACE` is declared failed. When the command line cannot be read the pid is trusted, so a live run is never reported as failed.
- **antigravity** — The delegate skill's re-arm guidance said four consecutive `wait` timeouts covered "2 hours" (it is 1 hour at 15 minutes each), and both skills now state that deep research has no token cap.

## [v1.13.0] - 2026-06-23

### Added

- **autoresearch** — New plugin with rolling research loop, git worktree isolation, hybrid plateau escalation, Gemini agent bridge, temporary experiment commits, and unified `/start` entry point
- **antigravity** — New managed agent plugin with Gemini worker stability enhancements
- **storm** — Article generation plugin
- **office** — Image and video media generation skills, automatic backup pruning, lark-note skill, and lark workspace sync
- **frontend** — Articulate design skill, design system compliance checking, anti-patterns detector enabled, impeccable skill upstream sync, and project snapshots
- **github** — Triage agent for PR feedback and post-pr monitoring with auto-fix loop
- **git** — Pre-commit hook with skill reflection and user-input-driven setup
- **superpowers** — Generalized stop hook for state backfill (v3.3.0)
- **plugin-optimizer** — Skill file validation with version bump

### Changed

- **autoresearch** — Unified state and duration logic, rolling loop implementation, harden safety and transcript resilience, optimize gitflow model resolution
- **frontend** — Restructured skill architecture, renamed local docs and hardened scripts, updated plugin and skills documentation
- **github** — Optimized PR monitoring skill
- **swiftui** — Updated review guidelines and plugin
- **acpx** — Consolidated CLI documentation
- **gitflow** — Clarified pre-operation safety checks
- **github** — Clarified auto-closing limitations
- **superpowers** — Standardized `/goal` usage documentation
- **acpx** — Clarified exec vs prompt and added cwd workflows

### Fixed

- **acpx** — Trimmed skill.md for context limit
- **autoresearch** — Handled JSON args and validated GAN config, added bounded loop isolation and transcript resilience

## [v1.12.2] - 2026-06-03

### Added

- **superpowers 3.x** — Plan-completion and stop hooks, retrospective memory recall, unified retro event helpers, stall detection with phase recovery, stricter batch execution in executing-plans, design/code evaluation checklists (v2/v3), and read-only `superpowers-evaluator` for design folders and sprint contracts
- **frontend plugin** — New marketplace plugin with DESIGN.md design-system spec, React 19 best-practice rules, `design-md` skill, impeccable review skills, and frontend expert / anti-patterns agents (replaces standalone next-devtools/shadcn packaging)
- **office** — Lark workspace skill with management scripts; **tropes** skill for AI-writing-pattern detection with preference overrides
- **code-context** — Code checklist v3 for evaluator-driven reviews
- **claude-config** — Code checklist v2 with isolation rules and shared retrospective helpers
- **plugin-optimizer** — `displayName` on marketplace entries, severity-classified validation output, and JSON reporting mode
- **git** — Co-author injection contract and consolidated setup skills (v0.5.0)
- **utils** — `update-changelog` skill for Keep a Changelog–aligned releases
- **acpx** — User-invocable `use-acpx` skill
- **CI** — GitHub Actions workflow for superpowers shell tests and manifest validation on `superpowers/**` changes

### Changed

- **superpowers** — Refactored plan hooks and evaluation protocol; removed automated harness/calibration layers and the need-vet gate; executing-plans now tracks read loops, enforces format contracts, and logs plan completion with tighter stuck detection
- **plugin-optimizer** — Validation script reports severity levels; version bumped to 0.12.0
- **gitflow / github / refactor / swiftui / claude-config / office** — Version and manifest sync across the marketplace; gitflow skills aligned with git-agent workflows
- **frontend** — Upstream sync scripts and local mod-replay detection; plugin at 0.3.1

### Removed

- **meeseeks-vetted** and **need-vet** plugins and verification hooks
- Standalone **next-devtools** plugin (capabilities moved under **frontend**)
- Legacy superpowers skills and interactive approval gates superseded by hook-driven flow

### Fixed

- Superpowers stop hook crash on invalid `modified_files`; state-lock and missing-state-dir handling in setup and hooks
- Executing-plans `/goal` condition (single commit vs per-batch) and using-superpowers dispatcher regressions
- Utils vet `set -e` regression and evaluator documentation gaps

### Documentation

- Superpowers README and phase references for executing-plans, retrospectives, and evaluation formats
- Plugin-optimizer argument-hint standards; git and gitflow skill workflow docs
- Frontend README and agent reference naming

## [v1.12.1] - 2026-03-30

### Added

- Add use-git-agent skill to git plugin for explicit git-agent invocation
- Add need-vet skill to refactor plugin for verification gate control
- Add need_vet verification flag to devtools plugin for slash command classification
- Add shared utility functions to utils plugin for JSON handling and output formatting
- Add prd creation skill and templates to office plugin
- Add vet skill to superpowers for verification workflow control

### Changed

- Refactor git plugin to streamline git-agent workflow with unified skill structure
- Refactor git plugin to consolidate commit workflow into single skill with CLI support
- Refactor git plugin to update skill documentation with comprehensive tool lists
- Refactor git plugin to remove deprecated commit hooks and update hook patterns
- Refactor utils plugin to enable claude auth and update hook configuration
- Refactor utils plugin to improve vet utilities and hook output handling
- Refactor gitflow plugin to unify workflow templates and standardize skill tool definitions
- Refactor cod (claude-config) plugin to ensure task completion before promise resolution
- Refactor cod (claude-config) plugin to update plugin list and commit scopes
- Refactor office plugin to update agent-browser sync script for better integration
- Refactor superpowers plugin to standardize skill name references and align executing-plans
- Refactor devtools plugin to enhance superpowers hooks with improved detection

### Fixed

- Fix utils plugin to preserve skill context and clear vet flag on task completion
- Fix utils plugin to change stop-hook exit code and improve output handling
- Fix meeseeks plugin to update skip flag handling and improve hook compatibility
- Fix meeseeks plugin to make hooks macOS-compatible and improve prompt merge

### Documentation

- Update git skill descriptions with comprehensive guidance and tool requirements
- Update git plugin documentation with install section and CLI guide
- Update git skill documentation with agent workflow patterns
- Update gitflow skill documentation with git-agent steps integration
- Update git skill documentation with commit tool description and guidance
- Update cod (claude-config) plugin documentation with updated skill descriptions
- Update superpowers plugin documentation with skill descriptions and patterns
- Update devtools plugin documentation with slash command classification details
- Improve skill description documentation across all plugins

### Chores

- Bump devtools plugin version to 1.12.1
- Sync marketplace versions with plugin updates

## [v1.12.0] - 2026-03-24

### Added

- Add meeseeks-vetted plugin for plugin verification
- Add utils plugin with update-readme skill
- Add context researcher agent to claude-config
- Add license and expand bash permissions to claude-config
- Add verification gate to executing-plans in superpowers
- Add plan writing boundaries clarification to superpowers
- Add completion promise injection to prompt re-run in superpowers
- Add model invocation disable option to gitflow skills

### Changed

- Refactor meeseeks: add plugin, clean marketplace
- Refactor meeseeks: update task messages
- Refactor gitflow: standardize skill tool definitions
- Refactor: update skill descriptions
- Refactor superpowers: standardize skill name references
- Refactor superpowers: align executing-plans with single-loop pattern

### Fixed

- Fix superpowers: remove warning for missing transcript

### Documentation

- Update README plugin list for meeseeks
- Improve git skill descriptions and plugin keywords
- Update claude-config plugin descriptions
- Update swiftui-review skill description
- Add license to plugin.json

## [v1.11.0] - 2026-03-18

### Added

- Add superpowers v2.0.0 with significant enhancements
- Add prompt-file and first-action pattern to superpowers
- Add red-green pair workflow to superpowers
- Add ralph loop stop hook to superpowers
- Add ralph loop to superpowers v1.6.0

### Changed

- Refactor github skill context commands for simplicity
- Consolidate superpower-loop references in superpowers
- Rename ralph-loop to superpower-loop in superpowers

### Fixed

- Use portable shebang in validate-commit-pretool.sh
- Fix ralph loop syntax and promise order

### Documentation

- Add README for code-context plugin

### Chores

- Sync plugin versions

## [v1.10.0] - 2026-03-16

### Changed

- Maintenance release: sync develop with latest main changes

## [v1.9.0] - 2026-03-13

### Added

- Add shadcn plugin for UI component management (adds, searches, fixes, debugs, styles, and composes shadcn components)
- Add acpx plugin for agent-to-agent communication via ACP protocol with persistent sessions
- Add performance and test-coverage reviewers to review plugin for specialized code audits
- Add missing agent definitions (tech-lead-reviewer, ux-reviewer) to review plugin
- Add design reflection phase to plugin-optimizer for improved plugin quality
- Add plan reflection phase to superpowers for iterative design refinement
- Add agent tool restrictions to review plugin to enforce safe capability boundaries
- Add worktree isolation mode for agent teams in superpowers skill
- Add iphone-team agent implementing Apple's Project Purple methodology
- Add design reflection and MCP integration guidance to plugin-optimizer

### Changed

- Refactor git validation script to accept semantic versioning for Claude models (supports 4.6, 4.7, 5.0, etc.)
- Refactor plugin-optimizer skill structure for improved organization
- Optimize acpx skill documentation with progressive disclosure (Level 3 token structure)
- Standardize agent workflows across review plugin with autonomous explore phase
- Improve review plugin reference documentation with standardized patterns
- Enhance github plugin with repository template detection capabilities
- Improve swiftui plugin with Clean Architecture reference documentation
- Condense plugin-optimizer skill files for better maintainability
- Migrate swiftui plugin from command-based to skill-based architecture

### Fixed

- Fix git pretool hook to use correct decision field for commit validation
- Fix git title validation to properly enforce 50-character limit
- Fix git pretool hook to ensure it runs on every bash call
- Fix git error message formatting and symbol usage
- Fix jq output redirection in git validation script
- Fix bash 3.2 compatibility issues in git hook script
- Fix hook configuration for proper event-driven automation
- Fix duplicate message deduplication while preserving order in git hooks

### Documentation

- Add worktree isolation guidance for autonomous agents in plugin-optimizer
- Add tool design philosophy reference to plugin-optimizer
- Add Gherkin .feature file storage requirement to BDD workflow
- Enhance plugin documentation with standardized descriptions
- Clarify skill tool usage patterns in superpowers
- Correct MCP resources count in next-devtools documentation

### Chores

- Remove executing-plans transition step for improved workflow efficiency
- Remove version fields from SKILL.md frontmatter (version in plugin.json only)
- Update git commit scopes and types configuration
- Standardize plugin documentation structure across all plugins

## [v1.8.0] - 2026-02-26

### Added

- Add next-devtools plugin with MCP server integration for Next.js 16+ diagnostics
- Add build-like-iphone-team skill for Apple's radical innovation methodology

### Changed

- Migrate git skills (commit-and-push, config-git, update-gitignore) to agent-based workflow
- Refactor executing-plans with improved task naming and batch parallelism
- Simplify brainstorming phase 4 for better readability
- Adopt AI-native hook output schema for commit validation
- Switch to fragment-based CLAUDE.md generation in claude-config
- Revert to markdown error output for commit validation

### Fixed

- Add allowed-tools (Task, TaskCreate, TaskUpdate, Glob, Grep, Read) to executing-plans
- Use dynamic model placeholder in Co-Authored-By for different AI models
- Fix unbound variable warnings in validate-commit-pretool.sh
- Expand commit validation verb list

### Documentation

- Add Gherkin .feature file storage requirement to BDD workflow
- Embed BDD scenarios directly in task files
- Clarify explanation paragraph requirement in commit messages
- Update hook documentation with markdown patterns
- Add complex bug planning guidance to superpowers
- Update MCP capabilities documentation for next-devtools

### Chores

- Remove utils plugin from marketplace (features available elsewhere)
- Remove version fields from SKILL.md frontmatter (version in plugin.json only)
- Standardize plugin documentation structure across all plugins
- Clean up git commit scopes and types configuration

## [v1.7.0] - 2026-02-11

### Added

- Add task batch parallelism to executing-plans skill with dependency-aware restructuring
- Add example blocks to SwiftUI reviewer
- Add workflow skills plugin with brainstorming, writing-plans, and executing-plans
- Add agent team support to plugin optimizer
- Add unified renderer and lean template to claude-config

### Changed

- Convert executing-plans skill to knowledge-type with dependency-based batch formation
- Consolidate git commit documentation in superpowers
- Align plugin structure with skill best practices
- Rewrite brainstorming skill with enhanced BDD and agent team integration
- Enhance plugin best practices skill with focused reference structure
- Split optimize-plugin workflow into modular references
- Remove length validation script from claude-config
- Consolidate git commit skill documentation

### Fixed

- Remove invalid schema version field from superpowers
- Move review references to skills directory
- Add trigger phrases and fix skill type in superpowers
- Add trigger phrases to review paths
- Add trigger phrases to git descriptions
- Correct phase numbering in init-config workflow
- Clarify agent and skill workflows in refactor
- Enhance skill descriptions in gitflow
- Update plugin optimizer docs for unified validator
- Fix duplicate tags and branch issues in gitflow
- Ignore tool references in code fences for validator

### Documentation

- Update plugin list and commit scopes in docs
- Add path reference patterns to plugin optimizer
- Add execution context to task template in superpowers
- Add batch execution and git commit guidance
- Update office skill command documentation
- Update plugin skill descriptions in readme
- Update workflow skills structure in superpowers
- Improve inline bash description in plugin optimizer
- Add style preferences to claude-config
- Add Mermaid requirement to claude-config template
- Enhance claude.md with plugin patterns
- Update plugin best practices and component model
- Sync marketplace versions and add guide
- Add file organization guide to refactor
- Remove docs-claude documentation
- Clarify argument-hint requirements in plugin optimizer
- Add workflow guidance to claude.md
- Optimize GitHub skills with disclosure
- Update git config-git skill and template

### Chores

- Bump plugin versions: claude-config 1.4.0, superpowers 1.2.0, swiftui 0.2.0
- Add keywords and license to plugins
- Sync marketplace versions with plugins
- Update gitignore for Python configuration
- Bump plugin-optimizer to 0.11.1

## [v1.6.1] - 2026-01-30

### Changed

- Migrate GitFlow plugin to git-flow-next CLI
- Restructure GitFlow skill documentation
- Restructure Refactor plugin documentation with skill references
- Restructure Git plugin documentation with workflow guidance
- Enhance Plugin Optimizer workflow and configuration

### Fixed

- Align GitFlow changelog generation with Keep a Changelog standards

## [v1.6.0] - 2026-01-25

### Added

- Add changelog example and update skills in GitFlow plugin
- Add GitHub release creation step to finish-release workflow

### Changed

- Update marketplace plugin versions
- Clarify Plugin Optimizer guidance with RFC 2119 and component references
- Improve Plugin Optimizer skill documentation structure
- Simplify Refactor docs and README organization
- Enhance Git commit and .gitignore workflow guidance

## [v1.5.0] - 2026-01-24

### Changed

- Update marketplace plugin versions
- Clarify Plugin Optimizer guidance with RFC 2119 and component references
- Improve Plugin Optimizer skill documentation structure
- Simplify Refactor docs and README organization
- Enhance Git commit and .gitignore workflow guidance

## [v1.4.0] - 2026-01-24

### Added

- Add Review skills for quick and hierarchical review
- Add GitHub skills for issue and PR operations
- Add co-authored-by validation support in the Git workflow

### Changed

- Migrate plugin commands to skills across Office, Claude Config, GitHub, Review, and Refactor
- Make co-authored-by optional in the Git workflow
- Standardize README structure and installation instructions across plugins
- Add plugin marketplace installation guide
- Improve Plugin Optimizer skill reference guidance and parallel agent execution guidance
- Update GitFlow skill references and plugin configuration metadata

### Removed

- Remove legacy command files

## [v1.3.0] - 2026-01-23

### Added

- Add co-authored-by requirement option in Git validation
- Add Office browser-use skill sync tool
- Add Plugin Optimizer commands-to-skills migration check
- Enhance Office patent-architect structure

### Changed

- Optimize GitFlow workflows and reduce redundancy
- Migrate Git plugin to skills structure and update plugin config
- Relax Plugin Optimizer skill description validation
- Improve Git command documentation and workflow guidance
- Add Claude Code project guidance and plugin marketplace documentation

### Fixed

- Improve Git message extraction for heredoc and validation

## [v1.2.0] - 2026-01-21

### Added

- Add Plugin Optimizer plugin for best practices
- Add Claude Config plugin for configuration management
- Add Git hooks configuration and validation hooks
- Add Git config command for commit validation

### Changed

- Migrate Git hooks to external files and SKILL.md frontmatter
- Update agent definitions for skills
- Streamline plugin documentation and framework detection
- Add comprehensive Claude development guides

## [v1.1.0] - 2026-01-19

### Added

- Add Git workflow skills
- Add refactor commands
- Add safety checks to the Git commit command

### Changed

- Reorganize GitFlow workflow references and docs
- Enhance TypeScript best-practices reference in Refactor
- Improve Git conventional commit documentation
- Consolidate skills into a best-practices structure
- Optimize Office plugin patterns and code-simplifier config

### Fixed

- Use explicit skill tool call in the patent-architect command

## [v1.0.0] - 2026-01-18

### Added

- Initial release of the plugin marketplace with Git, GitFlow, GitHub, Review, Refactor, Office, and SwiftUI plugins
- Command system with standardized workflows, TDD, and Clean Architecture requirements
- Build pipeline for marketplace artifacts and plugin manifests
- Sync-to-GitHub script and local agent management
- Comprehensive READMEs and command guides

### Changed

- Restructure repository to the claude-plugins-official layout
- Refactor build scripts and prompt generation for maintainability
- Standardize command formats, commit standards, and documentation

### Fixed

- Fix build and release scripts for version detection and TOML prompts
- Improve sync script compatibility and error handling

[unreleased]: https://github.com/FradSer/dotclaude/compare/v1.13.0...HEAD
[v1.13.0]: https://github.com/FradSer/dotclaude/compare/v1.12.2...v1.13.0
[v1.12.2]: https://github.com/FradSer/dotclaude/compare/v1.12.1...v1.12.2
[v1.12.1]: https://github.com/FradSer/dotclaude/compare/v1.12.0...v1.12.1
[v1.12.0]: https://github.com/FradSer/dotclaude/compare/v1.11.0...v1.12.0
[v1.11.0]: https://github.com/FradSer/dotclaude/compare/v1.10.0...v1.11.0
[v1.10.0]: https://github.com/FradSer/dotclaude/compare/v1.9.0...v1.10.0
[v1.9.0]: https://github.com/FradSer/dotclaude/compare/v1.8.0...v1.9.0
[v1.8.0]: https://github.com/FradSer/dotclaude/compare/v1.7.0...v1.8.0
[v1.7.0]: https://github.com/FradSer/dotclaude/compare/v1.6.1...v1.7.0
[v1.6.1]: https://github.com/FradSer/dotclaude/compare/v1.6.0...v1.6.1
[v1.6.0]: https://github.com/FradSer/dotclaude/compare/v1.5.0...v1.6.0
[v1.5.0]: https://github.com/FradSer/dotclaude/compare/v1.4.0...v1.5.0
[v1.4.0]: https://github.com/FradSer/dotclaude/compare/v1.3.0...v1.4.0
[v1.3.0]: https://github.com/FradSer/dotclaude/compare/v1.2.0...v1.3.0
[v1.2.0]: https://github.com/FradSer/dotclaude/compare/v1.1.0...v1.2.0
[v1.1.0]: https://github.com/FradSer/dotclaude/compare/v1.0.0...v1.1.0
[v1.0.0]: https://github.com/FradSer/dotclaude/releases/tag/v1.0.0
