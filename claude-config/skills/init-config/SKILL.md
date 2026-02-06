---
name: init-config
description: Generate $HOME/.claude/CLAUDE.md with AI-driven environment detection and advanced configuration options
argument-hint: []
user-invocable: true
allowed-tools:
  - Read
  - Write
  - AskUserQuestion
  - Bash(*)
---

## Initialization
Run phases in order because later phases depend on saved choices from earlier phases.

## Phase 1: Environment Discovery
**Goal**: detect installed languages, tools, and package managers.

**Actions**:
1. Detect installed languages (Node.js, Python, Rust, Go, Java, Docker, and others).
2. Detect package manager options for selected ecosystems.
3. Store detection results for Phase 4 option generation.

## Phase 2: Developer Profile
**Goal**: detect or collect developer identity for personalization.

**Actions**:
1. Run `git config user.name` and `git config user.email` to detect developer info.
2. If both are detected, store as `developer_name` and `developer_email` for renderer arguments and proceed to Phase 3.
3. If either is missing, ask the user directly through conversation:
   - If name is missing: "I couldn't detect your name from git config. What name would you like to use? (or reply 'skip' to omit)"
   - If email is missing: "I couldn't detect your email from git config. What email would you like to use? (or reply 'skip' to omit)"
4. Store the user's responses (or empty values if skipped) as `developer_name` and `developer_email` for renderer arguments.

## Phase 3: TDD Preference
**Goal**: decide whether to include TDD requirements.

**Actions**:
Ask with header `TDD Mode`:
- `Include TDD (Recommended)` -> include TDD fragments.
- `Exclude TDD` -> keep base template.
Store boolean `include_tdd` for Phase 7 renderer arguments.

## Phase 3.5: Memory Management (Optional)
**Goal**: decide whether to add CLAUDE.md memory instructions.

**Actions**:
Ask with header `Memory`:
- `Skip (Recommended)`
- `Include memory rules`
Store boolean `include_memory` for renderer arguments. Do not append memory text manually.

## Phase 4: Technology Stack & Package Manager Selection
**Goal**: choose languages and package managers.

**Actions**:
1. Use **AskUserQuestion** (`multiSelect: true`) for technology stacks.
2. Generate options from detected technologies and mark detected ones as recommended.
3. For selected languages with multiple managers, ask preference:
- Node.js: npm, pnpm (Recommended), yarn, bun.
- Python: pip, uv (Recommended), poetry.
- Only show managers detected on the machine.
4. Store ordered stack selections as `language:::package_manager` for renderer arguments.

## Phase 5: Renderer Input Preparation
**Goal**: prepare deterministic renderer inputs from local references and user selections.

**Actions**:
1. Read `${CLAUDE_PLUGIN_ROOT}/assets/technology-stack-rules.md`.
2. Normalize each selected stack into ordered renderer input format `language:::package_manager`.
- Keep selection order unchanged.
3. For languages without explicit package manager choice, use `language:::` (empty manager).
4. Keep language keys exact (`Node.js`, `Python`, `Rust`, `Swift`, `Go`, `Java`) when available; do not invent aliases.
5. Do not manually generate language rule bullets in this phase; pass structured inputs to the renderer only.
6. Never call online search in this phase.

## Phase 6: Style Preference
**Goal**: choose emoji usage policy in generated CLAUDE.md.

**Actions**:
Ask with header `Style`:
- `No Emojis (Recommended)`
- `Use Emojis`
Store boolean `use_emojis` for renderer arguments that control emoji policy text in output.

## Phase 6.5: Validation Enforcement Preference
**Goal**: decide whether renderer validation should block writes.

**Actions**:
Ask with header `Validation`:
- `Warn only (Recommended)` -> render and write even when status is TOO_SHORT/TOO_LONG/EXCESSIVE.
- `Block on non-zero validation` -> fail write when validation exits non-zero.
Store boolean `enforce_validation` for renderer arguments.

## Phase 7: Assembly & Generation
**Goal**: generate final content through one renderer script.

**Actions**:
1. Run `${CLAUDE_PLUGIN_ROOT}/scripts/render-claude-config.sh` with:
- `--base-template ${CLAUDE_PLUGIN_ROOT}/assets/claude-template-no-tdd.md`
- `--rules-file ${CLAUDE_PLUGIN_ROOT}/assets/technology-stack-rules.md`
- `--target-file $HOME/.claude/CLAUDE.md`
- `--include-tdd <true|false>`
- `--include-memory <true|false>`
- `--use-emojis <true|false>`
- `--enforce-validation <true|false>`
- Optional `--developer-name` and `--developer-email`
- Repeated `--stack "language:::package_manager"` entries from Phase 5
2. Let the renderer handle all assembly concerns: template merge, TDD injection, developer profile, technology stack section, optional memory section, length check, backup, and final write.
3. Do not manually post-edit renderer output; if output shape is wrong, fix inputs or renderer behavior.

## Phase 8: Length Validation
**Goal**: handle renderer validation outcomes.

**Actions**:
1. Capture renderer validation output (`Word count`, `STATUS`, `RECOMMENDATION`).
2. If validation is not enforced and status is TOO_LONG or EXCESSIVE, ask user whether to regenerate with trimming instructions.
3. If validation is enforced and renderer exits non-zero, ask user whether to retry with adjusted settings.

## Phase 9: Write CLAUDE.md
**Goal**: report write and backup results from renderer.

**Actions**:
1. Use renderer output to confirm:
- Target path written.
- Backup path created when an existing target file was present.
- Validation result used for the write decision.
2. Report:
- File and backup locations.
- Developer info and TDD mode.
- Selected technology stacks and package managers.
- Renderer rule-application summary: which stacks received local rule lines and which did not.
- Word count, validation status, and whether validation was enforced.

## Best Practices
- Keep workflow progressive and deterministic.
- Prefer local references over generated prose for stack guidance.
- Keep generated constraints concise and enforceable.
- Always back up existing files before overwrite.
