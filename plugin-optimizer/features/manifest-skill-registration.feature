Feature: Plugin manifest skill registration
  Plugin skills live in skills/ and are discovered there by Claude Code.
  Declaring the same skills/<name>/ directories under "commands" registers
  each SKILL.md a second time, doubling the component inventory and the
  always-on token cost. A skill's visibility is set by its frontmatter, not
  by the manifest key.

  Scenario: A manifest with no commands key registers one skill per directory
    Given a plugin with skills/commit/SKILL.md and no "commands" key
    When the manifest validation runs
    Then the validation passes
    And there is no duplicate skill registration finding

  Scenario: Commands pointing into skills/ is rejected
    Given a plugin whose "commands" array contains "./skills/commit/"
    When the manifest validation runs
    Then the validation fails with "Duplicate skill registration"

  Scenario: Commands naming real command files is still allowed
    Given a plugin whose "commands" array contains "./commands/status.md"
    And the file commands/status.md exists
    When the manifest validation runs
    Then the validation passes
    And there is no duplicate skill registration finding

  Scenario: Commands given as an object map or string are checked too
    Given a plugin whose "commands" is an object map sourcing "./skills/commit/SKILL.md"
    When the manifest validation runs
    Then the validation fails with "Duplicate skill registration"

  Scenario: User-invocable skills do not need a commands declaration
    Given a plugin with skills/commit/SKILL.md set to "user-invocable: true"
    And the manifest has no "commands" key
    When the manifest validation runs
    Then the validation passes
    And there is no "Undeclared user-invocable skill" finding
