---
name: design-md
description: Author, consume, and enforce a DESIGN.md design system spec (Google Labs open format, package @google/design.md). This skill should be used when the project has a DESIGN.md at the root or under docs/, when the user mentions "design tokens", "design system spec", "DESIGN.md", "tokens.json", needs to translate a design system into Tailwind theme config, export tokens to DTCG, lint token consistency, diff design system revisions, or check WCAG contrast on component color pairs. Acts as the upstream source of truth for impeccable-colorize, impeccable-typeset, impeccable-audit, impeccable-critique, web-design-guidelines, and shadcn.
user-invocable: true
allowed-tools: ["Bash(npx @google/design.md*)", "Bash(npx @google/design.md@latest *)", "Read", "Write", "Edit", "Glob", "Grep", "WebFetch"]
---

# DESIGN.md — Design System Source of Truth

DESIGN.md is an open format (repo: `google-labs-code/design.md`, package `@google/design.md`) for describing a visual identity to coding agents. It combines **machine-readable design tokens** (YAML front matter) with **human-readable rationale** (Markdown prose). Tokens are normative; prose provides application context.

When this skill loads, the design system stops being something the agent guesses at and becomes something the agent *reads*. Every sibling design skill in the frontend plugin should defer to DESIGN.md when it exists.

## MANDATORY PREPARATION

The spec is `alpha` and under active development. Before any non-trivial authoring work, fetch the authoritative spec and linting rules:

```bash
npx @google/design.md@latest spec --rules
```

Treat that output as canonical. Do not paraphrase the schema from memory for high-stakes changes — re-verify.

## Detection & Mode

Before acting, decide which of three modes you are in.

1. **Consume mode** — `DESIGN.md` exists at the project root or `docs/DESIGN.md`. Read it first, internalize `## Overview` and `## Do's and Don'ts`, and ground every downstream suggestion in its tokens.
2. **Author mode** — user asks to "create a design system", "write design tokens", "generate a style guide", or wants to seed one alongside a shadcn init.
3. **Propose mode** — neither file nor explicit ask, but the user is picking colors/typography from scratch. Use `AskUserQuestion` to ask whether to commit to a DESIGN.md before scattering ad-hoc hex values.

Detect with `ls DESIGN.md docs/DESIGN.md 2>/dev/null` or `Glob("{DESIGN.md,docs/DESIGN.md,design/DESIGN.md}")`. Do not assume.

## Spec Essentials

Section order is fixed. Sections can be omitted, but the ones present must follow this order (the `section-order` lint rule is a warning):

| # | Section              | Aliases            |
|:--|:---------------------|:-------------------|
| 1 | Overview             | Brand & Style      |
| 2 | Colors               | —                  |
| 3 | Typography           | —                  |
| 4 | Layout               | Layout & Spacing   |
| 5 | Elevation & Depth    | Elevation          |
| 6 | Shapes               | —                  |
| 7 | Components           | —                  |
| 8 | Do's and Don'ts      | —                  |

YAML front matter schema (abbreviated — verify against `spec --rules` for edge cases):

```yaml
---
version: alpha
name: <string>
description: <string>                   # optional
colors:
  <token-name>: "#RRGGBB"               # sRGB hex, required start with "#"
typography:
  <token-name>:
    fontFamily: <string>
    fontSize: <Dimension>               # px | em | rem
    fontWeight: <number>                # 100..900
    lineHeight: <Dimension | number>    # unitless = multiplier of fontSize (preferred)
    letterSpacing: <Dimension>
    fontFeature: <string>               # optional, maps to font-feature-settings
    fontVariation: <string>             # optional, maps to font-variation-settings
rounded:
  <scale>: <Dimension>                  # sm, md, lg, xl, full, ...
spacing:
  <scale>: <Dimension | number>
components:
  <component>:
    backgroundColor: "{colors.primary}"  # references via {path.to.token}
    textColor: "{colors.on-primary}"
    typography: "{typography.body-md}"  # components may reference composite typography
    rounded: "{rounded.md}"
    padding: <Dimension>
    size|height|width: <Dimension>
---
```

