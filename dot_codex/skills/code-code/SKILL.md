---
name: code-code
description: Apply required coding guidelines and opinionated style rules
---

# Code Code

## Program Context

Inspect current requirements, code, and project documentation to identify:

- The program's purpose, users, operating environment, input sources, and the cost of failure.
- The state and work lifecycle, concurrent operations, and existing error handling, validation, and cancellation owners.

Complete when implementation constraints have evidence or are raised in the Decision Gate.

## Coding Guidelines
### 1. Decision Gate
- State assumptions and present meaningful options for choices that affect behavior, scope, data handling, risk, or irreversible actions. Ask the smallest question needed to resolve them.
- Present the simplest viable approach and its tradeoff.

Complete when every result-changing decision is resolved or explicitly assumed; then begin implementation.

### 2. Smallest Complete Change
- Justify each abstraction, option, dependency, and error branch with a current requirement; trim code not needed for the requested behavior before finishing.
- Add new test code only when explicitly requested.

The smallest complete change is reached when removing another line would make the requested behavior incomplete or less safe.

### 3. Surgical Diff
- Match existing style and avoid stylistic churn. Preserve unrelated or unexpected files, code, comments, formatting, structure, and artifacts; ask before changing anything with unclear purpose or ownership.
- Report unrelated dead code and leave it unchanged.
- Outside an explicit cleanup scope, remove only artifacts made unused by your changes or created in this task and confirmed unnecessary, including abandoned attempts.
- An explicit cleanup request also covers existing anti-patterns and unused artifacts in the agreed scope. Before removal, check current callers, public entry points, registrations, and initialization side effects.

The surgical diff is complete when every changed line traces directly to the user's request.

### 4. Verification Loop
- Before implementing, map each requested outcome to an observable check. Write a brief plan only when it reduces ambiguity, with a check for each meaningful step.
- Run the smallest repository-native check for each meaningful result; repeat until all criteria pass, available validation is exhausted, or a result-changing blocker requires the user.

Complete when evidence proves every requested result. If validation is exhausted or blocked, report the unverified criteria and limitations.

## Boundary

Preserve externally observable behavior outside authorized changes. Ask before making an additional behavior or public-contract change.

Preserve required external-input validation, data-loss prevention, security and permission checks, accessibility, and documented compliance or hardware constraints identified through Program Context.

Implement the current target behavior; include compatibility branches only when backward compatibility is explicitly requested.

## Rules

### Direct Ownership

Prefer direct ownership over shallow abstractions.
Inline pass-through wrappers within the requested scope.

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

### Reuse Before Implementation

- Before writing a replacement or adding a dependency, inspect existing modules, installed dependencies, current usage, and built-in features. Verify the candidate's inputs, outputs, errors, ordering, and lifecycle guarantees.
- Choose the first option that fully satisfies the current requirement: deletion, standard library, platform or framework feature, existing module or dependency, minimum direct implementation.
- Add configuration only for values that need to vary now, and dependencies only when existing options cannot express the required behavior clearly at lower cost.

### Readability

- Express current requirements with the fewest concepts and branches that keep intent obvious.
- Reuse existing aliases or enums when they already express the domain.
- Keep one-off literals inline unless an existing translation or configuration system owns them; extract repeated magic strings or numbers into named constants.
- Use plain objects or arrays unless `Map` or `Set` is clearly needed.

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
const isActiveStatus = (status: string) => {
  return status === "active"
}
```

#### Single-use Literal

```tsx
const APPROVAL_MESSAGE = "확인"
const ApprovalButton = () => <button>{APPROVAL_MESSAGE}</button>
```

```tsx
const ApprovalButton = () => <button>확인</button>
```

### Necessary Defenses

#### Error Handling

- Catch errors at the owner of recovery, contract translation, reporting, or user feedback. Handle expected failures specifically and let unhandled failures reach the existing error owner.
- Remove catches that only rethrow unchanged errors and consolidate duplicate handling. Keep resource cleanup in its owning lifecycle.
- Validate unchecked input at entry; rely on concrete types and established guarantees internally.

#### Cancellation

- Use `AbortSignal` for current user actions, lifecycle cleanup, resource limits, or explicit time limits with an identified initiator, trigger, and operation to stop.
- Reuse cancellation or stale-result protection already owned by the client or framework; preserve protection against older results overwriting newer state.
- Pass signals only through operations that need them; remove unused parameters, controllers, listeners, and redundant checks while preserving the required lifecycle.

## JavaScript/TypeScript

### Function Patterns

- Prefer a single object parameter with destructuring when a function has multiple related fields.
- Keep simple one- or two-argument functions positional when that shape is clearer.
- Extract helpers from dense inline logic.
- Prefer array methods such as `map`, `filter`, and `some` over manual loops for repeated transforms, and use `map` to render repeated React elements.
- Preserve evaluation order, side effects, and early-exit behavior when simplifying control flow.

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
- Keep small, single-use shapes inline; extract a `type` alias when the shape is long, reused, or clearer with a name.
- Prefer `type` aliases over `interface`.
- Prefer `undefined` over `null` unless `null` has real domain meaning.
- Use `value != null` when checking that a value is neither `null` nor `undefined`.

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

Complete when every applicable rule is satisfied and the Verification Loop proves the requested results.
