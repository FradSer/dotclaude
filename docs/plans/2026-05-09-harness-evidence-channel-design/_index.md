# harness-evidence channel — design

**Date**: 2026-05-09
**Type**: implementation design
**Predecessor**: `docs/retros/2026-05-09-v3-considered-deferred.md` §4 condition 2

## Context

This channel exists at the intersection of two independent triggers converging on 2026-05-09: (1) the maintainer surfaced a recurring need to capture content the existing superpowers pipeline drops on the floor — between-session scratch notes, file changes the user wants flagged after a session ends, prose recap of what just happened — that current channels do not absorb; (2) the v3.x knowledge-platform reject-form retrospective at `docs/retros/2026-05-09-v3-considered-deferred.md` §4 condition 2 explicitly designated a `harness-evidence.jsonl` channel as the activation gate's evidence corpus, but shipped no writer for it. The same artifact resolves both: a single append-only NDJSON channel writing 3 event types at every Stop hook, consumed by retrospective Phase 1 as un-distilled evidence rows.

**Critical posture (post round-1 evaluation pivot)**: no LLM call sits on the Stop-hook critical path. The writer captures raw inputs (`task`, last-assistant tail truncated to 500 bytes, `modified_files` paths) and exits. All distillation is deferred to retrospective Phase 1 step 8, where one `run_haiku_merge` call aggregates the N un-distilled rows in the window. This preserves the existing v2.x latency budget (~20 ms p95 added to Stop hook) and matches the established `vet.sh = Haiku, evaluator = Sonnet` asymmetry — no Sonnet on hot paths.

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
  harness-evidence.jsonl      <- harness-evidence.sh  (3 event types; path-only
                                                       writer, no LLM call;
                                                       consumed by retrospective
                                                       Phase 1 step 8 via one
                                                       run_haiku_merge call;
                                                       audit CLI exposes T3/T4
                                                       independently of retro)
