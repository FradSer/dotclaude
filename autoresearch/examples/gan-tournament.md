# Example: qualitative goal (gate + rubric, tournament on plateau)

`/autoresearch:start` is the single entry point. Give it a goal; it infers the
contract and runs the hybrid loop — cheap sequential rounds that escalate to a
parallel tournament when they stall. You rarely pass flags; this example shows
both the plain-language form and the contract it infers.

## Plain-language form

```
/autoresearch:start refactor src/parser.ts for clarity without changing behavior
```

The command inspects the repo and infers a contract like the one below (it would
ask you only if it could not find the file or a test command):

```
setup-autoresearch.sh \
  --prompt 'Refactor src/parser.ts for clarity without changing behavior.' \
  --objective 'cleaner, simpler parser; all tests stay green' \
  --edit src/parser.ts \
  --check-cmd 'pnpm test parser' \
  --rubric 'Prefer fewer branches, clear names, no dead code, smaller functions; behavior must be unchanged.' \
  --max-experiments 20
```

## What happens

- **Sequential rounds (cheap):** each round makes one change to `src/parser.ts`,
  commits, and keeps it only if `pnpm test parser` still passes (the gate). The
  rubric is dormant here — a single agent judging its own work would reward-hack.
- **Plateau escalation (the tournament):** after 3 non-improving rounds, the loop
  escalates one round to the bundled GAN engine. A few candidates each rewrite the
  file in isolated worktrees and run the gate; a **3-judge panel** ranks the
  test-passing survivors against the rubric; a synthesis grafts the best ideas and
  is re-evaluated. The winner is kept only if it still passes the gate. Then the
  loop resumes sequential rounds.

The rubric is **anchored** by the gate (`pnpm test`), so the loop can't trade
correctness for prose — `--rubric` requires a `--score-cmd` or `--check-cmd`.

## Variations

- **Numeric goal** ("minimize tour length in config/solver.yaml"): inferred as
  `--score-cmd ... --direction min`; sequential rounds optimize the number,
  escalation explores broadly when stuck.
- **Just make tests pass** ("fix the failing parser tests"): inferred as a bare
  `--check-cmd 'pnpm test parser'`; the loop iterates until the gate is green.
- A tournament round costs ~100k+ tokens, so escalation is reserved for genuine
  plateaus, and only for a single-file `--edit`.
