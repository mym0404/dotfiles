---
name: refacto
description: Apply opinionated code-style rules when refactoring existing code.
---

# Refacto

Apply every rule below to the requested refactoring surface.

## Boundary

Preserve externally observable behavior. When a rule conflicts with current behavior or a public contract, stop and ask which result to keep.

## Rules

### Direct Ownership

Keep behavior in the nearest unit that owns it.

Create a function or class only when it owns at least one current responsibility:

- policy or a decision
- state or a lifecycle
- an invariant
- boundary validation
- behavior reused by multiple current callers

Avoid pass-through methods that only delegate to another method without adding policy, state, an invariant, boundary validation, or contract adaptation. Call the direct owner instead.

A unit is shallow when it only forwards a call, renames an operation, or moves a small expression without owning one of these responsibilities. Inline existing shallow units and call the direct owner instead of adding another layer.

#### Examples

```ts
// Function: shallow
const getUser = (id: UserId) => userRepository.get(id)
await getUser(id)

// Function: direct
await userRepository.get(id)

// Class: shallow
class UserReader {
  constructor(private readonly repository: UserRepository) {}
  read(id: UserId) { return this.repository.get(id) }
}
await new UserReader(userRepository).read(id)

// Class: direct
await userRepository.get(id)
```

### Readability

- Prefer the simplest structure that keeps intent obvious.
- Reuse existing aliases or enums when they already express the domain.
- Keep one-off literals inline, and extract repeated magic strings or numbers into named constants.
- Avoid unnecessary abstraction layers, indirection, or extra options.
- Use plain objects or arrays unless `Map` or `Set` is clearly needed.
- Preserve already-correct code instead of creating stylistic churn.

#### Before

```ts
const createStatusChecker = () => {
  const store = new Map<string, string>([
    ["active", "active"],
    ["pending", "pending"],
  ])

  return {
    isActive: (status: string) => {
      return status === "active" || store.get(status) === "active"
    },
  }
}
```

#### After

```ts
const ACTIVE_STATUS = "active"

const isActiveStatus = (status: string) => {
  return status === ACTIVE_STATUS
}
```

### Comments

- Keep comments minimal and in English.
- Add comments only when they explain something the code does not make obvious.
- Keep user prompts and chat context out of code comments.
- Use plain text instead of decorative icons in code-facing text.

#### Before

```ts
// User asked to hide admin-only data
const filterVisibleUsers = (users: User[]) => {
  return users.filter((user) => user.isVisible)
}
```

#### After

```ts
const filterVisibleUsers = (users: User[]) => {
  return users.filter((user) => user.isVisible)
}
```

## JavaScript/TypeScript

Apply the following rules to JavaScript and TypeScript code.

### Function Patterns

- Prefer arrow functions.
- Prefer a single object parameter with destructuring when a function has multiple related fields.
- Keep simple one- or two-argument functions positional when that shape is clearer.
- Extract helpers from dense inline logic.
- Prefer array methods such as `map`, `filter`, and `some` over manual loops for repeated transforms, and use `map` to render repeated React elements.
- Keep control flow simple enough to understand in one pass.

#### Before

```ts
function createUser(name: string, email: string, role: "admin" | "member") {
  return { name, email, role }
}

const getVisibleNames = (users: User[]) => {
  const result: string[] = []

  for (const user of users) {
    if (user.deletedAt) {
      continue
    }

    if (user.name.trim().length === 0) {
      continue
    }

    result.push(user.name.trim())
  }

  return result
}
```

#### After

```ts
const createUser = ({
  name,
  email,
  role,
}: {
  name: string
  email: string
  role: "admin" | "member"
}) => {
  return { name, email, role }
}

const isVisibleUser = (user: User) => {
  return !user.deletedAt && user.name.trim().length > 0
}

const getVisibleNames = (users: User[]) => {
  return users.filter(isVisibleUser).map((user) => user.name.trim())
}
```

### Type Design

- Prefer inferred variable and return types.
- Use `Type[]` instead of `Array<Type>`.
- Keep one-off function parameter shapes inline.
- Extract a `type` alias when a shape is long or reused.
- Prefer `type` aliases over `interface`.
- Keep type declarations inline when a standalone declaration adds no reuse or clarity.
- Prefer `undefined` over `null` unless `null` has real domain meaning.

#### Before

```ts
interface UserProfile {
  name: string
  tags: Array<string>
}

const getDisplayName = (profile: UserProfile): string => {
  return profile.name ?? null
}
```

#### After

```ts
type UserProfile = {
  name: string
  tags: string[]
}

const getDisplayName = (profile: UserProfile) => {
  return profile.name
}
```

### Type Safety

- Use concrete types instead of `any`.
- Resolve the underlying type instead of casting with `as any` or `as unknown as`.
- Resolve type errors without `@ts-ignore`, `@ts-nocheck`, or `@ts-expect-error`.
- Use `unknown` only at real external boundaries such as `catch` or unchecked input.
- Use concrete types for ordinary function parameters.
- When types are genuinely unclear, stop and confirm the expected shape instead of forcing a cast.

#### Before

```ts
// @ts-ignore
const parseUser = (value: unknown) => {
  return (value as any).name as string
}
```

#### After

```ts
const getErrorMessage = (error: unknown) => {
  if (error instanceof Error) {
    return error.message
  }

  return "Unknown error"
}
```

### Module Boundaries

- Prefer named exports over default exports.
- Import modules directly instead of adding export-only `index.ts` barrel files.

#### Before

```ts
const createUserStore = () => {
  return {}
}

export default createUserStore
```

```ts
// user/index.ts
export * from "./UserCard"
export * from "./UserTable"
```

#### After

```ts
export const createUserStore = () => {
  return {}
}
```

```ts
import { UserCard } from "./UserCard"
import { UserTable } from "./UserTable"
```

## Completion

Every applicable rule above is satisfied. Every function and class added or changed by the refactor owns at least one responsibility listed under Direct Ownership. Repository-native checks pass without changing externally observable behavior.
