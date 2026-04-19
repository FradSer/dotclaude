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
