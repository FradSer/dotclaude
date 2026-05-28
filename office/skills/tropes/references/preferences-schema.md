# User Preferences Schema

Writing preferences for the tropes skill, stored as `.local.md` files. The tropes skill loads preferences at the start of each detection workflow and applies them as overrides or supplements to the default trope rules.

---

## Two-Tier Configuration

Preferences support global and project-level scopes, following the same pattern as the git plugin:

| Scope | Path | Use case |
|-------|------|----------|
| Global (user-level) | `~/.claude/office.local.md` | Personal defaults across all projects |
| Project-level | `.claude/office.local.md` (in repo root) | Team or project-specific overrides |

**Precedence**: Project-level settings override global settings field-by-field. Lists (e.g., `banned_words`) are merged; scalar values (e.g., `tone`, `sensitivity`) are replaced by the project-level value.

Example: Global sets `sensitivity: standard` and bans `["delve"]`. Project sets `sensitivity: strict` and bans `["leverage"]`. Effective result: `sensitivity: strict`, banned words: `["delve", "leverage"]`.

## File Format

Both files use YAML frontmatter for structured settings and markdown body for freeform rules. The format is identical; only the path determines scope.

```markdown
---
# Writing tone: formal | neutral | conversational
tone: neutral

# Check strictness: strict (catch more) | standard (default) | relaxed (fewer flags)
sensitivity: standard

# Custom word/phrase lists
banned_words: []        # Always flag these, on top of default trope words
preferred_terms: {}     # key = avoid, value = use instead

# Language-specific rules
zh:
  banned_words: []      # e.g. ["赋能", "抓手", "底层逻辑"]
  preferred_terms: {}   # e.g. {"助力": "支持"}
en:
  banned_words: []      # e.g. ["delve", "tapestry"]
  preferred_terms: {}   # e.g. {"utilize": "use"}

# Category toggles — skip entire trope categories
skip_categories: []     # e.g. ["formatting", "paragraph-structure"]

# Formatting preferences
formatting:
  max_em_dashes: 5      # Override default em-dash threshold
  allow_bold_first_bullets: false
---

# Freeform Writing Rules

Add any custom rules here in plain markdown. These are applied alongside
the structured settings above.

- Use active voice by default
- Keep paragraphs under 5 sentences
- Prefer "we" over "I" in team documentation
```

## Field Reference

| Field | Type | Default | Effect |
|-------|------|---------|--------|
| `tone` | `formal \| neutral \| conversational` | `neutral` | Shifts the "Professional Balance" baseline. `formal` tightens colloquial detection; `conversational` relaxes it |
| `sensitivity` | `strict \| standard \| relaxed` | `standard` | `strict`: flags single occurrences. `relaxed`: only flags 3+ occurrences |
| `banned_words` | `string[]` | `[]` | Added to the word-choice category. Always flagged regardless of context |
| `preferred_terms` | `map<string, string>` | `{}` | Key is the word to avoid, value is the replacement. Suggested during revision |
| `zh.banned_words` | `string[]` | `[]` | Chinese-specific banned words, checked only in Chinese text |
| `zh.preferred_terms` | `map<string, string>` | `{}` | Chinese term replacements |
| `en.banned_words` | `string[]` | `[]` | English-specific banned words, checked only in English text |
| `en.preferred_terms` | `map<string, string>` | `{}` | English term replacements |
| `skip_categories` | `string[]` | `[]` | Valid values: `word-choice`, `sentence-structure`, `paragraph-structure`, `tone`, `formatting`, `composition`, `professional-balance` |
| `formatting.max_em_dashes` | `number` | `5` | Override the em-dash cluster threshold |
| `formatting.allow_bold_first_bullets` | `boolean` | `false` | When `true`, skip bold-first-bullet detection |

## Preference Precedence

When preferences conflict with default trope rules:

1. `banned_words` / `preferred_terms` — **additive**: extend defaults, never remove them
2. `skip_categories` — **subtractive**: disables the named category entirely
3. `sensitivity` — **global override**: changes the threshold for all categories
4. `tone` — **baseline shift**: adjusts the professional-balance reference point
5. Freeform rules — **supplementary**: applied as additional checks after structured rules

## Merge Rules

When both global and project-level files exist:

| Field type | Merge strategy |
|------------|----------------|
| Scalar (`tone`, `sensitivity`) | Project value replaces global value |
| List (`banned_words`, `skip_categories`) | Lists are concatenated, deduplicated |
| Map (`preferred_terms`) | Project entries override global entries for the same key; non-conflicting keys are merged |
| Nested map (`zh.banned_words`, `formatting.max_em_dashes`) | Same rules applied per sub-field |
| Freeform markdown body | Project body is appended after global body |

## How to Manage

The tropes skill handles preference management during the detection workflow:

- **Create**: If neither file exists, offer to generate the global file (`~/.claude/office.local.md`) with defaults. If only the global file exists and the user wants project-specific rules, offer to create the project-level file (`.claude/office.local.md`).
- **Update**: After a detection run, offer to save newly discovered preferences. Default target is the global file unless the user specifies otherwise.
- **Read**: Load and merge at the start of each detection run (global first, then project overlay).

Users may also edit either file directly with any text editor.
