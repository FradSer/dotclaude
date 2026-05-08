# superpowers v3.x — Knowledge Platform Architecture

**Companion to**: `_index.md` (FR/NFR/Phase definitions), `bdd-specs.md` (scenarios), `best-practices.md` (security/performance/quality), `../../retros/meta-retro-2026-05-08-superpowers-v2.8.x.md` (motivation).

**Status**: design draft. Phase 0 (post-plan-diff + bail-log + harness-observations) is shipped in v2.8.x; everything below is gated on per-component retract triggers in §5.

---

## 1. Architectural Laws (binding)

These three laws come from the user's Phase 1 selection of Path 3 (`_index.md` §Rationale). Every component below MUST satisfy all three; non-conformance is a design failure, not a trade-off.

1. **Meta-recursive calibration** — every component ships with retract triggers (T1–T4 mirrored from `meta-retro` §6) and an assumption-test pathway via `harness-config.json` `disabled_components[]`. The platform itself is on probation; no component is exempt.
2. **Privacy tier explicit** — every storage artifact carries a `tier` label from {`local-only`, `cross-session`, `cross-project`, `external`}. Cross-tier flows MUST be user opt-in. Downward flow (more-private → less-private) is the only direction that requires consent; upward flow is read-side and free.
3. **Phase-gated rollout** — Phase N+1 unlocks only when Phase N's calibration data passes its retract gate (≥3-project read-rate evidence per `_index.md` SC-01/SC-02). No skipping, no parallel.

---

## 2. Data Flow

Four content sources map to four storage tiers. Arrows are **promote-only** and require explicit consent on first traversal of each tier boundary.

```
                    +-----------------------------+
 Source A           |  Phase 0 (shipped) + Phase 1 extension     consumption
 between-plan code  |  ----                                       ----
 (commits, refactor,+--> docs/retros/                            +--> retrospective
  experiments)      |    plans-completed.jsonl                    |    Phase 5a/5b
                    |    bail-out-events.jsonl                    |    (already wired)
                    |    harness-observations.jsonl               |
                    |    knowledge-events.jsonl   <-- Phase 1 NEW |
                    +-----------------------------+               |
                         tier: local-only                         |
                                |                                 |
                                | promote (opt-in, Phase 2)       |
                                v                                 |
 Source B           +-----------------------------+               |
 AI dialogue        |  ~/.claude/projects/<key>/  |               +--> brainstorming
 (Claude Code,      |    knowledge/               |                    Phase 1.5
 Codex, ACP)        |    decisions.ndjson         |                    (FR-07 query)
                    |    deposits/<id>.md         |
                    |  (Phase 2: active capture,  |
                    |   user-paste only)          |
                    |  (Phase 3: optional daemon  |
                    |   gated on Phase 2 evidence)|
                    +-----------------------------+
                         tier: cross-session
                                |
                                | promote (opt-in, Phase 3)
                                v
 Source C           +-----------------------------+
 cross-project      |  ~/.superpowers/kg/         |               +--> brainstorming
 patterns           |    patterns.ndjson          |                    Phase 1.5
                    |  (symbolic only;            |                    (cross-project
                    |   embeddings deferred to    |                     similar problems)
                    |   v4.x, see §7 Q-KG-SCHEMA) |
                    +-----------------------------+
                         tier: cross-project
                                |
                                | cite-only (no auto-promote)
                                v
 Source D           +-----------------------------+               +--> brainstorming
 external           |  ~/.superpowers/external/   |                    (cited best
 resources          |    cache/<sha1>.md          |                     practices)
 (web docs,         |    citations.ndjson         |
  papers)           +-----------------------------+
                         tier: external
                         (read-only, never auto-uplink)
```

The four-source phase mapping aligns with `_index.md` §Detailed Design:

- **Phase 0** (shipped): Source A subset (post-plan diff window).
- **Phase 1**: Source A extension (continuous between-plan capture beyond the 24h window) + audit view skill.
- **Phase 2**: Source B (active capture / deposit verb only — no daemon).
- **Phase 3**: Source C (cross-project pattern symbolic graph) + Source D (external citations).

This phase ordering deliberately favors **lower-privacy + higher-density** sources first. Source B (AI dialogue) is privacy-heavy and stays opt-in active capture in Phase 2; the daemon-style ambient capture is deferred to Phase 3+ contingent on Phase 2 read-rate evidence (§5 retract gates).

