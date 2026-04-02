# Executing Plans Details (2/2)

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when plan says to
- Between batches: just report and wait
- Stop when blocked, don't guess
- **Teammate Blocker:** If a teammate hangs or fails, use "Talk to teammates directly" or "Shut down teammates" to intervene.
- Never start implementation on main/master branch without explicit user consent

## Integration

**Required workflow skills (MANDATORY for all execution modes):**
- **Superpowers: Agent Team Driven Development** - Load `superpowers:agent-team-driven-development` skill using the Skill tool for team coordination guidance
- **Superpowers: Behavior Driven Development** - Load `superpowers:behavior-driven-development` skill using the Skill tool for BDD/TDD workflow guidance
- **Superpowers: Writing Plans** - Load `superpowers:writing-plans` skill using the Skill tool to create the plan this skill executes

## Evaluator Escalation

When the independent superpowers-evaluator is enabled, evaluation-driven escalation supplements existing escalation triggers.

### Trigger: Evaluator Rework After 2 Rounds

**Condition:** A task or batch receives REWORK or FAIL verdict from the superpowers-evaluator in 2 consecutive evaluation rounds.

**Evidence to include in escalation:**
- Evaluation scores from both rounds (per-dimension)
- Rework items from both rounds (file:line references, issue descriptions)
- Files reviewed by the superpowers-evaluator
- Evaluation report file paths (e.g., `evaluation-round-1-batch-2.md`, `evaluation-round-2-batch-2.md`)

**User options:**
| Option | Description |
|--------|-------------|
| Accept as-is | User accepts current quality, task marked complete with noted exceptions |
| Provide guidance | User gives specific direction for a targeted fix (no further evaluation rounds) |
| Abort task | Task is cancelled; dependent tasks are re-evaluated for impact |

### Trigger: Pivot Flag Raised

**Condition:** The superpowers-evaluator sets `pivot: true` in the evaluation report, indicating sustained low scores (2 or below on 2+ dimensions across 2 evaluation rounds).

**Evidence to include in escalation:**
- Pivot rationale from evaluation report
- Affected task IDs and scores
- Suggested plan modifications from the superpowers-evaluator

**User options:**
| Option | Description |
|--------|-------------|
| Continue as planned | Override pivot recommendation, proceed with current approach |
| Re-scope | Modify remaining tasks based on the superpowers-evaluator's suggestions |
| Pause execution | Stop execution for manual plan revision |

### Integration with Existing Triggers

Evaluator escalation triggers coexist with existing triggers (repeated verification failure, missing dependency, unclear instruction, teammate blocker). When multiple triggers fire simultaneously, present all to the user in a single AskUserQuestion with combined evidence.
