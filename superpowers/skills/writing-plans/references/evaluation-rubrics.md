# Plan Evaluation Rubrics

## Purpose

Score implementation plans across 5 dimensions before committing. Each dimension uses a 1-5 scale. Apply these rubrics during Phase 4 (Plan Reflection) to determine whether a plan is ready for execution or needs rework.

## Dimension 1: BDD Coverage

Are all design scenarios mapped to tasks?

| Score | Description |
|-------|-------------|
| 5 | Every design BDD scenario traced to specific task(s); coverage matrix complete; no orphaned scenarios |
| 4 | All scenarios covered; minor coverage gap (1 scenario split across tasks without clear mapping) |
| 3 | Most scenarios covered; 1-2 design scenarios have no corresponding task |
| 2 | Multiple design scenarios not covered; plan implements a subset of the design |
| 1 | Significant coverage gaps; plan does not reflect the design's BDD specifications |

**What to check:**
- Read `bdd-specs.md` from the design folder and list every scenario
- Read each task file and extract its BDD scenario
- Build a coverage matrix: design scenario -> task file(s)
- Flag orphaned scenarios (in design, not in plan)
- Flag extra scenarios (in plan, not in design)

## Dimension 2: Dependency Correctness

No cycles, correct depends-on, proper Red-Green pairing?

| Score | Description |
|-------|-------------|
| 5 | All dependencies correct; no cycles; all Red-Green pairs properly linked; no unnecessary sequential dependencies |
| 4 | Dependencies correct; no cycles; minor optimization opportunity (1-2 tasks could be parallel) |
| 3 | Dependencies mostly correct; 1 unnecessary sequential dependency limiting parallelism |
| 2 | Dependency errors present: missing dependency or incorrect ordering |
| 1 | Circular dependency detected OR critical dependency missing (impl before test) |

**What to check:**
- Extract `depends-on` from every task file
- Build a directed graph and run cycle detection
- Verify every impl task depends on its paired test task (Red before Green)
- Identify tasks that could run in parallel but are chained sequentially

## Dimension 3: Task Completeness

Does each task have BDD scenario, files, steps, verification?

| Score | Description |
|-------|-------------|
| 5 | All tasks have all required sections: Description, BDD Scenario (Given/When/Then), Files to Modify/Create, Steps, Verification Commands, Success Criteria |
| 4 | All tasks have required sections; 1 task has a section that could be more detailed |
| 3 | Most tasks complete; 1-2 tasks missing a non-critical section (e.g., Success Criteria) |
| 2 | Multiple tasks missing sections; BDD scenarios or verification commands absent |
| 1 | Tasks are skeletons; major sections missing across multiple tasks |

**Required sections per task file:**

```
- Description
- Execution Context (task number, phase, prerequisites)
- BDD Scenario (Given/When/Then)
- Files to Modify/Create
- Steps
- Verification Commands
- Success Criteria
```

## Dimension 4: Verification Quality

Are verification commands specific and testable?

| Score | Description |
|-------|-------------|
| 5 | All tasks have specific, runnable commands that test the exact acceptance criteria; exit codes defined |
| 4 | Commands are specific and runnable; minor gap (1 command tests output format but not logic) |
| 3 | Commands exist but some are generic (e.g., "file exists" without content verification) |
| 2 | Commands are vague or incomplete; some tasks have no verification |
| 1 | No meaningful verification commands; tasks cannot be independently verified |

**Weak vs strong verification examples:**

Weak (score 2-3):
```bash
# Only checks existence
test -f src/auth/handler.ts && echo "PASS"
```

Strong (score 4-5):
```bash
# Runs the specific test tied to the BDD scenario
pnpm vitest run tests/auth/handler.test.ts --reporter=verbose
# Verify exit code
echo "Exit code: $?"
```

## Dimension 5: Granularity

Are tasks appropriately sized?

| Score | Description |
|-------|-------------|
| 5 | All tasks are single-responsibility; estimable in 1 focused session; clear boundaries |
| 4 | Good granularity; 1 task slightly large but has clear internal steps |
| 3 | Most tasks appropriate; 1-2 tasks try to do too much (multiple concerns in one task) |
| 2 | Multiple over-sized tasks; or excessive micro-tasks that should be combined |
| 1 | Tasks are either monolithic (entire feature in one task) or trivially small (one line per task) |

**Signs of poor granularity:**
- Task touches more than 4 files across unrelated modules -> too large
- Task modifies a single import statement and nothing else -> too small
- Task description includes "and also" or lists multiple unrelated changes -> split it
- Task has no BDD scenario because it is too small to warrant one -> combine with neighbor

