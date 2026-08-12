---
name: react-skills
description: >
  React best practices for data fetching and @mj-studio/react-util adoption.
  Covers server-first loading in Server Components, client-side Suspense
  patterns with AsyncBoundary + TanStack Query, and guide-driven refactoring
  toward @mj-studio/react-util helpers.
license: MIT
metadata:
  author: mj
  version: "2.1.2"
---

# React Skills

Ruleset for React data fetching patterns and guide-driven utility refactoring.

## Rule Categories by Priority

| Priority | Category          | Impact | Prefix  |
| -------- | ----------------- | ------ | ------- |
| 1        | Data Fetching     | HIGH   | `data-` |
| 2        | React Util        | HIGH   | `react-util-` |

## Quick Reference

- `data-server-first-fetching` - Fetch data in Server Components first
- `data-async-boundary-suspense-query` - Use AsyncBoundary with useSuspenseQuery for client data fetching
- `react-util-usage` - Use upstream `llms.txt` to discover and apply `@mj-studio/react-util` helpers instead of bespoke React utility code

## How to Use

Read the rule files:

```
rules/data-server-first-fetching.md
rules/data-async-boundary-suspense-query.md
rules/react-util-usage.md
```
