# harness-evidence channel — design

**Date**: 2026-05-09
**Type**: implementation design
**Predecessor**: `docs/retros/2026-05-09-v3-considered-deferred.md` §4 condition 2

## Context

This channel exists at the intersection of two independent triggers converging on 2026-05-09: (1) the maintainer surfaced a recurring need to capture content the existing superpowers pipeline drops on the floor — between-session scratch notes, file changes the user wants flagged after a session ends, prose recap of what just happened — that current channels do not absorb; (2) the v3.x knowledge-platform reject-form retrospective at `docs/retros/2026-05-09-v3-considered-deferred.md` §4 condition 2 explicitly designated a `harness-evidence.jsonl` channel as the activation gate's evidence corpus, but shipped no writer for it. The same artifact resolves both: a single append-only NDJSON channel writing 3 event types at every Stop hook, consumed by retrospective Phase 1 as un-distilled evidence rows.

This channel is condition 2 of the v3 retro activation gate, **not** the activation. The v3 retro forbids bundling the gate's own infrastructure into v3.x scope: "must each be independently brainstormed with their own retract triggers" (§4). Building this channel does not satisfy the gate — conditions 1 (≥3 projects), 3 (read-rate evidence), and 4 (`meta-retrospective` skill) remain open. Whether v3.x ever activates is a separate decision deferred to its own future brainstorm session.

**Channel topology**:

```
Existing Phase 0 channels:
  bail-out-events.jsonl       <- bail-log.sh         (skill bail / --force events)
  plans-completed.jsonl       <- loop.sh             (plan completion + dedup gate)
  evolution-log.jsonl         <- Claude (manual)     (retrospective_run + proposals)
  harness-observations.jsonl  <- Claude (manual)     (Phase 5c disable test outcomes)
  post-plan-diff (no jsonl)   <- post-plan-diff.sh   (commits classified on demand)

New (this design):
  harness-evidence.jsonl      <- Stop hook + Sonnet  (3 event types; consumed by
                                                      retrospective Phase 1 step 8)
```

This channel is the only Phase 0 channel whose writer fires on every Stop hook (rather than a specific lifecycle verb), and the only one whose primary upstream is user prose rather than a deterministic harness event.

## Discovery Results

**Already exists (reusable, do not rebuild)**:
- `superpowers/lib/bail-log.sh` — append-only NDJSON writer with sourceable + CLI dual mode; reference for `harness-evidence.sh`
- `superpowers/lib/loop.sh:_loop_log_plan_completion_if_executing` (lines 32-113) — `git rev-parse --show-toplevel` resolution + `>>` jsonl append; canonical Stop-hook-write pattern
- `superpowers/lib/post-plan-diff.sh classify` — file-path → `feedback|evolution|unknown` classifier; reused by reader on demand
- `superpowers/lib/utils.sh:run_haiku_merge` (lines 254-271) — sourceable Haiku invocation with `SUPERPOWERS_MERGE_SESSION=1` recursion guard; `_run_sonnet_recap` mirrors this with model swap
- `superpowers/lib/vet.sh:_vet_synthesize_final_task` (lines 103-128) — already produces a 1-sentence Haiku recap into `state.task`; harness-evidence reads it verbatim, never recomputes
- `superpowers/hooks/stop-hook.sh` — extension point already wired (loop_phase → vet_phase ordering)
- Retrospective Phase 1 currently has 7 numbered data-collection steps; step 8 insertion (between current 7 and 8) matches existing structure exactly
- Retrospective already implements "未处理 vs 已处理" two-state semantics implicitly: `evolution-log.jsonl` last `retrospective_run.timestamp` defines the cutoff (`superpowers/skills/retrospective/SKILL.md:55`)

**Missing (must be built)**:
- No persistent channel today absorbs user-side input — every existing channel writes deterministic harness events
- No Sonnet invocation pattern in any existing Stop hook (only Haiku via `vet.sh`); harness-evidence establishes the Sonnet 200-500 word budget pattern
- No retract-trigger monitoring for any channel; v3 retro §6 T1-T4 pattern is documented prose but no script polls thresholds

