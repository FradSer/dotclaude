---
name: create-prd
description: This skill should be used when the user asks to "create PRD", "write product requirements document", or mentions "PRD", "product requirements document".
user-invocable: true
argument-hint: "--md | --lark [--folder-token TOKEN_OR_URL | --wiki-node TOKEN_OR_URL | --wiki-space ID_OR_URL]"
allowed-tools: ["Read", "Write", "AskUserQuestion", "Glob", "Bash(lark-cli:*)", "Skill"]
---

# PRD Creation

Follow the phases below to transform product ideas into a complete PRD document. All PRD content is written in Chinese (the target audience is Chinese-speaking teams).

## Output Mode

Determine output mode from `$ARGUMENTS`:

| Argument | Mode | Output |
|----------|------|--------|
| `--md` (default) | Local Markdown | Save as `.md` file to project directory |
| `--lark` | Feishu Cloud Doc | Create via `lark-cli` using Lark rich-text features |

`--lark` mode accepts optional location arguments (mutually exclusive), supporting token or Feishu URL:
- `--folder-token` — Target folder (token or URL)
- `--wiki-node` — Target wiki node (token or URL)
- `--wiki-space` — Target wiki space root (ID or URL, or `my_library`)

Pass URL directly to `lark-cli` — no manual token extraction needed. Defaults to user's personal space root when no location specified.

## Phase 0: Import Context

Check for existing design or requirements documents:

1. Search for `docs/`, `prd/` directories or user-specified files
2. If found, extract key information (problem statement, target users, core features) as pre-filled content
3. If nothing found, skip this phase

## Phase 1: Determine PRD Type

Ask the user which PRD type they need:

- **Full** (recommended): All standard sections, suitable for complex features
- **Brief**: Core sections only, suitable for small features or quick iteration
- **One-pager**: Single-page summary, suitable for concept validation and executive reporting

## Phase 2: Gather Information

Follow the interview questions in `references/prd-interview-questions.md`, one question at a time. Wait for the answer before continuing.

- Basic info (7 items): required for all types
- Full version extras (5 items): full type only
- AI Agent boundaries: needed when the PRD will be consumed by AI coding agents

If Phase 0 found pre-filled content, show it to the user for confirmation and skip covered questions.

## Phase 3: Generate PRD Document

1. **Select template**:
   - Full: `references/prd-template-full.md`
   - Brief: `references/prd-template-brief.md`
   - One-pager: `references/prd-template-onepager.md`

2. **Fill content**: Use gathered information for each section, following `references/prd-best-practices.md` writing principles

3. **AI Agent consumability**:
   - Write each requirement as a discrete, verifiable item (lists over long paragraphs)
   - Express non-goals as positive constraints
   - Split P0 features into 5-15 minute agent work stages with testable checkpoints
   - Full version includes a three-layer boundary framework: autonomous / needs confirmation / prohibited

4. **Quality requirements**:
   - Problem statement backed by specific data or research
   - Goals follow SMART principles
   - Success metrics are quantifiable
   - Avoid vague terms ("approximately", "maybe", "try to")
   - Use active voice and concrete verbs

5. **Format**:
   - `--md` mode: Standard Markdown with clear heading hierarchy
   - `--lark` mode: Lark-flavored Markdown (see Feishu enhancements section)

## Phase 4: Validate and Save

Run validation per `references/prd-validation-checklist.md` — completeness, SMART goals, content quality, BDD acceptance criteria.

### `--md` Mode

Save file after validation:
- Filename: `PRD-[ProductName]-[YYYYMMDD].md`
- Prefer `docs/` or `prd/` directory, otherwise current working directory
- Report path and file summary

### `--lark` Mode

Create Feishu document after validation:

1. **CRITICAL** — Confirm standalone `lark` plugin (`lark@frad-dotclaude`) is installed; follow its `lark-shared` skill for authentication
2. Follow the lark plugin's `lark-doc` skill for document creation guidance
3. Refer to `lark-doc-create.md` for full `docs +create` parameters and Lark-flavored Markdown syntax
4. Convert PRD content to Lark-flavored Markdown (see Feishu enhancements section)
5. Create document:
   ```bash
   lark-cli docs +create --title "PRD-[ProductName]-[YYYYMMDD]" \
     [--folder-token TOKEN_OR_URL | --wiki-node TOKEN_OR_URL | --wiki-space ID_OR_URL] \
     --markdown "<lark-flavored-markdown>"
   ```
6. For longer PRDs, split: `docs +create` for first half, then `docs +update --mode append` for remaining sections
7. If `board_tokens` are present:
   - Follow the lark plugin's `lark-whiteboard` skill
   - Fill each whiteboard with actual content (flowcharts, architecture diagrams)
   - All whiteboards must have real content before task is complete
8. Report the document URL

## Phase 5: Next Steps

After saving, suggest follow-up options:
- Convert PRD into implementation tickets
- Refine design decisions in open questions
- Share with team for review and feedback

## Feishu Document Enhancements

**CRITICAL** — In `--lark` mode, use Lark-flavored Markdown syntax to leverage Feishu's rich-text capabilities.

### Required Feishu Features by PRD Section

| PRD Section | Feishu Feature | Description |
|---|---|---|
| Project metadata (version/date/owner) | `<lark-table>` | Enhanced table with header row |
| Key risks/assumptions/dependencies | `<callout>` | Color-coded: risk=red, assumption=blue, dependency=yellow |
| Core goals / success metrics | `<callout emoji="..." background-color="light-green">` | Highlight key OKRs |
| Priority comparison (P0/P1/P2) | `<grid cols="3">` | Three-column side-by-side layout |
| User journey / business process | `<whiteboard type="blank">` | Flowchart, filled via lark-whiteboard |
| System architecture | `<whiteboard type="blank">` | Architecture diagram, filled via lark-whiteboard |
| Milestones / timeline | `<whiteboard type="blank">` | Timeline chart |
| Non-goals / scope exclusions | `<callout emoji="..." background-color="light-red">` | Red highlight for prohibited scope |
| Glossary / abbreviations | Two-column Markdown table | Compact reference |
| Decision records | `<callout>` + blockquote | Key decisions with rationale |

### Whiteboard Rules

Insert whiteboards for: user journeys, system architecture, data flows, milestones, team organization. Skip for pure text, data-heavy content (use tables), or when user requests text-only.

### Format Principles

- Max 4 heading levels
- Use `---` dividers between sections
- Do NOT write a top-level heading duplicating the title (Feishu auto-generates it)
- Use callouts sparingly; bold only core terms
- Use `<text color="red">` for key metrics or status
- Feishu auto-generates table of contents — do not add manually

## Quality Principles

- **Data-driven**: Support problem statements with specific data and user research
- **SMART goals**: Specific, Measurable, Achievable, Relevant, Time-bound
- **Concise and clear**: Avoid verbosity; descriptions must be clear enough for dev teams to implement directly
- **Collaboration-oriented**: PRD is a collaboration tool; tone promotes discussion, not command
- **Dual-audience design**: Serve both human teams and AI coding agents

## Supporting Files

- `references/prd-interview-questions.md` — Information gathering questionnaire
- `references/prd-validation-checklist.md` — Validation checklist
- `references/prd-template-full.md` — Full version template
- `references/prd-template-brief.md` — Brief version template
- `references/prd-template-onepager.md` — One-pager template
- `references/prd-best-practices.md` — Best practices guide
- `references/prd-examples.md` — High-quality PRD examples
- Standalone `lark` plugin (`lark@frad-dotclaude`) — Lark CLI skills (`--lark` mode)