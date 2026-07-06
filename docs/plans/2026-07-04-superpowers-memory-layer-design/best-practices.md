# Best Practices — Superpowers Memory Layer (`kind=memory`)

## Anti-Bloat Rules — Memory Extension

These extend, not duplicate, the five rules already shipped in `docs/plans/2026-07-04-docs-index-design/best-practices.md` §Anti-Bloat Rules (a)–(e).

### (f) Granularity for memory — one file = one distilled fact, decision, convention, or pitfall

Mirrors rule (a)'s "one line per folder" at a finer grain: the atomic unit here is a single reusable insight, never a whole skill run, a whole retrospective, or a bundle of unrelated observations. A memory file that packs three unrelated pitfalls under one slug both violates this rule and breaks the one-line-pointer economics — the `docs/README.md` row can only summarize one concept per line.

### (g) Write gates are rare by design — the primary anti-bloat mechanism

Each of the five skills writes memory only on its own pre-existing escalation threshold, never on routine success:

| Skill | Write-gate trigger | Not a new threshold — already exists at |
|---|---|---|
| brainstorming | 2+ evaluator REWORK rounds on a design | `skills/brainstorming/SKILL.md` "REWORK 2+ rounds: consider pivoting" |
| writing-plans | A Phase 4 reflection sub-agent FAIL requiring rework | `skills/writing-plans/SKILL.md` Phase 4 "fix the offending plan files ... rerun the affected sub-agent" |
| executing-plans | The intra-plan-learning "variety gap": all items PASS but the batch took 2+ rework rounds | `skills/executing-plans/references/intra-plan-learning.md:54` — deliberately distinct from `batch-execution-playbook.md:165`'s separate "max 2 rounds before escalation" hard-abort cap, which is retained as run-time flow control only |
| systematic-debugging | 3+ failed fixes ("question architecture"), or an explicit cross-cutting gotcha | `skills/systematic-debugging/SKILL.md` "Architecture Questioning After 3+ Failed Fixes" |
| retrospective | Existing ADD (2+ plans) / MODIFY (2+ false positives) thresholds — REMOVE/PROMOTE excluded | `skills/retrospective/SKILL.md` Phase 3 proposal-threshold table |

This is a direct reapplication of the plugin's own established anti-add-bias norm — see `docs/retros/retro-2026-07-04-docs-index-plan.md`, which self-rejected two ADD proposals this week for having only 1-plan evidence. The memory layer's write gates borrow the same discipline: a threshold that fires cheaply produces noise, not signal.

### (h) Consolidation as first-line defense

Extends rule (c)'s first-line collapse. When 2+ memory files address the same concept, they are MODIFY-merged into one file (see `bdd-specs.md` Scenario 14) rather than left to pile up — this shrinks the *working set* of live memory files before the 60-line table math ever engages the shared ceiling. Consolidation is retrospective's responsibility, using the same 2+-instance threshold shape as its existing MODIFY trigger. The absorbed file's row is flipped to `expired:superseded-by-consolidation:<survivor-path>` before it is dropped — never deleted with no terminal-state record.

### (i) Archive-and-drop as second-line defense

Extends rule (c)'s second-line "drop expired entries entirely" rule. For `kind=memory` specifically, dropping the row is paired with physically moving the file to `docs/memory/archive/` (see `bdd-specs.md` Scenario 15) — the counterpart correction to how design/plan rows can drop their row while the folder's content stays on disk under `docs/plans/`. A bare memory file with no row pointing at it would be an easy-to-lose orphan; archiving keeps it discoverable while it leaves the active index. `rebuild`'s memory scan is a plain, non-recursive `docs/memory/*.md` glob, so archived files are never re-added.

## Security

