# Designing Loops — Architecture

Repo-root-relative paths throughout. All line numbers confirmed by direct Read during Phase 1/Phase 2 research on 2026-07-08.

## 1. New skill directory

```
superpowers/skills/designing-loops/
├── SKILL.md
└── references/
    ├── loop-types.md
    └── quality-and-token-management.md
```

Registered in `superpowers/.claude-plugin/plugin.json`'s `"skills"` array (REQ-001):

```diff
   "skills": [
     "./skills/behavior-driven-development/",
     "./skills/using-superpowers/",
     "./skills/verification-before-completion/",
-    "./skills/receiving-code-review/"
+    "./skills/receiving-code-review/",
+    "./skills/designing-loops/"
   ],
```

## 2. Frontmatter (confirmed convention)

`grep -A6 "^---$" superpowers/skills/*/SKILL.md` confirms two disjoint frontmatter shapes with no exceptions:

| Category | Fields, in order |
|---|---|
| 5 command skills (`user-invocable: true`) | `name`, `description`, [`argument-hint`], `user-invocable: true`, `allowed-tools` |
| 4 internal skills (`user-invocable: false`) | `name`, `description`, `user-invocable: false` — exactly 3 fields, no exceptions |

`designing-loops` follows the internal-skill shape exactly (see `_index.md` Detailed Design for the drafted frontmatter block).

## 3. Cross-link integration points — exact anchors

### 3.1 `superpowers/skills/using-superpowers/SKILL.md` (REQ-013)

