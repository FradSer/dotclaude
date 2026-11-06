---
name: storm-research
description: Run STORM phase 1 — multi-perspective research. This skill should be used when the user asks to "research a topic for an article", "find sources on X from multiple perspectives", "do storm research on X", or invokes /storm:research. Discovers personas, runs simulated Q&A per persona in parallel, and produces an information table + deduplicated sources.
user-invocable: true
argument-hint: "<topic> [--max-perspective N] [--max-turns N] [--output-dir PATH | --save] [--docs DIR] [--docs-only] [--retriever mcp|web|local] [--force]"
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "Bash(mktemp:*)", "Bash(mkdir:*)", "Bash(date:*)", "WebSearch", "WebFetch", "Task", "Skill", "ToolSearch"]
---

# /storm:research

Phase 1 of the STORM pipeline. Discovers research personas, runs a simulated multi-turn conversation per persona (each grounded in retrieval), and produces the information table that downstream phases consume.

## CRITICAL: Load Engine First

Load `storm-engine` via the Skill tool. Its "Persona Discovery", "Simulated Conversation", "Retrieval", and "Citation Hygiene" sections govern this phase.

## Completion Contract

This phase is complete iff `research/sources.json` exists and has ≥1 entry. If `--force` is not set and the artifact exists, skip and exit early.

## Procedure

1. Resolve output dir (see engine). Ensure `research/` subdir exists.
2. **Persona discovery** — search the web for the topic + 2-3 related concepts; fetch reference pages and extract their section headings. Use those real structures to propose `--max-perspective` personas (default 3), each with a distinct question category, plus one "Basic fact writer". Write `research/personas.json`.
3. **Retrieval probe** — via `ToolSearch`, discover available web/academic/company search tools by describing the intent (do not hardcode exact MCP tool names). Record the selected tools in `run-config.json` as `retriever`. If none are available, fall back to `WebSearch`/`WebFetch`.
4. **Parallel simulated conversations** — launch one `storm-researcher` subagent per persona in a single message (parallel). Each subagent:
   - Receives: topic, persona definition, retrieval instructions, `max_turns`, and (when `--docs`/`--retriever local` is set) the local-document paths to consult as a source pool.
   - Runs the WikiWriter↔TopicExpert dialogue: writer asks a question, expert does `question_to_query`, retrieves, answers with source attribution.
   - Ends when writer says "Thank you so much for your help!" or `max_turns` reached.
   - Returns: a JSON array of `{question, queries, snippets, answer, cited_sources}`.
   - Launch all persona subagents in a single message (parallel) — do not serialize.
5. **Local-document ingestion** — when `--docs <dir>` (or `--retriever local`) is given, read the files in that directory (`.md`, `.txt`) and add each file as an additional source pool: one `sources.json` entry with `id`, `url` = the file path, and `snippet` = its text (chunk long files). With `--docs-only`, skip the web/MCP retrieval entirely and use only these document sources. Without `--docs`, skip this step.
6. **Merge** — collect all conversation records into `research/conversations.jsonl` (one JSON object per line). Deduplicate cited sources by URL into `research/sources.json`, assigning sequential `id`s (include the local-document entries). Strip any inline `[n]` from snippets before storing (citation hygiene).
7. **Verify** — assert `sources.json` has ≥1 entry and every persona produced ≥1 turn. If a persona produced nothing, note it but do not fail the whole phase.
8. Update `run-config.json`: `phases.research = "completed"`, `retriever`, source count.

## Concurrency Note

If the user reports rate-limit errors during this phase, reduce concurrency by running personas in smaller batches (e.g. 2 at a time) rather than lowering `max_turns` — mirroring upstream's `max_thread_num` guidance.

## Output

Report: number of personas, total conversation turns, number of deduplicated sources, and the path to `research/sources.json`.
