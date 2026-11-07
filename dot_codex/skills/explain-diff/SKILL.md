---
name: explain-diff
description: Create one self-contained interactive Korean HTML explanation for a code diff, branch, commit range, or pull request.
---

# Explain Diff

## Writing

Before drafting, read and apply [`vibe-writing`](../vibe-writing/SKILL.md) to all user-visible Korean text.

## Workflow

1. Resolve the exact change boundary, then run `git diff` for that boundary before drafting any code block. Read the relevant hunks first, then inspect surrounding code, entrypoints, and contracts. Complete discovery when the previous behavior, new behavior, and reason for each material change are evidence-backed by the diff.
2. Build the template's four sections:
   - Background: The existing system and behavior relevant to the diff.
   - Intuition: The reason for the change and its intended behavior.
   - Code: A walkthrough of the material source changes.
   - Quiz: Interactive multiple-choice questions with immediate feedback, following the content contract's coverage rules.
   Finish the draft when the first three sections collectively account for every material change from step 1 and every decision taught there maps to quiz coverage.
3. Read and apply [`references/notion-dark-theme.md`](references/notion-dark-theme.md) and [`references/components.md`](references/components.md). Copy [`assets/explanation-template.html`](assets/explanation-template.html) to `/tmp/YYYY-MM-DD-explanation-<slug>.html`, then use `apply_patch` on that copied file to replace every `{{EXPLAIN_DIFF_*}}` slot with the draft. Do not assemble or replace template content through inline shell, JavaScript, or Python strings. Leave the template's CSS, page skeleton, fixed code-block control template, and page script unchanged.
4. Run `node scripts/render-shiki.mjs <html-path>` from this skill directory. Rendering is complete when the command exits with code 0; otherwise report the blocking error and stop.

## Presentation Contract

- Build every bounded visual with the component catalog's exact HTML structures. Do not invent free-form cards, grids, diagrams, or page styles.
- Give every source code block the required absolute file and current line metadata from the content contract, and mark source without a valid current-checkout location as non-openable. Never write a code-block header, Zed control, URI, or icon; rendering owns them.
- Verify the filename starts with today's `YYYY-MM-DD-` date and remains outside the code repository.