- **Trust boundary**: `docs/memory/*.md` files are git-committed and shared with every teammate who checks out the repo/branch — the same trust boundary as `docs/plans/` or `docs/retros/`, and a stricter boundary than the private, harness-local global memory some facts may be promoted from.
- **MUST NOT contain**: secrets, API keys, tokens, credentials, internal hostnames/URLs not otherwise public, or PII (names, emails, user data drawn from real incidents/tickets).
- **Who checks, and when**: the writing skill, at write time. Whichever of the five skills' write-gate fires is responsible for reviewing its own drafted memory content for secret-shaped or PII-shaped strings before invoking the upsert — mirroring the plugin's existing stance that validation happens at the point of mutation, not as a downstream audit pass.
- **No new script-level enforcement is proposed.** A generic secret-shape regex in `lib/docs-index.sh` would false-positive constantly on legitimate technical content (SHA hashes, example config values, sample tokens in a "pitfall" writeup) — this is deliberately left as an authorial responsibility of the writing skill, not a mechanical gate.
- **Promoted facts (retrospective's global-memory bridge) get the same scrutiny.** A prior recalled from the private, harness-injected memory may itself have been written casually (an assistant note across an arbitrary conversation); promoting it into a git-tracked file does not waive the no-secrets/no-PII rule — if anything it is the one path most likely to accidentally carry over something never intended for a shared repo, so retrospective reviews promoted content with the same care as freshly-authored content.

## Common Pitfalls — Memory-Specific

- **#1 anti-pattern: writing a memory on every routine success.** The single most important thing to explicitly warn against. If a skill writes memory on first-pass PASS, the index accretes one row per run instead of one row per genuinely reusable insight, defeating rule (g) above and eventually forcing the 60-line collapse/drop machinery to do the pruning that gating should have done up front. `bdd-specs.md` Scenarios 9-13 are the regression tests for this.
- **Duplicating what git history or CLAUDE.md already records.** Mirrors the assistant's own memory-hygiene rule — "don't save what the repo already records." If a fact is fully recoverable from a commit message, a retro report, or something already stated in `CLAUDE.md`, it does not need its own `docs/memory/` file; memory exists for insights that are *not* already durably written down somewhere the five skills would naturally consult.
- **Multi-fact dump files.** See rule (f) above — a memory file bundling several unrelated pitfalls under one slug both breaks the one-file-one-fact discipline and can't be summarized in a single `summary` column value.
- **Skipping consolidation and letting near-duplicate memories accumulate.** Two files that say almost the same thing in different words are a MODIFY-merge candidate (Scenario 14), not two permanent rows — retrospective should actively scan for this rather than only reacting when the 60-line ceiling forces the issue.
- **Treating memory as a second checklist.** Memory captures reusable facts/decisions/conventions/pitfalls for *reading* skills to consult before they act; it is not a duplicate enforcement mechanism for retrospective's own checklist evolution (`docs/retros/checklists/`). Checklists gate evaluator PASS/FAIL; memory informs upfront reasoning. Conflating the two would double-write the same signal into two systems with different consumers.
- **Reusing `type` or `kind` as the per-file frontmatter field name.** Both words are already reserved by the index row schema; a memory file's classification field is always `category` (see `_index.md` Glossary) — a future contributor "helpfully" renaming it back to `type` (to match the assistant's own memory schema) would silently create a second, colliding vocabulary in the same feature.
- **Giving a memory row `status=reference`, `wip`, `implemented:<sha>`, or `superseded-by:<path>`.** These are all rejected by the script (see `bdd-specs.md` Scenario 19) — a contributor porting logic from the design/plan touchpoints without adjusting for `memory`'s narrower status subset is the most likely way this mistake gets introduced; the `validate_status_for_kind` check in `architecture.md` exists specifically to catch it at write time rather than relying on review to catch it.

## Status-Transition Notes for `kind=memory`

`kind=memory` rows use only two of the six shared status values — `active` and `expired:<reason>` — enforced by the script, never `wip`, `superseded-by:<path>`, or `reference`:

