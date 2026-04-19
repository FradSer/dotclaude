---
title: Hybrid RSC + TanStack Query for Initial Load + Interactivity
impact: HIGH
impactDescription: Eliminates client waterfall on first paint
tags: rsc, tanstack-query, data-fetching, hydration
---

## Hybrid RSC + TanStack Query for Initial Load + Interactivity

Use React Server Components for the initial render (zero client JS, streaming from the edge) and TanStack Query on the client for subsequent mutations, revalidation, and polling. Prefetch on the server and **hydrate the query cache** so the client doesn't refetch on first paint.

**Incorrect (client-only fetching — waterfall and loading flash on first paint):**

```tsx
"use client"
function Dashboard() {
  const { data } = useQuery({ queryKey: ["stats"], queryFn: fetchStats })
  if (!data) return <Skeleton />
  return <Stats data={data} />
}
```

**Correct (RSC prefetches, hydrates the client cache, client owns revalidation):**

```tsx
// Server component — fetches on the server and seeds the client cache
import { QueryClient, dehydrate, HydrationBoundary } from "@tanstack/react-query"

export default async function DashboardPage() {
  const queryClient = new QueryClient()
  await queryClient.prefetchQuery({ queryKey: ["stats"], queryFn: fetchStats })

  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      <Dashboard />
    </HydrationBoundary>
  )
}
```

```tsx
// Client component — reads from the hydrated cache, then owns revalidation + mutations
"use client"
function Dashboard() {
  const { data } = useQuery({ queryKey: ["stats"], queryFn: fetchStats })
  return <Stats data={data!} /> // already in cache on first render
}
```

**When to pick which:**

- Pure display, no client interactivity → **RSC only** (skip TanStack Query entirely)
- Interactive with mutations/revalidation/polling → **RSC prefetch + TanStack Query hydration**
- Purely client-driven (search-as-you-type, infinite scroll) → **TanStack Query only**, skip RSC

Reference: [TanStack Query — Advanced Server Rendering](https://tanstack.com/query/latest/docs/framework/react/guides/advanced-ssr)
