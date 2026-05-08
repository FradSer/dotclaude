# superpowers v3.x knowledge platform — Best Practices Research

Status: research draft, 2026-05-09. Scope: security/privacy, performance, code quality,
common pitfalls, v3.x-specific antipatterns. Not architecture, not BDD — these are the
guardrails any v3.x design must respect to avoid repeating v2.8.x's add-bias arc
(`docs/retros/meta-retro-2026-05-08-superpowers-v2.8.x.md:90-108`).

---

## 1. Security & Privacy

**Privacy tier 4-layer landing.** The four tiers (local-only / cross-session /
cross-project / external) must be **physically separable on disk**, not just policy
labels. Recommended layout: `${PROJECT_ROOT}/docs/retros/` (local-only,
already in use — see `superpowers/lib/bail-log.sh:39-41`), `${XDG_STATE_HOME}/superpowers/sessions/`
(cross-session, per-project subdir), `${XDG_DATA_HOME}/superpowers/pool/` (cross-project,
single user-scoped store), and **no built-in external tier** — external = "the user
exports manually". Each tier write goes through one helper that enforces the path
prefix, so a misrouted write fails closed rather than leaks up a tier.

**Cross-tier opt-in UX.** Voice/ambient AI scribe research shows two failure modes:
default-opt-in causes regulatory exposure (Google's $68M Assistant settlement, ABA
Health Law on ambient scribes) and re-prompting on every event causes consent fatigue
that flips users to "approve all". The middle path: **once-per-tier-per-project**
prompt via `AskUserQuestion`, persisted as `.superpowers/privacy.local.yaml`,
versioned with a schema_version. When the schema bumps (e.g. a new data category
joins cross-project), re-prompt only the affected category — never the whole consent
form. No bundled "approve all" button.

**Encrypted at rest.** local-only tier inherits the user's FileVault posture and
needs no app-layer encryption — adding it is theatre. cross-session and cross-project
SHOULD be encrypted because they outlive the project context. Recommendation:
**SQLCipher with key in macOS Keychain via `security` CLI** (Zetetic SQLCipher; data
stays AES-256 at rest, query API unchanged). Reject `age` for the hot path: age is
file-granular, so any read forces a full-file decrypt; SQLCipher pages are the right
unit. Reject app-managed key files in `~/.config/`: that just moves the secret one
indirection away with no Keychain ACL. If SQLCipher dependency is unacceptable, the
fallback is plaintext SQLite + `chmod 600` + a `KNOWN_LIMITATIONS.md` entry — better
than fake encryption.

