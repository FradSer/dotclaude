---
title: State Management Decision Tree
impact: MEDIUM
impactDescription: Picks the right tool; avoids over-centralization
tags: state-management, architecture, zustand, jotai, tanstack-query
---

## State Management Decision Tree

Match the container to the problem. Reaching for a global store when `useState` would do adds re-render surface area, bundle weight, and coupling.

**Decision tree:**

1. **Local UI state** (is this dropdown open?) → `useState` / `useReducer`
2. **URL-reflective state** (filter, tab, pagination, query) → URL search params (`useSearchParams`, `router.replace`)
3. **Server data** (fetched, cached, revalidated) → **TanStack Query** (or SWR). Never mirror server state in Zustand.
4. **Cross-component client state** (auth user, theme, feature flags) → **Zustand** for structured stores, **Jotai** for atomic state
5. **Form state** → `useActionState` (React 19) for Server Actions, `react-hook-form` for complex client-only forms

**Incorrect (Zustand storing fetched server data — loses cache, revalidation, dedup):**

```tsx
const useStore = create<Store>((set) => ({
  users: [],
  fetchUsers: async () => {
    const users = await fetch("/api/users").then((r) => r.json())
    set({ users })
  },
}))
```

**Correct (TanStack Query for server data, Zustand for UI-only state):**

```tsx
function useUsers() {
  return useQuery({
    queryKey: ["users"],
    queryFn: () => fetch("/api/users").then((r) => r.json()),
  })
}

const useUIStore = create<UIStore>((set) => ({
  sidebarOpen: false,
  toggleSidebar: () => set((s) => ({ sidebarOpen: !s.sidebarOpen })),
}))
```

**Rule of thumb:** if the state can be re-derived from the server, it's server state — use a query library with cache invalidation. Only use a client store for state that has no server representation.

Reference: [TanStack Query — Overview](https://tanstack.com/query/latest/docs/framework/react/overview)
