---
name: storm-engine
description: Provides the shared STORM methodology, artifact layout, stage-gating contract, citation hygiene, and retrieval fallback. Use when executing any /storm:* skill (generate, research, outline, write, polish). Internal knowledge; never user-invocable.
---

# STORM Engine

Internal knowledge for the STORM plugin. Encodes the methodology ported from Stanford STORM (NAACL'24 / EMNLP'24) into a Claude-native pipeline. Loaded automatically by every `/storm:*` skill.

## CRITICAL: Two-Stage Pipeline

The pipeline has two stages and four phases. Each phase is independently runnable and resumable — completed phases are loaded from the artifact directory, never re-run.

```
Stage 1 (Pre-writing)        Stage 2 (Writing)
  research  --------->  outline  --------->  write  --------->  polish
   (persona               (draft +            (per-section,        (summary +
    discovery,            refine from         cited, parallel)     dedup)
    simulated Q&A,        research)
    information table)
```

**NEVER skip stage 1.** An article generated from parametric memory alone is not a STORM article — it will hallucinate citations and miss the multi-perspective grounding that defines the method. If `research/` is absent, run `/storm:research` first.

**NEVER invent citations.** Every inline `[n]` must map to an entry in `sources.json` collected during research. If a section has no supporting sources, write it without citations and flag the gap in the polish phase — do not fabricate a reference.

## CRITICAL: Artifact Layout

All phases read from and write to a single per-topic directory:

```
<output_dir>/<slug>/
  research/
    personas.json          # discovered personas (name + perspective + rationale)
    conversations.jsonl   # one record per (persona, turn): question, queries, snippets, answer
    sources.json          # deduplicated Information objects: {id, title, url, description, snippets}
  outline.md              # refined outline (markdown headings)
  outline-draft.md        # pre-research draft (kept for reference)
  article.md              # per-section draft with inline [n] citations
  article-polished.md     # final polished article
  run-config.json         # snapshot of run parameters
```

**Stage-gating contract**: a phase is considered complete when its primary artifact exists and is non-empty. Before running a phase, check its output artifact:

- `research` complete iff `research/sources.json` exists and has ≥1 entry.
- `outline` complete iff `outline.md` exists and has ≥2 sections.
- `write` complete iff `article.md` exists and every outline section (except Introduction/Conclusion/Summary) has body text.
- `polish` complete iff `article-polished.md` exists.

If complete and the user did not pass `--force`, skip the phase and read its artifact. Log what was skipped.

## Slug Derivation

Derive `<slug>` from the topic by lowercasing, replacing non-alphanumeric runs with `-`, trimming leading/trailing `-`, and truncating to 60 chars. Two topics must not collide — append `-2`, `-3`, etc. if the dir already exists with a different `run-config.json` topic.

## Output Directory Resolution

1. If `--output-dir <path>` given → use `<path>/<slug>/`.
2. Else if `--save` given → use `docs/storm/<slug>/` (relative to cwd; create if missing).
3. Else → use a temporary directory: `$(mktemp -d)/storm-<slug>/`. Write `run-config.json` with `"temporary": true` and inform the user of the absolute path so they can rescue artifacts if desired. Temporary dirs are NOT cleaned up by the plugin (let the OS handle it), so the user can still resume within the session.

## Retrieval: MCP-First, WebSearch Fallback

CRITICAL: prefer connected MCP search tools, fall back to built-in web search only when no MCP search tool is available.

1. Probe for MCP search tools via ToolSearch: `exa-mcp-server__code-search`, `exa-mcp-server__research-paper-search`, `exa-mcp-server__company-search`, `exa-mcp-server__personal-site-search`, `exa-mcp-server__financial-report-search`, `exa-mcp-server__x-search`.
2. If at least one MCP search tool is available, use it for the research phase (select the most relevant type per query — e.g. `research-paper-search` for academic topics, `company-search` for organizations).
3. Only if NO MCP search tool is connected, fall back to the built-in `WebSearch` + `WebFetch`.
4. For grounding on user-provided documents (VectorRM-style), accept a `--docs <dir>` argument; if given, ingest those files as an additional source pool alongside web results (or instead of, if `--docs-only`).

