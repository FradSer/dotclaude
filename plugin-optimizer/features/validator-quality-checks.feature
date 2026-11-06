Feature: Validator quality checks cover real skill layouts and description voices
  The frontmatter and token checks must judge skill descriptions by their
  actual trigger scenarios (including Chinese and imperative variants), and
  must analyze token budgets for denested mirror layouts too, instead of
  silently skipping them.

  Scenario: Chinese trigger phrasing is not a missing-trigger false positive
    Given a skill whose description uses "当...时使用" to state when to use it
    When the frontmatter validation runs
    Then there is no "Description missing trigger phrases" finding

  Scenario: Imperative trigger variants are recognized
    Given a skill whose description says "Use before making changes" or "Use this skill whenever the user asks"
    When the frontmatter validation runs
    Then there is no "Description missing trigger phrases" finding

  Scenario: A description with no scenario is still flagged
    Given a skill whose description only states what it does with no when-to-use scenario
    When the frontmatter validation runs
    Then the validation reports "Description missing trigger phrases"

  Scenario: Denested entry files receive token-budget checks
    Given a plugin whose skills/<name>/ dirs hold <name>.md instead of SKILL.md
    When the token validation runs
    Then the token check reports "No skills found" is NOT emitted
    And every denested entry file gets a token-budget analysis