Valid component properties: `backgroundColor`, `textColor`, `typography`, `rounded`, `padding`, `size`, `height`, `width`. Variants are expressed as sibling keys (`button-primary`, `button-primary-hover`, `button-primary-active`).

Recommended (non-normative) token names:

- **Colors:** `primary`, `secondary`, `tertiary`, `neutral`, `surface`, `on-surface`, `error`
- **Typography:** `headline-display`, `headline-lg`, `headline-md`, `body-lg`, `body-md`, `body-sm`, `label-lg`, `label-md`, `label-sm`
- **Rounded:** `none`, `sm`, `md`, `lg`, `xl`, `full`

## CLI Workflow

All commands accept a file path or `-` for stdin. Default output is JSON, exit code `1` on error/regression.

### `lint` — validate structure and token resolution

```bash
npx @google/design.md@latest lint DESIGN.md
```

The linter runs eight rules:

| Rule                  | Severity | Meaning                                                   |
|:----------------------|:---------|:----------------------------------------------------------|
| `broken-ref`          | error    | `{path.to.token}` does not resolve                        |
| `missing-primary`     | warning  | Colors defined but no `primary` — agents will auto-synth  |
| `contrast-ratio`      | warning  | Component bg/text pair below WCAG AA 4.5:1                |
| `orphaned-tokens`     | warning  | Color token defined, never referenced by any component    |
| `missing-typography`  | warning  | Colors present, no typography — agents fall back to defaults |
| `section-order`       | warning  | Sections out of canonical order                           |
| `token-summary`       | info     | Per-section token counts                                  |
| `missing-sections`    | info     | Optional sections absent when other tokens exist          |

Fix `error` rows first. Surface `contrast-ratio` warnings to the user — promote them to ship blockers if the project commits to WCAG AA+.

### `diff` — regression detection between two revisions

```bash
npx @google/design.md@latest diff DESIGN.md DESIGN.next.md
```

Exits `1` when the candidate has more errors or warnings than the baseline. Use before committing any token schema change.

### `export` — emit consumable token shapes

```bash
npx @google/design.md@latest export --format tailwind DESIGN.md   # v3 theme.extend JSON
npx @google/design.md@latest export --format dtcg DESIGN.md       # W3C DTCG tokens.json
```

### `spec` — inject spec into an agent prompt

```bash
npx @google/design.md@latest spec                     # full markdown spec
npx @google/design.md@latest spec --rules             # + lint rules table
npx @google/design.md@latest spec --rules-only        # only the rules table
npx @google/design.md@latest spec --format json       # programmatic
```

### Programmatic API (when scripting)

```ts
import { lint } from '@google/design.md/linter';

const report = lint(markdownString);
report.findings;      // Finding[]
report.summary;       // { errors, warnings, info }
report.designSystem;  // parsed DesignSystemState
```

## Tailwind v4 Adaptation (critical)

`export --format tailwind` emits **Tailwind v3** shape (JS `theme.extend` object with `colors`, `fontFamily`, `fontSize`, `borderRadius`, `spacing`). The frontend plugin targets **Tailwind v4** with CSS-first `@theme { ... }`. Do not drop the raw JSON into `tailwind.config.*`.

Apply this transform when emitting into `app/globals.css` (or wherever `@theme` lives):

| DESIGN.md token                      | Tailwind v4 CSS variable              |
|:-------------------------------------|:--------------------------------------|
| `colors.<name>`                      | `--color-<name>`                      |
| `typography.<name>.fontFamily`       | `--font-<name>`                       |
| `typography.<name>.fontSize`         | `--text-<name>`                       |
| `typography.<name>.lineHeight`       | `--text-<name>--line-height`          |
| `typography.<name>.letterSpacing`    | `--text-<name>--letter-spacing`       |
| `typography.<name>.fontWeight`       | `--font-weight-<name>`                |
| `rounded.<scale>`                    | `--radius-<scale>`                    |
| `spacing.<scale>`                    | `--spacing-<scale>`                   |

Example:

```css
@theme {
  --color-primary: #1a1c1e;
  --color-neutral: #f7f5f2;
  --font-h1: "Public Sans", sans-serif;
  --text-h1: 3rem;
  --text-h1--line-height: 1.1;
  --text-h1--letter-spacing: -0.02em;
  --radius-sm: 4px;
  --spacing-md: 16px;
}
```