```
19	## When to invoke which skill
20	
21	| Trigger signal | Invoke |
22	|---|---|
23	| "brainstorm", "design", "I have an idea", new feature with ambiguous shape, multi-component design | `superpowers:brainstorming` |
24	| "write a plan", "decompose into tasks", "implementation plan" — a completed design folder under `docs/plans/*-design/` exists | `superpowers:writing-plans` |
25	| "execute the plan", "run the plan", "implement", a completed plan folder under `docs/plans/*-plan/` exists | `superpowers:executing-plans` |
26	| Bug report, "fix this error", test failure, unexpected behavior, "why does X happen" | `superpowers:systematic-debugging` |
27	| After a completed plan: "let's retro", "what should we learn", "update checklists" | `superpowers:retrospective` |
28	
29	## Lineage and rationale
```

**Insert** a new section between line 27 (table end) and line 29 (`## Lineage and rationale`). **Do not** add a row to the table itself — `superpowers/hooks/session-start.sh:28` (`grep -E '^\| .*superpowers:' "$USING_SKILL"`) injects every matching row into every session's bootstrap context regardless of intent; a `designing-loops` row would be injected on every session start even though the table answers "which", not "how".

Proposed heading: `## A second axis: how to run the chosen skill`. One short paragraph, closing with a pointer to `../designing-loops/SKILL.md`.

### 3.2 Five user-invocable skills' `## Recommended: run wrapped in /goal` sections (REQ-014)

All five end their `/goal` section with a closing sentence citing `goal-wrapper.md`, immediately followed by the next `##` heading:

| Skill | Anchor: file:line (existing closing sentence) | Next heading (insert before) |
|---|---|---|
| brainstorming | `superpowers/skills/brainstorming/SKILL.md:20` | line 22 `## CRITICAL: Bail-Out Check (run before Initialization)` |
| writing-plans | `superpowers/skills/writing-plans/SKILL.md:21` | line 23 `## CRITICAL: Bail-Out Check (run first)` |
| executing-plans | `superpowers/skills/executing-plans/SKILL.md:21` | line 23 `## Step 1 of every iteration — orient via batch-progress.sh` |
| retrospective | `superpowers/skills/retrospective/SKILL.md:23` | line 25 `## Pre-Check (run first, in order)` |
| systematic-debugging | `superpowers/skills/systematic-debugging/SKILL.md:27` | line 29 `## CRITICAL: Bail-Out Check (run before Phase 1)` |

Draft sentence (brainstorming, writing-plans, executing-plans): *"To decide whether this run should be a plain turn, `/goal`, `/loop`, or `/schedule`, see `../designing-loops/SKILL.md`."*

**retrospective** (REQ-015, merged with REQ-014 into one sentence to conserve its 4671/5000-token budget): *"Retrospective runs periodically after a batch of plans ships, which makes it a natural time-based/proactive (`/schedule`) candidate rather than a one-off `/goal` run — see `../designing-loops/SKILL.md`."*

**systematic-debugging**: the goal-wrapper.md-adjacent sentence stays the plain REQ-014 form; the time-based note (REQ-016) is anchored separately at §3.3 below, not merged into this sentence, since this file has more token headroom than retrospective/writing-plans and the two notes address different sections of the file.

### 3.3 `systematic-debugging/SKILL.md` — flaky/CI time-based note (REQ-016)

```
352	## When Process Reveals No Root Cause
353	
354	If systematic investigation reveals issue is environmental, timing-dependent, or external:
355	
356	1. Process has been completed
357	2. Document what was investigated
358	3. Implement appropriate handling (retry, timeout, error message)
359	4. Add monitoring/logging for future investigation
360	
361	**Note:** 95% of "no root cause" cases represent incomplete investigation.
362	
363	## References
```

**Insert** a new sentence after line 361, before line 363. This section already names exactly the "environmental, timing-dependent" symptom class the note is about.

Also **append** a second bullet to the existing `**Related skills:**` list:

```
372	**Related skills:**
373	- `superpowers:behavior-driven-development` - BDD principles including Gherkin scenarios for test design
```

→ add: `- \`superpowers:designing-loops\` - loop-type classification (turn/goal/time/proactive) for flaky or recurring debugging work`

### 3.4 `superpowers/skills/references/workflow-orchestration.md` (REQ-017)

No existing "See also"/References section (full 52 lines confirmed — file ends at line 52 with no trailing metadata block). **Append** as a new final section:

```markdown
## See also

`../designing-loops/SKILL.md` — this is the "many independent tasks, parallel, opt-in" arm of the four loop types; the other three (goal-based/`/goal`, time-based/`/loop`, proactive/`/schedule`) live there.
```

### 3.5 `superpowers/README.md` — Internal Skills section (REQ-018)

```
133	## Internal Skills (Loaded Automatically)
134	
135	### Using Superpowers (the 1% Rule dispatcher)
136	
137	Reintroduced in v3.0.0. ...
138	
139	### Behavior-Driven Development
140	
141	Loaded when implementing features or bugfixes during execution. Enforces the Red-Green-Refactor cycle driven by BDD scenarios in Gherkin format (Given-When-Then).
142	
143	(The `systematic-debugging` skill was promoted to user-invocable in 2.4.0 — see `/superpowers:systematic-debugging` above.)
144	
145	## End-to-End Workflow
```

**Insert** three new subsections after line 143, before line 144/145: `### Verification Before Completion`, `### Receiving Code Review` (backfilling the two pre-existing undocumented entries — same section, same file, same edit pass, not a separate PR), and `### Designing Loops` (the new entry, matching the existing two entries' one-paragraph format).

Separately noted, **not fixed by this design**: `README.md:5` says `**Version**: 3.3.0` while `plugin.json` is at `3.7.0` — pre-existing, unrelated sync drift (tracked by this repo's own manual-README-sync convention), out of scope here.

## 4. Baseline validation (run 2026-07-08, before implementation)

```
$ python3 plugin-optimizer/scripts/validate-plugin.py superpowers
superpowers  (commands=0, agents=1, skills=9)

  skills/retrospective/SKILL.md  should  Token count approaching limit: 4671 tokens (max: 5000)
  skills/writing-plans/SKILL.md  should  Token count approaching limit: 4778 tokens (max: 5000)

PASSED  2 should
EXIT CODE: 0
```

No MUST violations, no token-budget-critical (exit 2) failures. The two `should` warnings are the concrete reason §3.2's retrospective edit is merged into one sentence rather than two, and the reason the implementation plan must re-run this exact command after every edit to either file.

(The validator's summary folds `plugin.json`'s `"commands"` (5) and `"skills"` (4) arrays into one `skills=9` count for this script version — not a defect relevant to this design.)

## 5. Cross-link verification (mechanical, post-implementation)

Each of the 7 integration points is independently confirmable with a single grep, per REQ-019:

```bash
grep -l designing-loops superpowers/skills/using-superpowers/SKILL.md
grep -l designing-loops superpowers/skills/{brainstorming,writing-plans,executing-plans,retrospective,systematic-debugging}/SKILL.md
grep -l designing-loops superpowers/skills/references/workflow-orchestration.md
grep -l designing-loops superpowers/README.md
```

All 7 (counting the 5-skill glob as 5) must return their filename; zero-result on any is an incomplete integration.
