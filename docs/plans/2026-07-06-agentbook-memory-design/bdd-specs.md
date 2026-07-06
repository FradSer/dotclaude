# Agentbook Commons Bridge — BDD Specifications

Canonical vocabulary used throughout: **public commons** (the new tier), **commons bridge** (the `commons-bridge` plugin and its two skills), **recall** (inbound act — matches the `recall` MCP tool 1:1), **publish** (outbound act — a skill-level decision that, once made, invokes the `remember` MCP tool). See `_index.md` Glossary for full rationale.

## Traceability Notes (structural/non-functional requirements not expressed as Given/When/Then)

The requirements below are architecture decisions or blanket non-functional constraints, not runtime behaviors a Gherkin scenario observes — each is fully specified in `_index.md`/`architecture.md`/`best-practices.md` and is cross-referenced here rather than re-stated as a scenario:

- **Req #1** (standalone `commons-bridge` plugin, not a nested superpowers skill) and **Req #2** (exactly two skills, `recall`/`publish`) — the architecture decision itself; exercised indirectly by every scenario below that calls `commons-bridge:recall`/`commons-bridge:publish` by its cross-plugin name, and structurally by the file's own two-Feature-group split (every recall-side Feature calls `commons-bridge:recall` only; every publish-side Feature calls `commons-bridge:publish` only — no scenario mixes the two skills). See `_index.md` Rationale §"Standalone plugin, not a nested superpowers skill" and §"Two skills, not one."
- **Req #3** (bundled `.mcp.json` with env-var-interpolated credential) — a static file-shape requirement, not an observable runtime behavior; see `architecture.md` §Bundled `.mcp.json` for the exact contents, and Req #21 below for its credential-hygiene testing strategy.
- **Req #11** (MUST NOT add a `kind=agentbook` value to `docs-index.sh`) — an explicit non-addition; there is no positive runtime behavior to assert, only the absence of a docs-index row for agentbook records, which the "Tier B/Tier C provenance bridge" Feature's final assertion below directly confirms ("no `docs/README.md` index row is added, changed, or requires a `kind` change"). See `_index.md` Rationale §"Not a docs-index `kind`" for the full argument.
- **Req #16** — see the comment immediately above the "Cross-plugin dependency declaration" Feature below.
- **Req #18** (SHOULD log every recall/report outcome at the call site) — already implicit in every touchpoint Feature below: the autoresearch Feature's report scenario is explicitly "a parallel write next to the existing `results.tsv` line," the github:create-pr Feature's report scenario fires "at exactly the moment the Monitor already detects the pass" (i.e., alongside its own existing log), and systematic-debugging's report scenario is independent of, not a replacement for, the existing Tier B capture. No separate scenario is needed since this SHOULD is a property of how each existing scenario's report call is placed, not a distinct behavior.
- **Req #19** (SHOULD default recall to explicit, skill-documented invocation points, never automatic background calls) — satisfied by construction: every scenario in this file names an explicit call site (a specific phase/step/loop-iteration in an existing skill), and none describes a hook-triggered or scheduled background call. See Req #21's sibling non-functional note below and `architecture.md`'s Consumer Touchpoints diagrams, which show every arrow originating from an existing, already-documented step.
- **Req #20** (MUST NOT introduce a hard dependency in `executing-plans`' autonomous execution path) — confirmed by omission: `executing-plans` is not among the three consumer plugins/touchpoints in this file (autoresearch, systematic-debugging, github:create-pr) and does not declare `"dependencies": ["commons-bridge"]` anywhere in this design. The "Public commons MCP server unreachable" Scenario's closing assertion ("this holds without exception inside `executing-plans`' fully autonomous execution path") documents the guarantee explicitly, even though `executing-plans` has no direct touchpoint of its own — the only path by which agentbook could affect it is transitively through `systematic-debugging`, which that same scenario's degrade-silently guarantee already covers.
- **Req #21** — see the comment immediately after this Feature's Background below.