For v3 projects, copy the JSON straight into `theme.extend` and stop.

## Sibling Skill Integration

When DESIGN.md is present, **it is the source of truth**. Override heuristic defaults from other skills:

- **`frontend:impeccable`** — inject the `## Overview` and `## Do's and Don'ts` prose into the context-gathering protocol. Never suggest palettes that contradict defined tokens.
- **`frontend:impeccable-colorize`** — restrict new accents to the `colors.*` map. If a hue is genuinely missing, propose adding it to DESIGN.md (and the token name) rather than inlining raw hex.
- **`frontend:impeccable-typeset`** — pull from `typography.*` tokens directly. Surface `missing-typography` findings before suggesting fonts from scratch.
- **`frontend:impeccable-audit`** — run `lint --format json` as part of the audit. Include every `error` in the report; treat `contrast-ratio` warnings as blockers on AA-committed projects.
- **`frontend:impeccable-critique`** — cite `## Do's and Don'ts` when flagging usability issues.
- **`frontend:web-design-guidelines`** — cross-reference `contrast-ratio` findings with the guideline rules.
- **`frontend:shadcn`** — map DESIGN.md `components.button-primary.*` onto shadcn's CSS variable contract (`--primary`, `--primary-foreground`, `--radius`). DESIGN.md exports provide the semantic variables that satisfy the shadcn rule "no raw `bg-blue-500`".

## Authoring Flow

1. Use `AskUserQuestion` to collect: brand personality (2–3 adjectives), primary brand color, typography preference (serif / sans / geometric), target density (spacious / compact).
2. Draft YAML front matter with `primary` and `neutral` as minimum colors. Most sections break without `neutral`.
3. Write `## Overview` first — it grounds every later token decision.
4. Fill `## Colors` and `## Typography`. Expand `## Components` only once base tokens stabilize.
5. Run `lint`. Fix `error` rows before writing any implementation code.
6. Run `export --format tailwind`, apply the v4 transform above, and commit to the project's global stylesheet.
7. Run `export --format dtcg` if the project also feeds Figma variables or a separate token pipeline.

## Consumption Flow

1. Read `DESIGN.md` in full. Internalize `## Overview` and `## Do's and Don'ts`.
2. Run `lint --format json` once at session start. Surface any `error` to the user before proceeding.
3. Reference tokens by name in prose suggestions ("use `colors.tertiary` for the CTA"). Let the implementation emit the matching Tailwind v4 variable (e.g., `bg-[var(--color-tertiary)]` or the project's mapped utility).
4. Never introduce raw hex / rem values that cannot be expressed as existing tokens. If a new token is needed, propose adding it to DESIGN.md and re-run `lint`.

## Caveats

- Spec version is `alpha`. Re-check `spec --rules` if more than a week has passed since last use.
- `export --format tailwind` still targets v3. Apply the v4 transform above until upstream ships a v4 adapter.
- Linter WCAG findings are warnings by default — promote to errors in `impeccable-audit` for AA+ commitments.
- No runtime dependency. All CLI invocations go via `npx @google/design.md@latest`. Do not add `@google/design.md` to `dependencies` or `devDependencies`.
- `alpha` status means token groups may gain or lose fields — treat unknown properties as warnings, not errors (matches the spec's "Consumer Behavior for Unknown Content" table).

## References

- Spec (live): `npx @google/design.md@latest spec`
- Lint rules (live): `npx @google/design.md@latest spec --rules-only`
- Spec (cached): `./references/upstream-spec.md` — pinned snapshot of upstream `docs/spec.md`, refreshed by `frontend/scripts/sync-design-md.sh`
- README (cached): `./references/upstream-README.md` — CLI reference, token interop notes
- GitHub repo: https://github.com/google-labs-code/design.md
- Examples: https://github.com/google-labs-code/design.md/tree/main/examples — `atmospheric-glass`, `paws-and-paths`, `totality-festival`
- Launch blog: https://blog.google/innovation-and-ai/models-and-research/google-labs/stitch-design-md/
