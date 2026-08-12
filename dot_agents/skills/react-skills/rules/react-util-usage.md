---
title: "@mj-studio/react-util Guide-Driven Refactoring"
impact: HIGH
impactDescription: Helps simplify and refactor React code by applying @mj-studio/react-util's documented hooks and components
tags: react, react-util, mj-studio, llms, hooks, refactoring, simplification
---

## @mj-studio/react-util Guide-Driven Refactoring

When React utility logic is being added, reviewed, or refactored, check whether `@mj-studio/react-util` already documents a public hook or component that can replace custom lifecycle, timer, stable-callback, client-only, or browser-event code. The point of this rule is not to restate the guide locally, but to make the guide actively shape implementation and refactoring decisions.

Guide reference:
- [Repository](https://github.com/mj-studio-library/react-util)
- [Original llms.txt](https://github.com/mj-studio-library/react-util/blob/master/llms.txt)
- [Raw llms.txt](https://raw.githubusercontent.com/mj-studio-library/react-util/master/llms.txt)

### Required Workflow

1. Open the upstream `llms.txt` before adding or refactoring React utility logic in the domains covered by `@mj-studio/react-util`.
2. If the user explicitly requests using `@mj-studio/react-util` and the package is not installed in the project, install it first.
3. Check whether an existing public hook or component can replace the local code with a simpler and clearer implementation.
4. If the documented helper matches the intended semantics, prefer refactoring to that helper instead of keeping bespoke React utility code.
5. Use the guide to discover supported patterns and best practices, then apply them directly in the project code.
6. Re-check `llms.txt` whenever behavior, options, naming, or runtime assumptions are uncertain.

### Do Not

- Do not treat `@mj-studio/react-util` as a passive reference only. Use it to simplify React code when it is a good semantic match.
- Do not install the package proactively when the user did not ask to use `@mj-studio/react-util`.
- Do not keep ad-hoc hooks or wrapper components if the package already provides the same behavior clearly.
- Do not wrap or recreate documented helpers without a concrete project-specific reason.
- Do not paraphrase all function and component docs into this skill. Keep this rule focused on when and how to apply the upstream guide.

This rule applies to every public hook and component from `@mj-studio/react-util`. The upstream `llms.txt` should be used as the working guide for discovering replacement opportunities, simplifying existing React code, and standardizing utility usage across the project.

Reference:
[Repository](https://github.com/mj-studio-library/react-util)
[@mj-studio/react-util llms.txt](https://github.com/mj-studio-library/react-util/blob/master/llms.txt)
