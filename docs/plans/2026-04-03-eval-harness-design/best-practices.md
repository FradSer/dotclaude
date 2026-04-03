# Best Practices

## Golden Artifact Authoring

### What makes a good "high-quality" artifact

A high-quality (expected PASS) golden artifact must meet the rubric thresholds for its mode — but should NOT be trivially perfect. Perfect artifacts inflate agreement rate artificially and don't stress-test evaluator discrimination near the PASS/REWORK boundary.

Target scores for high-quality artifacts: all dimensions at 4 or 5, with at least one dimension at exactly 4. This tests whether the evaluator correctly identifies a near-perfect but imperfect artifact as PASS.

### What makes a good "low-quality" artifact

A low-quality (expected REWORK/FAIL) artifact must have at least one dimension below 3 — triggering REWORK under the standard threshold rules. The failure mode should be realistic: not obviously broken, but genuinely missing requirements in a way that matters.

Avoid "obviously bad" artifacts where every dimension scores 1. These are too easy for the evaluator and don't test discrimination near the boundary. Target: 2-3 dimensions at 2, rest at 3-4, with a clear REWORK verdict.

### Synthetic content requirement

Golden artifact content must be synthetic — not derived from real project work. Two reasons:
1. **Familiarity bias**: if the evaluator has seen real project patterns before, it may rate familiar artifacts more charitably
2. **Drift**: real project artifacts change; golden artifacts must be stable baselines

Good synthetic domains: a fictional "notification service", a "user preference manager", a "rate limiter library". Avoid domains that touch known codebase components.

### Human scoring protocol

Before adding an artifact to the golden set:
1. Score it independently (no rubric open during scoring; apply rubric after)
2. Re-read the rubric after scoring; adjust if needed
3. Write a rationale for each dimension below 4
4. For any score of 3 or below, write a rationale that names the specific missing element

Do NOT score an artifact you authored. Wait at least 24 hours before scoring your own artifacts.

### Minimum viable golden set

Per mode, minimum for a calibration run:
- 2 high-quality artifacts (different failure modes at dimension 4)
- 2 low-quality artifacts (different REWORK triggers)
- Total: 4 artifacts per mode, 12 for `--mode all`

Silver-to-gold promotion (for shared calibration sets): 2 independent scorers with >= 80% agreement rate (defined as: all dimensions within 1 point AND same verdict).

## Bias Detection and Thresholds

### Leniency bias is more dangerous than severity bias

A lenient evaluator causes false PASSes — work that should be reworked gets accepted. A severe evaluator causes false REWORKs — work gets rejected unnecessarily. False PASSes compound: they let low-quality code proceed to the next phase, where it causes harder-to-detect problems. Severity bias causes friction but is caught quickly by the user.

This means: leniency bias amendments take priority over severity bias amendments. If both are present, fix leniency first.

### Threshold calibration: don't over-tighten

After a rubric amendment, run recalibration before applying further amendments. Rubric descriptions interact non-linearly — tightening `risk_coverage` can shift evaluator behavior on `bdd_completeness` if the evaluator uses holistic reasoning. One amendment at a time, then verify.

Target: per-dimension mean_delta <= 0.75 (well within the 1.0 threshold). Aiming for exactly 0.0 is over-engineering — the evaluator is a reasoning agent, not a deterministic scorer.

### Evaluator variance across runs

The same evaluator run twice on the same artifact may produce scores ± 1 per dimension due to sampling variance. This is expected. Calibration should be run 2-3 times to establish a stable mean before attributing a delta to bias.

Consider a dimension biased only if `mean_delta > threshold` across **multiple** calibration runs, not just one.

## Pipeline Execution Safety

### Dry-run first

Always run `--dry-run` before `--apply-rubric-changes`. The dry-run output shows which amendments would be proposed; review them before applying. The rubric optimizer cannot undo its changes automatically.

### Rubric backups

Before any rubric amendment run, the `eval-orchestrator` reads and stores the current rubric content in `calibration-report.json` under a `prior_rubric_snapshot` field. This enables manual rollback if an amendment causes regression.

### Regression check protocol

After applying rubric amendments:
1. Re-run calibration on the same golden set
2. Verify all `expected_verdict` values still match evaluator verdicts (zero regression requirement — see Success Criteria SC-7 in `_index.md`)
3. If regression detected: rollback the amendment using the prior_rubric_snapshot and investigate

### Pipeline idempotency

Running `eval-harness` twice on the same golden set should produce the same calibration-report structure (modulo evaluator variance). If proposals differ significantly across runs, the golden set may be under-specified. Add more artifacts to reduce variance.

## Score Trend Tracking

### evaluation-history.json is ephemeral

Like sprint contracts, `evaluation-history.json` is a working artifact — it lives in the plan directory during execution and is NOT committed. It serves as inter-round communication between the evaluator and the generator. After plan execution completes, it can be deleted or retained for audit purposes.

### Trend classification edge cases

**First round**: trend is always `null`. Do not inject trend context in the first rework cycle — there is no baseline to compare against.

**Mixed improvement/decline**: If task "003" improves on Correctness but declines on Completeness, classify as `declining` (any decline takes precedence over improvement). This is conservative: avoid continuing when signals are mixed.

**Single-dimension tasks**: `config` and `setup` tasks are scored on fewer dimensions. `plateau` detection should only compare the applicable dimensions (N/A dimensions do not count as "unchanged").

### Plateau escalation is not failure

When a task hits `plateau` for 2 consecutive rounds and escalates, this is not a task failure — it is a signal to rethink the approach. The escalation path (per `blocker-and-escalation.md`) asks: is the issue in the implementation, the plan, or the design? Answer that before retrying.

## Rubric Optimization Guardrails

### Threshold invariant

Every rubric has implicit thresholds: FAIL = score 1, REWORK = score 2-3, PASS = score 4-5 (default). Amendments MUST NOT move a score description into a different threshold tier. For example: do not rewrite the score-3 description to describe what was previously score-2 behavior. This would silently shift the PASS/REWORK boundary.

Before proposing any amendment, the optimizer checks: does this amendment maintain the ordering `fail <= rework floor < pass`? If not, reject the amendment.

### Scope isolation

Rubric amendments affect only the mode being calibrated. Do NOT amend the design rubric based on code-mode calibration findings — the dimensions are different, and cross-mode amendments have unpredictable effects.

After amending a plan rubric, re-run design and code calibration to verify no unexpected cross-mode impact (via shared evaluator reasoning patterns).

### Amendment rationale is mandatory

Every proposed amendment must include:
- Which artifact showed the bias (artifact_id)
- Which dimension and what delta
- The specific sentence in the rubric that creates the scoring window

Amendments without this evidence should be rejected. "The rubric seems lenient" is not a valid rationale.

## Cost Considerations

### Calibration frequency

Full calibration (`--mode all`, 12 artifacts) invokes the evaluator 12 times plus bias analysis and potentially rubric optimization. This is expensive. Recommended cadence:
- Run after any change to rubric files
- Run after any change to evaluator agent definition
- Run monthly if no changes (drift detection)
- Do NOT run as part of every development workflow

### Targeted calibration

If you change only the plan rubric, run `--mode plan` only. This reduces cost by 2/3 while still validating the changed rubric.

### Session limits

A full `--mode all` run with 12 artifacts is estimated at 12-15 evaluator invocations (some code artifacts need 2 invocations: sprint contract + evaluation). This should complete within a single Claude Code session. If context limits are approached, use `--mode design`, `--mode plan`, `--mode code` in separate sessions.
