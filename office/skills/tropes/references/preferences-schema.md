# User Preferences Schema

Writing preferences for the tropes skill, stored as `office.local.json`. The tropes skill loads and merges preferences at the start of each detection workflow via `office/scripts/load-preferences.sh`, then applies them as overrides or supplements to the default trope rules.

**CRITICAL**: These are the office plugin's own preference files, following the official `.claude/plugin-name.local.*` convention with `.json` carriers. They are NOT Claude Code's `settings.json` and do NOT participate in the harness four-layer settings merge. The merge is implemented by `load-preferences.sh`, not by Claude Code.

---

## Four-Tier Configuration

Mirrors Claude Code's `settings.local.json` (personal/gitignored) overlaying `settings.json` (shared/committed), split across global and project scopes.

| Precedence | Scope | Path | Use case |
|------------|-------|------|----------|
| 1 (highest) | Project, personal | `.claude/office.local.json` | Per-project personal overrides (gitignore this) |
| 2 | Project, shared | `.claude/office.json` | Team/project shared defaults (commit this) |
| 3 | Global, personal | `~/.claude/office.local.json` | Personal defaults across all projects |
| 4 (lowest) | Global, shared | `~/.claude/office.json` | Shared global baseline |

**Precedence**: Higher layer overlays lower. Scalars are replaced; lists are concatenated and deduplicated; objects are deep-merged. `.local` overrides shared at each scope; project overrides global. See Merge Rules below.

## File Format

Both files are plain JSON. The format is identical; only the path determines scope.

