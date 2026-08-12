---
title: Use AsyncBoundary with useSuspenseQuery for Client Data Fetching
impact: HIGH
impactDescription: Eliminates manual loading/error state, enforces declarative data flow
tags: react, suspense, error-boundary, tanstack-query, suspensive
---

## Use AsyncBoundary with useSuspenseQuery for Client Data Fetching

This pattern is **exclusively for client-side rendering contexts** — React Native apps and web `'use client'` components. **Do NOT use in Server Components or SSG/ISR pages** where data should be fetched at build time or request time on the server (see `data-server-first-fetching` rule instead).

Wrap client-side data fetching components with `AsyncBoundary` (ErrorBoundary + Suspense) and use `useSuspenseQuery` inside. Separate the boundary (outer) from the data consumer (inner) so loading and error states are handled declaratively, not imperatively.

### AsyncBoundary Component

Combine `@suspensive/react`'s `ErrorBoundary` and `Suspense` into a single reusable boundary:

```tsx
'use client';

import { ErrorBoundary, Suspense } from '@suspensive/react';
import type { ComponentProps, ReactNode } from 'react';

type AsyncBoundaryProps = {
  children: ReactNode;
  pendingFallback?: ReactNode;
  rejectedFallback?: ComponentProps<typeof ErrorBoundary>['fallback'];
  clientOnly?: boolean;
  ignoreError?: boolean;
};

export const AsyncBoundary = ({
  children,
  pendingFallback = <DefaultPendingFallback />,
  rejectedFallback = ({ error, reset }) => <DefaultRejectedFallback error={error} reset={reset} />,
  clientOnly = false,
  ignoreError = false,
}: AsyncBoundaryProps) => {
  return (
    <ErrorBoundary fallback={ignoreError ? null : rejectedFallback}>
      <Suspense clientOnly={clientOnly} fallback={pendingFallback}>
        {children}
      </Suspense>
    </ErrorBoundary>
  );
};
```

- `clientOnly` — delays rendering until the client, preventing SSR hydration mismatches for auth-dependent or browser-only data.
- `ignoreError` — silently swallows errors (useful for non-critical UI sections like activity feeds).

### Usage Pattern: Boundary ↔ Consumer Separation

**Incorrect — imperative loading/error handling inside the component:**

```tsx
'use client';

import { useEffect, useState } from 'react';

export const CommentSection = ({ postId }: { postId: string }) => {
  const [comments, setComments] = useState<Comment[]>([]);
  const [isLoading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    fetchComments(postId)
      .then(setComments)
      .catch(setError)
      .finally(() => setLoading(false));
  }, [postId]);

  if (isLoading) {
    return <Spinner />;
  }

  if (error) {
    return <p>{error.message}</p>;
  }

  return <CommentList comments={comments} />;
};
```

Problems: loading/error state scattered across component logic, no automatic retry on error, no cache, refetch on mount every time.

**Correct — declarative boundary + suspense query:**

```tsx
'use client';

import { useSuspenseQuery } from '@tanstack/react-query';

import { AsyncBoundary } from '@/lib/component/AsyncBoundary';

// Outer: provides loading/error boundary
export const CommentSection = ({ postId }: { postId: string }) => {
  return (
    <AsyncBoundary
      clientOnly
      pendingFallback={
        <div className={'flex min-h-[200px] items-center justify-center'}>
          <span className={'loading loading-ring loading-lg'} />
        </div>
      }
    >
      <CommentSectionContent postId={postId} />
    </AsyncBoundary>
  );
};

// Inner: assumes data is always available — no loading/error checks
const CommentSectionContent = ({ postId }: { postId: string }) => {
  const { comments } = useComments(postId);

  return <CommentList comments={comments} />;
};

// Hook: encapsulates query logic
const useComments = (postId: string) => {
  const { data } = useSuspenseQuery({
    queryKey: ['comments', postId],
    queryFn: async () => {
      const res = await fetch(`/api/comments?postId=${postId}`);

      if (!res.ok) {
        throw new Error('Failed to fetch comments');
      }

      return (await res.json()) as Comment[];
    },
  });

  return { comments: data };
};
```

### Key Rules

1. **Client-only pattern** — this entire pattern (AsyncBoundary + useSuspenseQuery) applies only to React Native or web client components (`'use client'`). In Server Components or SSG/ISR pages, fetch data directly on the server without Suspense boundaries or TanStack Query.
2. **Outer boundary, inner consumer** — the component that renders `AsyncBoundary` never calls `useSuspenseQuery` itself. A child component consumes the data.
2. **Use `clientOnly` for auth-dependent or browser-only queries** — prevents SSR from attempting to render before the client has session state.
3. **Use `ignoreError` only for non-critical sections** — activity feeds, optional panels. Never for primary page content.
4. **Custom `pendingFallback` per context** — match the loading skeleton to the section's visual layout (card skeleton for cards, table skeleton for tables).
5. **`useSuspenseQuery` from `@tanstack/react-query`** — not from `@suspensive/react-query` (deprecated re-exports). Import directly from TanStack.
6. **Throw errors in `queryFn`** — `useSuspenseQuery` propagates thrown errors to the nearest `ErrorBoundary`. Never swallow fetch errors silently.
7. **Never use in Server Components or SSG** — Server Components can `await` data directly. SSG/ISR pages use `fetch` with caching options at build/request time. Using AsyncBoundary + useSuspenseQuery there is unnecessary and will not work as expected.

### Nested AsyncBoundary

Multiple `AsyncBoundary` wrappers can be nested for independent loading states:

```tsx
export default function ProfilePage() {
  return (
    <AsyncBoundary clientOnly>
      <ProfileContent />
      {/* Nested boundary for secondary section */}
      <AsyncBoundary clientOnly pendingFallback={<CardSkeleton />}>
        <MyCommentsList userId={profile.id} />
      </AsyncBoundary>
    </AsyncBoundary>
  );
}
```

Each boundary isolates its own loading/error state — a failure in `MyCommentsList` won't take down `ProfileContent`.

Reference:
- [@suspensive/react Docs](https://suspensive.org/en/docs/react/Suspense)
- [TanStack Query useSuspenseQuery](https://tanstack.com/query/latest/docs/framework/react/reference/useSuspenseQuery)
- [@suspensive/react v2 Migration (AsyncBoundary removal)](https://suspensive.org/en/docs/react/migration/migrate-to-v2)
