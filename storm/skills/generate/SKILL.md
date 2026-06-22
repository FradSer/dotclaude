---
name: storm-generate
description: Run the full STORM pipeline end-to-end. This skill should be used when the user asks to "generate a storm article", "write a wikipedia-style article about X", "research and write a long-form piece on X", or invokes /storm:generate. Orchestrates research -> outline -> write -> polish, skipping already-completed phases.
user-invocable: true
argument-hint: "<topic> [--max-perspective N] [--max-turns N] [--output-dir PATH | --save] [--docs DIR] [--docs-only] [--force] [--retriever mcp|web|local]"
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "Bash(mktemp:*)", "Bash(mkdir:*)", "Bash(date:*)", "WebSearch", "WebFetch", "Task", "Skill", "ToolSearch"]
---

# /storm:generate

End-to-end STORM article generation. Runs all four phases in sequence, skipping any phase whose artifact already exists (unless `--force`).

## CRITICAL: Load Engine First

Load the `storm-engine` skill via the Skill tool before doing anything else. It defines the artifact layout, stage-gating contract, citation hygiene, and retrieval fallback that this orchestration depends on. Do not improvise these.

## Arguments

- `<topic>` (required) — the subject of the article.
- `--max-perspective N` (default 3) — number of personas to discover.
- `--max-turns N` (default 3) — max Q&A turns per persona.
- `--output-dir PATH` — explicit output location. Mutually exclusive with `--save`.
- `--save` — persist to `docs/storm/<slug>/` instead of a temp dir.
- `--docs DIR` — ground on local documents in addition to (or, with `--docs-only`, instead of) the web.
- `--force` — re-run all phases even if artifacts exist.
- `--retriever mcp|web|local` — override retrieval source (default: mcp with fallback).

## Procedure

1. Parse arguments; if no topic, invoke `AskUserQuestion` to request one.
2. Derive `<slug>` and resolve `<output_dir>` per the engine contract. Create the directory.
3. Write `run-config.json` with a snapshot of all parameters. Stamp `started_at` using `date -u +%Y-%m-%dT%H:%M:%SZ` (the only place a timestamp is generated).
4. For each phase in order — `research`, `outline`, `write`, `polish`:
   a. Check the phase's completion artifact (per engine contract).
   b. If complete and not `--force`: mark `phases.<name>: "skipped"` in `run-config.json`, log "Skipping <name> (artifact present)".
   c. Otherwise: invoke the corresponding `/storm:<phase>` skill via the Skill tool, passing the resolved output dir and run parameters. After it returns, verify its artifact and mark `phases.<name>: "completed"` (or `"failed"` with the error).
5. After all phases, read `article-polished.md` and print a summary: topic, word count, number of sources cited, number of sections, and the absolute path to the final article.
6. If the run used a temporary directory, surface its absolute path prominently so the user can rescue artifacts.

## Concurrency

`research` and `write` phases use Task subagents internally (see their own SKILL.md files). This orchestration skill runs phases strictly sequentially — never parallelize across phases, because each phase depends on the previous phase's artifacts.

## Failure Handling

If a phase fails, stop and report. Do not proceed to the next phase. Update `run-config.json` with the failure reason. A re-invocation (without `--force`) will resume from the failed phase since completed prior phases will be skipped.

## Output

The final message to the user must include:
- The absolute path to `article-polished.md`.
- Word count and section count.
- Number of cited sources.
- The output directory (especially if temporary).
- A one-line note that re-running without `--force` resumes from the first incomplete phase.