---

## 3. Storage Schemas

### 3.1 Source A — between-plan code (tier: `local-only`, repo-scoped)

Phase 0 schemas already shipped (`docs/retros/{plans-completed,bail-out-events,harness-observations,evolution-log}.jsonl`).

Phase 1 adds `docs/retros/knowledge-events.jsonl`:

```json
{"event":"between_plan_capture","schema_version":1,"timestamp":"2026-05-09T11:14:00Z","plan_context":null,"commit":"a7a62a6","class":"refactor","files":["src/auth.py"],"pattern_signature":"sha1:f2c1...","tier":"local-only","read_count":0}
```

`read_count` increments each time a downstream consumer (retrospective Phase 5a, audit view) reads the row — this is the FR-13 self-value signal that drives §5 retract gates.

### 3.2 Source B — AI dialogue (tier: `cross-session`, project-key-scoped)

Phase 2 deposit verb writes to `~/.claude/projects/<project-key>/knowledge/`:

- `decisions.ndjson` — distilled decision-shape rows (one per deposit batch)
- `deposits/<id>.md` — raw transcript / paste content

Example `decisions.ndjson` row:

```json
{"event":"decision_deposited","schema_version":1,"timestamp":"2026-05-09T08:14:01Z","id":"DEC-042","source_tool":"codex","prompt_hash":"a1b2","decision_summary":"chose lognormal over exponential for phone_call distribution","tier":"cross-session","retract_after":"90d","read_count":0}
```

Raw transcript stored separately in `deposits/DEC-042.md` so `decisions.ndjson` stays scannable. Encryption at rest deferred to Phase 3 (via SQLCipher; see `best-practices.md` §1) — Phase 2 ships unencrypted because `~/.claude/projects/<key>/` is already user-home-scoped and never `git add`-able by NFR-02.

### 3.3 Source C — cross-project pattern graph (tier: `cross-project`)

Phase 3 NDJSON-only symbolic graph at `~/.superpowers/kg/patterns.ndjson`. Each row is one node-or-edge event:

```json
{"event":"pattern_promoted","schema_version":1,"timestamp":"2026-05-13T09:01:00Z","pattern_id":"PAT-007","label":"openai-model-param-handling","kind":"recurring-failure","evidence":[{"project_key":"<hash-A>","artifact":"docs/retros/retro-2026-05-08-user-simulation.md","consent_event":"2026-05-09T08:30:00Z"},{"project_key":"<hash-B>","artifact":"docs/retros/retro-2026-05-12-rayneo.md","consent_event":"2026-05-13T09:01:00Z"}],"tier":"cross-project","read_count":0}
```

**No SQLite, no embeddings, no graph DB in v3.x.** NDJSON-flat-file works through ~10k entries (see `best-practices.md` §2 the 10k entries fs/sqlite cutoff). v4.x revisits this only if Phase 3 read-rate evidence justifies the leap.

### 3.4 Source D — external resources (tier: `external`, read-only)

Phase 3 file-system cache at `~/.superpowers/external/cache/<sha1>.md` with `citations.ndjson` sidecar:

```json
{"event":"external_cited","schema_version":1,"timestamp":"2026-05-09T08:00:00Z","sha1":"f2c1de...","url":"https://arxiv.org/abs/2505.18279","title":"Collaborative Memory: Multi-User Memory Sharing","cited_in":"docs/plans/2026-05-09-knowledge-platform-design/_index.md","license":"arxiv-perpetual","tier":"external","embed_into_kg":false,"read_count":0}
```

`embed_into_kg: false` is the default — external content informs brainstorming inline but does not auto-promote into the cross-project graph (would invert tier ordering, violating Law 2).

---

## 4. Phased Rollout