**Known cross-channel inconsistency (respected, not fixed)**:
- `bail-log.sh` writes to `$PWD`-relative path (`bail-log.sh:39`); `loop.sh` writes to `git rev-parse --show-toplevel`-relative path. harness-evidence.sh follows the `loop.sh` pattern. Fixing `bail-log.sh` is a separate v2.x.y patch (YAGNI).

## Glossary

| Concept | Canonical label | Rejected variants |
|---|---|---|
| The jsonl file as a stream | **channel** | inbox, fragment store, capture log, evidence corpus (the last is reserved for v3-retro-facing prose) |
| One jsonl line | **row** (interchangeable with **event** when referring to its `event` field) | line, entry |
| Write timing | **Stop hook** (mechanism), **session** (user-facing) | stop-event |
| Read-time aggregation | **distill** | summarize, consolidate, process |
| Channel sunset action | **retract** | deprecate, sunset, disable |
| Sonnet failure path | **fallback=true field on session_recap** | new error event type (rejected: violates 3-event lock) |
| Reader cutoff | **timestamp comparison against `evolution-log.jsonl` last `retrospective_run.timestamp`** | `distilled_at` field on rows (rejected: violates append-only) |

The vocab-divergence symptom that contributed to v3.x deferral (v3 retro §2 privacy-tier divergence across 3 sub-agents) is the failure mode this glossary blocks.

## Requirements

12 IDs total, 9 substantive concerns (FR-006 is a discipline rule on FR-001; NFR-007 and NFR-008 share the latency-budget reasoning; SC-010/011/012 are tightly coupled). All requirements use `REQ-NNN` ID for traceability into `bdd-specs.md`.

### Functional

- **REQ-001 (FR Writer)**: `superpowers/lib/harness-evidence.sh` provides sourceable + CLI dual-mode functions `emit_session_recap`, `emit_v3_friction`, `emit_file_change_summary`, each appending one NDJSON row to `<git_root>/docs/retros/harness-evidence.jsonl`. All rows carry wrapper fields `{schema_version: 1, event, timestamp (ISO 8601 UTC), git_root, session_id, skill_name}` plus event-specific fields.
- **REQ-002 (FR Stop-hook integration)**: Every Stop hook invocation calls `emit_session_recap` after `loop_phase` returns and before `vet_phase` runs. Empty-session filter: `task=="" AND modified_files==[] AND pending_prompt==""` → silent skip, exit 0. The Sonnet recap call runs sequentially (parallelization deferred — see REQ-007).
- **REQ-003 (FR File change reference)**: `emit_file_change_summary` fires inside `_loop_log_plan_completion_if_executing` after the `plan_completed` jsonl write. Records `{completion_commit, files: [{path}, ...]}`. **Path-only storage**; reader calls `post-plan-diff.sh classify` on demand at distill time.
- **REQ-004 (FR Retrospective reader)**: Retrospective Phase 1 inserts a step 8 (renumbering existing 8/9 to 9/10) that reads `harness-evidence.jsonl` rows with `timestamp > <last evolution-log.jsonl retrospective_run.timestamp>`. Buckets by `event`: `v3_friction` rows pass through to Phase 5a verbatim; `session_recap` rows are distilled by Haiku via `run_haiku_merge`; `file_change_summary` rows are cross-correlated with `plans-completed.jsonl` to surface untracked completions.
- **REQ-005 (FR Retract trigger)**: Three triggers, all surface via AskUserQuestion in the retrospective report; never auto-disable.
  - **T3 calendar**: today ≥ 2027-05-09 → mark "harness-evidence T3 age-out reached, AskUserQuestion to confirm retract"
  - **T4 read-rate**: rolling 30-day window where retrospective reports contain zero `harness-evidence` substring references → mark T4 trigger
  - **T5 writer reliability**: 30-day rolling `fallback=true` ratio > 5% on `session_recap` rows → mark T5 trigger
  - When multiple triggers fire in one retrospective run, emit one coalesced AskUserQuestion listing all reasons
- **REQ-006 (FR Schema versioning)**: All rows carry `schema_version=1`. Reader tolerates unknown fields (forward compat). Adding a 4th event type requires a new brainstorm cycle (audited by REQ-012).

