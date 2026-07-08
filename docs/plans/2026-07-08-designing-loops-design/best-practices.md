# Designing Loops — Best Practices (v2, reference-file shape)

## Loop-selection pitfalls (content of `loop-types.md` itself)

**Over-recommendation is over-engineering.** Recommending `/schedule` for one-off work, or `/goal` for a single mechanical edit, imposes overhead the task never needed. `loop-types.md` opens with the stay-out-of-the-way rule (REQ-005) mirroring the plugin-wide Bail-Out philosophy — and the shape pivot recorded in `_index.md` is this principle applied to the design itself: the round-1 auto-loading skill was the meta-level instance of the failure its own content warns about.

**Under-recommendation under-delivers.** Telling Claude to self-judge completion on genuinely multi-step work with a real acceptance criterion abandons why `/goal` exists — explicit conditions plus a turn cap (now `goal-wrapper.md` Rule 3, REQ-010) so Claude neither stops early nor runs away.

**Time-based conflation.** Native `/loop` (platform, active) vs. the plugin's deleted v2.x `lib/loop.sh` runtime (removed v3.0.0) — different owners, different histories; the time-based section must name them unambiguously (REQ-003; regression scenario in `bdd-specs.md`).

## The advisory-vs-mandatory boundary (L2/L3 lesson, applied correctly)

The recorded L2/L3 lesson (`feedback_skill_level_enforcement`) gates **mandatory rules**: anything an agent must obey needs a `CRITICAL:` block in a loaded SKILL.md body, because L3-only rules get skipped. The pivot does not violate this: `loop-types.md` is advisory decision support (which primitive fits), not a rule an agent can "violate". The two mandatory-adjacent behaviors it touches land in loaded carriers: turn-cap discipline lives in `goal-wrapper.md` Rule 3 (reached from every command skill's existing `/goal` section), and Workflow opt-in already has its L2 CRITICAL blockquote in `executing-plans`. **Rule for future editors:** if `loop-types.md` ever grows a genuinely mandatory rule, move that rule into the consuming skill's L2 body with a CRITICAL marker and leave only the detail here — do not let the reference file become the sole home of an obligation.

## Citation-staleness discipline (adversarial-review finding, REQ-009)

"Cite, don't duplicate" solves authoring-time divergence but not maintenance-time drift: a pointer-existence grep cannot detect that a cited target changed underneath. Mitigations adopted: (a) cite by file path + section/rule **name** ("workflow-orchestration.md Rule 2 — user must opt in"), never bare line numbers — a renamed/renumbered rule then fails an obvious grep instead of silently pointing wrong; (b) keep verbatim quotes to the two Iron Law one-liners at most, since every quoted sentence is a drift surface. Residual risk stated honestly: no automated cross-file drift check exists in this repo; building one is out of scope and noted as a candidate future retrospective checklist item.

## Forward pointer: behavioral testing of guidance content

No in-repo eval harness tests whether guidance *content* actually steers Claude correctly (as distinct from `plugin-optimizer`'s structural validation). The applicable future pattern (external skill-creator methodology): repeated-run variance benchmarking over held-out classification prompts. Noted only — not built. The pivot reduced what would need testing: with no trigger surface, there is no firing-precision question left, only content quality, which the evaluator's checklist and post-ship retrospective mining already cover at the artifact level.

## Security / performance

No hooks, no env vars, no registration, no network calls, no session-start cost — a plain markdown file loaded only when a pointer is followed. The round-1 skill shape's always-resident description cost is deleted, not optimized.
