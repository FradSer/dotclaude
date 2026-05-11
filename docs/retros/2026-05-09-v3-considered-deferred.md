# v3.x Knowledge Platform — Considered, Deferred — 2026-05-09

**Type**: Reject-form retrospective on a brainstorm output, sibling to `meta-retro-2026-05-08-superpowers-v2.8.x.md`. Captures the v3.x scope that was elaborated by parallel sub-agents and then declined by the maintainer in the same session.

**Predecessor**: `docs/retros/meta-retro-2026-05-08-superpowers-v2.8.x.md` (v2.8.x meta-retrospective; this folder's §0 explicitly cited it).

**Original artifact**: `docs/plans/2026-05-09-knowledge-platform-design/` — a 6-file design folder (`_index.md` 159 / `architecture.md` 213 / `bdd-specs.md` 469 / `best-practices.md` 204 / `evaluation-design-round-1.md` / `evaluation-design-round-2.md`), now removed. ~880 lines of elaboration committed in a self-contradictory state: §0 declared the design `DESIGN-NOT-YET-JUSTIFIED` while the rest read as approved spec.

**Status**: **DESIGN-CONSIDERED-DEFERRED — DO NOT IMPLEMENT**. Activation gate (see §4) is currently un-triggerable, not just un-met. To advance v3.x, the gate's own infrastructure must be brainstormed independently first.

**Empirical sample base**: N = 0 projects had used v2.8.2 in steady state at design time. The four v3.x content-source quadrants (between-plan code / AI dialogue / external reading / cross-project pattern transfer) were inferred from one maintainer's stated friction, not measured.

---

## 1. Why this exists (and why it stops here)

The v3.x design was produced by `superpowers:brainstorming` Phase 2 spawning three parallel sub-agents (architecture / best-practices / context+requirements). The context+requirements sub-agent, after writing `_index.md`, returned an unsolicited self-critique that mirrored the v2.8.x meta-retro's structural complaints. The maintainer accepted it as substantive.

| Sub-agent's self-critique | Verbatim quote |
|---|---|
| **N=0 evidence base** | "Based on N=0 project data, weaker than v2.8.x's N=1" |
| **Path 3 is post-hoc rationalization** | "User answering 3 forcing-function questions ≠ v3.x must be designed; Path A / Path C are strawmen" |
| **SC-NN are circular** | "Criteria assume v3.1 has shipped — the real SC should be 'should v3.0 ship at all'" |
| **NFR-01 numbers are fabricated** | "50 ms p50 / 200 ms p99 has no baseline measurement backing" |
| **Structurally replicates v2.8.x add-bias** | "28 requirements / 4 phases / multi-channel architecture, no external review gate, no 'don't do' path" |
| **What should have been written** | "v3.x not yet justified. Recommend: dogfood v2.8.2 + Phase 0 channels on ≥3 projects, measure read-rate, collect friction points in `docs/retros/harness-evidence.jsonl` (event=v3_friction) as real-data basis before designing v3.x" |

The original folder's §0 took a non-destructive `C-variant` (keep folder, mark status, do not advance). This retro takes the destructive `B-variant`: collapse to a single retro file, delete the elaboration. Reason: the folder's own §0 ↔ §1+ contradiction was itself the v2.8.x **add-bias pattern replicated at the document layer** — ~880 lines of mechanism elaboration on N=0 evidence. Banner-form would preserve the plan-shape four-source/four-phase model as reference; reject-form removes the model and keeps the reasoning.

---

## 2. Considered scope (not approved requirements)

The original folder declared 28 requirement IDs (FR-01..15 / NFR-01..08 / SC-01..05). Compressed here to one bullet each, **as record of what was considered, not as binding scope**:

- **FR (functional)**: passive between-plan capture extending v2.8.x post-plan-diff window; active capture verb for diff/file/transcript/URL promotion; AI dialogue capture default-off + per-session opt-in; external reading captured only when explicitly cited; cross-project pattern indexing; integration into retrospective Phase 1 / brainstorming Phase 1.5 / executing-plans Phase 6; privacy tier on every item; ID-based retraction (append-only); tier promote/demote without re-capture; per-component disable; per-component read-rate self-value signal; auto-surface as retract candidate when read-rate falls below threshold; one-minute audit view across all captured items.
- **NFR (non-functional)**: Stop-hook latency budget vs v2.8.2 baseline (concrete numbers deferred to baseline measurement); per-tier privacy SLO with sanitizer; backward-compat with v2.8.x channels (no migration); audit view <1 s for ≤1 k items; reversibility via single-flag disable; integration test per new lib script (no mock-only); zero-cost-default until activated; `schema_version` on every JSONL line with one-major-version tolerance.
- **SC (success criteria)**: every Phase 1 component shows ≥1 downstream read per project across N=3 projects, or surfaces for retract; retract-candidate count ≤1 across the same sample; 100% privacy-tier violation detection on a 20-case test corpus; Stop-hook latency regression within NFR-01; audit view readable in <60 s.

**Privacy tier vocabulary** (canonical for this retro file, after reconciliation): `local-only` / `cross-session` / `cross-project` / `external`. The original `_index.md:92` used a different `public/project/local` triple — that was the vocabulary divergence symptom this brainstorm session produced and is part of the reason the design was deferred.

---

## 3. Three architectural rules — preserved as reasoning, not as binding laws

If v3.x ever activates, these three rules survived the brainstorm as load-bearing reasoning. Each maps to a v2.8.x failure mode it claims to neutralize:

- **Meta-recursive calibration**. Every component logs its own read-rate; consumers that go unread surface as retract candidates via `AskUserQuestion` (never auto-disable). Counters the v2.8.x **add-bias** mode where mechanisms ossify because nothing reviews whether they earned their weight. Operationally would mirror `meta-retro-2026-05-08` §6 T1–T4 triggers per component.
- **Privacy tier explicit**. Every captured item carries an explicit tier; cross-tier downward flow (more-private → less-private) requires opt-in; upward (less-private → more-private read-side) is free. Counters the v2.8.x Phase 5b **input-surface suppression** mode where a "safety layer" removed user agency.
- **Phase-gated rollout**. Each phase ships independently disable-able; a later phase locks until the earlier phase produces real-data read-rate evidence (≥3 projects). Counters the v2.8.x **pacing failure** mode where five rounds stacked in one session.

These rules do **not** make repeating the v2.8.x spiral impossible inside v3.x — a sufficiently determined add-bias arc routes around any architecture rule — but they make the bias visible at design time rather than only at retract time.

---

## 4. Activation gate — currently un-triggerable

Before any v3.x scope advances to `superpowers:writing-plans`, all four conditions must hold:

1. **≥3 distinct projects** have completed at least one full plan cycle using v2.8.2 (post-plan-diff + bail-log + plans-completed channels in steady use).
2. **`docs/retros/harness-evidence.jsonl`** in each project records concrete friction points (event=`v3_friction`) the user encountered that v3.x would have addressed — at least one per project, append-only via `lib/harness-evidence.sh emit-v3-friction`. Schema unchanged from the original v3 retro (class / description / could_phase_0_handle / workaround_used) plus the standard wrapper fields (schema_version, timestamp, git_root, session_id, skill_name). See `docs/plans/2026-05-09-harness-evidence-channel-design/` for the channel design.
3. **Phase 0 read-rate measurement** across the same ≥3 projects shows consumers (retrospective Phase 5a, executing-plans Phase 6) actually read post-plan-diff / bail-log / plans-completed data with non-trivial frequency.
4. **A formal `meta-retrospective` skill run** (out-of-band, not a normal `retrospective`) reviews the v3-evidence corpus and emits PASS / REWORK on whether v3.x scope still matches user friction.

**Gate-trigger note (historical)**: condition 2 originally referenced a `v3-evidence.jsonl` channel that did not exist in `superpowers/lib/` and had no shipped writer. As of the 2026-05-09 follow-on design (`docs/plans/2026-05-09-harness-evidence-channel-design/`), the channel ships as `lib/harness-evidence.sh` writing `docs/retros/harness-evidence.jsonl`. Condition 2 is now triggerable. Condition 4 (`meta-retrospective` skill) is still not registered in any `plugin.json` and remains un-triggerable. If v3.x is to be activated later, condition 4's skill must be independently brainstormed with its own retract triggers — it is itself a new mechanism with the same N=0 risk. **Do not bundle the gate's infrastructure into v3.x scope.**

If activation passes, this retro is the starting reference; sub-agents in a fresh brainstorming session re-examine the §2 scope against the harness-evidence corpus (filtered to event=v3_friction) and prune anything that wasn't real friction (sub-agent self-prediction: 30–50% pruning factor per quadrant).

If activation fails (≥3 projects use v2.8.2 happily without missing v3.x scope), this file ages out as audit evidence that v3.x was considered and deemed unnecessary.

---

## 5. Conflicts between the original design and `superpowers/` at write time

Read-only audit of `superpowers/lib/` and `superpowers/hooks/` on 2026-05-09 (the same day the design was committed):

| Original design claim | Reality |
|---|---|
| `architecture.md:137` "Phase 0 (done, v2.8.x): post-plan-diff + bail-log + harness-observations + evolution-log + plans-completed" | Only `post-plan-diff.sh`, `bail-log.sh`, `loop.sh`→`plans-completed.jsonl` are lib-driven. **`harness-observations.jsonl` and `evolution-log.jsonl` are still Claude-instructed manual writes from SKILL.md with no lib helper.** |
| `architecture.md:144-149` `harness-config.json` mechanism is shipped | Only retrospective Phase 5c manual write instruction; no lib helper, file is created lazily by Claude. |
| `architecture.md:185` `lib/knowledge-write.sh` enforces tier transitions | File does not exist. |
| `architecture.md:188` sanitizer scans for credentials before promotion | `sanitizer.sh` does not exist. |
| `architecture.md:138` `superpowers:audit` skill (FR-15) | Not registered in `superpowers/.claude-plugin/plugin.json`. |
| `architecture.md:139` `/superpowers:knowledge` deposit/import/promote verbs | Not registered. |
| `architecture.md:199` `meta-retrospective` skill | Not registered. |
| `bdd-specs.md` post-commit hook fires on every commit | No PostCommit hook is registered (only Stop / UserPromptSubmit / PostToolUse). |
| `bdd-specs.md` `~/.claude/projects/<project-key>/knowledge/` directory | Does not exist; no creator. |

The folder's "Phase 0 already shipped" framing was therefore **not accurate**: two of five claimed Phase 0 channels (`harness-observations.jsonl`, `evolution-log.jsonl`) are still Claude-instructed manual writes awaiting lib extraction. Promoting them to lib helpers is a separate v2.x.y patch with its own retract criteria — not bundled here.

---

## 6. Triggers for revisiting v3.x

Mirroring `meta-retro-2026-05-08-superpowers-v2.8.x.md` §6, the activation conditions in §4 above are themselves a T1–T4-shaped trigger set. Additional shape:

| Trigger | Threshold | Source of truth |
|---|---|---|
| **T1: Activation gate satisfied** | All four §4 conditions hold | `docs/retros/harness-evidence.jsonl` (event=v3_friction) across ≥3 projects + meta-retrospective skill emit |
| **T2: New friction class** | A user reports a friction class outside the four §2 quadrants — between-plan / AI dialogue / external / cross-project — that is genuinely common | external — maintainer observation |
| **T3: Calendar age-out** | 365 days from this retro (i.e., 2027-05-09) without T1 or T2 — folder ages out as "considered, deemed unnecessary" | calendar |
| **T4: Counter-evidence** | ≥3 projects use v2.8.2 happily and in §5 (Phase 0 partial-ship) the manual writes also stay un-promoted with zero friction — confirms v3.x scope was hypothetical | observation |

**Bias warning**: do not advance v3.x inside any conversational arc that produces v2.8.x or v2.9.x retract patches. Cross-arc contamination is exactly the pacing failure both retros identify.

---

## 7. Audit trail

- **Brainstorm date**: 2026-05-09 (single session)
- **Verdict source**: context+requirements sub-agent self-critique, delivered as delayed task-notification
- **Maintainer calibration**: ultrathink reflection in main session; chose B-variant (reject) over the original folder's C-variant (preserve as reference)
- **Refactor date**: 2026-05-09 same session (this file replaces the elaborated folder)
- **Co-located mechanism changes**: `JUST-01` checklist item added to `docs/retros/checklists/design-v1.md`; evaluator §0 read added to `superpowers/agents/superpowers-evaluator.md`; writing-plans NOT-JUSTIFIED gate added to `superpowers/skills/writing-plans/SKILL.md`; brainstorming Phase 2.5 vocab-reconciliation added to `superpowers/skills/brainstorming/SKILL.md`. These mechanism changes ensure future NOT-JUSTIFIED designs cannot pass the gate the same way.
- **Counter-options considered**:
  - A: keep folder, add NOT-JUSTIFIED banners + reconcile vocab — rejected because plan-shape four-source/four-phase model would survive
  - C: original folder's choice (keep + status flag) — rejected because §0 ↔ §1+ contradiction would persist
- **Co-author**: Claude Opus 4.7
- **2026-05-09 follow-on**: condition-2 channel designed and named `harness-evidence.jsonl`. v3.x activation gate's condition 2 is now structurally satisfiable; conditions 1, 3, 4 remain open (see ownership table below). See `docs/plans/2026-05-09-harness-evidence-channel-design/`.
- **2026-05-10 follow-on (harness-evidence design pivot)**: design rewritten post-round-1 review. See `docs/plans/2026-05-09-harness-evidence-channel-design/evaluation-design-round-2.md` for the rewrite summary and the round-2 PASS verdict.
- **2026-05-10 follow-on (brainstorming reform extracted)**: the four brainstorming SKILL.md changes that landed 2026-05-09 are now recorded in their dedicated retro `docs/plans/2026-05-10-brainstorming-vocab-reform-retro.md` rather than as a bullet here. Cleaving the audit trail follows design checklist v2 SCOPE-CREEP-01.

### v3.x activation-gate ownership (filled 2026-05-10)

The activation gate (§4) has four conditions. Condition 2 is now triggerable. Conditions 1, 3, 4 are open. Without explicit ownership those conditions will be forgotten and a future maintainer will re-design v3.x without knowing this retro existed. Recorded here:

| Condition | What it means | Owner / mechanism | Trigger checkpoint |
|---|---|---|---|
| 1: ≥3 distinct projects on v2.8.2+ | Three projects must complete a full plan cycle using post-plan-diff + bail-log + plans-completed channels | retrospective Phase 5a aggregates across projects when invoked with `--cross-project` | check on 2026-08-01 (target N=3 reached); if not reached, push to 2026-11-01 |
| 2: harness-evidence.jsonl recording v3_friction | At least one v3_friction row per project | **satisfied** — `lib/harness-evidence.sh emit-v3-friction` ships | n/a |
| 3: Phase 0 read-rate measurement | Retrospective Phase 5a / executing-plans Phase 6 reads post-plan-diff / bail-log / plans-completed channels with non-trivial frequency | `harness-evidence.sh audit` T4 trigger surfaces zero-read-rate; cross-channel read-rate stays manual until T4 fires on any channel | re-check whenever T4 fires on any channel; otherwise quarterly review |
| 4: meta-retrospective skill | A formal skill that reviews the v3-evidence corpus and emits PASS/REWORK | not yet registered in `plugin.json`; **owner pending — requires independent brainstorm** | not before 2026-07-01; do not advance until conditions 1 and 3 are also met |

**Discipline**: do not start condition 4's brainstorm until 1 and 3 are met. Condition 4 carries the same N=0 risk this entire retro warns against; designing it speculatively before evidence exists is the failure mode this whole audit trail is meant to prevent.

---

## Sources

- `docs/retros/meta-retro-2026-05-08-superpowers-v2.8.x.md` — sibling retro shape, T1-T4 trigger language, add-bias diagnosis
- `superpowers/lib/post-plan-diff.sh`, `superpowers/lib/bail-log.sh`, `superpowers/lib/loop.sh`, `superpowers/lib/seed-checklists.sh` — actually-shipped Phase 0 baseline at write time
- `superpowers/skills/retrospective/references/harness-config.md` — established gating-via-config pattern (precedent for any future v3.x gate)
- [Collaborative Memory: Multi-User Memory Sharing in LLM Agents with Dynamic Access Control](https://arxiv.org/abs/2505.18279) — two-tier private/shared memory model; informed the §3 privacy tier reasoning
- [Personal Knowledge Graphs in AI RAG-powered Applications with libSQL](https://turso.tech/blog/personal-knowledge-graphs-in-ai-rag-powered-applications-with-libsql) — symbolic vs. vector trade-off
- [SQLite Edge Production: 2026 Database Renaissance](https://byteiota.com/sqlite-edge-production-2026-database-renaissance/) — encryption-at-rest baseline (deferred)
- [LLM Wiki: Karpathy's Local Knowledge Base Setup](https://www.kunalganglani.com/blog/llm-wiki-karpathy-local-knowledge-base) — local-first defaults

End of considered-deferred retro.
