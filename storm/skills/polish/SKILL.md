---
name: storm-polish
description: Run STORM phase 4 — article polishing. This skill should be used when the user asks to "polish the storm article", "finalize the article", or invokes /storm:polish. Adds a summary section, removes duplicate content, and verifies citation integrity.
user-invocable: true
argument-hint: "<topic> [--remove-duplicate] [--output-dir PATH | --save] [--force]"
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "Bash(mktemp:*)", "Bash(mkdir:*)", "Bash(date:*)", "Skill"]
---

# /storm:polish

Phase 4 of the STORM pipeline. Adds a summary/intro section, removes duplicate content across sections, and verifies every inline `[n]` citation resolves to a References entry and vice versa.

## CRITICAL: Prerequisites

- Load `storm-engine` via the Skill tool.
- `article.md` MUST exist (phase 3 complete). If absent, stop and instruct the user to run `/storm:write` first.

## Completion Contract

This phase is complete iff `article-polished.md` exists. If `--force` is not set and it exists, skip and exit early.

## Procedure

1. Resolve output dir.
2. Read `article.md`, `outline.md`, and `research/sources.json`.
3. **Summary section** — if `outline.md` had an "Introduction" or "Summary" placeholder, write a summary section synthesizing the article's main points (1-2 paragraphs). Do not introduce new claims or citations not already in the body.
4. **Duplicate removal** (default on; `--remove-duplicate` is explicit but the behavior is the default) — detect near-duplicate paragraphs across sections and remove the later occurrence, keeping the one in the more topically-appropriate section.
5. **Citation integrity** — build the set of `[n]` keys present in the body. Append a `## References` section listing exactly those sources, numbered to match, each as `n. title — url (accessed YYYY-MM-DD)`. Drop any `[n]` in the body that has no source (replace with `<!-- TODO: missing source -->`). Drop any source not cited (do not list uncited sources in References).
6. Write `article-polished.md`.
7. Update `run-config.json`: `phases.polish = "completed"`, final word count, source count, any integrity warnings.

## Output

Report: final word count, number of cited sources, number of duplicate paragraphs removed, any integrity warnings (missing sources / TODO sections), and the absolute path to `article-polished.md`.
