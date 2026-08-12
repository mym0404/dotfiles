---
name: js-skills
description: >
  Zod schema definition patterns, dayjs date/time handling conventions,
  @mj-studio/js-util guide-driven refactoring rules, and class-based
  module patterns.
  Use when defining Zod schemas, creating domain models, integrating
  const assertion enums with Zod validation, working with dayjs
  for date/time operations, using @mj-studio/js-util functions, or
  building stateful modules, Zustand stores, and feature-first folder
  structures where feature-specific code lives under `feature/{domain}` in
  JavaScript/TypeScript.
license: MIT
metadata:
  author: mj
  version: "2.9.5"
---

# JS Skills — Schema, Dayjs, Util, Module & Structure Patterns

Consistent Zod schema definition rules, dayjs date/time conventions, guide-driven utility refactoring rules, class-based module patterns, Zustand store patterns, and feature-first architecture patterns extracted from production domain modeling.

## When to Apply

Reference these guidelines when:

- Defining new domain model schemas with Zod
- Extending base schemas for entity models
- Integrating const assertion enums with Zod validation
- Composing or deriving schemas from existing ones
- Creating model instances with auto-generated base fields
- Setting up dayjs plugins and locale in a project
- Working with timestamps, time arithmetic, formatting, or durations
- Using or reviewing public APIs from `@mj-studio/js-util`
- Building a stateful module with internal mutable state and related methods
- Creating standard, persisted, or provider-based Zustand stores
- Organizing code by feature folders with `feature/{domain}` and `feature/common` for shared pieces

## Rule Categories by Priority

| Priority | Category         | Impact | Prefix    |
| -------- | ---------------- | ------ | --------- |
| 1        | Schema Patterns  | HIGH   | `schema-` |
| 2        | Dayjs Patterns   | HIGH   | `dayjs-`  |
| 3        | JS Util Patterns | HIGH   | `js-util-` |
| 4        | Module Patterns  | HIGH   | `module-` |
| 5        | Zustand Patterns | HIGH   | `zustand-` |
| 6        | Architecture Patterns | HIGH | `architecture-` |

## Quick Reference

### 1. Schema Patterns (HIGH)

- `schema-definition-patterns` — Current Zod 4 definition helpers, logical schema grouping, type inference, composition, and createModel flow

### 2. Dayjs Patterns (HIGH)

- `dayjs-usage` — Plugin setup, timestamp ops, time arithmetic, formatting, duration

### 3. JS Util Patterns (HIGH)

- `js-util-usage` — Use upstream `llms.txt` to discover, apply, and refactor toward `@mj-studio/js-util` helpers instead of bespoke utility code

### 4. Module Patterns (HIGH)

- `module-class-over-factory` — Use a class instead of a closure factory object when a module owns mutable state and related methods

### 5. Zustand Patterns (HIGH)

- `zustand-store-patterns` — Use consistent patterns for normal stores, persisted stores, and provider-backed stores

### 6. Architecture Patterns (HIGH)

- `architecture-broad-domain-nesting` — Organize code by feature, default to `feature/{domain}`, allow only one nested `feature/{parent}/feature/{child}` split when unavoidable, keep shared pieces in `feature/common`

## How to Use

Read individual rule files for details and examples:

``` 
rules/schema-definition-patterns.md
rules/dayjs-usage.md
rules/js-util-usage.md
rules/module-class-over-factory.md
rules/zustand-store-patterns.md
rules/architecture-broad-domain-nesting.md
```

Each rule file contains:

- Why the rule matters
- Incorrect implementation example
- Correct implementation example
- Reference links
