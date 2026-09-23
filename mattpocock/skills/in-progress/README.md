# In Progress

Skills that are still being developed. They're not ready to ship — expect rough edges, breaking changes, and abandoned experiments. They're excluded from the plugin and the top-level README until they graduate to a stable bucket.

- **[loop-me](./loop-me/SKILL.md)**: Grill yourself into implementable workflow specs over multiple sessions, using the current directory as a stateful workspace. User-invoked.
- **[writing-beats](./writing-beats/SKILL.md)**: Shape an article as a journey of beats, choose-your-own-adventure style. Pick a starting beat, write only that beat, then pivot to the next, until the article reaches a natural end.
- **[writing-fragments](./writing-fragments/SKILL.md)**: Grilling session that mines you for fragments (heterogeneous nuggets of writing) and appends them to a single document as raw material for a future article.
- **[writing-shape](./writing-shape/SKILL.md)**: Take a markdown file of raw material and shape it into an article paragraph by paragraph, arguing format choices at each step.
- **[claude-handoff](./claude-handoff/SKILL.md)**: Hand the current conversation off to a fresh background agent that picks up the work immediately, seeded with a handoff summary via `claude --bg`. User-invoked.
- **[setup-ts-deep-modules](./setup-ts-deep-modules/SKILL.md)**: Wire dependency-cruiser into a TypeScript repo so each package is a deep module: implementation hidden in subfolders, reachable only through its entry-point files, tests exercising it through those. User-invoked.
- **[implement-spec](./implement-spec/SKILL.md)**: Implement a whole spec on one branch. Works the tickets as a task graph rather than a list, running implementer subagents across the ready frontier for maximum concurrency, and lands the result as a single PR. User-invoked.
- **[pr](./pr/SKILL.md)**: Reference for the shape a pull request body should take: a summary from the primary source (not the diff), the smallest visual that shows the change, a before/after pair of evidence, what was left out on purpose, and a one-way/two-way door call. Model-invoked.
- **[retro](./retro/SKILL.md)**: Suggest improvements to the coding agent's environment (steering files, coding standards, automated checks, tooling) after a session. STUB: design notes only, not functional yet. User-invoked.
- **[batch-grill-me](./batch-grill-me/SKILL.md)** — Relentless interview that walks the design tree in rounds instead of one question at a time — each round asks the whole frontier of decisions whose prerequisites are already settled, then recomputes from your answers. User-invoked.
