# Styling & Customization

See [customization.md](../customization.md) for theming, CSS variables, and adding custom colors.

## Contents

- Semantic colors
- Built-in variants first
- className for layout only
- No space-x-* / space-y-*
- Prefer size-* over w-* h-* when equal
- Prefer truncate shorthand
- No manual dark: color overrides
- Use cn() for conditional classes
- No manual z-index on overlay components

---

## Semantic colors

**Incorrect:**

```tsx
<div className="bg-blue-500 text-white">
  <p className="text-gray-600">Secondary text</p>
</div>
```

**Correct:**

```tsx
<div className="bg-primary text-primary-foreground">
  <p className="text-muted-foreground">Secondary text</p>
</div>
```

---

## No raw color values for status/state indicators

For positive, negative, or status indicators, use Badge variants, semantic tokens like `text-destructive`, or define custom CSS variables — don't reach for raw Tailwind colors.

**Incorrect:**

```tsx
<span className="text-emerald-600">+20.1%</span>
<span className="text-green-500">Active</span>
<span className="text-red-600">-3.2%</span>
```

**Correct:**

```tsx
<Badge variant="secondary">+20.1%</Badge>
<Badge>Active</Badge>
<span className="text-destructive">-3.2%</span>
```

If you need a success/positive color that doesn't exist as a semantic token, use a Badge variant or ask the user about adding a custom CSS variable to the theme (see [customization.md](../customization.md)).

---

## Built-in variants first

**Incorrect:**

```tsx
<Button className="border border-input bg-transparent hover:bg-accent">
  Click me
</Button>
```

**Correct:**

```tsx
<Button variant="outline">Click me</Button>
```

---

## className for layout only

Use `className` for layout (e.g. `max-w-md`, `mx-auto`, `mt-4`), **not** for overriding component colors or typography. To change colors, use semantic tokens, built-in variants, or CSS variables.

**Incorrect:**

```tsx
<Card className="bg-blue-100 text-blue-900 font-bold">
  <CardContent>Dashboard</CardContent>
</Card>
```

**Correct:**

```tsx
<Card className="max-w-md mx-auto">
  <CardContent>Dashboard</CardContent>
</Card>
```

To customize a component's appearance, prefer these approaches in order:
1. **Built-in variants** — `variant="outline"`, `variant="destructive"`, etc.
2. **Semantic color tokens** — `bg-primary`, `text-muted-foreground`.
3. **CSS variables** — define custom colors in the global CSS file (see [customization.md](../customization.md)).

---

## No space-x-* / space-y-*

Use `gap-*` instead. `space-y-4` → `flex flex-col gap-4`. `space-x-2` → `flex gap-2`.

```tsx
<div className="flex flex-col gap-4">
  <Input />
  <Input />
  <Button>Submit</Button>
</div>
```

---

## Prefer size-* over w-* h-* when equal

`size-10` not `w-10 h-10`. Applies to icons, avatars, skeletons, etc.

---

## Prefer truncate shorthand

`truncate` not `overflow-hidden text-ellipsis whitespace-nowrap`.

---

## No manual dark: color overrides

Use semantic tokens — they handle light/dark via CSS variables. `bg-background text-foreground` not `bg-white dark:bg-gray-950`.

---

## Use cn() for conditional classes

Use the `cn()` utility from the project for conditional or merged class names. Don't write manual ternaries in className strings.

**Incorrect:**

```tsx
<div className={`flex items-center ${isActive ? "bg-primary text-primary-foreground" : "bg-muted"}`}>
```

**Correct:**

```tsx
import { cn } from "@/lib/utils"

<div className={cn("flex items-center", isActive ? "bg-primary text-primary-foreground" : "bg-muted")}>
```

---

## No manual z-index on overlay components

`Dialog`, `Sheet`, `Drawer`, `AlertDialog`, `DropdownMenu`, `Popover`, `Tooltip`, `HoverCard` handle their own stacking. Never add `z-50` or `z-[999]`.


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

