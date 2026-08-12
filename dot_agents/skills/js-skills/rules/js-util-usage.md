---
title: "@mj-studio/js-util Guide-Driven Refactoring"
impact: HIGH
impactDescription: Helps simplify and refactor project code by applying @mj-studio/js-util's documented public helpers and guidance
tags: js-util, mj-studio, llms, utilities, refactoring, simplification
---

## @mj-studio/js-util Guide-Driven Refactoring

When string, object, array, or JSON-like utility code is being added, reviewed, or refactored, check whether `@mj-studio/js-util` already documents a public helper that can replace custom logic. The point of this rule is not to restate the guide locally, but to make the guide actively shape implementation and refactoring decisions.

Guide reference:
- [Repository](https://github.com/mj-studio-library/js-util)
- [Original llms.txt](https://github.com/mj-studio-library/js-util/blob/master/llms.txt)
- [Raw llms.txt](https://raw.githubusercontent.com/mj-studio-library/js-util/master/llms.txt)

### Required Workflow

1. Open the upstream `llms.txt` before adding or refactoring utility logic in the domains covered by `@mj-studio/js-util`.
2. If the user explicitly requests using `@mj-studio/js-util` and the package is not installed in the project, install it first.
3. Check whether an existing public helper can replace the local code with a simpler and clearer implementation.
4. If the documented helper matches the intended semantics, prefer refactoring to that helper instead of keeping bespoke utility code.
5. Use the guide to discover supported patterns and best practices, then apply them directly in the project code.
6. Re-check `llms.txt` whenever function behavior, options, or naming is uncertain.

### Do Not

- Do not treat `@mj-studio/js-util` as a passive reference only. Use it to simplify code when it is a good semantic match.
- Do not install the package proactively when the user did not ask to use `@mj-studio/js-util`.
- Do not keep ad-hoc utility implementations if the package already provides the same behavior clearly.
- Do not wrap or recreate documented helpers without a concrete project-specific reason.
- Do not paraphrase all function docs into this skill. Keep this rule focused on when and how to apply the upstream guide.

This rule applies to every public function from `@mj-studio/js-util`. The upstream `llms.txt` should be used as the working guide for discovering replacement opportunities, simplifying existing code, and standardizing utility usage across the project.

Reference:
[Repository](https://github.com/mj-studio-library/js-util)
[@mj-studio/js-util llms.txt](https://github.com/mj-studio-library/js-util/blob/master/llms.txt)
