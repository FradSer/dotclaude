# Modifications — react-best-practices

Upstream: `vercel-labs/agent-skills` → `skills/react-best-practices`
Sync script: `scripts/sync-vercel-skills.sh`

Each `## Add` block below is a new rule file that the sync script will delete.
After sync, recreate each file with the exact `Content` block, then re-apply
the SKILL.md Quick Reference edits in the `## Edit` blocks.

---

## Add: client-use-action-state rule

**Target**: `skills/react-best-practices/rules/client-use-action-state.md`

**Intent**: Document React 19 `useActionState` for wiring Server Actions to
forms. Upstream skill pre-dates React 19 hook coverage; without this rule the
assistant regresses to `useState + onSubmit` scaffolding.

**Content**:

````markdown
---
title: useActionState for Form State
impact: MEDIUM
impactDescription: Replaces useState + manual submit handling
tags: react-19, forms, server-actions
---

## useActionState for Form State

React 19's `useActionState` wires a Server Action to a `<form>` and returns `[state, formAction, isPending]`. It handles submission lifecycle, pending state, and return-value wiring automatically — no `useState` + `onSubmit` scaffold required.

**Incorrect (manual state, manual pending, race conditions):**

```tsx
"use client"
function SignupForm() {
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setPending(true)
    const result = await signup(new FormData(e.currentTarget))
    setError(result.error ?? null)
    setPending(false)
  }

  return (
    <form onSubmit={handleSubmit}>
      <input name="email" />
      <button type="submit" disabled={pending}>Sign up</button>
      {error && <p>{error}</p>}
    </form>
  )
}
```

**Correct (useActionState handles state + pending + submission):**

```tsx
"use client"
function SignupForm() {
  const [state, formAction, isPending] = useActionState(signup, { error: null })

  return (
    <form action={formAction}>
      <input name="email" />
      <button type="submit" disabled={isPending}>
        {isPending ? "Signing up..." : "Sign up"}
      </button>
      {state.error && <p>{state.error}</p>}
    </form>
  )
}
```

The Server Action signature must accept `(prevState, formData)`:

```ts
"use server"
export async function signup(prevState: State, formData: FormData): Promise<State> {
  // ...
}
```