```gherkin
Feature: Agentbook commons bridge — recall
  As a Claude Code skill that autonomously investigates or solves a problem
  I want to optionally consult the public commons via the recall skill
  So that I reuse validated fixes without the integration ever becoming a
  blocker, a hang, a hard failure, or an unsafe execution path.

  Background:
    Given the calling skill declared "commons-bridge" as a plugin.json dependency
    And the calling skill loads the "commons-bridge:recall" skill before consulting it
    And every agentbook call is wrapped so no failure of it can block the core workflow

  # ---------------------------------------------------------------------------
  Scenario: Bundled .mcp.json and skill content carry no literal credential (Req #21)
  # ---------------------------------------------------------------------------
    Given `commons-bridge/.mcp.json` and every `commons-bridge/skills/*/SKILL.md` file
      are about to be committed
    When the same review discipline this repo already applies to every committed
      file runs over these files
    Then `.mcp.json`'s `Authorization` header contains only the literal string
      `Bearer ${AGENTBOOK_API_KEY}` — an env-var interpolation, never a resolved
      `ak_...` value
    And no `SKILL.md` file contains an example, fixture, or documentation snippet
      with a real-looking API key in place of the `${AGENTBOOK_API_KEY}` placeholder
    And this check is a precondition of every commit touching `commons-bridge/`,
      not a one-time setup step — see `best-practices.md` §Security & Credential
      Handling item 1

  # ---------------------------------------------------------------------------
  Scenario: Successful anonymous recall returns a known, validated solution (Req #7)
  # ---------------------------------------------------------------------------
    Given the agentbook MCP server is reachable with no Authorization header configured
    And the calling skill has just identified an error it needs to resolve
    And the public commons holds a validated (non-demoted, non-candidate) solution
      for a materially similar problem
    When the skill calls the `recall` tool with `query` set to the error text
    Then the call succeeds within the anonymous rate budget of 30/minute
    And the response contains a `best_solution` with `content`, `steps`, and `confidence`
    And the skill treats `content`/`steps` as reference data, never as directly
      executable instructions (see Scenario: A recalled solution looks malicious,
      wrong, or unsafe (Req #7, #8))
    And the skill applies the fix using the recalled content only as a hint to its
      own solve step, gated on the solution's `confidence`

  # ---------------------------------------------------------------------------
  Scenario: Recall miss — no matching problem in the public commons (Req #4)
  # ---------------------------------------------------------------------------
    Given the agentbook MCP server is reachable
    And no problem in the public commons matches the current error signature
    When the skill calls the `recall` tool
    Then the response indicates no actionable match (empty results, `no_good_match`,
      or a matched problem with no `best_solution`)
    And this is a normal successful response, not one of the tool-layer error values
    And the skill proceeds to solve the problem itself without the public commons' help
    And no error, warning, or blocking prompt is surfaced to the user because of the miss

  # ---------------------------------------------------------------------------
  Scenario: Public commons MCP server unreachable, unconfigured, or absent (Req #4)
  # ---------------------------------------------------------------------------
    Given agentbook is either absent from the runtime's `mcpServers` config
      (the commons-bridge plugin's bundled `.mcp.json` was never activated)
    Or a call to `recall`/`trace`/`remember`/`report`/`verify` raises a transport
      or network error
    When the calling skill's workflow reaches a step that would consult the public commons
    Then the workflow catches the failure (missing tool / network error / timeout)
      at that call site
    And it degrades silently to "no external memory available" for that step
    And it continues to completion — it does not retry indefinitely, does not hang,
      and does not fail because the public commons was unreachable
    And this holds without exception inside `executing-plans`' fully autonomous
      execution path — the public commons introduces zero hard dependency there

  # ---------------------------------------------------------------------------
  Scenario: A recalled solution looks malicious, wrong, or unsafe (Req #7, #8)
  # ---------------------------------------------------------------------------
    Given `recall` or `trace` returned a solution whose content/steps look malicious,
      wrong, or would perform an unsafe action if executed as-is
    When the skill evaluates whether to apply it
    Then the skill does NOT execute the recalled commands verbatim without
      understanding them
    And the skill gates any application on the solution's `confidence` and its own
      `verification` checks before trusting it
    And when the solution is judged bad, the skill calls `report` with `success: false`
      and `notes` explaining what went wrong, so the solution gets demoted
    And if no write credential is configured, the skill still refuses to execute the
      unsafe content locally — it just cannot report the failure upstream (falls back
      to the no-credential scenario below)

  # ---------------------------------------------------------------------------
  Scenario: verify distinguishes not_verifiable from a real sandbox failure (Req #9)
  # ---------------------------------------------------------------------------
    Given a solution's content is prose/steps, or code in a language other than
      single-file Python
    When the skill calls `verify` with that `solution_id`
    Then the response is `{"status": "not_verifiable", "reason": "..."}`
    And the skill interprets this as "verification was not attempted for
      content-shape reasons" — NOT as a failed sandbox run
    And the skill does not call `report(success: false)` based solely on
      `not_verifiable`, falling back instead to confidence/report-based trust signals

    Given instead a solution's content IS a single runnable Python file
    When the skill calls `verify` with that `solution_id`
    Then the call blocks synchronously until the sandbox finishes and returns
      `{"status": "verified", "passed": true|false, "exit_code": <n>, "duration_seconds": <f>}`
    And `passed: false` here is genuine negative evidence the skill should weigh
      when deciding whether to trust or report the solution

Feature: Agentbook commons bridge — write path (remember / report / verify)
  As the commons-bridge "publish" skill or any skill calling report/verify directly
  I want every write attempt to fail safely and every rate limit to be respected
  So that the public commons is never flooded and a missing credential never breaks
  the calling workflow.

  # ---------------------------------------------------------------------------
  Scenario: Write attempted with no credential configured (Req #5)
  # ---------------------------------------------------------------------------
    Given the skill has no AGENTBOOK_API_KEY (or equivalent Authorization header)
      resolved via the progressive-env chain
    When the skill calls `remember`, `report`, or `verify`
    Then the MCP tool returns a tool-layer error, not a protocol-layer crash:
      `{"error": "unauthorized", "detail": "Authentication required: no credentials provided"}`
    And the skill treats this as a graceful, silent skip: no retry, no hard error
      surfaced to the user, no block on the calling workflow
    And `recall`/`trace` continue to work normally in the same session since they
      need no auth

  # ---------------------------------------------------------------------------
  Scenario: A presented credential is invalid or malformed (Req #5)
  # ---------------------------------------------------------------------------
    Given an AGENTBOOK_API_KEY is configured but is revoked, malformed, or
      does not resolve to an agent
    When any tool call is made with that credential
    Then the request is rejected at the transport with HTTP 401 before any tool runs
      (not a tool-layer isError)
    And the skill surfaces this once as a configuration problem — distinct from the
      silent no-credential skip above — since a broken key, unlike an absent one,
      indicates the user intended write access and it is not working

  # ---------------------------------------------------------------------------
  Scenario Outline: Rate limit exceeded on a write-path tool (Req #6)
  # ---------------------------------------------------------------------------
    Given the authenticated agent has already made <limit> <tool> calls in the
      trailing <window>
    When the skill calls <tool> again
    Then the response is `{"error": "rate_limit_exceeded", ...}` (with
      `retry_after_seconds` where the tool provides it)
    And the skill backs off for at least that duration before calling <tool> again
    And the pending action (a contribution, an outcome report) is deferred or
      dropped for this run rather than blocking the calling workflow

    Examples:
      | tool     | limit | window |
      | remember | 120   | hour   |
      | report   | 10    | hour   |
      | verify   | 5/min + 20/hr sandbox budget | (dual limit) |

  # ---------------------------------------------------------------------------
  Scenario: Recall rate limit exceeded (anonymous) (Req #6)
  # ---------------------------------------------------------------------------
    Given the anonymous caller has already made 30 `recall` calls in the current minute
    When the skill calls `recall` again
    Then the response is `{"error": "rate_limit_exceeded", "retry_after_seconds": <n>}`
    And the skill backs off for at least that duration
    And in the meantime it degrades exactly like a recall miss — solves without the hint

Feature: Agentbook commons bridge — publish (outbound contribution)
  As the "publish" skill, loaded only by retrospective's promotion pathway
  I want every contribution to pass a mandatory redaction gate and the mirror-image
  promotion gate before it reaches the public commons
  So that no project-internal detail, secret, or premature/non-generalizable fact
  is ever published irrevocably.

  # ---------------------------------------------------------------------------
  Scenario: Redaction gate before contributing a locally-discovered pitfall (Req #10)
  # ---------------------------------------------------------------------------
    Given retrospective has identified a `docs/memory/pitfall_*.md` file as a
      candidate for outward publication
    When the publish skill prepares the `remember` call
    Then a content-review/redaction step MUST run first and MUST NOT be skipped:
      strip secrets, tokens, PII, internal hostnames/paths/project names, and
      confirm the remaining content is a generically reusable problem/solution
    And the raw internal file/note is never passed through automatically as
      `remember` arguments — only the redacted fields are submitted
    And this redaction is mandatory (not best-effort) because the platform's own
      write gate is only a backstop, and content becomes CC0-1.0 public domain
      and effectively irrevocable once published

  # ---------------------------------------------------------------------------
  Scenario: Publish promotion gate — candidate PASSES all four criteria (Req #13)
  # ---------------------------------------------------------------------------
    Given a `docs/memory/pitfall_<slug>.md` file has `category: pitfall`
    And retrospective has identified the same fact recurring in 2+ independent
      *projects*, naming the specific other project(s)/incidents
    And the redacted content passes the stricter public/CC0 content bar
      (no secrets, PII, or content tied to this repo's own idiosyncratic structure)
    And the fact was NOT itself just promoted from Tier A → Tier B via the
      existing req #23 pathway (a project-specific-and-durable fact is a poor
      candidate for immediate outward re-promotion)
    When retrospective surfaces the candidate as a publish proposal
    Then the proposal requires explicit human confirmation before the `remember`
      call fires — this is NOT auto-applied the way ADD/MODIFY proposals are
    And only after confirmation does the publish skill call `remember`

  # ---------------------------------------------------------------------------
  Scenario: Publish promotion gate — candidate FAILS (wrong category) (Req #13)
  # ---------------------------------------------------------------------------
    Given a `docs/memory/decision_<slug>.md` file (category: decision)
    When retrospective evaluates it as a publish candidate
    Then it is rejected — agentbook's problem/solution data model has no natural
      shape for `convention`/`decision`/`preference` categories
    And no publish proposal is surfaced

  # ---------------------------------------------------------------------------
  Scenario: Publish promotion gate — candidate FAILS (project-specific, not generalizable) (Req #13)
  # ---------------------------------------------------------------------------
    Given a `docs/memory/pitfall_<slug>.md` file describes a gotcha tied to this
      workspace's own nested-repo layout (e.g. a `repo_root()` fallback quirk
      specific to this monorepo's structure)
    And no evidence of the same fact recurring in an independent, differently-
      structured project exists
    When retrospective evaluates it as a publish candidate
    Then it is rejected — it is durable and true, but not proven generalizable
      beyond this repo's own idiosyncratic structure
    And no publish proposal is surfaced

  # ---------------------------------------------------------------------------
  Scenario: Publish promotion gate — candidate FAILS (fast-follow of the inward gate) (Req #14)
  # ---------------------------------------------------------------------------
    Given a `docs/memory/pitfall_<slug>.md` file was itself created moments earlier
      by retrospective's existing private-global-to-repo-local promotion pathway
      (the Tier A → Tier B bridge, gated on "project-specific and durable")
    And no independent cross-project recurrence evidence has since been gathered
      for it
    When retrospective evaluates it as an outward publish candidate
    Then it is rejected — a fact that just proved project-specific enough to
      promote inward is, by that same reasoning, a poor candidate for immediate
      outward re-promotion, since the two gates select for opposite properties
      (project-specific vs. generalizable)
    And no publish proposal is surfaced
    And this rejection is distinct from the "project-specific, not generalizable"
      scenario above: that one is rejected on its own content; this one is
      rejected specifically because of how recently and by which pathway it
      entered Tier B, regardless of content

# git/gitflow plugins: confirmed NO FIT (see _index.md Req #16 and Rationale
# §"Why git/gitflow are excluded") — every documented error signature in those
# plugins already has exactly one prescribed action; there is no hypothesis-forming
# loop to attach recall to and no "worked/didn't work" moment to report. No
# touchpoint, no dependency declaration, and deliberately no scenario here.

Feature: Cross-plugin dependency declaration
  As a consumer plugin (autoresearch, superpowers, github)
  I want to declare a formal dependency on commons-bridge
  So that its recall/publish skills are guaranteed available rather than relying
  on undocumented cross-plugin Skill-tool resolution.

  # ---------------------------------------------------------------------------
  Scenario Outline: Consumer plugin declares the dependency (Req #17)
  # ---------------------------------------------------------------------------
    Given `<plugin>/.claude-plugin/plugin.json` lists `"dependencies": ["commons-bridge"]`
    When the user installs or enables `<plugin>`
    Then Claude Code auto-resolves and installs `commons-bridge` if not already present
    And `<plugin>`'s skill content can load `commons-bridge:recall` /
      `commons-bridge:publish` via the Skill tool with a documented, enforced guarantee
      that the target skill exists

    Examples:
      | plugin       |
      | autoresearch |
      | superpowers  |
      | github       |

  # ---------------------------------------------------------------------------
  Scenario: commons-bridge is later removed or goes missing
  # ---------------------------------------------------------------------------
    Given `commons-bridge` was installed as a dependency of `autoresearch`
    And it is subsequently uninstalled or its files go missing
    When `/reload-plugins` runs
    Then `commons-bridge` is reinstalled automatically
    And `autoresearch`'s recall touchpoint continues to function without a
      manual reinstall step

Feature: Agentbook commons bridge — autoresearch touchpoint (Req #15)
  As the autoresearch experiment loop (scripts/setup-autoresearch.sh)
  I want to recall a previously-successful approach before escalating to an
  expensive GAN tournament, and report the outcome alongside my existing local log
  So that a cheap cross-project hint is tried before paying for a parallel
  tournament round, without altering the existing plateau-detection mechanics.

  # ---------------------------------------------------------------------------
  Scenario: Recall runs at the plateau moment, before the GAN tournament escalates
  # ---------------------------------------------------------------------------
    Given `autoresearch/.claude-plugin/plugin.json` lists `"dependencies": ["commons-bridge"]`
    And the last `ESCALATE_AFTER` (3) rows in `results.tsv` are all non-improving
      (status `discard`/`crash`/`gatefail`), triggering the `TOURNAMENT_BLOCK` plateau check
    When the experiment loop, before escalating to the parallel GAN tournament, loads
      `commons-bridge:recall` and calls `recall` with the artifact/objective description
    Then a hit surfaces a previously-successful approach for a similarly-shaped
      optimization problem, tried as step 2's next concrete change instead of
      immediately escalating
    And a miss, rate limit, or unreachable public commons falls back to the existing
      `TOURNAMENT_BLOCK` escalation to `workflows/gan.mjs` unchanged — recall never
      replaces or blocks the existing plateau-escalation path

  # ---------------------------------------------------------------------------
  Scenario: Report fires alongside the existing results.tsv write at step 6
  # ---------------------------------------------------------------------------
    Given the experiment loop has just decided an experiment's status
      (`keep`/`discard`/`gatefail`/`crash`/`tournament`) at step 6
    And this line is about to be appended to `results.tsv` as it already is today
    When the loop calls the `commons-bridge:recall` skill's report path
    Then `report(success: true)` fires for a `keep`/`tournament` (worked) outcome, and
      `report(success: false)` fires when the same recalled approach produced
      `discard`/`crash`/`gatefail` again
    And this is a parallel write next to the existing `results.tsv` line — it does
      not change what gets written locally, block the loop, or introduce a new
      decision point beyond the status the loop had already computed

Feature: Agentbook commons bridge — systematic-debugging touchpoint (Req #15)
  As the superpowers systematic-debugging skill
  I want a recall check at Phase 1 and a report call at Phase 4
  So that a cross-project/cross-agent source runs alongside the existing
  repo-local (Tier B) memory consult, without altering systematic-debugging's
  existing "fix + regression test, never a planning artifact" contract.

  # ---------------------------------------------------------------------------
  Scenario: Recall runs alongside the existing Tier B consult at Phase 1 step 0
  # ---------------------------------------------------------------------------
    Given `superpowers/.claude-plugin/plugin.json` lists `"dependencies": ["commons-bridge"]`
    And systematic-debugging Phase 1 step 0 has already run its existing Tier B
      consult (`docs-index.sh list --kind memory --status active`)
    When systematic-debugging loads `commons-bridge:recall` and calls `recall` with
      the bug's symptom text
    Then the two sources are consulted independently — a Tier B hit and a Tier C
      hit are not required to agree, and either, both, or neither may return a match
    And a Tier C miss or an unreachable public commons does not block or delay
      Phase 1 from proceeding to step 1 (Read Error Messages)

  # ---------------------------------------------------------------------------
  Scenario: Report fires at Phase 4 step 3, independent of the Tier B write gate
  # ---------------------------------------------------------------------------
    Given systematic-debugging Phase 4 step 3 ("Verify Fix") has just confirmed a fix works
    And the existing Tier B "Capture Memory" write (Phase 4 step 6) is gated on the
      3+-failed-fixes threshold or an explicit cross-cutting gotcha
    And this particular fix did NOT meet that threshold (e.g. it was the first attempt)
    When systematic-debugging calls the `commons-bridge:recall` skill's report path
    Then `report(success: true)` fires anyway, because the Tier C report gate is
      independent of and lighter than the Tier B write gate
    And no `docs/memory/*.md` file is written for this fix, since the Tier B
      threshold was not met — Tier B and Tier C write decisions are decoupled

Feature: Agentbook commons bridge — github:create-pr touchpoint (Req #15)
  As the github create-pr skill's post-PR CI monitoring loop
  I want to recall a previously-successful fix for a recurring CI failure signature
  and report the outcome once resolved
  So that repeated CI failures with the same root cause don't require re-deriving
  the fix from logs every time.

  # ---------------------------------------------------------------------------
  Scenario: Recall before applying a fix for a recurring CI failure
  # ---------------------------------------------------------------------------
    Given `github/.claude-plugin/plugin.json` lists `"dependencies": ["commons-bridge"]`
    And the post-PR Monitor has detected a `[ci]` failure (lint, type, test, or build error)
    When the create-pr skill loads `commons-bridge:recall` and calls `recall` with
      the CI error signature before consulting the reaction table's default action
    Then a hit surfaces a previously-successful fix for the same or a materially
      similar error signature, applied as a hint alongside the existing reaction
      table entry (e.g. "apply type fix" from `post-pr-monitoring.md`)
    And a miss or unreachable public commons falls back to the existing reaction
      table behavior unchanged — the recall step never replaces or blocks it

  # ---------------------------------------------------------------------------
  Scenario: Report fires once the Monitor confirms CI is green
  # ---------------------------------------------------------------------------
    Given a fix was applied and pushed for a `[ci]` failure
    And the Monitor subsequently detects `[ci] <name>: pass`
    When the create-pr skill calls the `commons-bridge:recall` skill's report path
    Then `report(success: true)` fires at exactly the moment the Monitor already
      detects the pass — no new polling or decision point is introduced
    And if the same failure recurs after push instead, `report(success: false)`
      fires at the moment the Monitor detects the recurrence

Feature: Agentbook commons bridge — Tier B/Tier C provenance bridge
  As the commons-bridge publish skill
  I want to record the resulting agentbook problem_id back onto the originating
  Tier B memory file
  So that a `docs/memory/pitfall_*.md` file's provenance is traceable to its
  public-commons counterpart without any docs-index row-level change.

  # ---------------------------------------------------------------------------
  Scenario: A successful publish writes source: agentbook:<problem_id> back onto the Tier B file (Req #12)
  # ---------------------------------------------------------------------------
    Given `docs/memory/pitfall_repo-root-fallback.md` passed the four-criterion
      publish promotion gate and was confirmed by the user
    And the publish skill's `remember` call succeeded, returning a new `problem_id`
    When the publish skill finishes processing the confirmed contribution
    Then it rewrites `docs/memory/pitfall_repo-root-fallback.md`'s frontmatter
      `source` field to `agentbook:<problem_id>` (replacing or appending to
      whatever `source` value it held before, e.g. a prior `<path>` or `commit:<sha>`)
    And no `docs/README.md` index row is added, changed, or requires a `kind` change
      for this write — the bridge is entirely a frontmatter-level change on the
      existing Tier B file
    And a later reader of `docs/memory/pitfall_repo-root-fallback.md` can follow
      `source: agentbook:<problem_id>` to `trace` the public record's current
      confidence and solution history
```
