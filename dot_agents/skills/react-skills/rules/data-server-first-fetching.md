---
title: Prefer Server-First Fetching
impact: HIGH
impactDescription: Improves first paint and simplifies client state
tags: react, server-components, data-fetching
---

## Prefer Server-First Fetching

Load primary route data in Server Components before introducing client-side fetch logic.

**Incorrect:**

```tsx
"use client"

import { useEffect, useState } from "react"

export default function DashboardPage() {
  const [stats, setStats] = useState<{ users: number }>({ users: 0 })

  useEffect(() => {
    fetch("/api/stats").then(async (res) => {
      setStats((await res.json()) as { users: number })
    })
  }, [])

  return <p>{stats.users}</p>
}
```

**Correct:**

```tsx
export default async function DashboardPage() {
  const res = await fetch("https://example.com/api/stats", {
    next: { revalidate: 60 },
  })
  const stats = (await res.json()) as { users: number }

  return <p>{stats.users}</p>
}
```

Reference:
[Next.js Data Fetching](https://nextjs.org/docs/app/building-your-application/data-fetching)
