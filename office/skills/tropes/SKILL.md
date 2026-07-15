---
name: tropes
description: Detects and eliminates AI writing tropes that make text sound artificial or formulaic. Use when generating text content, writing documentation, creating code comments, or reviewing writing style. Supports four-tier JSON preferences (global/project x shared/local office.json) read via load-preferences.sh.
---

# AI Writing Tropes Detection

Scan generated text for common AI writing patterns that make content sound artificial or formulaic. This skill provides a systematic workflow for identifying and eliminating tropes.

Source: [tropes.fyi](https://tropes.fyi) by [ossama.is](https://ossama.is)
Original gist: [ossa-ma/f3baa9d2](https://gist.github.com/ossa-ma/f3baa9d25154c33095e22272c631f5a1) — the raw 33-trope list this skill's `references/` are structured from and extended.

## Core Principle

**Write like a human expert: varied, precise, and professional.**

The goal is to find the "middle ground" between overly colloquial or casual writing and the obscure, formulaic style typical of AI generation. A single pattern used once is usually fine; the problem occurs when multiple tropes cluster together or when the same trope repeats throughout the text.

## When to Check

Scan for tropes when:
- Generating any text content (documentation, comments, messages)
- Reviewing writing before committing or publishing
- Editing AI-generated drafts
- Responding to user questions or creating explanations

## Detection Workflow

### 0. Load User Preferences

CRITICAL: User preferences live in `office.*.json` files (NOT Claude Code's `settings.json`). These are the office plugin's own preference files following the `.claude/plugin-name.local.*` convention with `.json` carriers. They do NOT participate in the harness four-layer settings merge — the merge is done by `load-preferences.sh`.

Run the loader script to get the merged preferences as a single JSON object:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/load-preferences.sh
```

The script reads up to four files in precedence order (highest first): `.claude/office.local.json` (project, personal) > `.claude/office.json` (project, shared) > `~/.claude/office.local.json` (global, personal) > `~/.claude/office.json` (global, shared). It deep-merges them (scalars replaced by higher layer, lists concatenated and deduped, pattern_caps deduped by `id`, dead_metaphors.entries by `word`), and prints the merged JSON to stdout. If jq is missing or all files are absent, it fails open to `{}` and default rules apply.

Apply the merged preferences as overrides/supplements to the default detection below:
- `banned_words` / `banned_phrases` / `zh.*` / `en.*` — additive to default trope words
- `preferred_terms` — suggested replacements during revision
- `skip_categories` — disables the named category entirely (enum: `word-choice`, `sentence-structure`, `paragraph-structure`, `tone`, `formatting`, `composition`, `professional-balance`)
- `sensitivity` — threshold override (`strict` flags single occurrences; `relaxed` only 3+)
- `tone` — baseline shift for professional-balance
- `formatting.max_em_dashes` / `formatting.allow_bold_first_bullets` — formatting thresholds
- `dead_metaphors` — enforce per-word caps (default 1; `quote_exception` skips quoted speech); suggest `replacement`
- `pattern_caps` — enforce per-pattern caps (`reversal_sentence`, `parallelism_triple`, `arrow_flow`, `numbered_bold_sections`), honoring `forbidden_in` / `scope` / `exception`
- `rhetorical_bans` — ban rhetorical patterns by stable ID (`self_qa`, `self_eval_summary`, `parallel_antithesis_subheading`, `process_meta_narration`)
- `principles` — judgmental free-text rules applied as additional checks

If both files are absent, after the detection run, offer to create the global file with default values.

See `references/preferences-schema.md` for the full field reference and merge rules.

### 1. Pattern Scan

Read through the text and identify:
- Repeated sentence structures or openings
- Formulaic transitions ("It's worth noting", "Here's the thing")
- Ornate vocabulary where simple words work better
- Rhetorical patterns that feel artificial
- Overly colloquial or "chatty" fragments that lack professional weight

### 2. Cluster Check

Look for multiple tropes appearing together:
- 3+ patterns in a single paragraph = high risk
- Same pattern used 2+ times in a piece = needs revision
- Em-dashes appearing 5+ times = formatting issue

### 3. Revision Strategy

For each identified trope:
- **Word choice**: Replace with simpler, more direct language, or precise technical terms (avoid "magic adverbs").
- **Sentence structure**: Vary openings and lengths naturally, grouping related thoughts into coherent paragraphs.
- **Transitions**: Use logic-driven connectors (e.g., "Consequently," "Conversely") instead of filler phrases.
- **Formatting**: Reduce em-dashes, remove bold-first bullets.

### 4. Verification

After revision:
- Re-scan for remaining patterns
- Check that text sounds natural when read aloud
- Ensure specificity (concrete details vs vague attributions)
- Confirm the tone is professional yet accessible ("Expert Clarity")

### 5. Preference Sync (Optional)

After the detection run, offer to save preferences to one of the four files (default `~/.claude/office.local.json`):
- `~/.claude/office.local.json` — global personal defaults
- `~/.claude/office.json` — global shared baseline
- `.claude/office.local.json` — project personal (gitignore this)
- `.claude/office.json` — project shared (commit this for the team)

When the user wants a rule shared with a team, suggest a `.json` (shared) file; for personal preferences, a `.local.json` file. Then:
- Newly flagged words → `banned_words` / `banned_phrases` / `zh.banned_words` / `en.banned_words`
- Repeated correction patterns → `preferred_terms`
- New dead metaphors → `dead_metaphors.entries` (with `word`, `replacement`, `cap`)
- New sentence-pattern caps → `pattern_caps` (with `id`, `max`/`max_nodes`, optional `forbidden_in`/`scope`/`exception`)
- Rhetorical pattern bans → `rhetorical_bans` (stable ID)
- Judgmental rules → `principles`
- Sensitivity adjustments → `sensitivity`

Default target is the global file unless the user specifies project-level. Do not auto-write. Present a diff preview: which file, which field, and what the merged JSON will look like. Let the user confirm before writing.

## Pattern Categories

The complete trope catalog is organized into seven categories. Load specific references as needed:

1. **Word Choice** - `references/word-choice.md`
   Ornate vocabulary, magic adverbs, pompous constructions

2. **Sentence Structure** - `references/sentence-structure.md`
   Negative parallelism, rhetorical questions, formulaic patterns

3. **Paragraph Structure** - `references/paragraph-structure.md`
   Short fragments, listicle disguises

4. **Tone** - `references/tone.md`
   False suspense, pedagogical voice, vague attributions

5. **Formatting** - `references/formatting.md`
   Em-dash overuse, bold-first bullets, unicode decoration

6. **Composition** - `references/composition.md`
   Fractal summaries, dead metaphors, content duplication

7. **Professional Balance** - `references/professional-balance.md`
   Avoiding both overly colloquial "humanisms" and obscure AI-isms.

Plus one supporting schema (not a trope category):

- **User Preferences** - `references/preferences-schema.md`
  Two-tier JSON config: global `~/.claude/office.local.json` + project `.claude/office.local.json`, read and merged by `load-preferences.sh`. Custom banned words/phrases, dead metaphors, pattern caps, sensitivity, tone, skip categories.
