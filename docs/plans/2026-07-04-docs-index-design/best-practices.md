# Best Practices — Docs Index Convention

## Anti-Bloat Rules

Calibrated to the plugin's existing compactness (`docs/writing-skills/README.md` = 13 lines; top `README.md` uses dense tables, not prose).

### (a) Granularity — one line per *folder*, not per file

The atomic unit of a design/plan is a folder (`*-design/`, `*-plan/`), not the individual files inside (`_index.md`, `bdd-specs.md`, task files, eval rounds). Indexing per-file would explode the line count by 5–10× for zero navigational value — the folder path is the click target, and the folder's own `_index.md` is the per-file table of contents. **One index line = one folder.**

### (b) Summary field width — ≤ 72 chars, single line, no wrapped prose

Matches the conventional-commit subject line discipline the plugin already follows (`git-agent` conventional-format commits). Enforce by truncation with `…`; the summary is a *reminder*, not a substitute for the doc.

### (c) Threshold & collapse rule — hard ceiling of 60 index lines

Rationale: 60 one-line entries at ~100 chars/line ≈ 6 KB, comfortably scannable in under 30 seconds. When the count would exceed 60:

- **First-line defense:** collapse any group of ≥ 3 entries sharing a status of `implemented` or `expired` and a common topic prefix into a single summary line (`... and 4 prior implemented designs in docs/plans/*-auth-* — see git history`). This mirrors the plugin's existing "see `git show docs/retros/checklists/`" deferrals — push detail to git, keep the index as a map.
- **Second-line defense (if still > 60):** drop `expired` entries entirely from the index, leaving their tombstone only in the retro report that expired them (`expired:<reason>` already cites the retro path). The index is a *current-state map*; expired entries are history, and history lives in git.
- **Never collapse** `active`, `wip`, or `superseded-by` entries — those carry live navigational signal.

The `rebuild` subcommand applies the collapse rule automatically on regeneration.

### (d) Infrastructure files — EXCLUDED

`docs/retros/evolution-log.jsonl`, `docs/retros/plans-completed.jsonl`, `docs/retros/checklists/{mode}-v{N}.md`, and `docs/retros/retro-*.md` reports are **not indexed as rows**. The retro *report* (`retro-*.md`) IS indexed (as `kind=retro`) — but the machine-generated channels are not. Reasons: (1) they are machine-generated with their own canonical readers (the retrospective skill reads `evolution-log.jsonl` directly; the Stop hook writes `plans-completed.jsonl`); (2) indexing them would double-count a signal that already has a durable home; (3) checklist versions are append-only history, not navigable docs — `git show docs/retros/checklists/` is already the plugin's chosen review surface. The index covers *human-authored design/plan/retro artifacts* only.

### (e) Checklist version files (`design-v1.md`, `design-v2.md`...) — NOT indexed individually

The checklist lineage is not a navigable doc; it's the retrospective skill's audit trail, reachable via `git show docs/retros/checklists/`. The index covers design/plan/retro *folders* only. A retro report folder (if retrospectives ever produce a folder rather than a single `retro-*.md` file) would get one row as `kind=retro`.

## Status Taxonomy — Transition Rules

