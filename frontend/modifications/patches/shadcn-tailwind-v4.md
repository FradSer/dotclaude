<!-- LOCAL-MOD: tailwind-v4 (auto-replayed by sync-shadcn.sh; do not edit in styling.md directly — sync wipes it) -->
---

## Tailwind v4 specifics (when `tailwindVersion: "v4"`)

Check `tailwindVersion` in the shadcn project context before applying these — they only apply to v4.

### Define tokens in CSS via `@theme`, not `tailwind.config.js`

Tailwind v4 has no JS config. All design tokens live in the global CSS file (`tailwindCssFile` in project context) under `@theme` or `@theme inline`.

**Incorrect (v3-style JS config in a v4 project):**

```js
// tailwind.config.js — file should not exist in v4
module.exports = {
  theme: {
    extend: {
      colors: { brand: "oklch(0.7 0.2 260)" },
    },
  },
}
```

**Correct (CSS-first tokens in the global stylesheet):**

```css
@import "tailwindcss";

@theme inline {
  --color-brand: oklch(0.7 0.2 260);
  --font-display: "Cal Sans", sans-serif;
}
```

Every `@theme` token is auto-exposed as a CSS variable AND a utility — `--color-brand` is usable as `bg-brand` and as `var(--color-brand)`. Don't redeclare theme tokens at `:root`.

### Avoid `@apply` for arbitrary styling

`@apply` still exists but is discouraged in v4. Prefer writing semantic utilities in markup, or plain CSS properties in component stylesheets.

### Use container queries natively

v4 ships container queries without a plugin. Prefer `@container` + `@md:grid-cols-2` for component-level responsiveness when the component appears in different layouts.

```tsx
<div className="@container">
  <div className="grid gap-4 @md:grid-cols-2 @lg:grid-cols-3">
    {items.map((item) => <Card key={item.id} />)}
  </div>
</div>
```

### Dark mode via CSS variables, not `dark:` variants

shadcn/ui already defines token values for both modes and flips them with a `.dark` selector on `html`. Keep using semantic tokens (`bg-background`, `text-foreground`) — never write `dark:bg-gray-900` in component classNames.
