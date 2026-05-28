---
name: tropes
description: Detects and eliminates AI writing tropes that make text sound artificial or formulaic. Use when generating text content, writing documentation, creating code comments, or reviewing writing style. Supports two-tier preference overrides (global ~/.claude/office.local.md + project .claude/office.local.md).
---

# AI Writing Tropes Detection

Scan generated text for common AI writing patterns that make content sound artificial or formulaic. This skill provides a systematic workflow for identifying and eliminating tropes.

Source: [tropes.fyi](https://tropes.fyi) by [ossama.is](https://ossama.is)

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

Check for preference files in order (project overrides global):
1. `.claude/office.local.md` (project-level, in the current working directory)
2. `~/.claude/office.local.md` (user-level, global)

If either exists:
- Parse YAML frontmatter for structured settings (sensitivity, tone, banned words, skip categories)
- Read markdown body for freeform rules
- Merge: project-level settings override global settings field-by-field
- Apply merged preferences as overrides to the default detection behavior below

If neither exists, offer to create the global file with default values after the detection run completes.

See `references/preferences-schema.md` for the full field reference and precedence rules.

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

After the detection run, offer to save preferences to either `~/.claude/office.local.md` (global) or `.claude/office.local.md` (project):
- Newly flagged words the user wants to permanently ban → add to `banned_words`
- Repeated correction patterns → add to `preferred_terms`
- Sensitivity adjustments based on false positives → update `sensitivity`

Default target is the global file unless the user specifies project-level. Do not auto-write preferences. Present the proposed changes and let the user confirm.

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

8. **User Preferences** - `references/preferences-schema.md`
   Two-tier overrides: global `~/.claude/office.local.md` + project `.claude/office.local.md`. Custom banned words, sensitivity, tone, skip categories.
