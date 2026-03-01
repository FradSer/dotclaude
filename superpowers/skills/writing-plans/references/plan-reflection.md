# Phase 4: Plan Reflection - Detailed Guidance

## Goal

Use parallel sub-agents to systematically review plan files and identify gaps before committing.

## Why Reflection Matters

Implementation plans can have issues that block execution:
- Missing tasks for BDD scenarios
- Incorrect or missing dependencies
- Incomplete task structure
- Circular dependencies
- File conflicts between tasks

Reflection catches these issues before execution begins.

## Why Use Sub-Agents

Sub-agents provide:
- **Fresh perspective** - No bias from having written the plan
- **Parallel execution** - Multiple review aspects simultaneously
- **Specialized focus** - Each agent focuses on one aspect deeply
- **Objective analysis** - Independent assessment without context attachment

## Sub-Agent Launch Strategy

### Core Reflection Sub-Agents (Always Required)

Launch these three sub-agents in parallel using the Agent tool with `subagent_type=general-purpose`:

**Sub-agent 1: BDD Coverage Review**

```
You are reviewing an implementation plan for BDD scenario coverage.

Context:
- Design folder: [Provide path to design folder with bdd-specs.md]
- Plan folder: [Provide path to plan folder]

Your task:
1. Read bdd-specs.md from the design folder - extract all scenarios
2. Read all task files in the plan folder - extract BDD scenarios from each
3. Create a coverage matrix: each design scenario → covering task
4. Identify orphaned scenarios (in design but not in plan)
5. Identify extra scenarios (in plan but not in design)

Output format:
- Coverage Matrix (design scenario → task file)
- Orphaned Scenarios (not covered by any task)
- Extra Scenarios (in tasks but not in design)
- Coverage Percentage
```

**Sub-agent 2: Dependency Graph Review**

```
You are reviewing an implementation plan for dependency correctness.

Context:
- Plan folder: [Provide path to plan folder]

Your task:
1. Read all task files in the plan folder
2. Extract depends-on field from each task
3. Build a dependency graph (task → dependencies)
4. Check for cycles (A depends on B, B depends on A)
5. Check for missing dependencies (depends on non-existent task)
6. Check for unnecessary dependencies (tasks that could be parallel)
7. Verify Red-Green pairing (impl depends on its test)

Output format:
- Dependency Graph (visual representation)
- Circular Dependencies Found (if any)
- Missing Dependencies (references to non-existent tasks)
- Unnecessary Dependencies (could be parallel)
- Red-Green Pairing Issues (impl without test dependency)
```

**Sub-agent 3: Task Completeness Review**

```
You are reviewing an implementation plan for task structure completeness.

Context:
- Plan folder: [Provide path to plan folder]

Your task:
1. Read all task files in the plan folder
2. For each task, verify it has:
   - Description section
   - Execution Context section (task number, phase, prerequisites)
   - BDD Scenario section (with Given/When/Then)
   - Files to Modify/Create section
   - Steps section
   - Verification Commands section
   - Success Criteria section
3. Check for vague descriptions (e.g., "implement feature" without specifics)
4. Check for missing file paths
5. Check for missing verification commands

Output format:
- Complete Tasks (all sections present)
- Incomplete Tasks (missing sections)
  - Task file → missing sections
- Vague Descriptions (tasks needing more detail)
- Missing File Paths (tasks without file specifications)
- Missing Verification (tasks without test commands)
```

### Additional Reflection Sub-Agents (Launch as Needed)

**Red-Green Pairing Review** (for plans with many test/impl tasks):

```
You are reviewing an implementation plan for Red-Green task pairing.

Context:
- Plan folder: [Provide path to plan folder]

Your task:
1. Read all task files in the plan folder
2. Identify test tasks (type=test or contains "test" in filename)
3. Identify impl tasks (type=impl or contains "impl" in filename)
4. Check that test and impl tasks for the same feature share the same NN prefix
5. Verify each impl task depends on its paired test task
6. Identify orphaned test tasks (no corresponding impl)
7. Identify orphaned impl tasks (no corresponding test)

Output format:
- Paired Tasks (test → impl, sharing NN prefix)
- Orphaned Test Tasks (test without impl)
- Orphaned Impl Tasks (impl without test)
- Incorrect Pairing (different NN prefixes)
- Missing Dependencies (impl doesn't depend on test)
```

**File Conflict Review** (for plans with many file modifications):

```
You are reviewing an implementation plan for file conflicts.

Context:
- Plan folder: [Provide path to plan folder]

Your task:
1. Read all task files in the plan folder
2. Extract file paths from "Files to Modify/Create" sections
3. Build a file → tasks mapping
4. Identify files modified by multiple tasks
5. Check if parallel tasks modify the same files (potential conflict)
6. Verify sequential ordering for conflicting file modifications

Output format:
- File Usage Matrix (file → tasks that modify it)
- Potential Conflicts (same file modified by parallel tasks)
- Safe Parallelization (files used by only one task)
- Recommendations (ordering or merging suggestions)
```

## Integration Workflow

### 1. Collect Sub-Agent Results

Use TaskOutput tool to retrieve results from all launched sub-agents.

### 2. Synthesize Findings

Merge findings into a unified issue list:

| Category | Issue | Severity | Fix Action |
|----------|-------|----------|------------|
| Coverage | "Scenario X not covered" | High | Add task |
| Dependency | "Circular: A→B→A" | High | Restructure |
| Completeness | "Task Y missing files" | Medium | Add section |
| Pairing | "Impl Z has no test" | Medium | Add test task |

### 3. Prioritize Issues

**High Severity** (must fix before commit):
- Missing BDD scenario coverage
- Circular dependencies
- Tasks without verification commands
- Missing Red-Green pairing

**Medium Severity** (should fix):
- Incomplete task sections
- Unnecessary dependencies (limits parallelism)
- Vague descriptions
- Potential file conflicts

**Low Severity** (nice to have):
- Minor wording improvements
- Additional context

### 4. Update Plan Files

Based on prioritized issue list:

1. **Add missing tasks** - Create tasks for orphaned scenarios
2. **Fix dependencies** - Remove cycles, add missing, remove unnecessary
3. **Complete sections** - Add missing files, steps, verification
4. **Clarify descriptions** - Make vague tasks specific
5. **Fix pairing** - Ensure Red-Green tasks are properly paired

### 5. Re-Verify Updated Sections

For significant updates, consider launching a quick verification sub-agent:

```
You are verifying that specific issues have been addressed.

Issues that were identified:
[List the specific issues that were fixed]

Your task:
1. Read the updated task files in docs/plans/YYYY-MM-DD-<topic>-plan/
2. Verify each issue is now resolved
3. Report any issues that remain

Output format:
- Verification Results (issue → resolved: yes/no)
- Remaining Issues
```

## Output

- Updated plan with complete BDD coverage
- Correct dependency graph (no cycles, no missing deps)
- All tasks have complete structure
- Proper Red-Green task pairing
- No file conflicts in parallel tasks

## Anti-Patterns to Avoid

- **Skipping reflection** - "The plan looks good enough"
- **Single-agent reflection** - Not leveraging parallel sub-agents
- **Ignoring coverage gaps** - Proceeding with incomplete plans
- **Ignoring dependency issues** - Will cause execution failures
- **Incomplete task structure** - Executors won't have enough context