**Source shape** (mirrors upstream `Information`): every source must be normalized to
```json
{"id": 1, "title": "...", "url": "...", "description": "...", "snippets": ["..."]}
```
Assign sequential `id`s as sources are added. The `id` is the citation key used in inline `[n]`.

## Citation Hygiene

- Inline citations use `[1]` / `[1][2]` form, placed immediately after the claim they support.
- The trailing `## References` section lists every cited source, numbered to match, with `title — url (accessed YYYY-MM-DD)`.
- Before reusing a snippet from an existing source (e.g. as context for a follow-up question), strip any inline citations the snippet itself contained — this prevents multi-hop citation confusion. Function: `strip_citations(text) -> text` removing all `[n]` and `[n][m]` patterns.
- Uncited sources may still appear in research but must NOT appear in References. References = exactly the set of `[n]` keys present in the body.
- If a section genuinely has no supporting source, write it uncited. Mark it with an HTML comment `<!-- TODO: no source -->` so polish can flag it.

## Persona Discovery

Ground personas in real structure, not hallucination — mirror STORM's "scrape related Wikipedia TOCs" step:

1. Search the web for the topic + 2-3 closely related concepts.
2. For each top result that looks like a reference page (Wikipedia, handbook, survey), fetch it and extract its table of contents / section headings.
3. Feed those real headings as inspiration to persona generation: ask the LLM to propose N perspectives (default 3) such that each persona would ask a different category of question about the topic. Always include a "Basic fact writer" persona in addition.
4. Each persona record: `{"name": "...", "perspective": "...", "rationale": "..."}`.

## Simulated Conversation (per persona)

For each persona, run a multi-turn dialogue between a WikiWriter (asks questions) and a TopicExpert (answers, grounded in retrieval):

1. Writer poses a question from its persona's angle.
2. Expert breaks the question into 1-3 search queries (`question_to_query`), retrieves via the retrieval contract above, and answers with inline source attribution.
3. Conversation ends when the Writer says "Thank you so much for your help!" or `max_turns` (default 3) is reached.
4. Collect every `(question, queries, snippets, answer)` tuple into `conversations.jsonl` and every cited source into `sources.json` (deduplicated by URL).

## Outline Generation

1. Draft an outline from parametric knowledge alone (`outline-draft.md`) — this is the LLM's prior structure.
2. Refine using the concatenated conversation history: reorganize, add/remove sections so the outline reflects what was actually learned. Write to `outline.md`.
3. Both files are kept. The refined `outline.md` is the one `write` consumes.

## Per-Section Writing

1. Index `sources.json` for retrieval.
2. For each outline section (in parallel via Task subagents), retrieve top-k relevant sources and write the section with inline `[n]` citations.
3. Skip auto-generated sections ("Introduction", "Conclusion", "Summary") — these are filled in `polish`.
4. Concatenate into `article.md` preserving outline heading structure.

## Polish

1. Add a summary/intro section if the outline had an "Introduction" or "Summary" placeholder.
2. Remove duplicate content across sections.
3. Verify every `[n]` in the body resolves to a References entry and vice versa; drop orphan entries on either side.
4. Write `article-polished.md`.

## Run Config

`run-config.json` always contains:
```json
{
  "topic": "<original topic>",
  "slug": "<derived>",
  "temporary": <bool>,
  "output_dir": "<absolute>",
  "max_perspective": 3,
  "max_turns": 3,
  "search_top_k": 3,
  "retrieve_top_k": 3,
  "retriever": "mcp" | "web" | "local",
  "started_at": "<ISO from caller>",
  "phases": {"research": "completed|skipped|pending", ...}
}
```

Timestamps: the plugin MUST NOT call `date` itself in deterministic contexts — accept `started_at` from the invoking skill via the caller's environment. In practice the invoking `/storm:*` skill passes the current time; `storm-engine` never generates timestamps.