| Status | Applies to memory? | Justification |
|---|---|---|
| `active` | Yes (default) | The only "in force" state; memory writes are single-turn, atomic artifacts (`bdd-specs.md` Scenario 18), so there is no meaningful partial/mid-pipeline state to represent. |
| `expired:<reason>` | Yes | Covers two cases: (1) a retro concludes a captured fact was wrong or is stale, and (2) consolidation tombstones the absorbed file of a merge (Scenario 14) before it is dropped. Reusing the shared `expired:` vocabulary here means the parameterized-value parsing is fully reused — only the *set of allowed statuses* narrows for this kind, not the syntax. |
| `wip` | No — rejected, exit 2 | Memory is never drafted across multiple turns the way a design is — the write-gate fires once, fully formed, at the end of a skill's threshold check. A `wip` memory row would imply a half-written insight nobody should consult yet, which the gate design doesn't produce. |
| `superseded-by:<path>` | No — rejected, exit 2 | Design/plan supersession is a *positive replacement* — a newer independent doc exists and the old one stays as a historical pointer. Memory consolidation is different: when two files address the same concept, the absorbed file's row is tombstoned as `expired:` then dropped outright (Scenario 14), never left pointing at a survivor. Keeping only `expired:` avoids a second terminal-state family that would need its own transition rules for no added value. |
| `reference` | No — rejected, exit 2 | `reference` is reserved for evergreen, non-expiring reference bundles (`docs/writing-skills/`). Memory's entire design premise is the opposite — entries are expected to expire, get superseded by consolidation, or get archived. Giving memory files `reference` status would blur two lifecycle concepts the shipped taxonomy deliberately keeps apart. |
| `implemented:<sha>` | No — rejected, exit 2 | Reserved for plans that ship code; a memory fact isn't "implemented," it's simply recorded. |

This restriction is enforced in `bdd-specs.md` Scenario 19 as a negative-transition matrix, matching the base spec's existing style for `implemented`/`superseded`/`expired`/`reference`, and is script-level (via the new `validate_status_for_kind` function in `architecture.md`), not a documentation-only convention.

## Testing Strategy Additions

- **Unit tests**: `validate_kind` accepts `memory` and rejects everything else with the extended vocabulary in its diagnostic; `default_status_for_kind` maps `memory` → `active` (matching the existing `retro` → `active` precedent, not the `design`/`plan` → `wip` default); the new `validate_status_for_kind` rejects `wip`/`implemented:<sha>`/`superseded-by:<path>`/`reference` for `kind=memory` with exit 2, and accepts `active`/`expired:<reason>`; category validation on a `kind=memory` upsert (missing/invalid/reserved-word category exits 2, no file and no row written — Scenario 16, including the `reference` case specifically).
- **Collapse-grouping test**: `collapse_rows`/`topic_of_path()` groups `kind=memory` rows by their no-date-prefix fallback (effectively by `category`-bearing summary text) rather than by the `docs/plans/YYYY-MM-DD-` folder-topic heuristic, since flat `docs/memory/<category>_<slug>.md` paths carry no date prefix to strip — this needs its own dedicated unit test rather than assuming the existing single-row (`docs/writing-skills/`) fallback path transfers cleanly to a multi-row case (Scenario 17).
- **Consolidation test**: two memory files on the same concept merge into exactly one file and one row in a single operation (Scenario 14); the absorbed file's row is tombstoned to `expired:superseded-by-consolidation:<path>` then dropped, and the survivor's `summary`/`updated` fields are refreshed.
- **Expiry/archive test**: an `expired:<reason>` `kind=memory` row's file is moved to `docs/memory/archive/` (created on first use) and the row is dropped from `docs/README.md` in the same operation (Scenario 15); `git status` confirms the move is tracked as a rename, not a delete; a subsequent `rebuild` does not resurrect the row.
- **Integration tests**: each of the five skills' memory-read touchpoint (`list --kind memory --status active` at Initialization) and each skill's write-gate firing/not-firing per its own threshold (Scenarios 4–13), run end-to-end on a temp repo exactly as the base spec's Integration Tests section already does for the four original touchpoints.
- **Regression test — systematic-debugging's contract**: a run where the memory write-gate fires still narrates exactly the three-part completion output (root-cause one-liner, fix diff summary, regression-test path) with no additional phase or commit (Scenario 18) — protects against the memory layer silently growing into a new deliverable obligation for the one skill that previously had none.
