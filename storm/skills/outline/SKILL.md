---
name: storm-outline
description: Run STORM phase 2 — outline generation. This skill should be used when the user asks to "generate an outline for a storm article", "draft a wikipedia-style outline", or invokes /storm:outline. Produces a draft outline from parametric knowledge then refines it using the research information table.
user-invocable: true
argument-hint: "<topic> [--output-dir PATH | --save] [--force]"
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "Bash(mktemp:*)", "Bash(mkdir:*)", "Bash(date:*)", "Skill"]
---

# /storm:outline

Phase 2 of the STORM pipeline. Drafts an outline from the model's parametric knowledge, then refines it using the research conversations to reflect what was actually learned.

## CRITICAL: Prerequisites

- Load `storm-engine` via the Skill tool.
- `research/sources.json` MUST exist (phase 1 complete). If absent, stop and instruct the user to run `/storm:research` first. Do not proceed with a parametric-only outline as the final artifact.

## Completion Contract

This phase is complete iff `outline.md` exists and has ≥2 sections. If `--force` is not set and it exists, skip and exit early.

## Procedure

1. Resolve output dir.
2. Read `research/conversations.jsonl` and `research/sources.json`. Concatenate the conversation histories as the refinement input.
3. **Draft** — generate `outline-draft.md` from parametric knowledge alone. This is the model's prior structure for the topic. Use markdown `## Section` headings.
4. **Refine** — reorganize the draft using the conversation history: merge redundant sections, add sections for material the research surfaced that the draft missed, drop sections the research did not support. Write the result to `outline.md`.
5. Mark "Introduction", "Conclusion", "Summary" sections as placeholders if present — they are filled in the `polish` phase, not here.
6. Verify `outline.md` has ≥2 sections. Update `run-config.json`: `phases.outline = "completed"`, section count.

## Output

Report: number of draft sections, number of refined sections, sections added/removed during refinement, and the path to `outline.md`.
