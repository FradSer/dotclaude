# STORM

A Claude Code plugin that ports [Stanford STORM](https://github.com/stanford-oval/storm) (Synthesis of Topic Outlines through Retrieval and Multi-perspective Question Asking) into a Claude-native, zero-dependency skill pipeline.

Given a topic, STORM produces a Wikipedia-style long-form article with inline `[n]` citations and a trailing References list — grounded in web search, not parametric memory.

## Pipeline (two stages, four phases)

```
research  ->  outline  ->  write  ->  polish
  (persona      (draft +     (per-section,      (summary +
   discovery)    refine)      cited)             dedup)
```

Each phase is **independently runnable and resumable** — completed phases are loaded from the artifact directory, mirroring STORM's stage-gated runner.

## Commands

| Command | Purpose |
|---------|---------|
| `/storm:generate` | End-to-end orchestration (runs all four phases, skipping completed ones) |
| `/storm:research` | Phase 1 — persona discovery + simulated Q&A → information table |
| `/storm:outline` | Phase 2 — draft outline from parametric knowledge, refine from research |
| `/storm:write` | Phase 3 — parallel per-section writing with inline citations |
| `/storm:polish` | Phase 4 — summary section + duplicate removal |

## Design (mirrors upstream STORM)

- **Multi-perspective research**: one Task subagent per persona runs the simulated Q&A concurrently.
- **Retrieval**: prefers connected MCP search tools (e.g. exa-mcp-server), falls back to built-in WebSearch + WebFetch.
- **Citation hygiene**: inline `[1][2]` + trailing `References` section; source snippets are citation-stripped before reuse.
- **Stage gating**: each phase writes to a predictable path under the output dir; re-invocation skips completed phases.
- **Cost/quality split**: cheap persona/conversation turns vs. stronger outline/section/polish work (delegated to the strongest available model).

## Artifacts

By default, artifacts live in a temporary directory that is discarded at session end. Pass `--save` (or `--output-dir <path>`) to persist to `docs/storm/<slug>/`:

```
<output_dir>/<slug>/
  research/                 # personas + simulated conversations + sources.json
  outline.md
  article.md
  article-polished.md
  run-config.json
```

## License

MIT. Based on the STORM research framework by Stanford Oval (NAACL'24 / EMNLP'24).
