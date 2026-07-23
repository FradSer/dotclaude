# Frontend Plugin Slim-Down — BDD Specifications

Vocabulary per `_index.md` Glossary: "slim-down" = delete 5 mirror skills in place, keep original integration layer; "mirror skill" = verbatim upstream sync; "integration layer" = locally-authored content with no upstream home.

## Traceability Notes (structural requirements not expressed as Given/When/Then)

- **REQ-010** (keep design-md sync machinery) is verified structurally by `architecture.md` §Verification — `ls scripts/sync-design-md.sh scripts/lib/sync-common.sh` succeeds post-slim. No runtime scenario: it is a file-presence invariant.
- **REQ-012** (version bump + marketplace sync) is verified by a JSON-equality grep in `architecture.md` §Verification, not a behavioral scenario.
- **REQ-014** (no LLM/network on UserPromptSubmit critical path) is verified by grepping the rewritten hook for `curl`/`npx`/`node`/`http` — absence is the assertion. Documented as a structural check.
- **REQ-015** (token budget) is verified by `validate-plugin.py` exit code 0. Structural.
- **REQ-016** (manual README sync, no `/utils:update-readme`) is a process constraint, not testable in-repo; documented in `best-practices.md`.

```gherkin
Feature: Mirror skill deletion — the 5 verbatim-upstream skills are removed from the plugin
  As a marketplace maintainer
  I want to delete mirror skills that duplicate upstream repos
  So that the plugin carries only original integration-layer content

  Background:
    Given the frontend plugin directory exists at frontend/
    And the 5 mirror skills are: supabase, supabase-postgres-best-practices, web-design-guidelines, impeccable, shadcn

  Scenario: Each mirror skill directory is deleted (REQ-001)
    Given the pre-slim frontend/skills/ contained 9 skill directories
    When the slim-down is applied
    Then frontend/skills/supabase/ does not exist
    And frontend/skills/supabase-postgres-best-practices/ does not exist
    And frontend/skills/web-design-guidelines/ does not exist
    And frontend/skills/impeccable/ does not exist
    And frontend/skills/shadcn/ does not exist
    And frontend/skills/design-md/ still exists
    And frontend/skills/articulate/ still exists
    And frontend/skills/next-devtools-guide/ still exists

  Scenario: No orphaned sync script references a deleted mirror skill (REQ-002)
    Given sync scripts sync-supabase-skills.sh, sync-vercel-skills.sh, sync-shadcn.sh, sync-impeccable.sh existed
    When the slim-down is applied
    Then frontend/scripts/sync-supabase-skills.sh does not exist
    And frontend/scripts/sync-vercel-skills.sh does not exist
    And frontend/scripts/sync-shadcn.sh does not exist
    And frontend/scripts/sync-impeccable.sh does not exist
    And frontend/.sync-snapshots/supabase-skills.manifest does not exist
    And frontend/.sync-snapshots/vercel-skills.manifest does not exist
    And frontend/.sync-snapshots/shadcn.manifest does not exist
    And frontend/.sync-snapshots/impeccable.manifest does not exist
```

```gherkin
Feature: Modifications replay log — blocks targeting deleted skills are removed
  As a maintainer
  I want modification blocks whose Target file is a deleted mirror skill to be removed
  So that check-coherence.sh assertion 3 (Target files exist) does not fail

  Scenario: All mirror-bound modification files are deleted (REQ-003)
    Given modifications/impeccable.md, modifications/shadcn.md, modifications/patches/shadcn-tailwind-v4.md, modifications/react-best-practices.md existed
    When the slim-down is applied
    Then frontend/modifications/impeccable.md does not exist
    And frontend/modifications/shadcn.md does not exist
    And frontend/modifications/patches/shadcn-tailwind-v4.md does not exist
    And frontend/modifications/react-best-practices.md does not exist

  Scenario Outline: No surviving modification block targets a deleted skill (REQ-003)
    Given a modification file remains under frontend/modifications/
    When its **Target** lines are scanned
    Then no Target path starts with skills/supabase/
    And no Target path starts with skills/shadcn/
    And no Target path starts with skills/impeccable/
    And no Target path starts with skills/web-design-guidelines/
    And no Target path starts with skills/supabase-postgres-best-practices/

    Examples:
      | file |
      | (none — if modifications/ is empty after deletion, the dir itself is removed) |
```

```gherkin
Feature: Anti-patterns agent rewrite — the detect.mjs hard dependency is removed
  As a maintainer
  I want the frontend-anti-patterns agent to stop calling impeccable/scripts/detect.mjs
  So that it does not ship a broken find-path to a deleted skill

  Background:
    Given the agent body referenced skills/impeccable/scripts/detect.mjs via a find command

  Scenario: The detect.mjs invocation block is removed (REQ-004)
    When the slim-down is applied
    Then frontend/agents/frontend-anti-patterns.md does not contain "find ~/.claude -path '*/frontend/skills/impeccable/SKILL.md'"
    And frontend/agents/frontend-anti-patterns.md does not contain "node \"$SKILL_DIR/scripts/detect.mjs\""
    And frontend/agents/frontend-anti-patterns.md does not contain "detect.mjs"

  Scenario: The agent's manual-check fallback is preserved (REQ-004)
    Given the agent had a documented manual fallback for when the detector errored
    When the slim-down is applied
    Then frontend/agents/frontend-anti-patterns.md still contains its manual anti-pattern checks
    And the agent notes that the executable detector was removed because impeccable was slimmed out
```

