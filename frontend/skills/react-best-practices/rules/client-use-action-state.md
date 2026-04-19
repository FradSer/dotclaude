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
