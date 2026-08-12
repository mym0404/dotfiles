---
title: Use Consistent Zustand Store Patterns
impact: HIGH
impactDescription: Keeps Zustand usage predictable by standardizing plain stores, persisted stores, and provider-backed stores
tags: typescript, zustand, store, persist, provider, immer
---

## Use Consistent Zustand Store Patterns

Use Zustand with three explicit patterns depending on ownership and lifecycle:

- plain store for app-global in-memory state
- persisted store for state that must survive reloads
- provider-backed store for tree-scoped state instances

Keep state and actions in a single store type, define `initialState` from non-function fields, and prefer `immer` middleware for updates.

### Plain Store

Use `create()` for the default global store shape. Expose the main hook as `useX`, keep a `reset` action in the store, and provide a shallow-selected `useXStore` convenience hook for full-store reads.

```typescript
import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';

export type AuthState = {
  reset: () => void;
};

const initialState: OmitFunctions<AuthState> = {};

export const useAuth = create<AuthState>()(
  immer((set, get) => ({
    ...initialState,
    reset: () => set(initialState),
  })),
);

export const useAuthStore = () => useAuth(useShallow((state) => state));
```

### Persist Store

Use `persist()` only when the state must survive reloads. Persist stores should track hydration explicitly with `_hasHydrated` and `_markHydrate`, preserve the hydration flag on reset, and use `createJSONStorage(() => zustandPersistStorage)` as the storage boundary.

```typescript
import { create } from 'zustand';
import { createJSONStorage, persist } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';

export type AuthState = {
  _hasHydrated: boolean;
  _markHydrate: () => void;
  reset: () => void;
};

const initialState: OmitFunctions<AuthState> = {
  _hasHydrated: false,
};

export const useAuth = create<AuthState>()(
  persist(
    immer((set, get) => ({
      ...initialState,
      reset: () =>
        set((state) => ({
          ...initialState,
          _hasHydrated: state._hasHydrated,
        })),
      _markHydrate: () => set({ _hasHydrated: true }),
    })),
    {
      version: 0,
      name: 'Auth-storage',
      storage: createJSONStorage(() => zustandPersistStorage),
      onRehydrateStorage: (state) => () => state._markHydrate(),
    },
  ),
);

export const useAuthStore = () => useAuth(useShallow((state) => state));
```

Do not implement `zustandPersistStorage` in this rule. Treat it as a project-owned storage boundary.

### Provider-Backed Store

Use a provider-backed store when each subtree needs its own isolated store instance. Standardize this through a reusable `createZustandStoreProvider` helper instead of hand-writing context wrappers per store.

```tsx
export type AuthState = {};
export type AuthAction = {};

const initialState: AuthState = {};

export const {
  Provider: AuthProvider,
  useStoreProvider: useAuth,
  useStoreProviderShallow: useAuthShallow,
} = createZustandStoreProvider<AuthState & AuthAction>({
  name: 'Auth',
  creator: immer((set, get) => ({
    ...initialState,
  })),
});
```

The helper should:

- create the store with `createStore`
- hold the store instance in context
- create the instance once with `useRefValue`
- expose `useStoreProvider` and `useStoreProviderShallow`
- support optional equality functions through `useStoreWithEqualityFn`

### Store Utility Rules

- Define `initialState` with `OmitFunctions<T>` so state defaults exclude actions.
- If the project does not already have `OmitFunctions`, add it in a shared utility location.
- Keep `reset` inside the store instead of duplicating reset logic at call sites.
- Use `useShallow` for full-store selector convenience hooks such as `useAuthStore`.
- Keep store names consistent: `useAuth` for the main Zustand hook, `useAuthStore` for the shallow all-state reader, and `AuthProvider` / `useAuth` / `useAuthShallow` for provider-based variants.

`OmitFunctions` utility:

```typescript
type NonFunctionPropertyNames<T> = {
  [K in keyof T]: T[K] extends Function ? never : K;
}[keyof T];

export type OmitFunctions<T> = Pick<T, NonFunctionPropertyNames<T>>;
```

Reference:
[Zustand Introduction](https://zustand.docs.pmnd.rs/getting-started/introduction)
[Zustand Persist Middleware](https://zustand.docs.pmnd.rs/integrations/persisting-store-data)