**AI conversation logs — default off.** Stanford 2025 chatbot privacy research and
ABA ambient-scribe analysis converge on one rule: passive transcript capture is the
single highest-PII channel in any agentic system. v3.x MUST default this off. Capture
is opt-in per session, with an in-band banner ("transcript logging ON for this
session") rendered every N turns so the user cannot forget. No silent multi-session
batch-up.

**Cross-project pool red lines (threat model).** Threats: (T-A) project A's secrets
leak into project B's brainstorming context; (T-B) a future maintainer accidentally
adds a `git push` of the pool to a shared remote; (T-C) `claude --dangerous` or a
sloppy MCP tool exfiltrates the pool. Mitigations, in order: pool path MUST NOT
live under any git-tracked tree (kills T-B); pool entries MUST be content-hashed
and stripped of absolute paths and git remote URLs at write time (reduces T-A
blast radius); pool reads MUST be tier-gated through the same helper that consent
checks (kills T-C-by-default). Never upload, never cross-user, no telemetry — these
are not configurable knobs.

## 2. Performance

**post-plan-diff Stop-hook budget.** The current implementation
(`superpowers/lib/post-plan-diff.sh:114-150`) uses `post_plan_summary`'s
streaming `git log | classify` path specifically to avoid the per-commit `jq` fork
that the NDJSON `list` path needs — already a v2.8.2 optimization round. v3.x
budget: **Stop hook must stay under ~50 ms p50, ~200 ms p99** on a 100-commit
window. Any new knowledge-platform Stop-hook write must obey the same `set -e`-free,
best-effort, append-only pattern (`bail-log.sh:14-16` and `:31-62`). No synchronous
fanout to multiple files, no embedded LLM call, no network — Stop-hook is **not** a
place to compute embeddings.

**Cross-project query laziness.** Pool reads MUST be lazy. Specifically: only the
brainstorming Phase 1 step that asks "have we solved a similar problem before?"
triggers a read, with an explicit time/result cap (e.g. ≤200 ms, ≤5 hits). No
ambient watcher, no SessionStart pre-warm, no PreCompact dump. The retro's add-bias
warning applies: ambient scan feels valuable but produces "another channel of noise
to triage" rather than measurable yield.

**Conversation log capture must be non-blocking.** When transcript capture is on,
writes go to a per-session ndjson append in `${XDG_STATE_HOME}/superpowers/sessions/<id>.ndjson`,
fire-and-forget. The capturing process MUST NOT hold a lock or fsync per turn — a
crashed tail line is acceptable; a frozen sibling Claude session is not.

**File system vs sqlite threshold.** Empirical rule from local-first PKM literature
(Obsidian, Anytype, AFFiNE) and SQLite forum guidance: under ~10k entries with
predominantly append-and-grep access, **flat ndjson + ripgrep beats sqlite** on
ops-overhead. Cross over to sqlite when (a) entries exceed ~10k, (b) queries
require non-trivial joins, or (c) encryption-at-rest is required (sqlcipher pages
> per-line gpg). Choose per-tier, not platform-wide. local-only = ndjson today
and probably forever.

## 3. Code Quality

**BDD-driven TDD.** Per project CLAUDE.md: every new behavior begins with a
`.feature` Given/When/Then before any test or production line. v3.x knowledge-layer
features especially — privacy gates, tier transitions, retract logic — must have
executable scenarios. Without them, "best-effort, fail-closed" claims are
unfalsifiable.

**Clean Architecture mapping.** The knowledge layer is **infrastructure**, not
domain. Domain stays pure (calibration concepts, plan/retro value objects, tier
enum). Application orchestrates: "given a brainstorm request, ask the knowledge
port for similar prior solutions". Composition root (`cmd/` equivalent — for
superpowers, the SKILL.md instructions and lib/ helpers wired by hooks) does the
wiring. The knowledge layer NEVER imports from skills — skills depend on a
narrow port. This rules out the temptation to put "smart" relevance ranking
inside the SQLite helper.

**Best-effort lib helpers.** v2.8.x already established the pattern: helpers
have **no `set -e`** (`bail-log.sh:14-16`, `post-plan-diff.sh:32-33`), missing
deps return 0 silently, hot-path writes are wrapped in `|| true`. Replicate
exactly for any v3.x lib/ addition. A knowledge-platform helper that crashes
the Stop hook is worse than one that silently no-ops — the meta-retro's R3
retract (`meta-retro-2026-05-08-superpowers-v2.8.x.md:147-157`) shows what
happens when "useful field" turns into 0 downstream consumers + maintenance tax.

**Add-bias detection at PR time.** v2.8.x produced ~1,479 net inserted lines
where ~80 were real bug fix (meta-retro §1). Adopt a hard PR rule: when
**inserted:deleted ratio > 10:1 and the diff is in `superpowers/`**, the PR
description MUST include a "what would break if this were skipped?" paragraph.
This is the meta-retro's §4 "external mechanism review" prompt operationalized
at PR time, not 6 months after.

## 4. Common pitfalls (v2.8.x meta-retro distilled)

**"I can add X to make Y better" trap.** Per `meta-retro:90-108`: implementation-mode
LLMs default to visible-add over invisible-skip because adding produces tangible
output. Counter-question on every v3.x mechanism: *"if X did not exist, how much
worse would Y actually be — measured, not hypothesized?"* The meta-retro's R1
veto-gate retract is the canonical example — added to "protect" Phase 4, but Phase
4 was already the protection.

