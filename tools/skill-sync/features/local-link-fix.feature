Feature: Denest fixes intra-skill reference links
  Mirror syncs denest each sub-skill's SKILL.md into <name>.md and rebuild the
  skills/ tree. Some upstream reference files address sibling docs with a path
  that assumes the skill root as cwd (e.g. references/X.md) or omit the ../
  needed to reach a sibling sub-directory (e.g. palettes/X.md). From inside
  references/ those links are broken. The denest step must repair them so the
  fix survives every resync instead of being a local hand-edit that sync
  overwrites.

  Scenario: A double-nested references/ link is deduplicated
    Given a reference file inside <skill>/references/ linking to references/X.md
    And X.md exists beside that reference file
    When denest applies the local-link fix
    Then the link points to X.md and resolves

  Scenario: A sibling sub-directory link gains ../
    Given a reference file inside <skill>/references/ linking to palettes/X.md
    And palettes/X.md exists one directory up
    When denest applies the local-link fix
    Then the link points to ../palettes/X.md and resolves

  Scenario: Already-correct link is left untouched
    Given a reference file linking to ./X.md that already resolves
    When denest applies the local-link fix
    Then the link is unchanged

  Scenario: Idempotent on a second run
    Given a tree whose local links were already fixed
    When denest applies the local-link fix again
    Then no file changes