## Verdict Rules

| Verdict | Condition |
|---------|-----------|
| PASS | All dimensions >= 3 AND no dimension == 1 |
| REWORK | Any dimension < 3 OR any dimension == 1 |

When the verdict is REWORK, list each failing dimension with its score and a specific action to raise it to at least 3.

## Scoring Summary Template

Use this template to record evaluation results:

```
## Plan Evaluation: [Plan Name]

| Dimension | Score | Notes |
|-----------|-------|-------|
| BDD Coverage | X/5 | |
| Dependency Correctness | X/5 | |
| Task Completeness | X/5 | |
| Verification Quality | X/5 | |
| Granularity | X/5 | |

**Verdict**: PASS / REWORK
**Actions** (if REWORK):
- [ ] ...
```

## Calibration Example

Below is a worked evaluation of a realistic plan folder.

### Plan: `docs/plans/2026-03-15-user-auth-plan/`

The plan implements a user authentication feature with 8 tasks. The design folder at `docs/plans/2026-03-15-user-auth-design/bdd-specs.md` defines 5 BDD scenarios: login-success, login-invalid-credentials, token-refresh, logout, session-expiry.

**`_index.md` Execution Plan:**

```yaml
tasks:
  - id: "001"
    subject: "Setup auth module structure"
    type: "setup"
    depends-on: []
  - id: "002"
    subject: "Login success test"
    type: "test"
    depends-on: ["001"]
  - id: "002"
    subject: "Login success implementation"
    type: "impl"
    depends-on: ["002"]
  - id: "003"
    subject: "Invalid credentials test"
    type: "test"
    depends-on: ["001"]
  - id: "003"
    subject: "Invalid credentials implementation"
    type: "impl"
    depends-on: ["003"]
  - id: "004"
    subject: "Token refresh test and implementation"
    type: "impl"
    depends-on: ["002", "003"]
  - id: "005"
    subject: "Logout test"
    type: "test"
    depends-on: ["004"]
  - id: "005"
    subject: "Logout implementation"
    type: "impl"
    depends-on: ["005"]
```

### Evaluation

**BDD Coverage: 3/5**
- login-success -> task-002 (covered)
- login-invalid-credentials -> task-003 (covered)
- token-refresh -> task-004 (covered)
- logout -> task-005 (covered)
- session-expiry -> NOT COVERED (orphaned scenario)
- One design scenario has no corresponding task. Add a task-006 pair for session-expiry.

**Dependency Correctness: 4/5**
- No cycles detected.
- All impl tasks depend on their test tasks (Red before Green).
- Minor optimization: task-004 depends on both 002 and 003, but it only needs the auth module from 001. The dependency on 002/003 is unnecessary if token-refresh is independent of login logic. Could parallelize.

**Task Completeness: 2/5**
- task-004 (token-refresh) combines test and impl into one task, missing a separate Red phase.
- task-001 (setup) has no BDD scenario and no Verification Commands section -- acceptable for setup tasks only if verification is present. In this case, verification is absent.
- Two tasks missing critical sections.

**Verification Quality: 3/5**
- task-002 and task-003 have specific test commands: `pnpm vitest run tests/auth/login.test.ts`
- task-004 verification is generic: `test -f src/auth/token.ts && echo "PASS"` -- checks file existence only, does not run tests.
- task-005 has proper verification.
- One task has weak verification that does not test acceptance criteria.

**Granularity: 4/5**
- Most tasks are single-responsibility Red-Green pairs.
- task-004 combines test and implementation for token-refresh. Slightly large but has clear internal steps listed.

### Summary

```
## Plan Evaluation: user-auth-plan

| Dimension | Score | Notes |
|-----------|-------|-------|
| BDD Coverage | 3/5 | session-expiry scenario not covered |
| Dependency Correctness | 4/5 | task-004 deps could be relaxed |
| Task Completeness | 2/5 | task-004 missing Red phase; task-001 missing verification |
| Verification Quality | 3/5 | task-004 uses file-existence check only |
| Granularity | 4/5 | task-004 slightly large |

**Verdict**: REWORK
**Actions**:
- [ ] Add task-006 test/impl pair for session-expiry scenario
- [ ] Split task-004 into separate test and impl files
- [ ] Add verification commands to task-001 (e.g., directory structure check)
- [ ] Replace task-004 file-existence check with actual test runner command
```

Task Completeness scored 2 (below 3), so the verdict is REWORK. After applying the listed actions, re-evaluate to confirm all dimensions reach at least 3.
