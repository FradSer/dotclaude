# Antigravity usage examples

Concrete invocations of `/antigravity:delegate` and `/antigravity:research`.

## Delegate: compute in an isolated sandbox

```
/antigravity:delegate Compute the 200th Fibonacci number and factor it. Show the code.
```

Runs `code_execution` in the remote sandbox; returns the answer plus the code trace.

## Delegate: research with code, no outbound network

```
/antigravity:delegate Summarize today's top Hacker News stories with links --network none
```

`google_search` and `url_context` still work (they run on Google infra), but the
sandbox's own code cannot make outbound connections — safest default for untrusted output.

## Delegate: analyze a GitHub repository

```
/antigravity:delegate List the three most impactful open issues and sketch fixes --repo https://github.com/owner/name
```

Mounts the repo at `/workspace/repo` so the agent can read and run against the code.

## Delegate: restrict tools

```
/antigravity:delegate Explain this algorithm and benchmark two implementations --tools code_execution
```

Disables search/URL tools; only code execution is offered to the agent.

## Research: deep, cited report

```
/antigravity:research Compare the energy density and safety tradeoffs of LFP vs NMC EV batteries in 2026
```

Runs the deep-research agent (several minutes), then returns a cited report.

## Research: max mode (deeper, slower)

```
/antigravity:research State of solid-state battery commercialization in 2026 --max
```

Uses `deep-research-max-preview-04-2026` for a higher-effort report.