```

This channel is the only Phase 0 channel whose writer fires on every Stop hook (rather than a specific lifecycle verb), and the only one whose primary upstream is user prose rather than a deterministic harness event. Its writer remains a fast path-only NDJSON append — the LLM work that distills the prose lives at retrospective read-time, not at write-time.

## Discovery Results

**Already exists (reusable, do not rebuild)**:
- `superpowers/lib/bail-log.sh` — append-only NDJSON writer with sourceable + CLI dual mode; reference for `harness-evidence.sh`
- `superpowers/lib/loop.sh:_loop_log_plan_completion_if_executing` (lines 32-113) — `git rev-parse --show-toplevel` resolution + `>>` jsonl append; canonical Stop-hook-write pattern
- `superpowers/lib/post-plan-diff.sh classify` — file-path → `feedback|evolution|unknown` classifier; reused by reader on demand
- `superpowers/lib/utils.sh:run_haiku_merge` (lines 254-271) — sourceable Haiku invocation with recursion guard; reused **at read-time** by retrospective Phase 1 step 8 to distill un-distilled rows. No new LLM-call wrapper introduced.
- `superpowers/lib/vet.sh:_vet_synthesize_final_task` (lines 103-128) — already produces a 1-sentence Haiku recap into `state.task`; harness-evidence reads it verbatim at write-time, never recomputes
- `superpowers/hooks/stop-hook.sh` — extension point already wired (loop_phase → vet_phase ordering); writer emit slots between them as a fast path-only append
- Retrospective Phase 1 currently has 7 numbered data-collection steps; step 8 insertion (between current 7 and 8) matches existing structure exactly
- Retrospective already implements "未处理 vs 已处理" two-state semantics implicitly: `evolution-log.jsonl` last `retrospective_run.timestamp` defines the cutoff (`superpowers/skills/retrospective/SKILL.md:55`)

**Missing (must be built)**:
- No persistent channel today absorbs user-side prose input — every existing channel writes deterministic harness events
- No retract-trigger monitoring CLI for any channel; v3 retro §6 T1-T4 pattern is documented prose but no script polls thresholds
- No write-time event-type allowlist enforcement; siblings rely on caller discipline. harness-evidence introduces the precedent: three verbs hardcoded into the CLI dispatcher with no `--event` arg

**Known cross-channel inconsistency (respected, not fixed in this PR; tracked in `superpowers/TODO-v3.md`)**:
- `bail-log.sh` writes to `$PWD`-relative path (`bail-log.sh:39`); `loop.sh` writes to `git rev-parse --show-toplevel`-relative path. harness-evidence.sh follows the `loop.sh` pattern. Fixing `bail-log.sh` is a separate v2.x.y patch (YAGNI).

## Glossary

| Concept | Canonical label | Rejected variants |
|---|---|---|
| The jsonl file as a stream | **channel** | inbox, fragment store, capture log, evidence corpus (the last is reserved for v3-retro-facing prose) |
| One jsonl line | **row** (interchangeable with **event** when referring to its `event` field) | line, entry |
| Write timing | **Stop hook** (mechanism), **session** (user-facing) | stop-event |
| Read-time aggregation | **distill** | summarize, consolidate, process |
| Channel sunset action | **retract** | deprecate, sunset, disable |
| Independent retract-trigger surface | **`harness-evidence.sh audit` CLI subcommand** | retrospective-only detection (rejected: circular dependency on retrospectives being run) |
| Reader cutoff | **timestamp comparison against `evolution-log.jsonl` last `retrospective_run.timestamp`** | `distilled_at` field on rows (rejected: violates append-only) |
| Writer-side allowlist | **CLI dispatcher exposes only 3 emit verbs; `event` field hardcoded inside each function** | runtime `--event` arg (rejected: shifts allowlist to caller discipline, fails the goal of REQ-012) |

The vocab-divergence symptom that contributed to v3.x deferral (v3 retro §2 privacy-tier divergence across 3 sub-agents) is the failure mode this glossary blocks.

## Requirements

12 IDs total, all `REQ-NNN` for traceability into `bdd-specs.md`. After the round-1 evaluation pivot, the design no longer puts an LLM call on the Stop-hook critical path; REQ-007/009/011 were rewritten to reflect that and the surviving complexity sits at read-time inside the existing `run_haiku_merge` precedent.

### Functional

- **REQ-001 (FR Writer)**: `superpowers/lib/harness-evidence.sh` provides sourceable + CLI dual-mode functions `emit_session_recap`, `emit_v3_friction`, `emit_file_change_summary`, plus the `audit` subcommand (REQ-009). Each emit function appends one NDJSON row to `<git_root>/docs/retros/harness-evidence.jsonl`. All rows carry wrapper fields `{schema_version: 1, event, timestamp (ISO 8601 UTC), git_root, session_id, skill_name}` plus event-specific fields. The `event` field is hardcoded inside each emit function — the CLI dispatcher exposes 3 emit verbs and no `--event` flag (REQ-012 enforcement).
- **REQ-002 (FR Stop-hook integration)**: Every Stop hook invocation calls `emit_session_recap` after `loop_phase` returns and before `vet_phase` runs. **No LLM call.** The writer reads `state.task` (vet.sh's already-produced 1-sentence Haiku recap), the last-assistant tail truncated to 500 bytes, and `state.modified_files`; it composes one NDJSON line and appends. Empty-session filter: `task=="" AND modified_files==[] AND pending_prompt==""` → silent skip, exit 0. Wall-clock target: ≤ 20 ms p95 added to the Stop hook (one `jq -n` invocation + one `>>` append).
- **REQ-003 (FR File change reference)**: `emit_file_change_summary` fires inside `_loop_log_plan_completion_if_executing` after the `plan_completed` jsonl write. Records `{completion_commit, files: [{path}, ...]}`. **Path-only storage**; reader calls `post-plan-diff.sh classify` on demand at distill time.
- **REQ-004 (FR Retrospective reader)**: Retrospective Phase 1 inserts a step 8 (renumbering existing 8/9 to 9/10) that reads `harness-evidence.jsonl` rows with `timestamp > <last evolution-log.jsonl retrospective_run.timestamp>`. Buckets by `event`: `v3_friction` rows pass through to Phase 5a verbatim; `session_recap` rows are aggregated and distilled by **one** `run_haiku_merge` call over all N rows in the window (one LLM call per retrospective run, never per row); `file_change_summary` rows are cross-correlated with `plans-completed.jsonl` to surface untracked completions.
- **REQ-005 (FR Retract trigger)**: Two triggers, both surface via AskUserQuestion in the retrospective report and via the `audit` CLI; never auto-disable.
  - **T3 calendar**: today ≥ 2027-05-09 → mark "harness-evidence T3 age-out reached, AskUserQuestion to confirm retract"
  - **T4 read-rate**: rolling 30-day window where retrospective reports contain zero `harness-evidence` substring references → mark T4 trigger
  - When multiple triggers fire in one retrospective run, emit one coalesced AskUserQuestion listing all reasons. T5 (writer-reliability) does not exist — the writer no longer has a fallible LLM path.
- **REQ-006 (FR Schema versioning)**: All rows carry `schema_version=1`. Reader tolerates unknown fields (forward compat). Adding a 4th event type is structurally prevented by REQ-001 + REQ-012 — would require editing both the CLI dispatcher and `emit_*` functions, blocked at code-review.

### Non-functional

- **REQ-007 (NFR Stop-hook latency budget)**: Bare path-only writer adds ≤ 20 ms p95 to non-empty Stop hooks (one `jq -n` + one `>>` append, no fork, no LLM). Empty sessions exit before the `jq -n` call, adding ≤ 2 ms. Concrete ms regression numbers vs. v2.8.2 baseline are recorded into the retrospective by Phase 1 step 8 itself once the channel has run on N=1 for one week — not fabricated here (deliberately avoiding v3 retro §1 NFR-01 fabricated-numbers failure mode; the 20 ms ceiling is upper-bounded by `bail-log.sh`'s measured behavior, not a new estimate).
- **REQ-008 (NFR JSONL durability + size)**: Writer uses bare `>>` redirect with single-write of pre-rendered jsonl line ≤ ~1.2 KB (well under 4 KiB POSIX `O_APPEND` atomicity guarantee). Daily volume estimate at N=10 sessions ≈ 13 KB/day → ~5 MB/year. Rotation deferred to future-work; revisit only if a project hits 50 MB.
- **REQ-009 (NFR Audit CLI independent run)**: `bash superpowers/lib/harness-evidence.sh audit` exits 0 when no triggers fire and non-zero (with one-line-per-trigger stderr) when T3 / T4 fires. It is callable from any context (cron, CI, manual, retrospective Phase 1 step 8) and contains zero retrospective-internal logic — Phase 1 step 8 calls it and parses output. This removes the "retract triggers fire only if retrospectives are run" circular dependency.

### Success Criteria

- **REQ-010 (SC channel justification — pending N=1 observation)**: Criteria thresholds are deliberately not numeric in this design. After the channel ships on N=1 maintainer project for ≥ 7 days starting on the implementation-merge date, the observed weekly emit count, empty-session-skip ratio, and Phase 1 step 8 consumption count are recorded into a new `evaluation-data-week-1.md` in this folder. Numeric SCs are then defined for the N=3 cross-project window. **Until that file exists, REQ-010 is unmet by construction** — design cannot be advanced to "shipped, ready to retract-monitor" until N=1 data backs the thresholds. This is the v3 retro §1 NFR-01 lesson applied recursively to this design.
- **REQ-011 (SC writer-side allowlist invariant)**: Across any time window, `jq -r .event harness-evidence.jsonl | sort -u` is a subset of `{file_change_summary, session_recap, v3_friction}`. This is no longer monitored by a 30-day audit; it is **structurally invariant** because the CLI dispatcher exposes 3 verbs and each emit function hardcodes its `event` field (REQ-001 + REQ-012). The audit CLI still asserts this at runtime as a regression net — any non-allowlist value present means an out-of-band write happened, which itself is a defect to investigate.
- **REQ-012 (SC no add-bias replication)**: Adding a 4th event type requires (a) editing `harness-evidence.sh` CLI dispatcher to add a verb, (b) writing a new `emit_*` function, (c) updating the audit allowlist constant. Step (c) is the choke point: CI test asserts the allowlist constant matches `{file_change_summary, session_recap, v3_friction}` by string equality. Lifting the lock requires a fresh brainstorm cycle that updates the CI assertion. This converts REQ-012 from "30-day eventual detection" into "write-time blocked at code-review".

**Explicit non-criteria** (called out to prevent v3 retro §1 SC-circular failure mode): we do not measure "% of recaps that produce useful proposals", "% of friction events that map to existing checklist items", or "user satisfaction with recap quality". Those criteria assume the channel has earned its weight; the SCs above test whether the channel earned the right to make such measurements at all. Furthermore, **REQ-010 explicitly does not encode N=0 numeric thresholds** — those wait for N=1 data.

## Risks

| Risk | Mitigation (concrete action) |
|---|---|
| Raw user prose in recap may contain credentials, customer data, internal URLs | best-practices.md §Operational warnings prints a verbatim warning instructing user to add `docs/retros/harness-evidence.jsonl` to `.gitignore` before first Stop hook fires; v3 retro §5 records why no sanitizer ships |
| jsonl growth past 50 MB makes git operations slow | Rotation deferred; T4 retract trigger surfaces before growth becomes painful at typical N=10 session/day |
| Schema growth bias (4th event type smuggled in by future patch) | REQ-001 + REQ-012 enforce 3 verbs in CLI dispatcher and a CI string-equality test on the allowlist constant; lifting the lock requires editing the assertion, blocked at code-review |
| `bail-log.sh` `$PWD` vs. harness-evidence `git_root` divergence confuses operators | `superpowers/TODO-v3.md` is the single tracker for the unify-path-resolution debt; best-practices.md §Known issues and architecture.md §E link to it instead of restating the fix |
| `last_assistant_tail` exceeds 500 bytes and bloats jsonl | Writer truncates to 500 bytes before composing the line (literal `${var:0:500}` slice, matches `vet.sh:75`) |
| First-run project has no `evolution-log.jsonl` so cutoff timestamp is empty | Reader falls back to "process all rows"; semantically correct for first-retrospective state |
| Retract triggers never fire because retrospectives are rarely run | REQ-009 audit CLI is callable from any context (cron, CI, manual); retract surfaces are no longer gated on retrospective being run |
| Haiku distill at read-time fails (Haiku CLI down) | `run_haiku_merge` already returns "" on failure (utils.sh:268); reader falls back to listing one verbatim `recap` row per session instead of distilled prose — degrades to "raw evidence dump", not blocks the retrospective |

## Rationale

| Option | Description | Verdict | Reason |
|---|---|---|---|
| A: Inline into existing channel | Write recaps to `bail-out-events.jsonl` or `plans-completed.jsonl` | Reject | Conflates event semantics; bail-log is for bail-out events specifically (Phase 5a aggregator counts (skill, event) pairs), plans-completed is per-plan-completion ledger. Cross-purpose data corrupts both reader assumptions. |
| B: Wait for v3.x activation gate to satisfy itself | Don't build until ≥3 projects produce friction signals organically into nothing | Reject | The activation gate (v3 retro §4 condition 2) explicitly references this file. Without a writer the condition is structurally un-satisfiable. The retro called this out: "must be independently brainstormed with their own retract triggers." This design is that independent brainstorm. |
| **C: This design (post round-1 pivot)** | Build minimal channel as condition-2 substrate, scope = recap + friction + file-change-ref only, single writer, single reader, single jsonl, **zero LLM on hot path** | **Accept** | Single-purpose, append-only, path-only. Reuses `run_haiku_merge` at **read-time** (the established Haiku precedent in `vet.sh`). The Stop-hook critical path adds only one `jq -n` + one `>>` append (≤ 20 ms p95). Retract triggers honor v3 retro §3 (never auto-disable, AskUserQuestion only) and are exposed via a dedicated `audit` CLI so they fire without depending on retrospectives being run. Writer-side event-type allowlist replaces the original "30-day eventual audit". |
| C-v0 (pre-pivot): Sonnet recap on every Stop hook | The original round-1 design — Sonnet 600-1500 ms call on hot path, `fallback=true` row, T5 trigger | Rejected post-evaluation | Sonnet@stop-hook violates the established "Haiku-on-hot-paths, Sonnet-at-deliberate-cycles" asymmetry; the latency tax is on every non-empty Stop, the `fallback=true` field plus T5 trigger introduced a new failure surface, and "telemetry will tell us if 1.5 s is too slow" is a tautology when telemetry comes from a channel that itself injects the latency. Read-time distill (one Haiku call per retrospective run over N rows) is strictly cheaper and inherits an already-tested error path. |
| D: Build full v3.x scope (4 quadrants × 3 phases × 28 requirements) | What `2026-05-09-knowledge-platform-design/` originally elaborated | Reject | v3 retro §1 + §2 + §6 catalog the failure modes explicitly: N=0 add-bias, vocab divergence, structural replication of v2.8.x mistake. v3 retro §6: "do not advance v3.x inside any conversational arc that produces v2.8.x or v2.9.x retract patches." |

C is constrained on three sides: rejected B because the gate cannot self-satisfy, rejected C-v0 because the latency tax was unjustified, rejected D because the gate exists precisely to delay D.

## Don't-do path

Each item maps to a v3 retro §5 conflict-table row.

- **No LLM call on the Stop-hook critical path.** See Rationale row C-v0 before re-proposing.
- **No PostCommit hook.** v3 retro §5 lists it as a v3.x mechanism not currently registered.
- **No `~/.claude/projects/<project-key>/knowledge/` directory.** v3 retro §5: "Does not exist; no creator." Channel writes only to `<git_root>/docs/retros/harness-evidence.jsonl`.
- **No `lib/knowledge-write.sh`.** Writer is `lib/harness-evidence.sh` with three append verbs plus the audit subcommand.
- **No `lib/sanitizer.sh` / no credential scanning.** Path-only file storage means no diff bodies. User-pasted secrets in `v3_friction` description are out of scope; the recap row stores the existing `state.task` (1 sentence) plus the last-assistant tail (truncated to 500 bytes) — no fresh prompt actively elicits secrets.
- **No `superpowers:audit` skill / no `/superpowers:knowledge` slash command.** Reading is via retrospective Phase 1 only; CLI `audit` subcommand is a script, not a skill.
- **No `meta-retrospective` skill.** v3 retro §4 condition 4 — separate brainstorm, separate retract gate.
- **No privacy tiers.** No `local-only` / `cross-session` / `cross-project` / `external` enum. The `v3_friction.class` enum value `cross_project` is preserved as v3 retro condition 2 schema compatibility, not as architecture dimension.
- **No four-quadrant content-source axis.** The four `v3_friction.class` values exist only as a field enum; they generate no code paths, no phases, no extra jsonl files.
- **No phase-gated rollout.** Channel ships in one piece or not at all.
- **Schema event types locked at 3 — structurally, not by audit.** CLI dispatcher has 3 verbs; each emit function hardcodes its `event` field; CI asserts the allowlist constant by string equality. Adding a 4th requires lifting the assertion, which is a fresh brainstorm cycle.
- **No `fallback=true` field, no T5 trigger.** The writer no longer has a fallible LLM path. T5 was specific to Sonnet failure ratio; it has no analog in the path-only writer and is intentionally omitted.

## Detailed Design

See companion files:
- `architecture.md` — `lib/harness-evidence.sh` interface, Stop-hook integration patch, retrospective SKILL.md insertion, v3 retro reconciliation patches, test scaffolding
- `bdd-specs.md` — Gherkin scenarios covering REQ-001 through REQ-012
- `best-practices.md` — operational warnings, `.gitignore` recommendation, schema versioning policy, test strategy

## Reconciliation work (commits with this design)

Five line-level edits to `docs/retros/2026-05-09-v3-considered-deferred.md` rename the channel reference from `v3-evidence.jsonl` to `harness-evidence.jsonl` and reframe the §4 gate-trigger note from "currently un-triggerable" to "condition 2 now triggerable; conditions 1, 3, 4 remain open." §4 condition 2 schema body itself is preserved verbatim. Specific patches enumerated in `architecture.md` §D.

The four brainstorming SKILL.md changes surfaced during this design (Phase 1.5 rename, Phase 2 vocab heading, Pre-loop Resolution, Phase 1 rejection branch reword) have already landed in 2026-05-09 commits but are **not** bundled into this PR. They are recorded in `docs/plans/2026-05-10-brainstorming-vocab-reform-retro.md` as the dedicated audit trail. This design's §7 audit trail in `2026-05-09-v3-considered-deferred.md` carries only a one-line cross-reference, per SCOPE-CREEP-01 of design checklist v2.

## Design Documents

- `_index.md` (this file) — overview, requirements, rationale, risks
- `bdd-specs.md` — Gherkin scenarios, REQ-001..REQ-012 traceability
- `architecture.md` — interface, integration, patch list, test scaffolding
- `best-practices.md` — ops, security, schema policy, testing
