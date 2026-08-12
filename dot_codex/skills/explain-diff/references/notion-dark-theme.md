# Explain Diff Content Contract

Read this entire file before filling [`../assets/explanation-template.html`](../assets/explanation-template.html). The template is the single source of truth for page structure, design tokens, CSS, responsive behavior, code-block controls, and page JavaScript. Copy it as the starting point; do not recreate, restyle, reorder, or supplement its fixed parts.

## Template slots

Replace every occurrence of these slots and leave no slot in the rendered file:

- `{{EXPLAIN_DIFF_TITLE}}`: one concise, HTML-escaped title. It appears in both `<title>` and `<h1>`.
- `{{EXPLAIN_DIFF_SUMMARY}}`: one concise Korean summary without a wrapper element.
- `{{EXPLAIN_DIFF_BACKGROUND}}`, `{{EXPLAIN_DIFF_INTUITION}}`, `{{EXPLAIN_DIFF_CODE}}`, and `{{EXPLAIN_DIFF_QUIZ}}`: HTML fragments for the named section.

Keep the fixed header, section ids, section order, stylesheet, code-block control template, and script unchanged. Do not add another `<style>` or `<script>` block.
Do not add a table of contents, navigation, sidebar, breadcrumbs, progress, metrics, status badges, sticky controls, or top-level tabs.
Do not add ARIA attributes, roles, external fonts, stylesheets, scripts, or runtime syntax-highlighting assets.

## Open-flow content

Every section starts with direct, unframed prose. Keep ordinary headings, paragraphs, lists, and complete `.explanation-group` elements in document flow.

- Use only the bounded visuals defined in [`components.md`](components.md), and copy their structures exactly.
- Use one `.quiz-card` for each quiz question.
- Never wrap all non-heading children of a section or an entire `.explanation-group` in a bounded visual.

## Code source contract

Treat every code block as a **proof slice**: one adjacent prose claim and only the contiguous source lines needed to prove it. Choose and trim each slice before copying source.

1. Write the claim as one sentence.
2. Start from the exact changed lines in the relevant `git diff` hunk. Expand outward only far enough to identify the symbol, scope, or control flow needed by the claim. A current-source slice may contain no changed line when it teaches surrounding behavior.
3. Include code only when removing the block would prevent the reader from understanding the change reason, execution result, or invariant, or from applying a quiz decision. Use prose or a diagram for the rest.
4. Split a large change by meaningful claim or real hunk. Show a complete contiguous function or hunk only when splitting it would break one indivisible algorithm. Run the deletion test on every context line and keep only the context required by the claim.
5. Add **diff annotations** only to displayed lines present on the added or removed side of the inspected hunk. Keep surrounding source lines neutral. For a move or rename with unchanged behavior, annotate the identity lines that prove the transition.
6. Add **highlight annotations** to current lines whose behavior, invariant, or relationship deserves attention. For a wholly new file, state its creation in prose, reserve diff for the identity lines that prove creation, and highlight only the mechanics taught by the claim.
7. Treat diff and highlight as optional, independent reading aids. A block may use neither, either, or both. Let one line carry both only when the transition and its current meaning are both necessary to the same claim; keep one coherent proof slice rather than separating annotation kinds mechanically.

Annotation attributes:

- `data-code-add-lines` and `data-code-remove-lines` mark lines confirmed on the corresponding side of the inspected diff.
- `data-code-highlight-lines` marks important lines.
- These attributes may coexist on one block and their ranges may overlap. Omit all three when syntax highlighting alone is enough.
- `data-code-source` marks a block for the renderer.
- `data-code-lang` accepts a bundled language id or alias and defaults to `text` when omitted or unknown.
- `data-code-title`, `data-code-file`, and `data-code-line` are required.
- `data-code-file` must be an absolute path to the relevant checkout.
- `data-code-line` and `data-code-column` are 1-based. The column defaults to `1`.
- `data-code-openable` defaults to `true`. Use `false` only when the displayed source has no valid current-checkout location.

```html
<pre
  data-code-source
  data-code-lang="cpp"
  data-code-title="src/tree.cpp"
  data-code-file="/absolute/worktree/src/tree.cpp"
  data-code-line="42"
  data-code-column="1"
  data-code-openable="true"
  data-code-add-lines="2"
  data-code-remove-lines="1"
  data-code-highlight-lines="2-3"
><code>oldCall();
newCall();
return currentValue;</code></pre>
```

- Keep code text directly inside `<code>` so line metadata stays 1-based and predictable.
- Point a mixed before/after block at the current-side line that best represents its claim. Point moves and renames at the new path and new line.
- Set `data-code-openable="false"` for deleted files, removed-only source, and historical source that differs from the current checkout. The page script then omits the Open control.
- Keep absolute paths and positive line/column values even when opening is disabled. For openable blocks, the renderer also requires a current regular file and a line within that file.
- HTML-escape `&`, `<`, and `>` inside `<code>`; line metadata refers to the decoded source.
- Line lists accept comma-separated 1-based numbers and closed ranges. No range may exceed the source, and added and removed ranges must not overlap each other.
- Copy lines exactly from the inspected diff or current source. Never invent placeholder comments, shorten implementations into pseudocode, or rename variables inside a code block.
- Keep real hunk order and adjacency. Never join nonadjacent hunks into an apparent replacement; use separate blocks when multiple hunks matter.
- Use metadata as the only diff state. Preserve legitimate source lines beginning with `+` or `-`, but never add patch markers that are absent from the source.
- Recompute metadata after every content edit. Verify each added and removed line verbatim against the corresponding side of the source diff.
- When adjacent prose names a changed symbol as evidence, include that symbol's exact changed line.
- The renderer replaces each source block with static Shiki HTML and removes every `data-code-*` marker. The template owns the header, compact WebStorm Open control, code layout, and styling.
- Never write the rendered `<figure>`, WebStorm control HTML, editor URI, or icon markup. Supply only the source block and its `data-code-*` metadata.

## Quiz coverage

Derive question count from coverage.

1. List the material decisions taught across `Background`, `Intuition`, and `Code`.
2. Cover every decision with at least one question; combine decisions when one applied scenario tests both.
3. Remove duplicate and trivial questions. Make every distractor plausible and avoid filename recall.
4. Ask readers to predict behavior, apply an invariant, or choose the change that fixes a concrete case.
5. Give every option an immediate explanation through `data-feedback`.

Place all questions in one `.quiz-list`. Each `.quiz-card` contains one `.quiz-options` group, buttons with exactly one `data-correct="true"`, and one `.quiz-feedback`. The template script marks only the selected button and its feedback as correct or incorrect.
