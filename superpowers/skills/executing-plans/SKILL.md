---
name: executing-plans
description: Executes written implementation plans efficiently using agent teams or subagents. This skill should be used when the user has a completed plan.md, asks to "execute the plan", or is ready to run batches of independent tasks in parallel following BDD principles.
argument-hint: [plan-folder-path]
user-invocable: true
allowed-tools: ["TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Read", "Glob", "Grep", "Task", "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-superpower-loop.sh:*)"]
---

# Executing Plans

Execute written implementation plans efficiently. Each task runs in its own Superpower Loop for iterative refinement, following BDD/TDD principles.

## Initialization

1. **Resolve Plan Path**:
   - If `$ARGUMENTS` provides a path (e.g., `docs/plans/YYYY-MM-DD-topic-plan/`), look for `_index.md` or `plan.md` inside it.
   - If no argument is provided:
     - Search `docs/plans/` for the most recent `*-plan/` folder matching the pattern `YYYY-MM-DD-*-plan/`
     - If found, confirm with user: "Execute this plan: [path]?"
     - If not found or user declines, ask the user for the plan folder path.
2. **Plan Check**: Verify the plan file exists and contains actionable tasks.

## Background Knowledge

**Core Principles**: Review before execution, batch verification, explicit blockers, evidence-driven approach.

**MANDATORY SKILLS**: Both `superpowers:agent-team-driven-development` and `superpowers:behavior-driven-development` must be loaded regardless of execution mode.

## Phase 1: Plan Review & Understanding

Read `_index.md` only — task files are read on-demand during execution.

1. **Read Plan**: Read `_index.md` to understand scope, task list, architecture decisions, and dependencies. Do NOT read individual task files yet.
2. **Understand Project**: Explore codebase structure, key files, and patterns relevant to the plan.
3. **Check Blockers**: See `./references/blocker-and-escalation.md`.

## Phase 2: Task Creation (MANDATORY)

**CRITICAL**: You MUST use TaskCreate to create ALL tasks BEFORE executing any task. Task creation must complete before dependency analysis or execution begins.

1. **Extract Tasks**: Extract all tasks from the plan file. Parse each task's:
   - `subject`: Brief title in imperative form (e.g., "Implement login handler")
   - `description`: Detailed description including files, verification steps, BDD scenario reference
   - `activeForm`: Present continuous form (e.g., "Implementing login handler")
   - `depends-on`: Dependencies (if any)

2. **Create Tasks First**: Use TaskCreate to register every task
   - All tasks MUST be created before proceeding to the next phase
   - Do NOT execute any tasks until all tasks are created

3. **Analyze Dependencies**: After all tasks are created, build the dependency graph
   - Compute dependency tiers: Tier 0 = no dependencies, Tier N = all depends-on tasks are in earlier tiers
   - Within each tier, group tasks by type to maximize parallelism (e.g., all "write test" tasks together, all "implement" tasks together)
   - **Identify Red-Green Pairs**: Scan all task filenames for matching NNN prefixes (e.g., `task-002-auth-test` + `task-002-auth-impl`). Mark each such pair as a **Red-Green pair** — these are always scheduled as a coordinated unit in the same batch. The test task retains its Tier 0 position; the impl task follows immediately after in the same batch execution (not a separate batch).
   - **Target**: Each batch should contain 3-6 tasks
   - **Rule**: Every batch must contain ≥2 tasks unless it is the sole remaining batch

4. **Setup Task Dependencies**: Use TaskUpdate to configure dependencies between tasks
   - `addBlockedBy`: Array of task IDs this task must wait for before starting
   - `addBlocks`: Array of task IDs that must wait for this task to complete
   - Example: `TaskUpdate({ taskId: "2", addBlockedBy: ["1"] })` means task #2 waits for task #1

## Phase 3: Batch Execution Loop with Superpower Loop

Execute tasks in batches using Superpower Loop for each task to enable iterative refinement.

**For Each Batch**:

1. **Choose Execution Mode** (strict priority — justify any downgrade explicitly):
   - **Red-Green Pair (MANDATORY)**: If the batch contains a Red-Green pair (same NNN prefix, one `test` + one `impl`), assign exactly two dedicated agents — one per task. The test agent runs first: writes the failing test and confirms Red state. Once Red is confirmed, the impl agent starts: implements to make the test pass. Two agents, coordinated sequence within the pair. Multiple pairs across batches run in parallel. This is non-negotiable and overrides all other mode selection rules for that pair.
   - **Agent Team** (default): Use unless a specific technical reason prevents it. File conflicts or sequential `depends-on` within a batch are NOT valid reasons to downgrade — resolve by splitting the batch further.
   - **Agent Team + Worktree**: Launch parallel agents with worktree isolation when multiple agents edit overlapping files or for competitive implementation (N solutions, pick best).
   - **Subagent Parallel** (downgrade only if): Agent Team overhead is disproportionate (e.g., batch has exactly 2 small tasks). State the reason explicitly.
   - **Linear** (last resort only if): Tasks within the batch have unavoidable file conflicts that cannot be split, or the batch genuinely contains only 1 task. State the reason explicitly.