| Phase | Components | Sources unlocked | Retract gate (must pass before next phase) |
|---|---|---|---|
| **0 (done, v2.8.x)** | post-plan-diff, bail-log, harness-observations, evolution-log, plans-completed | A (subset) | meta-retro §6 T1–T4 |
| **1 (v3.0)** | between-plan capture extension; `lib/knowledge-write.sh`; `superpowers:audit` skill (FR-15); retrospective Phase 5a reads `knowledge-events.jsonl` | A (full) | T1: ≥1 read per Phase 1 component per project across N=3 projects (SC-01). T2: zero user complaints. T3: 90 days. T4: maintainer used audit on real plan. |
| **2 (v3.1)** | active capture verb `superpowers:deposit` for AI dialogue; `decisions.ndjson` writer; `~/.claude/projects/<key>/knowledge/`; brainstorming Phase 1.5 reads decisions (FR-07 within-project) | B (deposit-only, no daemon) | T1: ≥3 deposits + ≥1 read per project across N=3. T2: zero privacy issue filed. T3: 120 days. |
| **3 (v3.2)** | cross-project pattern symbolic graph `~/.superpowers/kg/patterns.ndjson`; `superpowers:knowledge promote/import`; external citation cache; brainstorming Phase 1.5 cross-project query (FR-07 cross-project) | C + D | T1: ≥3 promotions corroborated across ≥2 projects. T2: zero leakage in audit. |
| **4+ (deferred to v4.x)** | encrypted-at-rest (SQLCipher), embedding-based retrieval, ambient daemon capture, automatic kg edge inference | (none) | Out of scope until Phase 3 evidence justifies. |

Each phase gate is a `harness-config.json` entry — same machinery as v2.8.x, no new mechanism:

```json
{"version":1,"disabled_components":[
  {"component":"v3_phase_2_deposit","reinstate_conditions":"phase_1_read_rate >= 1.0 across N=3 projects","tier":"cross-session"}
]}
```

When a gate is locked, downstream components return `PHASE-GATE-LOCKED` with the unmet condition (see `bdd-specs.md` §3 Phase Gate scenario).

---

## 5. Per-Component Retract Gates

Mirroring `meta-retro` §6, every v3.x component declares T1–T4. This is the FR-13 / FR-14 self-value mechanism made concrete.

| Component | T1 (data) | T2 (friction) | T3 (calendar) | T4 (maintainer) |
|---|---|---|---|---|
| `between_plan_capture` (Phase 1) | read_count == 0 across 30 days on ≥3 projects | user disables in config | 90 days dormant | maintainer disables on own machine 1 week |
| `audit_view` (Phase 1) | called <1× per plan completed across N=3 | usability complaint | 90 days no use | manual disable |
| `deposit_verb` (Phase 2) | <3 deposits per project across N=3 | promotion ritual ignored ≥3× | 120 days dormant | manual disable for 1 retro cycle |
| `decisions_reader` (Phase 2 brainstorming hook) | 0 reads of `decisions.ndjson` across N=3 brainstorms | irrelevant suggestions reported | 90 days | manual disable |
| `pattern_graph` (Phase 3) | 0 promotions across 5 retros | promote ritual ignored | 90 days | manual |
| `external_cache` (Phase 3) | <10% brainstorms cite cached doc | cite-storm filed | 90 days | manual |

Notably absent: there is **no retract gate that auto-vetoes user decisions** (the v2.8.x R1 antipattern). Retract gates surface candidates via `AskUserQuestion` only, never auto-disable.

---

## 6. Privacy Tier Matrix

Rows = data source. Columns = target tier the row's data may flow to. `auto` = allowed without prompt, `opt-in` = AskUserQuestion required, `block` = forbidden architecturally (sanitizer enforced).

| Source ↓ \ Target → | local-only | cross-session | cross-project | external |
|---|---|---|---|---|
| Source A (between-plan) | auto (own tier) | opt-in | opt-in (after sanitize) | block |
| Source B (AI dialogue) | block (B never demotes to per-repo) | auto | opt-in (decision_summary only, never raw transcript) | block |
| Source C (cross-project) | opt-in (read-only inject into retro) | opt-in | auto | block |
| Source D (external) | opt-in (cite into retro) | opt-in (cite into session) | block (D never auto-promotes; manual ritual only) | auto |

Two architectural blocks deserve explicit mention:

- **B → local-only is blocked**: a session captured cross-tool MUST NOT silently land back in a project's `docs/retros/`. Demotion would surface dialogue from unrelated work in repo-scoped retrospectives. Enforcement: `lib/knowledge-write.sh` rejects any `tier: cross-session → local-only` flow with non-zero exit.
- **D → cross-project is blocked**: external content can be cited inside a session or retro but cannot become a `pattern_graph` node. Prevents the kg from accreting unverified web claims as first-class patterns. To promote, the user must run a manual `/superpowers:knowledge promote-external` ritual — explicitly out of scope for v3.x, deferred to v4.x.