### Non-functional

- **REQ-007 (NFR Stop-hook latency budget)**: Sonnet recap call adds ~600-1500 ms (streaming) per non-empty Stop. v0 ships sequential; backgrounded async deferred until telemetry shows pain. Concrete ms regression numbers vs. v2.8.2 baseline are recorded into the retrospective by Phase 1 step 8 itself, not fabricated here (deliberately avoiding v3 retro §1 NFR-01 fabricated-numbers failure mode).
- **REQ-008 (NFR JSONL durability + size)**: Writer uses bare `>>` redirect with single-write of pre-rendered jsonl line ≤ ~1.2 KB (well under 4 KiB POSIX `O_APPEND` atomicity guarantee). Daily volume estimate at N=10 sessions ≈ 13 KB/day → ~5 MB/year. Rotation deferred to future-work; revisit only if a project hits 50 MB.
- **REQ-009 (NFR Sonnet failure fallback)**: When `_run_sonnet_recap` returns empty (timeout, network, auth missing), `emit_session_recap` writes a row with `fallback=true` and copies `recap_paragraph` from the existing `state.task` field (vet.sh's already-produced Haiku 1-sentence). No new event type; no skip.

### Success Criteria

- **REQ-010 (SC channel justification)**: Across ≥3 projects after 30 days of use, retrospective Phase 1 has consumed ≥1 un-distilled row per project. If 0 rows consumed in 30 days, T4 trips. **This is the channel-survival criterion**, not a usage-quality one.
- **REQ-011 (SC writer correctness)**: Across the same 30-day window, `fallback=true` row count / total `session_recap` row count < 5%. Above 5% trips T5 — Sonnet integration is too unreliable to keep, channel re-architects or retracts.
- **REQ-012 (SC no add-bias replication)**: 30-day audit shows the channel has not silently grown beyond its 3 declared event types. Auditable via `jq -r .event harness-evidence.jsonl | sort -u` returning at most `{file_change_summary, session_recap, v3_friction}`.

**Explicit non-criteria** (called out to prevent v3 retro §1 SC-circular failure mode): we do not measure "% of recaps that produce useful proposals", "% of friction events that map to existing checklist items", or "user satisfaction with recap quality". Those criteria assume the channel has earned its weight; the SCs above test whether the channel earned the right to make such measurements at all.

## Risks

| Risk | Mitigation (concrete action) |
|---|---|
| Raw user prose in recap may contain credentials, customer data, internal URLs | best-practices.md §Operational warnings prints a verbatim warning instructing user to add `docs/retros/harness-evidence.jsonl` to `.gitignore` before first Stop hook fires; v3 retro §5 records why no sanitizer ships |
| Sonnet network dependency on Stop hook critical path | `_run_sonnet_recap` sets timeout to 8s; on non-zero exit, write `fallback=true` row using state.task verbatim; do not retry |
| jsonl growth past 50 MB makes git operations slow | Rotation deferred; T4 retract trigger surfaces before growth becomes painful at typical N=10 session/day |
| Schema growth bias (4th event type smuggled in via Sonnet output) | REQ-012 30-day audit greps `jq -r .event \| sort -u` against the 3-allowlist; CI test asserts only allowed event values |
| `bail-log.sh` `$PWD` vs. harness-evidence `git_root` divergence confuses operators | best-practices.md §Known issues documents the asymmetry; harness-evidence header comment cites `loop.sh` as canonical precedent |
| Recap text exceeds 500 words and bloats jsonl | `_run_sonnet_recap` truncates output at 500 words before append; helper rejects upstream prose > 4 KiB before write |
| First-run project has no `evolution-log.jsonl` so cutoff timestamp is empty | Reader falls back to "process all rows"; semantically correct for first-retrospective state |

## Rationale

| Option | Description | Verdict | Reason |
|---|---|---|---|
| A: Inline into existing channel | Write recaps to `bail-out-events.jsonl` or `plans-completed.jsonl` | Reject | Conflates event semantics; bail-log is for bail-out events specifically (Phase 5a aggregator counts (skill, event) pairs), plans-completed is per-plan-completion ledger. Cross-purpose data corrupts both reader assumptions. |
| B: Wait for v3.x activation gate to satisfy itself | Don't build until ≥3 projects produce friction signals organically into nothing | Reject | The activation gate (v3 retro §4 condition 2) explicitly references this file. Without a writer the condition is structurally un-satisfiable. The retro called this out: "must be independently brainstormed with their own retract triggers." This design is that independent brainstorm. |
| **C: This design** | Build minimal channel as condition-2 substrate, scope = recap + friction + file-change-ref only, single writer, single reader, single jsonl | **Accept** | Single-purpose, append-only, path-only. Reuses `post-plan-diff classify` and `run_haiku_merge`. Sonnet recap parallel to Haiku merge is a small isolated extension to the established Stop-hook pattern. Retract triggers honor v3 retro §3 (never auto-disable, AskUserQuestion only). |
| D: Build full v3.x scope (4 quadrants × 3 phases × 28 requirements) | What `2026-05-09-knowledge-platform-design/` originally elaborated | Reject | v3 retro §1 + §2 + §6 catalog the failure modes explicitly: N=0 add-bias, vocab divergence, structural replication of v2.8.x mistake. v3 retro §6: "do not advance v3.x inside any conversational arc that produces v2.8.x or v2.9.x retract patches." |

C is constrained on both sides: rejected B because the gate cannot self-satisfy, rejected D because the gate exists precisely to delay D.

## Don't-do path

Each item maps to a v3 retro §5 conflict-table row.

- **No PostCommit hook.** v3 retro §5 lists it as a v3.x mechanism not currently registered.
- **No `~/.claude/projects/<project-key>/knowledge/` directory.** v3 retro §5: "Does not exist; no creator." Channel writes only to `<git_root>/docs/retros/harness-evidence.jsonl`.
- **No `lib/knowledge-write.sh`.** Writer is `lib/harness-evidence.sh` with three append verbs.
- **No `lib/sanitizer.sh` / no credential scanning.** Path-only file storage means no diff bodies. User-pasted secrets in `v3_friction` description are out of scope (recap prompt does not actively elicit secrets).
- **No `superpowers:audit` skill / no `/superpowers:knowledge` slash command.** Reading is via retrospective Phase 1 only.
- **No `meta-retrospective` skill.** v3 retro §4 condition 4 — separate brainstorm, separate retract gate.
- **No privacy tiers.** No `local-only` / `cross-session` / `cross-project` / `external` enum. The `v3_friction.class` enum value `cross_project` is preserved as v3 retro condition 2 schema compatibility, not as architecture dimension.
- **No four-quadrant content-source axis.** The four `v3_friction.class` values exist only as a field enum; they generate no code paths, no phases, no extra jsonl files.
- **No phase-gated rollout.** Channel ships in one piece or not at all.
- **Schema event types locked at 3.** Adding a 4th requires a fresh brainstorm. REQ-012 audits this.

## Detailed Design

See companion files:
- `architecture.md` — `lib/harness-evidence.sh` interface, Stop-hook integration patch, retrospective SKILL.md insertion, v3 retro reconciliation patches, test scaffolding
- `bdd-specs.md` — Gherkin scenarios covering REQ-001 through REQ-012
- `best-practices.md` — operational warnings, `.gitignore` recommendation, schema versioning policy, test strategy

## Reconciliation work (commits with this design)

Five line-level edits to `docs/retros/2026-05-09-v3-considered-deferred.md` rename the channel reference from `v3-evidence.jsonl` to `harness-evidence.jsonl` and reframe the §4 gate-trigger note from "currently un-triggerable" to "condition 2 now triggerable; conditions 1, 3, 4 remain open." §4 condition 2 schema body itself is preserved verbatim. Specific patches enumerated in `architecture.md` §D.

## Design Documents

- `_index.md` (this file) — overview, requirements, rationale, risks
- `bdd-specs.md` — Gherkin scenarios, REQ-001..REQ-012 traceability
- `architecture.md` — interface, integration, patch list, test scaffolding
- `best-practices.md` — ops, security, schema policy, testing