```json
{
  "tone": "neutral",
  "sensitivity": "standard",
  "banned_words": [],
  "preferred_terms": {},
  "zh": { "banned_words": [], "preferred_terms": {} },
  "en": { "banned_words": [], "preferred_terms": {} },
  "skip_categories": [],
  "formatting": { "max_em_dashes": 5, "allow_bold_first_bullets": false },

  "dead_metaphors": {
    "default_cap": 1,
    "quote_exception": true,
    "entries": [
      { "word": "护城河", "replacement": "壁垒 / 结构性优势 / 我们守住的位置", "cap": 3 },
      { "word": "楔子", "replacement": "切入原型 / 验证场景", "cap": 1 }
    ]
  },
  "pattern_caps": [
    { "id": "reversal_sentence", "max": 1, "forbidden_in": ["title"] },
    { "id": "parallelism_triple", "max": 1 },
    { "id": "arrow_flow", "max_nodes": 3, "exception": ["state_machine", "transition_diagram"] },
    { "id": "numbered_bold_sections", "max": 1, "scope": "chat_reply" }
  ],
  "banned_phrases": ["一句话讲完", "收敛成一句话", "改动点："],
  "rhetorical_bans": ["self_qa", "self_eval_summary", "parallel_antithesis_subheading", "process_meta_narration"],
  "principles": ["关键数字必须可溯源：口头转述的金额/百分比/用户量发布前须核实"],
  "source_notes": ["源自 2026-06-12 雷鸟战略长文复盘"]
}
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
| `skip_categories` | `enum[]` | `[]` | Valid values: `word-choice`, `sentence-structure`, `paragraph-structure`, `tone`, `formatting`, `composition`, `professional-balance` |
| `formatting.max_em_dashes` | `number` | `5` | Override the em-dash cluster threshold |
| `formatting.allow_bold_first_bullets` | `boolean` | `false` | When `true`, skip bold-first-bullet detection |
| `dead_metaphors.default_cap` | `number` | `1` | Default max occurrences per dead metaphor |
| `dead_metaphors.quote_exception` | `boolean` | `true` | When `true`, quoted speech (meetings/others' words) does not count toward cap |
| `dead_metaphors.entries` | `object[]` | `[]` | Each: `{word, replacement, cap}`; `cap` overrides `default_cap`; `replacement` may be empty |
| `pattern_caps` | `object[]` | `[]` | Each: `{id, max \| max_nodes, forbidden_in?, scope?, exception?}`. Caps a sentence pattern |
| `banned_phrases` | `string[]` | `[]` | Phrases always flagged (e.g. self-evaluation declarations, summary labels) |
| `rhetorical_bans` | `string[]` | `[]` | Stable IDs of banned rhetorical patterns (see IDs table below) |
| `principles` | `string[]` | `[]` | Judgmental free-text rules, applied as additional checks (not pattern-matched) |
| `source_notes` | `string[]` | `[]` | Retrospective provenance metadata; not used in detection, for editing traceability only |

### `pattern_caps` IDs

| ID | Caps | Optional constraints |
|----|------|----------------------|
| `reversal_sentence` | "不是 X，是 Y" reversal pattern | `forbidden_in: ["title"]` |
| `parallelism_triple` | 排比三连 ("承认 A，承认 B，承认 C") | — |
| `arrow_flow` | `X → Y → Z` arrow chains | `max_nodes`, `exception: ["state_machine", "transition_diagram"]` |
| `numbered_bold_sections` | `**N. xxx**` numbered bold subsections | `scope: "chat_reply"` (docs exempt) |

### `rhetorical_bans` IDs

- `self_qa` — self-Q&A rhetorical questioning ("为什么？因为……")
- `self_eval_summary` — self-evaluation summary labels at reply end ("改动点："/"优化点：")
- `parallel_antithesis_subheading` — "去 X / 改 Y / 删 Z" antithesis subheadings
- `process_meta_narration` — operation-step meta-narration ("先取 block id…再…然后…") in user-facing replies

## Preference Precedence

When preferences conflict with default trope rules:

1. `banned_words` / `banned_phrases` / `preferred_terms` — **additive**: extend defaults, never remove them
2. `skip_categories` — **subtractive**: disables the named category entirely
3. `sensitivity` — **global override**: changes the threshold for all categories
4. `tone` — **baseline shift**: adjusts the professional-balance reference point
5. `dead_metaphors` / `pattern_caps` / `rhetorical_bans` / `principles` — **supplementary**: applied as additional checks after structured rules

## Merge Rules

Implemented by `office/scripts/load-preferences.sh` (jq deep merge). When both global and project files exist:

| Field type | Merge strategy |
|------------|----------------|
| Scalar (`tone`, `sensitivity`, `dead_metaphors.default_cap`, `formatting.*`) | Project value replaces global value; null in project keeps global |
| Plain string list (`banned_words`, `banned_phrases`, `skip_categories`, `zh.banned_words`, `en.banned_words`, `rhetorical_bans`, `principles`, `source_notes`) | Concatenated, deduplicated (note: `unique` reorders entries alphabetically; order is not preserved) |
| Object map (`preferred_terms`, `zh.preferred_terms`, `en.preferred_terms`) | Same key: project overrides global; non-conflicting keys merged |
| Nested object (`zh`, `en`, `formatting`, `dead_metaphors`) | Recursive deep merge per sub-field |
| Object array keyed by `id` (`pattern_caps`) | Concatenated, deduplicated by `id`, project entry wins on conflict |
| Object array keyed by `word` (`dead_metaphors.entries`) | Concatenated, deduplicated by `word`, project entry wins on conflict |

If jq is unavailable or a file is missing/invalid JSON, the loader fails open (warns on stderr, treats the input as `{}`) so detection still runs with defaults.

## How to Manage

The tropes skill handles preference management during the detection workflow:

- **Create**: If no file exists, offer to generate `~/.claude/office.local.json` (global personal) with defaults. For team-shared rules, suggest `.claude/office.json` (committed); for personal project overrides, `.claude/office.local.json` (gitignored).
- **Update**: After a detection run, offer to save newly discovered preferences. Default target is `~/.claude/office.local.json` unless the user specifies otherwise. Present a diff preview (file, field, merged JSON) before writing.
- **Read**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/load-preferences.sh` returns the merged JSON across all four layers.

Users may also edit either file directly with any text editor.

### Migration from `office.local.md` (v0.5.x → v0.6.0)

If `~/.claude/office.local.md` still exists and `office.local.json` does not, the old YAML-frontmatter + markdown-body format is in use. Migrate by structuring each body rule into the JSON fields above (dead-metaphor registry → `dead_metaphors.entries`; sentence-pattern limits → `pattern_caps`; banned self-evaluation phrases → `banned_phrases`; rhetorical bans → `rhetorical_bans`; judgmental rules → `principles`; retrospective provenance → `source_notes`), then delete the `.local.md` file.