Sanitizer (Phase 2 ships, FR-09 / NFR-02 enforces) scans for absolute paths matching foreign `repo_root` values, env-var names, and credential-shaped strings before any `cross-session → cross-project` promotion.

---

## 7. Architectural Decisions (resolved during Phase 1) + Deferred

### Resolved (Phase 1 user-confirmed)

1. **Q-CAPTURE-MODE — RESOLVED: strict T1-evidence gate.** Phase 2 ships deposit-only. Phase 3 does NOT add daemon ambient capture by default. Daemon mode is unlocked only when T1 evidence proves deposit is insufficient — concretely: ≥1 user-reported scenario (e.g. "I deposited the same content 3+ times in a week"). Without that evidence, Phase 3+ stays deposit-only. Rationale: daemon is a privacy-heavy mechanism; merely passing Phase 2's read-rate gate is insufficient justification.
2. **Q-KG-SCHEMA — RESOLVED: symbolic NDJSON.** Phase 3 cross-project pattern graph uses `~/.superpowers/kg/patterns.ndjson` symbolic-only. No SQLite, no FTS5, no vector embeddings in v3.x. Reassess when `patterns.ndjson` exceeds ≥1k entries OR when cross-project query latency p95 exceeds 200ms — at that point a Phase 4+ proposal can introduce SQLite + FTS5 with explicit retract gate. Vector embedding remains deferred to v4.x territory.
3. **Q-CONSENT-UI — RESOLVED: per-promote AskUserQuestion.** Each cross-tier promotion fires one AskUserQuestion (Confirm / Cancel) at promote time. Low-frequency expectation (Phase 2 promote rate measured against a soft threshold of ≤5/week; if exceeded, file an issue and reassess). Batched-review path is **not** introduced in v3.x — it would defer cross-project signal materially and conflicts with the per-decision audit trail expected by `evolution-log.jsonl`.
4. **Q-RETRACT-OF-PLATFORM — RESOLVED: `~/.superpowers/disabled` flag + meta-retrospective scheduling.** When ≥3 Phase 1 components trip retract triggers simultaneously, this signals v3.x as a whole is misaligned. The platform-level kill switch is `~/.superpowers/disabled` — its presence short-circuits all v3.x writes (lib `knowledge-write.sh` exits early). The flag is created/removed by `meta-retrospective` skill (out-of-band, not a regular `retrospective` action), mirroring the v2.9.0 design pattern from `meta-retro-2026-05-08-superpowers-v2.8.x.md` §5. The flag is binary: on or off; no granular per-component overrides at platform tier (those are `harness-config.json`'s job).

### Deferred to writing-plans phase

5. **Q-EXTERNAL-LICENSE**: external cache license compatibility. **Default chosen pending user override**: per-domain TTL config + `license` field on `citations.ndjson`. Phase 3 ships with a small allowlist (arxiv, MDN, official Mozilla / Python / Rust / Apple docs); proprietary domains require explicit user override at cite time (`/superpowers:knowledge cite <url> --license-override`). Per-domain TTL defaults: arxiv = perpetual, MDN = 90d, official docs = 30d, override domains = 7d. Writing-plans phase finalizes the allowlist + TTL table.

---

## Sources

- `docs/retros/meta-retro-2026-05-08-superpowers-v2.8.x.md` — retract-trigger pattern (T1–T4) and add-bias warning that bounds Phase 1 scope.
- [Collaborative Memory: Multi-User Memory Sharing in LLM Agents with Dynamic Access Control](https://arxiv.org/abs/2505.18279) — two-tier private/shared memory model with provenance attributes; informs §6 tier matrix.
- [Personal Knowledge Graphs in AI RAG-powered Applications with libSQL](https://turso.tech/blog/personal-knowledge-graphs-in-ai-rag-powered-applications-with-libsql) — symbolic vs. vector trade-off referenced in §7 Q-KG-SCHEMA.
- [SQLite Edge Production: 2026 Database Renaissance](https://byteiota.com/sqlite-edge-production-2026-database-renaissance/) — encryption-at-rest baseline (deferred to v4.x).
- [LLM Wiki: Karpathy's Local Knowledge Base Setup](https://www.kunalganglani.com/blog/llm-wiki-karpathy-local-knowledge-base) — local-first defaults backing NFR-07 zero-cost-default principle.
