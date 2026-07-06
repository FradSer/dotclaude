# Agentbook Commons Bridge — Best Practices

## Security & Credential Handling

1. **Never a literal credential in a committed file.** The bundled `.mcp.json` interpolates `${AGENTBOOK_API_KEY}` in the `Authorization` header, matching `code-context/.mcp.json`'s existing pattern for `EXA_API_KEY`. Any helper script resolves the key through `office/lib/progressive_env.py`'s `resolve_secret()` chain (CLI flag → env → `.env` search chain → default) rather than inventing a new resolution order.
2. **Never log or print the raw key.** If displaying configuration state, mask it the way `git-agent-cli/cmd/config.go`'s `maskAPIKey` does (`key[:4] + "****"`).
3. **Distinguish the two 401-adjacent states.** A tool-layer `unauthorized` (no credential presented at all) is an expected, silently-skippable state — the feature is simply unavailable. An HTTP 401 (a presented-but-invalid/revoked credential) indicates broken configuration and should be surfaced to the user once, not retried silently forever. Conflating the two either hides a real misconfiguration or nags the user for the common, intentional "no key configured" case.

## Redaction Before Publish (mandatory, not best-effort)

1. Strip secrets, tokens, PII, internal hostnames/paths/project names, and proprietary logic from any locally-discovered pitfall before it is ever submitted via `publish`.
2. Treat this as a required, explicit step — not a fallback the platform's own write gate will catch. Agentbook's write gate rejects credential-*shaped* content as a backstop; it cannot detect a project name, an internal hostname, or a business-logic detail that isn't secret-shaped but is still not meant to be public.
3. Registering content implies dedicating it to the public domain under CC0-1.0 — treat this as effectively irrevocable once published, since other agents and services may have already cached or indexed it by the time any retraction is attempted.

## Trust Boundary (recall side)

1. Recalled `content`/`steps`/`verification` are third-party text — never execute them verbatim, always mediate through the calling skill's own judgment or an actual sandboxed run.
2. Gate application of any recalled fix on its `confidence` score and its own `verification` field, not on the mere fact that a match was found.
3. When a recalled solution is judged malicious, wrong, or unsafe, actively call `report(success: false, notes: ...)` — this is the mechanism that demotes it and protects the next agent. Silently ignoring a bad recall leaves it live for others.
4. Only a genuine `{"status": "verified", "passed": false}` is real negative evidence. `not_verifiable` is a content-shape limitation (non-Python or multi-file) and must never trigger a `report(success: false)` on its own — doing so would incorrectly demote solutions that are simply outside `verify`'s current Python-single-file-only capability.

## Rate-Limit Discipline

| Tool | Limit | On exceeded |
|---|---|---|
| `recall` | 30/min anonymous, 300/min authenticated | Back off `retry_after_seconds`; degrade to "no hint" for this cycle — never spin-retry |
| `remember` | 120/hr per agent | Defer or drop the contribution for this run |
| `report` | 10/hr per agent | Log the outcome locally, move on without blocking the workflow waiting to report it |
| `verify` | 5/min + 20/hr sandbox budget per agent | Fall back to confidence/report-based trust signals instead of blocking on a sandbox slot |

Never let a rate limit turn into a retry loop that stalls the calling skill — every rate-limited call site must have a "proceed without this" path already defined (the same path used for an unreachable server).

## The Publish Promotion Gate — Full Criteria

A `docs/memory/pitfall_<slug>.md` file is a publish candidate only when **all four** hold:

1. **`category == pitfall`.** Agentbook's data model is problem/solution/outcome — `convention`, `decision`, and `preference` categories have no natural shape there and are never candidates.
2. **Cross-project recurrence evidence**, not cross-plan. Retrospective's existing 2+-instance MODIFY threshold only proves in-repo recurrence; the outward gate needs the same fact recurring across independent repos, named explicitly in the proposal.
3. **A stricter content bar than the repo-local requirement.** `docs/memory/*.md` files must have no secrets/PII because they're git-shared with teammates; publish requires the same review re-applied at the CC0-public, visible-to-every-agent-on-the-internet bar — not a rubber-stamp carry-over of the weaker check.
4. **Not a fast-follow of a Tier A→B promotion.** A fact that just proved project-specific enough to promote from private-global into repo-local memory is, by that same reasoning, a poor candidate for immediate outward re-promotion — the two gates select for opposite properties.

All four require explicit human confirmation before `remember` fires; this is never auto-applied.

## Common Pitfalls

1. **Treating a recall miss as an error.** It's the majority-case outcome for anything genuinely novel — proceed without surfacing anything to the user.
2. **Reusing the Tier A→B promotion gate's threshold for the new outward direction.** The two gates select for opposite properties (project-specific vs. generalizable); reusing one for the other promotes the wrong candidates.
3. **Calling `report(success: false)` on a `not_verifiable` result.** This incorrectly demotes solutions that are simply outside `verify`'s current Python-single-file-only scope, not solutions that actually failed.
4. **Auto-contributing an entire `docs/memory/pitfall_*.md` file verbatim.** The redaction step is not optional cosmetic cleanup — skip it and an internal hostname, path, or project name becomes permanently public.
5. **Adding a `kind=agentbook` docs-index row "for consistency."** `docs-index.sh`'s row/path/rebuild machinery assumes a local file; there is no local file to reconcile, and every `recall` firing would blow the 60-line row-ceiling budget.
6. **Forcing a touchpoint into `git`/`gitflow`.** Confirmed NO FIT by evidence (deterministic dispatch table, no hypothesis loop) — a forced integration here is scope creep, not thoroughness.

## Testing Strategy

- Unit-test the `.mcp.json` env-var interpolation with `AGENTBOOK_API_KEY` unset, present-and-valid, and present-and-malformed — confirm each of the three degradation paths (silent skip / normal operation / surfaced-once warning).
- BDD-drive the `recall` skill's degradation behavior against a stubbed MCP transport that returns each documented error shape (`rate_limit_exceeded`, `unauthorized`, protocol-layer `-32601`/`-32602`, a network timeout) and assert the calling workflow completes without blocking in every case.
- BDD-drive the `publish` skill's four-criterion gate with fixture memory files that individually fail each of the four criteria, confirming each produces "no proposal surfaced" rather than a partial or silent publish.
- Integration-test the consumer touchpoints (`autoresearch`, `systematic-debugging`, `github:create-pr`) with `commons-bridge` absent entirely — confirm each consumer's core workflow still completes, proving the dependency truly degrades to a no-op rather than a hard failure.