```gherkin
Feature: Coordinator agent pruning — frontend-expert references only surviving skills
  As a maintainer
  I want frontend-expert pipelines to stop referencing deleted skills
  So that the coordinator does not load non-existent skill IDs

  Scenario Outline: No deleted skill ID appears in the coordinator (REQ-005)
    Given frontend/agents/frontend-expert.md is scanned
    When the file is grepped for deleted qualified skill IDs
    Then it does not contain "frontend:supabase"
    And it does not contain "frontend:supabase-postgres-best-practices"
    And it does not contain "frontend:shadcn"
    And it does not contain "frontend:react-best-practices"
    And it does not contain "frontend:web-design-guidelines"
    And it does not contain "frontend:impeccable"

    Examples:
      | deleted_id |
      | frontend:supabase |
      | frontend:shadcn |
      | frontend:impeccable |

  Scenario: Surviving skill IDs remain referenced where appropriate (REQ-005)
    When the coordinator is pruned
    Then frontend/agents/frontend-expert.md may contain "frontend:design-md"
    And may contain "frontend:articulate"
    And may contain "frontend:next-devtools-guide"
```

```gherkin
Feature: Hook preamble rewrite — deleted skills are dropped from the token-authority ladder
  As a maintainer
  I want the design-md-first hook to stop injecting references to deleted skills
  So that the injected system reminder names only installed skills

  Background:
    Given the hook preamble had 4 ladder steps citing design-md, impeccable, shadcn, anti-patterns

  Scenario: Deleted skill IDs are removed from the preamble (REQ-006)
    When the slim-down is applied
    Then frontend/hooks/design-md-first.sh does not contain "frontend:impeccable"
    And frontend/hooks/design-md-first.sh does not contain "frontend:shadcn"
    And frontend/hooks/design-md-first.sh still contains "frontend:design-md"

  Scenario: The hook still fires only when DESIGN.md exists (REQ-006, REQ-014)
    Given a working directory with no DESIGN.md and no docs/DESIGN.md
    When the hook runs
    Then it exits 0 with no hookSpecificOutput
    And it performs no network or subprocess call
```

```gherkin
Feature: SKILL.md cross-references — surviving skills stop citing deleted siblings
  As a maintainer
  I want design-md and articulate SKILL.md to drop references to deleted skills
  So that loaded skill docs do not point at non-existent IDs

  Scenario Outline: Deleted sibling refs removed from surviving SKILL.md (REQ-007, REQ-008)
    Given a surviving skill's SKILL.md is scanned
    When the file is grepped for deleted sibling IDs
    Then it does not contain "frontend:impeccable"
    And it does not contain "frontend:web-design-guidelines"
    And it does not contain "frontend:shadcn"

    Examples:
      | skill |
      | design-md |
      | articulate |
```

```gherkin
Feature: Plugin manifest consistency — plugin.json reflects the surviving content set
  As a maintainer
  I want plugin.json commands/skills/agents arrays to list only surviving skills
  So that validate-plugin.py passes on the slimmed plugin

  Scenario: Manifest arrays contain no deleted skill path (REQ-009)
    When the slim-down is applied
    Then frontend/.claude-plugin/plugin.json does not list "./skills/supabase/"
    And does not list "./skills/supabase-postgres-best-practices/"
    And does not list "./skills/web-design-guidelines/"
    And does not list "./skills/impeccable/"
    And does not list "./skills/shadcn/"
    And lists "./skills/design-md/"
    And lists "./skills/articulate/"
    And lists "./skills/next-devtools-guide/"
    And still declares the next-devtools mcpServer
    And still declares the design-md-first UserPromptSubmit hook

  Scenario: validate-plugin.py exits 0 on the slimmed plugin (REQ-009, REQ-015)
    When python3 plugin-optimizer/scripts/validate-plugin.py frontend/ is run
    Then the exit code is 0
```

```gherkin
Feature: Coherence checker re-scoping — assertions reflect the new content set
  As a maintainer
  I want check-coherence.sh to not assert on deleted-skill invariants
  So that it passes on the slimmed plugin

  Scenario: Impeccable-specific assertions are dropped (REQ-011)
    When the slim-down is applied
    Then frontend/scripts/check-coherence.sh does not assert on phantom "frontend:impeccable-<cmd>" IDs
    And does not assert on "node *.mjs" path resolution for impeccable
    And assertion 4 (frontend-expert IDs registered) validates against the pruned plugin.json
```

```gherkin
Feature: Migration note — deleted-skill users get an upstream replacement path
  As an existing frontend plugin user
  I want to know which upstream repo to install for each deleted skill
  So that I do not silently lose capability on update

  Scenario: README lists each deleted skill with its upstream repo (REQ-013)
    Given the slim-down deleted 5 mirror skills
    When frontend/README.md is read
    Then it names supabase and supabase-postgres-best-practices with the supabase/agent-skills repo URL
    And names web-design-guidelines with the vercel-labs/agent-skills repo URL
    And names shadcn with the shadcn-ui/ui repo URL
    And names impeccable with the pbakaus/impeccable repo URL
```