**N=1 framing abuse.** v2.8.1 was triggered by *one* disable decision being wrong
in *one* project (meta-retro §2: "upgraded 'one user retrospective decision was
wrong' into 'systemic bias'"). v3.x rule: a single anecdote is grounds for *a
hypothesis*, never for a *new mechanism*. Mechanisms ship after ≥3 distinct
projects show the pattern (the meta-retro's T1 trigger, `:178-182`).

**Pacing — no 5-round single-session arcs.** v2.8.x stacked v2.8.0 → v2.8.1 →
v2.8.2 → simplify → ultrathink-agent in one session, each patching the prior
(meta-retro §4). v3.x rule: between any two superpowers commits, **at least one
real-project dogfood** must occur. The meta-retro's §6 closing line is explicit:
"do not execute v2.9.0 inside the same conversational arc that produced v2.8.x".
v3.x inherits the rule.

**Mechanism-stacking review gap.** Each individual addition looks defensible;
the cumulative system is unknowable (meta-retro §4). Schedule an external
mechanism review every N major changes — independent agent, isolated context,
explicit license to recommend retract. Code-layer `simplify` is not a substitute;
it caught comment verbosity, not gates that should not exist.

**Conventional-commit assumption.** `post-plan-diff.sh:41-42` hardcodes
`refactor/fix/style/perf` as feedback signals. v3.x knowledge platform serves
projects that may use plain English, gitmoji, or no convention at all. Any
classification helper MUST degrade gracefully to `unknown` (already correct in
the v2.8.x helper at `:59-61`) and MUST NOT make decisions on `unknown`
without a human in the loop.

## 5. v3.x-specific antipatterns

**"Knowledge graph cathedral" syndrome.** GraphRAG/KG literature (Neo4j
GraphRAG, MDPI 2024 KG construction survey) is honest about the cost: incremental
graph maintenance is research-grade, not productized. For a single-user
plugin operating on a few hundred plans across a few projects, **a flat
ndjson append log with ripgrep beats any graph schema on every axis except
"sounds impressive"**. Reject graph models until N (entries) × Q (cross-entity
queries) actually exceeds what flat-search can answer in <100 ms.

**Ambient transcript capture as default.** Stanford 2025 chatbot-privacy
research and the ABA ambient-scribe analysis are unanimous: full-volume
passive capture of LLM dialogue is privacy fire — the highest-PII data
channel in any agentic system, with consent regimes still unsettled.
v3.x MUST NOT introduce always-on capture, even behind a "you can disable
in settings" toggle. Capture is per-session opt-in with visible status
(see §1).

**Meta-recursive over-nesting.** The proposed v3.x design adds calibration
loops to component additions. The temptation will be to add a calibration
loop *to the calibration loop* (which mechanism reviews the mechanism review?).
The meta-retro's §4 already names this risk by analogy. Hard rule: **at most
one level of meta**. The mechanism-review described in §3 is a flat
PR-time prompt and a calendar timeout (cf. meta-retro T3,
`:182`), not a recursively self-evaluating subsystem. If v3.x finds itself
designing "calibration of calibration", stop and retract.

---

## Sources

- `docs/retros/meta-retro-2026-05-08-superpowers-v2.8.x.md` (in-repo)
- `superpowers/lib/bail-log.sh`, `superpowers/lib/post-plan-diff.sh` (in-repo)
- [Stanford Report — AI chatbot privacy risks (2025)](https://news.stanford.edu/stories/2025/10/ai-chatbot-privacy-concerns-risks-research)
- [ABA Health Law — Ambient AI Scribes privacy/cybersecurity](https://www.americanbar.org/groups/health_law/news/2026/ambient-ai-scribes-privacy-cybersecurity/)
- [Tech-Channels — Google $68M ambient-AI settlement](https://www.tech-channels.com/breaking-news/always-listening-rarely-trusted-googles-68m-privacy-settlement-the-limits-of-ambient-ai)
- [LocArk — Privacy-First Knowledge Management 2025](https://locark.com/privacy-first-knowledge-management-2025/)
- [Zetetic SQLCipher product overview](https://www.zetetic.net/sqlcipher/)
- [SQLCipher GitHub repo](https://github.com/sqlcipher/sqlcipher)
- [Blackhawk — best practices for securing SQLite](https://blackhawk.sh/en/blog/best-practices-for-securing-sqlite/)
- [TruffleSecurity — pre-commit hooks and secrets leakage limits](https://trufflesecurity.com/blog/do-pre-commit-hooks-prevent-secrets-leakage)
- [Gitleaks GitHub repo](https://github.com/gitleaks/gitleaks)
- [LangChain — calibrating LLM-as-a-judge with human corrections](https://www.langchain.com/articles/llm-as-a-judge)
- [Anthropic Engineering — demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)
- [arXiv 2604.16790 — Bias in the Loop: Auditing LLM-as-a-Judge](https://arxiv.org/html/2604.16790v1)
- [Neo4j Developer Blog — Knowledge Graph Generation](https://neo4j.com/blog/developer/knowledge-graph-generation/)
- [MDPI Information 15(8):509 — KG Construction state and challenges](https://www.mdpi.com/2078-2489/15/8/509)