2. **For Each Task in Batch**:

   a. **Read Task Context**: Read the task file to get full context (subject, description, BDD scenario, verification steps)

   b. **Construct Task Prompt**: Build a prompt based on task type (inferred from filename suffix):

      **For `*-test` tasks (Red agent)**:
      ```
      ## Task: {subject}

      {description}

      ## BDD Scenario
      {full scenario from task file}

      ## Verification Steps
      {verification steps from task file}

      Your goal: write the failing test only (Red phase).
      - Write the test file that covers the BDD scenario above
      - Run the test and confirm it fails for the right reason
      - Do NOT write any implementation code

      Output <promise>TASK_{taskId}_COMPLETE</promise> when the test exists and fails as expected.
      ```

      **For `*-impl` tasks (Green agent)**:
      ```
      ## Task: {subject}

      {description}

      ## BDD Scenario
      {full scenario from task file}

      ## Verification Steps
      {verification steps from task file}

      Your goal: implement the minimal code to make the failing test pass (Green phase).
      - The test file already exists and is failing — do not modify it
      - Write the implementation that satisfies the BDD scenario
      - Run the test and confirm it passes
      - Refactor while keeping tests green

      Output <promise>TASK_{taskId}_COMPLETE</promise> when all verification steps pass.
      ```

      **For all other task types** (config, refactor, setup, etc.):
      ```
      ## Task: {subject}

      {description}

      ## BDD Scenario
      {full scenario from task file}

      ## Verification Steps
      {verification steps from task file}

      Execute this task and output <promise>TASK_{taskId}_COMPLETE</promise> when all verification steps pass.
      ```

   c. **Start Superpower Loop for Task**: Run via Bash with the constructed prompt:
      ```bash
      "${CLAUDE_PLUGIN_ROOT}/scripts/setup-superpower-loop.sh" "<task-prompt>" --completion-promise "TASK_<taskId>_COMPLETE" --max-iterations 20 --state-file ".claude/superpower-loop-task-<taskId>.local.md"
      ```
      Replace `<task-prompt>` with the full task prompt built in step b, and `<taskId>` with the actual task ID.
      Each task MUST use a unique `--state-file` path. This prevents parallel loops from overwriting each other's state.

   d. **Execute Task in Loop**:
      - The Superpower Loop allows iterative refinement
      - Each iteration, Claude sees previous work and can improve
      - When verification passes, output `<promise>TASK_${taskId}_COMPLETE</promise>` as the **absolute last line** — nothing after it
      - Loop continues until promise is output or max iterations reached

   e. **Mark Task Complete**: Use TaskUpdate to set status to `completed`

4. **Batch Completion**: After all tasks in batch complete, report progress and proceed to next batch

**Parallel Execution Note**: Tasks within the same batch that have no dependencies can be executed in parallel using Agent Teams, but each task still runs in its own Superpower Loop. Teammates can work on different tasks simultaneously.

See `./references/batch-execution-playbook.md`.

## Phase 4: Verification & Feedback

Close the loop.

1. **Publish Evidence**: Log outputs and test results.
2. **Confirm**: Get user confirmation.
3. **Loop**: Repeat Phase 3-4 until complete.

## Git Commit

Commit the implementation changes to git with proper message format.

See `../../skills/references/git-commit.md` for detailed patterns, commit message templates, and requirements.

**Critical requirements**:
- Commit only after Phase 4 user confirmation
- Prefix: `feat(<scope>):` for implementation changes
- Subject: Under 50 characters, lowercase
- Footer: Co-Authored-By with model name
- Commit should reflect the completed feature, not individual tasks
- Use meaningful scope (e.g., `feat(auth):`, `feat(ui):`, `feat(db):`)

## Exit Criteria

All tasks executed and verified, evidence captured, no blockers, user approval received, final verification passes.

## References

- `./references/blocker-and-escalation.md` - Guide for identifying and handling blockers
- `./references/batch-execution-playbook.md` - Pattern for batch execution
- `../../skills/references/git-commit.md` - Git commit patterns and requirements (shared cross-skill resource)
- `../../skills/superpower-loop/references/prompt-patterns.md` - Writing effective task prompts for superpower loop
- `../../skills/superpower-loop/references/completion-promises.md` - Per-task completion promise design
