---
name: explain-diff
description: Create one self-contained interactive Korean HTML explanation for a code diff, branch, commit range, or pull request, with mandatory built-in fluent Korean writing, sentence-by-sentence hard-mode editing, and validation.
---

# Explain Diff

## Mandatory Korean Gate

- As the first action on every invocation, read [`references/korean-hard-mode.md`](references/korean-hard-mode.md) in full. It is the only Korean writing and editing contract for this skill. Do not rely on memory, metadata, excerpts, or a prior summary. If it is missing or cannot be read completely, report the blocking path and stop.
- Apply the built-in writing rules while drafting and the hard mode sentence by sentence to every user-visible Korean title, summary, explanation, label, code-block title, quiz choice, and feedback message. Preserve code, identifiers, facts, causality, certainty, and technical terms.
- Run the hard-mode pass once on the completed draft and again on the user-visible text in the filled HTML. Complete the gate only after all seven checks under `강한 검증` pass and no document-wide repetition rule remains violated. Revert any correction that conflicts with meaning preservation.
- Never run the prose segmentation scripts on filled HTML. Edit only user-visible text nodes, leaving HTML tags, attributes, CSS, JavaScript, code, paths, URIs, and escapes unchanged.

## Workflow

1. Resolve the exact change boundary, then run `git diff` for that boundary before drafting any code block. Read the relevant hunks first, then inspect surrounding code, entrypoints, and contracts. Complete discovery when the previous behavior, new behavior, and reason for each material change are evidence-backed by the diff.
2. Draft every user-visible Korean sentence under the built-in writing rules from the start, then build these sections:
   - Background: Explain the existing system relevant to this change. (You should broadly explore surrounding code for this.) We don't know how much the reader already knows, so include a deep background for beginners (note that it can be skipped if the reader is already familiar), and then a more narrow background directly relevant to the change.
   - Intuition: Explain the core intuition for the code change. The focus here is to explain the essence, not the full details. Use concrete examples with toy data. Use figures and diagrams liberally.
   - Code: Do a high-level walkthrough of the changes to the code. Group/order the changes in an understandable way.
   - Quiz: Come up with questions that test the reader's knowledge of this PR. This should be medium difficulty, difficult enough that you actually need to understand the substance of the PR to answer them, but not gotchas. The goal is to help the reader make sure that they've actually understood. These should be presented as interactive multiple-choice questions, and when the user clicks, it tells them whether they were correct and gives feedback. Let coverage determine the question count.
   Finish the draft when the first three sections collectively account for every material change from step 1 and every decision taught there maps to quiz coverage.
3. Run the first built-in Korean hard-mode pass on the completed draft. For a long draft materialized as a `.txt` or `.md` file, follow the temporary worksheet procedure in [`references/korean-hard-mode.md`](references/korean-hard-mode.md) with `scripts/segment.py` and `scripts/reassemble.py`; inspect protected headings, lists, tables, labels, and code separately.
4. Read and apply [`references/notion-dark-theme.md`](references/notion-dark-theme.md) and [`references/components.md`](references/components.md). Copy [`assets/explanation-template.html`](assets/explanation-template.html) to `/tmp/YYYY-MM-DD-explanation-<slug>.html`, then use `apply_patch` on that copied file to replace every `{{EXPLAIN_DIFF_*}}` slot with the draft. Do not assemble or replace template content through inline shell, JavaScript, or Python strings. Leave the template's CSS, page skeleton, fixed code-block control template, and page script unchanged.
5. Run the second built-in Korean hard-mode pass on every user-visible Korean text node in the filled HTML, then run `node scripts/render-shiki.mjs <html-path>` from this skill directory. Rendering is complete only when the Korean gate passes and the command exits with code 0; otherwise report the blocking error and stop.

## Presentation Contract

- Build every bounded visual with the component catalog's exact HTML structures. Do not invent free-form cards, grids, diagrams, or page styles.
- Give every source code block the required absolute file and current line metadata from the content contract, and mark source without a valid current-checkout location as non-openable. Never write a code-block header, WebStorm control, URI, or icon; rendering owns them.
- Verify the filename starts with today's `YYYY-MM-DD-` date and remains outside the code repository.
