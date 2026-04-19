---
title: React Compiler Replaces Manual Memoization
impact: MEDIUM
impactDescription: Removes boilerplate, catches missed optimizations
tags: react-19, compiler, memoization
---

## React Compiler Replaces Manual Memoization

When [React Compiler](https://react.dev/learn/react-compiler) is enabled, the toolchain auto-memoizes components, hooks, and derived values. Manual `memo()`, `useMemo()`, and `useCallback()` become redundant noise.

**Incorrect (manual memoization with compiler enabled):**

```tsx
const ExpensiveList = memo(function ExpensiveList({ items, onSelect }: Props) {
  const sorted = useMemo(() => items.toSorted(byName), [items])
  const handleClick = useCallback((id: string) => onSelect(id), [onSelect])
  return sorted.map((item) => (
    <Row key={item.id} item={item} onClick={handleClick} />
  ))
})
```

**Correct (compiler handles memoization, code reads naturally):**

```tsx
function ExpensiveList({ items, onSelect }: Props) {
  const sorted = items.toSorted(byName)
  const handleClick = (id: string) => onSelect(id)
  return sorted.map((item) => (
    <Row key={item.id} item={item} onClick={handleClick} />
  ))
}
```

**Verify the compiler is on** before stripping memoization:
- Next.js 15+: `experimental.reactCompiler: true` in `next.config.js`
- Other toolchains: `babel-plugin-react-compiler` configured

**Keep manual memoization when:**
- Compiler is NOT enabled in the project
- The file opts out via `"use no memo"` directive
- Profiling shows the compiler missed a hot path

Reference: [React Compiler](https://react.dev/learn/react-compiler)