For each status, "who can set it" maps to the four skills; "terminal" means no skill may transition away from it without manual `--force` intervention (mirrors the plugin's `--force` override convention on bail-out checks).

| Status | Who can set | From which prior states | Terminal? | Notes |
|---|---|---|---|---|
| `wip` | brainstorming, writing-plans, executing-plans | (new entry), `active`, `implemented:<sha>` | No | Set on a partial/mid-pipeline commit (rare). Default for a completed artifact is `active`, not `wip`. |
| `active` | brainstorming, writing-plans | `wip` | No | The artifact is the current source of truth for its topic. |
| `implemented:<sha>` | executing-plans | `wip`, `active` | No (see Rework After Ship) | The `<sha>` is the completion commit's short SHA. Marks "shipped." |
| `superseded-by:<path>` | brainstorming (the newer design's run), retrospective | `active`, `wip` | Yes (default) | Set when a newer doc on the same topic is committed. Resurrection only via retrospective re-promotion. |
| `expired:<reason>` | retrospective only | `active`, `wip` | Yes (default) | The reason MUST cite the retro report path. Only retrospective can set this — never the other three skills — because expiry requires cross-plan evidence. |
| `reference` | retrospective, `rebuild` (seed) | (new entry) | Sticky (constrained — see below) | Evergreen reference doc (e.g., `docs/writing-skills/`). |

### Edge cases

**Can a doc go `expired` → `active` again (resurrection)?** Yes, but ONLY via retrospective. Rationale: expiry is retrospective-only by the table above; symmetry says resurrection is also retrospective-only. The retro report must contain an explicit `revalidates: <path>` line with new evidence. This is rare and deliberate — it models "we thought approach X was wrong, but a later retro with new data reversed that judgment." The retro's Pre-Check B (recall persistent memory) and Phase 1 step 5 (evolution history) already encode the same "don't re-propose without materially new evidence" guard — apply it here too: no resurrection unless the new retro evidence is materially different from the expiry rationale.

**Can `implemented:<sha>` flip back to `wip` (rework after ship)?** Yes (Scenario 15). When executing-plans is re-invoked on a plan folder whose index entry is `implemented:<old-sha>`, it MUST flip the entry to `wip` before spawning batch 1 — this prevents a stale "implemented" signal from misleading a concurrent brainstorming run. On re-completion it sets `implemented:<new-sha>`. The old `<sha>` is lost from the index (recoverable via git); this is acceptable because the index tracks current state, and git tracks history.

**Is `reference` ever mutable?** Mutability is constrained, not forbidden. The *status* `reference` is sticky — once a doc is demoted to `reference`, it does not flip back to `active` (that path goes `reference` → `expired` → retro-resurrection → `active`, never `reference` → `active` directly). However, the *summary line* of a `reference` entry may be edited by retrospective if the retro's findings reframe what the reference teaches. The other three skills may NOT edit a `reference` entry's summary — they lack the cross-plan evidence to reframe it. This keeps `reference` as a curated, slow-moving section rather than a mutable scratchpad.

**`superseded-by` vs `expired` — what's the difference?** `superseded-by` means "a newer doc on this topic exists and is authoritative" — a positive replacement. `expired` means "this doc's conclusions are wrong/invalidated and there may or may not be a replacement" — a negative judgment. A doc can be both (set `superseded-by` first when the replacement lands, then `expired` later if the retro independently concludes the old approach was wrong); in that case `expired` wins as the displayed status and `superseded-by` is preserved in the reason string. This ordering matters: brainstorming can set `superseded-by` (it knows about the new doc) but only retro can add `expired`.

## Retro-Invalidation Signal Boundary

**The concrete rule:** a prior design/plan entry is marked `expired:<reason>` if and only if the retrospective report contains an explicit, machine-grep-able line of the form:

```
invalidates: <repo-relative-path-of-prior-doc>
```

(One such line per invalidated doc; multiple lines allowed for batch invalidation.) The path MUST already exist in the index — no speculative expiry of docs that aren't tracked.

Everything else in a retrospective output — including a Phase 3 `REMOVE` proposal on a checklist item, a Phase 5a post-plan-correction finding, a Phase 5b usage recommendation, or a narrative "the approach in design X was suboptimal" remark — does **NOT** justify expiry. Rationale, mapped to the plugin's existing signal discipline:

- **A `REMOVE` proposal on a checklist item** removes a *checklist line* (`{mode}-v{N+1}.md`), not a design doc. The retro skill itself draws this boundary: Phase 4 writes new checklist versions, not design-folder edits. Conflating the two would let a checklist cleanup silently rewrite design history — exactly the kind of "silently corrupt the next run" failure the plugin guards against in its evolution-log warnings.
- **A Phase 5a post-plan-correction finding** (e.g., "the plan missed a CODE-CONTRACT check") is evidence for a *new checklist item* (ADD proposal), not evidence that the *design* was wrong. The design may have been correct; the checklist was incomplete. These are different failure surfaces.
- **A narrative remark** ("approach in design X was suboptimal") is non-grep-able and non-authoritative — it would let an LLM's phrasing trigger history rewrites. The plugin's own `/goal` docs warn that the evaluator "does NOT read files or run commands" and that conditions must be phrased against *literal narrated output*; the same discipline applies here — require a literal `invalidates:` line, not an interpretation.

**Why this boundary is load-bearing:** The retrospective's Phase 3 already has thresholds (ADD = 2+ plans, REMOVE = 3+ reports) precisely to prevent cheap triggers from rewriting durable state. Expiry is an even stronger mutation — it rewrites how *other* skills treat a doc on every future consult. So its trigger must be (a) explicit (a grep-able line, not inference), (b) authored by retrospective only (the skill that holds cross-plan evidence), and (c) cited with the retro report path so the entry's `expired:<reason>` field is auditable via `git show docs/retros/retro-*.md`.

### Boundary cases that fall on the *non*-expiring side (left as `implemented:<sha>` historical)

- Retro concludes a plan was over-scoped → not invalidation, it's a process note.
- Retro's REMOVE proposal drops a checklist item that the design referenced → the design's *checklist pointer* is stale, not the design's conclusions; the index entry stays `implemented` and the design file itself is untouched.
- Retro surfaces a post-plan `fix:` commit correcting a bug the plan introduced → the *code* was fixed in-flight; the design's approach may still be valid. This is Phase 5a ADD-signal territory, not expiry.
- Retro recommends a future MODIFY to a checklist → advisory, not invalidation.

### Boundary cases that DO justify `invalidates:`

- Retro report's analysis explicitly concludes the design's central approach is wrong and a replacement exists or is mandated — e.g., "design X's sliding-window refresh is invalidated by the cache-stampede incident (see retro-2026-06-12 §Analysis); auth-model-v2 supersedes it." The retro author writes `invalidates: docs/plans/2026-06-12-auth-design` and the index entry flips to `expired:retro-2026-07-04:wrong-abstraction`.
- Retro finds that a design's BDD scenarios are unverifiable against the shipped code in a way that makes the design actively misleading to future readers — explicit `invalidates:` line warranted.

### Safeguard: path must be tracked

The `invalidates:` line MUST name a path that already exists in the index. If the path is absent, `set-status` exits 3 (not in index), the retrospective logs a warning, and skips the expiry — mirroring the retro's existing self-rejection pattern for proposals that contradict recalled priors (Phase 4 "proposals_rejected").

## Reference Entries

`docs/writing-skills/` is the canonical reference entry. On first `rebuild` (or the first `upsert` that creates `docs/README.md`), the script seeds it as:

```
| docs/writing-skills/ | retro | reference | Evergreen skill-authoring references (Anthropic best practices, persuasion, testing) | <date> |
```

The `kind=retro` is a slight stretch (it's not a retro report), but `retro` is the catch-all for "non-design, non-plan doc artifact" and `reference` makes its lifecycle unambiguous. Its own `docs/writing-skills/README.md` remains the per-file reference; the top-level index just points at the folder.

A `reference` entry is never flipped to `expired:` or `superseded-by:` (see Status Transitions above and Scenario 10). It is, however, eligible for summary edits by retrospective if a retro reframes what the reference teaches.

## Security

- **No remote execution**: `lib/docs-index.sh` reads/writes only within `${repo_root}/docs/`. It does not invoke `curl`, `wget`, or any network tool. Safe under the plugin's Bash() scoped-tool model.
- **No shell injection from row content**: the `summary` field is passed via `--summary "<value>"` and the script treats it as data (quoted, never `eval`'d). Long summaries are truncated to 72 chars before write.
- **Path validation**: `<path>` args are validated to be repo-relative and to not contain `..` (no traversal outside `docs/`). The script refuses paths starting with `/` or containing `..`.
- **Atomic writes**: writes go to `docs/README.md.tmp.$$` then `mv` over the target — POSIX atomic rename. A crash mid-write leaves either the old or the new file, never a torn half-table.

## Performance

- **`list`/`show`**: O(n) scan of `docs/README.md` where n = row count (≤ 60 after collapse). Sub-millisecond for any realistic n.
- **`upsert`/`set-status`**: O(n) scan + atomic rewrite. Sub-millisecond.
- **`rebuild`**: O(m) where m = folder count under `docs/plans/` + `docs/retros/`. Fast for any personal-plugin scale.
- **No `jq` dependency**: the script parses pipe-delimited markdown with `awk`/`grep` only (requirement #13). The plugin already degrades gracefully when `jq` is absent; the index must not reintroduce a hard `jq` dependency.

## Common Pitfalls

- **Forgetting the consult-before step.** The most likely failure mode: a skill skips `list`/`show` and upserts blindly, missing a prior `expired:` design on the same topic. Mitigation: the consult-before touchpoint is in each skill's Initialization (the earliest phase), and the BDD Scenario "Every mutating skill consults before it mutates" enforces it.
- **Upserting per-file instead of per-folder.** A future maintainer might "improve" the script to index `_index.md` and `bdd-specs.md` separately. Don't — it violates the anti-bloat granularity rule (a) and offers no navigational value. The folder is the unit.
- **Using `--amend` to capture the SHA in the same commit.** Tempting (Option A in `architecture.md` §Commit-Ordering) but `--amend` rewrites history and confuses the Stop hook's `completion_commit` detection. Use a dedicated tiny index commit instead (Option B).
- **Bulk-expiring by date.** A future maintainer might add a `expire --before <date>` subcommand for "spring cleaning." Don't — it bypasses the explicit `invalidates:` boundary and would silently expire docs that a retrospective never actually examined. Expiry is always per-`invalidates:`-line, never bulk-by-date.
- **Free-text statuses.** A future maintainer might add a `status=blocked` or `status=needs-review`. Don't — add to the controlled vocabulary in `architecture.md` §Status Taxonomy first, with a transition rule here. Free-text statuses drift and lose queryability.
- **Letting brainstorming set `expired:`.** Only retrospective holds cross-plan evidence. Brainstorming may set `superseded-by:` (it knows about the new doc) but never `expired:` (it hasn't done the cross-plan analysis). The transition matrix enforces this.
- **Indexing infrastructure `.jsonl` files.** A future maintainer might index `evolution-log.jsonl` for "completeness." Don't — it's a machine audit trail with its own reader; indexing it double-counts the signal and bloats the index.
- **Skipping the collapse rule on `rebuild`.** If `rebuild` doesn't apply the 60-line ceiling, the index grows unbounded. The collapse rule is part of `rebuild`'s contract, not optional.

## Testing Strategy

- **Unit tests** (`tests/test-docs-index.bats` or equivalent bash test harness): each subcommand, each exit code, each transition in the matrix, idempotent upsert, malformed-index degradation, controlled-vocab rejection (Scenario Outline examples), path validation (reject `..` and leading `/`).
- **Property tests**: `upsert` is idempotent (running it N times leaves exactly one row); `set-status` on a rejected transition leaves the index byte-identical; `rebuild` is idempotent (running it twice produces the same file).
- **Integration tests**: run each of the 4 skills' touchpoints end-to-end on a temp repo, assert the index row appears/flips as specified in the BDD scenarios.
- **Regression test for the invalidation boundary**: a retro report with a `REMOVE` proposal but no `invalidates:` line must NOT change any design/plan row (Scenario: "A retrospective REMOVE proposal does not invalidate a design").
