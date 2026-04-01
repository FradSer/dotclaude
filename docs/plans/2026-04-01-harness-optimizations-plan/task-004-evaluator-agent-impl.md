# Task 004: Create evaluator agent definition

**depends-on**: task-002

## Description

Create the Independent Evaluator agent at `superpowers/agents/evaluator.md`. This is the core artifact of the harness optimizations -- an architecturally separate agent that reviews completed work with a skeptical lens. The evaluator is spawned as a sub-agent (not teammate) to ensure conversation context isolation from the generator. It has restricted tools (no Write/Edit) to prevent it from fixing code itself. The agent prompt must include few-shot calibration examples and reference Level 3 files for rubrics and formats.

## Execution Context

**Task Number**: 004 of 10
**Phase**: Core Features (REQ-001)
**Prerequisites**: Task 002 (evaluation file formats must exist for the evaluator to reference)

## BDD Scenario

```gherkin
Scenario: Evaluator is architecturally separate from generator
  Given the evaluator agent definition exists at superpowers/agents/evaluator.md
  When the evaluator is spawned via the Agent tool
  Then it runs as a sub-agent (not teammate)
  And it has no shared conversation context with the generator
  And it receives only artifacts and sprint contract -- not the generator's self-assessment

Scenario: Evaluator has restricted tools preventing code modification
  Given the evaluator agent definition
  When its tools list is inspected
  Then it includes Read, Grep, Glob
  And it includes Bash(test:*), Bash(npm:*), Bash(pnpm:*)
  And it does NOT include Write or Edit
  And this prevents the evaluator from fixing code itself

Scenario: Evaluator includes few-shot calibration examples
  Given the evaluator agent definition
  When its prompt content is read
  Then it includes at least 2 example blocks following the agent pattern
  And examples cover PASS, REWORK, and FAIL verdicts
  And each example shows Context, user message, assistant response, and commentary
```


## Files to Modify/Create

- Create: `superpowers/agents/` (directory)
- Create: `superpowers/agents/evaluator.md`

## Steps

### Step 1: Create agents directory
- Create `superpowers/agents/` directory (does not currently exist)

### Step 2: Create evaluator.md agent definition
- Follow the agent definition pattern from CLAUDE.md (Role -> Responsibilities -> Process -> Standards -> Output Format)
- Include YAML frontmatter with:
  - `name: evaluator`
  - `description`: "Use this agent when..." with trigger phrases for post-batch evaluation
  - `model: inherit`
  - `color: red` (adversarial role)
  - `tools`: `["Read", "Grep", "Glob", "Bash(test:*)", "Bash(npm:*)", "Bash(pnpm:*)"]` -- no Write/Edit
- Include 2-3 `<example>` blocks (required by plugin patterns):
  - Example 1: PASS verdict -- batch meets all criteria
  - Example 2: REWORK verdict -- batch has fixable issues
  - Example 3: FAIL verdict -- batch has fundamental problems
- Agent body instructs evaluator to:
  - Read sprint contract from plan directory
  - Read produced artifacts (code, tests)
  - Run verification commands
  - Read rubrics from `references/evaluation-rubrics.md` on-demand
  - Write evaluation report following format from `references/evaluation-file-formats.md`
- Framing: skeptical, "assume issues exist until proven otherwise"
- Do NOT embed rubrics or format specs in the agent body -- reference them as Level 3 files to read on-demand

### Step 3: Verify agent structure
- Confirm frontmatter has all required fields
- Confirm tools list is restricted (no Write/Edit)
- Confirm 2-3 example blocks present
- Confirm references to Level 3 files (not embedded content)

## Verification Commands

```bash
# Directory and file exist
test -d superpowers/agents/ && test -f superpowers/agents/evaluator.md && echo "PASS: agent file exists"

# Frontmatter has restricted tools (no Write or Edit)
head -20 superpowers/agents/evaluator.md | grep -q "tools:" && \
! grep -q '"Write"' superpowers/agents/evaluator.md && \
! grep -q '"Edit"' superpowers/agents/evaluator.md && \
echo "PASS: tools restricted"

# Has example blocks
grep -c '<example>' superpowers/agents/evaluator.md | grep -qE '^[2-9]' && echo "PASS: has 2+ examples"

# References Level 3 files
grep -q "evaluation-rubrics.md" superpowers/agents/evaluator.md && \
grep -q "evaluation-file-formats.md" superpowers/agents/evaluator.md && \
echo "PASS: references Level 3 files"
```

## Success Criteria

- Agent definition created at `superpowers/agents/evaluator.md`
- Restricted tools: Read, Grep, Glob, Bash(test/npm/pnpm) only -- no Write/Edit
- 2-3 example blocks covering PASS, REWORK, FAIL verdicts
- Skeptical framing in agent body
- References `evaluation-rubrics.md` and `evaluation-file-formats.md` for on-demand reading
- Follows Role -> Responsibilities -> Process -> Standards -> Output Format structure
