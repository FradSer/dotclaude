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
