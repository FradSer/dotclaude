# Definition of Done (executing-plans)

These rules are non-negotiable and override all other guidance in the skill.

**PROHIBITED outputs** — a task MUST NOT be marked `completed` if it produces any of the following:

- Stub files: files containing only function signatures, `pass`, or `...` with no logic
- Placeholder implementations: `TODO`, `FIXME`, `NotImplemented`, `raise NotImplementedError`, or equivalent in any language
- Empty function bodies: functions that return a hardcoded default or `None`/`null` without executing real logic
- Skeleton-only files: files with only imports, type declarations, or class definitions but no method bodies

**A task is "done" only when ALL of the following are true:**

1. Verification commands from the task file exit with code 0
2. Expected output matches actual output (no test failures, no assertion errors)
3. No prohibited patterns exist in any file written during the task
4. The implementer sub-agent ran the verification command **this turn** and pasted command + exit code + output tail as evidence (per the `superpowers:verification-before-completion` skill — no completion claims without fresh verification evidence)
5. The batch coordinator's returned verdict is PASS (evaluator PASS on the batch containing this task)

Verification failure handling lives inside the batch coordinator (see `./batch-execution-playbook.md` — Verification Gate + Rework Loop). The main agent never retries verification in its own context; it receives a structured PASS / REWORK_ESCALATED / PIVOT result from the coordinator.
