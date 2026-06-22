---
name: storm-write
description: Run STORM phase 3 — per-section article writing. This skill should be used when the user asks to "write the article sections", "draft the storm article", or invokes /storm:write. Writes each outline section in parallel with inline citations grounded in the research sources.
user-invocable: true
argument-hint: "<topic> [--retrieve-top-k N] [--output-dir PATH | --save] [--force]"
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "Bash(mktemp:*)", "Bash(mkdir:*)", "Bash(date:*)", "Task", "Skill"]
---

# /storm:write

Phase 3 of the STORM pipeline. Writes each outline section in parallel (one Task subagent per section), each grounded in top-k relevant sources from the research information table, with inline `[n]` citations.

## CRITICAL: Prerequisites

- Load `storm-engine` via the Skill tool.
- `outline.md` MUST exist (phase 2 complete). If absent, stop and instruct the user to run `/storm:outline` first.

## Completion Contract

This phase is complete iff `article.md` exists and every outline section (except Introduction/Conclusion/Summary placeholders) has body text. If `--force` is not set and it exists, skip and exit early.

## Procedure

1. Resolve output dir.
2. Read `outline.md` and `research/sources.json`. Index sources for retrieval (simple: rank by keyword/heading overlap with the section title).
3. **Identify sections** to write — skip any whose heading is exactly "Introduction", "Conclusion", or "Summary" (these are filled in `polish`).
4. **Parallel writing** — for each section, launch ONE Task subagent (single message, parallel). Each subagent:
   - Receives: topic, section heading, top-k relevant sources (default `--retrieve-top-k` 3), the full outline for context.
   - Writes the section body with inline `[n]` citations mapping to `sources.json` ids.
   - If no relevant sources, writes uncited and marks `<!-- TODO: no source -->`.
   - Returns the section markdown.
5. **Assemble** — concatenate sections in outline order under their headings into `article.md`. Preserve the heading hierarchy from `outline.md`.
6. Verify every non-placeholder section has body. Update `run-config.json`: `phases.write = "completed"`, section count, any TODO-flagged sections.

## Citation Rules

- Only cite `[n]` where `n` is an existing `id` in `sources.json`. Never mint a new id here.
- Place `[n]` immediately after the claim it supports. Multi-source claims use `[1][2]`.
- Do not cite in placeholder sections.

## Output

Report: number of sections written, number of citations used, list of sections flagged as TODO (no source), and the path to `article.md`.
