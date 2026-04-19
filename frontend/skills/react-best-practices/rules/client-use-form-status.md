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
