# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

- Initial release of the plugin marketplace with Git, GitFlow, GitHub, Review, Refactor, Utils, Office, and SwiftUI plugins
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

[unreleased]: https://github.com/FradSer/dotclaude/compare/v1.6.1...HEAD
[v1.6.1]: https://github.com/FradSer/dotclaude/compare/v1.6.0...v1.6.1
[v1.6.0]: https://github.com/FradSer/dotclaude/compare/v1.5.0...v1.6.0
[v1.5.0]: https://github.com/FradSer/dotclaude/compare/v1.4.0...v1.5.0
[v1.4.0]: https://github.com/FradSer/dotclaude/compare/v1.3.0...v1.4.0
[v1.3.0]: https://github.com/FradSer/dotclaude/compare/v1.2.0...v1.3.0
[v1.2.0]: https://github.com/FradSer/dotclaude/compare/v1.1.0...v1.2.0
[v1.1.0]: https://github.com/FradSer/dotclaude/compare/v1.0.0...v1.1.0
[v1.0.0]: https://github.com/FradSer/dotclaude/releases/tag/v1.0.0
