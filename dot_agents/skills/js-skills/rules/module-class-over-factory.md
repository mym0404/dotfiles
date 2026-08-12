---
title: Prefer Classes over Closure Factories for Stateful Modules
impact: HIGH
impactDescription: Makes stateful modules easier to understand, extend, and reuse by giving their state and behavior a named class boundary
tags: typescript, javascript, class, module, factory, state
---

## Prefer Classes over Closure Factories for Stateful Modules

When a module owns internal mutable state and exposes multiple related methods, prefer a class over a `createX()` closure factory that returns an object. Use the class instance as the module boundary instead of hiding state inside a factory function. Within that class, default to `private` for internal members, add `readonly` when a field should not be reassigned, and prefer constructor parameter properties for stored constructor inputs.

**Incorrect:**

```typescript
const createWriteDebugLogger = () => {
  const logs: DcinsideDebugLog[] = [];

  const append = ({
    step,
    level,
    message,
    detail,
  }: {
    step: string;
    level: DcinsideDebugLogLevel;
    message: string;
    detail?: Record<string, unknown>;
  }) => {
    const nextLog: DcinsideDebugLog = {
      id: `dcinside-write-log-${logs.length + 1}`,
      time: dayjs().toISOString(),
      step,
      level,
      message,
      detail: detail ? JSON.stringify(detail, null, 2) : null,
    };

    logs.push(nextLog);
    console.info('[dcinside-write]', nextLog.time, nextLog.step, nextLog.detail ?? '');
  };

  return {
    append,
    getLogs: () => [...logs],
  };
};
```

Why it fails: The module has clear state and related behavior, but the factory hides that structure inside a function closure. The resulting object is less explicit than a named class, harder to extend, and less discoverable when the module grows.

**Correct:**

```typescript
export class WriteDebugLogger {
  private readonly logs: DcinsideDebugLog[] = [];

  constructor(private readonly logPrefix = 'dcinside-write') {}

  append({
    step,
    level,
    message,
    detail,
  }: {
    step: string;
    level: DcinsideDebugLogLevel;
    message: string;
    detail?: Record<string, unknown>;
  }) {
    const nextLog: DcinsideDebugLog = {
      id: `${this.logPrefix}-log-${this.logs.length + 1}`,
      time: dayjs().toISOString(),
      step,
      level,
      message,
      detail: detail ? JSON.stringify(detail, null, 2) : null,
    };

    this.logs.push(nextLog);
    console.info(`[${this.logPrefix}]`, nextLog.time, nextLog.step, nextLog.detail ?? '');
  }

  getLogs() {
    return [...this.logs];
  }
}

const logger = new WriteDebugLogger();
```

Use this pattern when:

- the module keeps mutable state across method calls
- multiple methods operate on the same state
- the module benefits from a named, explicit public surface

Class authoring details:

- Use `private` for fields and helper methods that are not part of the public surface.
- Add `readonly` when a field or dependency should not be reassigned after initialization.
- Prefer constructor parameter properties such as `constructor(private readonly logPrefix: string) {}` over separate field declarations plus manual assignments when the constructor input is stored directly.

Reference:
[TypeScript Classes](https://www.typescriptlang.org/docs/handbook/2/classes.html)
[MDN Classes](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Classes)