Reference: [React — useActionState](https://react.dev/reference/react/useActionState)
````

**Added**: 2026-04-19

---

## Add: client-use-form-status rule

**Target**: `skills/react-best-practices/rules/client-use-form-status.md`

**Intent**: Document `useFormStatus` so generic submit buttons read pending
state from the parent form instead of receiving it via props.

**Content**:

````markdown
---
title: useFormStatus for Pending UI in Form Children
impact: MEDIUM
impactDescription: Eliminates prop drilling for pending state
tags: react-19, forms, server-actions
---

## useFormStatus for Pending UI in Form Children

`useFormStatus` reads `{ pending, data, method, action }` from the nearest parent `<form>`. Use it inside *descendants* of a form — not on the form itself — to get pending state without threading props.

**Incorrect (prop drilling pending state through children):**

```tsx
function SubmitButton({ isPending }: { isPending: boolean }) {
  return (
    <button type="submit" disabled={isPending}>
      {isPending ? "Saving..." : "Save"}
    </button>
  )
}

function Form() {
  const [, formAction, isPending] = useActionState(save, null)
  return (
    <form action={formAction}>
      <SubmitButton isPending={isPending} />
    </form>
  )
}
```

**Correct (useFormStatus reads from parent form):**

```tsx
function SubmitButton() {
  const { pending } = useFormStatus()
  return (
    <button type="submit" disabled={pending}>
      {pending ? "Saving..." : "Save"}
    </button>
  )
}

function Form() {
  return (
    <form action={save}>
      <SubmitButton />
    </form>
  )
}
```

Especially useful for generic reusable submit buttons, inline spinners, and optimistic preview of the submitting data (`status.data` is the in-flight `FormData`).

Reference: [React — useFormStatus](https://react.dev/reference/react-dom/hooks/useFormStatus)
````

**Added**: 2026-04-19

---

## Add: client-use-optimistic rule

**Target**: `skills/react-best-practices/rules/client-use-optimistic.md`

**Intent**: Document `useOptimistic` for instant UI feedback on Server Action
mutations. Upstream skill has no optimistic-UI guidance.

**Content**:

````markdown
---
title: useOptimistic for Instant UI Feedback
impact: MEDIUM-HIGH
impactDescription: Makes async mutations feel instantaneous
tags: react-19, forms, optimistic-ui
---

## useOptimistic for Instant UI Feedback

`useOptimistic` renders a predicted result of a Server Action before it resolves. React auto-reverts the optimistic state on error and replaces it with the real state when the action settles.

**Incorrect (user waits for the round trip to see their own message):**

```tsx
"use client"
function Messages({ messages }: { messages: Message[] }) {
  async function send(formData: FormData) {
    await sendMessage(formData)
    // No feedback until the server responds
  }

  return (
    <>
      <ul>{messages.map((m) => <li key={m.id}>{m.text}</li>)}</ul>
      <form action={send}>
        <input name="text" />
        <button type="submit">Send</button>
      </form>
    </>
  )
}
```

**Correct (useOptimistic inserts the message instantly):**

```tsx
"use client"
function Messages({ messages }: { messages: Message[] }) {
  const [optimistic, addOptimistic] = useOptimistic(
    messages,
    (state, newText: string) => [...state, { id: "temp", text: newText, sending: true }],
  )

  async function send(formData: FormData) {
    const text = formData.get("text") as string
    addOptimistic(text)
    await sendMessage(formData)
  }

  return (
    <>
      <ul>
        {optimistic.map((m) => (
          <li key={m.id} style={{ opacity: m.sending ? 0.5 : 1 }}>{m.text}</li>
        ))}
      </ul>
      <form action={send}>
        <input name="text" />
        <button type="submit">Send</button>
      </form>
    </>
  )
}
```

Keep the reducer pure and fast — it runs synchronously during render. Don't fetch, log, or mutate refs inside it.

Reference: [React — useOptimistic](https://react.dev/reference/react/useOptimistic)
````

**Added**: 2026-04-19

---

## Add: advanced-use-hook-promise rule

**Target**: `skills/react-best-practices/rules/advanced-use-hook-promise.md`

**Intent**: Document the `use()` hook for unwrapping Server-passed Promises in
Client Components under Suspense. This is the canonical React 19 pattern for
eliminating `useEffect(fetch)` scaffolding in client code.

**Content**:

````markdown
---
title: use() to Unwrap Promises in Client Components
impact: MEDIUM
impactDescription: Streams server data to client without useEffect
tags: react-19, suspense, data-fetching
---

## use() to Unwrap Promises in Client Components

`use()` unwraps a Promise (or reads a Context) in a Client Component. When passed a Promise, React suspends until it resolves — so the call must be wrapped in a `<Suspense>` boundary. Unlike other hooks, `use()` is callable conditionally and inside loops.

**Incorrect (Client Component does its own fetch via useEffect):**

```tsx
"use client"
function Profile({ userId }: { userId: string }) {
  const [user, setUser] = useState<User | null>(null)
  useEffect(() => {
    fetch(`/api/user/${userId}`).then((r) => r.json()).then(setUser)
  }, [userId])
  if (!user) return <Skeleton />
  return <div>{user.name}</div>
}
```

**Correct (Server starts the fetch, Client unwraps the promise):**

```tsx
// Server component — kicks off the fetch without awaiting
export default function ProfilePage({ userId }: { userId: string }) {
  const userPromise = fetchUser(userId)
  return (
    <Suspense fallback={<Skeleton />}>
      <Profile userPromise={userPromise} />
    </Suspense>
  )
}
```

```tsx
// Client component — unwraps the promise with use()
"use client"
function Profile({ userPromise }: { userPromise: Promise<User> }) {
  const user = use(userPromise)
  return <div>{user.name}</div>
}
```

`use(context)` also reads Context; `useContext` still works and is preferred when you don't need conditional reads.

Reference: [React — use()](https://react.dev/reference/react/use)
````

**Added**: 2026-04-19

---

## Add: rerender-react-compiler rule

**Target**: `skills/react-best-practices/rules/rerender-react-compiler.md`

**Intent**: Tell the assistant to stop inserting `memo()`, `useMemo()`, and
`useCallback()` by reflex when the project has React Compiler enabled.
Without this rule, the existing `rerender-*` rules push manual memoization
even on compiler-enabled codebases.

**Content**:

````markdown
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
````

**Added**: 2026-04-19

---

## Add: client-state-management rule

**Target**: `skills/react-best-practices/rules/client-state-management.md`

**Intent**: Provide a decision tree for state management — `useState` vs URL
params vs TanStack Query vs Zustand vs Jotai. Upstream skill focuses on
performance primitives and does not address "which state tool for which job",
causing the assistant to reach for Zustand by default or mirror server state in
client stores.

**Content**:

````markdown
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
````

**Added**: 2026-04-19

---

## Add: server-rsc-tanstack-hybrid rule

**Target**: `skills/react-best-practices/rules/server-rsc-tanstack-hybrid.md`

**Intent**: Document the hybrid pattern — RSC prefetches on the server,
`HydrationBoundary` seeds the client query cache, TanStack Query owns
revalidation and mutations. Upstream skill covers RSC parallel fetching and
client SWR separately but not their integration.

**Content**:

````markdown
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
````

**Added**: 2026-04-19

---

## Edit: SKILL.md Quick Reference — Section 3 (Server-Side Performance)

**Target**: `skills/react-best-practices/SKILL.md`

**Intent**: Index the new `server-rsc-tanstack-hybrid` rule in the Quick
Reference so the assistant sees it when skimming the skill.

**Content**: After the `server-after-nonblocking` bullet under
"### 3. Server-Side Performance (HIGH)", append:

```
- `server-rsc-tanstack-hybrid` - Hybrid RSC prefetch + TanStack Query hydration for interactive pages
```

**Added**: 2026-04-19

---

## Edit: SKILL.md Quick Reference — Section 4 (Client-Side Data Fetching)

**Target**: `skills/react-best-practices/SKILL.md`

**Intent**: Index the four new `client-*` rules (React 19 form hooks + state
management decision tree) so the assistant can discover them.

**Content**: After the `client-localstorage-schema` bullet under
"### 4. Client-Side Data Fetching (MEDIUM-HIGH)", append:

```
- `client-use-action-state` - React 19: useActionState wires Server Actions to forms
- `client-use-form-status` - React 19: useFormStatus reads pending from parent form
- `client-use-optimistic` - React 19: useOptimistic for instant mutation feedback
- `client-state-management` - Decision tree: useState / URL / TanStack Query / Zustand / Jotai
```

**Added**: 2026-04-19

---

## Edit: SKILL.md Quick Reference — Section 5 (Re-render Optimization)

**Target**: `skills/react-best-practices/SKILL.md`

**Intent**: Index `rerender-react-compiler` so the assistant strips manual
memoization on compiler-enabled projects.

**Content**: After the `rerender-no-inline-components` bullet under
"### 5. Re-render Optimization (MEDIUM)", append:

```
- `rerender-react-compiler` - React Compiler replaces manual memo/useMemo/useCallback when enabled
```

**Added**: 2026-04-19

---

## Edit: SKILL.md Quick Reference — Section 8 (Advanced Patterns)

**Target**: `skills/react-best-practices/SKILL.md`

**Intent**: Index the `use()` hook rule under Advanced Patterns.

**Content**: After the `advanced-use-latest` bullet under
"### 8. Advanced Patterns (LOW)", append:

```
- `advanced-use-hook-promise` - React 19: use() unwraps Promises in Client Components under Suspense
```

**Added**: 2026-04-19
