---
name: humanizer
description: Rewrite English text to remove clustered AI-writing patterns while preserving meaning, structure, evidence, and the author's intended voice.
license: MIT
---

# Humanizer

## Workflow

1. Establish the preservation contract: facts, claims, citations, paragraph count, ordering, register, and any supplied author sample. Complete when every protected element is identifiable in the source.
2. Read [pattern-catalog.md](references/pattern-catalog.md) completely. Diagnose clusters of patterns rather than isolated words, then leave clean human choices intact.
3. Write a draft that covers everything the source covers, replaces AI-shaped phrasing with specific natural language, and matches the intended voice. Use a supplied author sample as the primary rhythm and diction reference.
4. Audit the draft by asking: `What still makes this sound obviously AI-generated?` Record only remaining concrete tells, then revise them.
5. Scan the final rewrite for invented evidence, changed certainty, missing paragraphs, voice drift, and any remaining em or en dash. Complete when every protected element survives, the final rewrite contains no em or en dashes, and no diagnosed pattern remains without a deliberate reason.

## Voice Contract

- Use neutral, plain prose for technical, legal, academic, encyclopedic, and reference text.
- Use personality, opinion, humor, asides, or first person only when the source genre and author voice support them.
- Match a supplied sample's sentence rhythm, vocabulary level, paragraph openings, punctuation, transitions, and recurring verbal habits.
- Preserve unusual concrete details, mixed feelings, authentic asides, and defensible editorial choices.

## Rewrite Contract

- Rewrite weak passages instead of deleting covered ideas.
- Preserve meaning, evidence, uncertainty, and causal claims.
- Keep the source's paragraph count and order unless the user requests restructuring.
- Replace vague authority with a named source only when that source exists in the input or verified evidence.
- Preserve the source or house punctuation style except for em and en dashes. Replace every em and en dash in the final rewrite with punctuation or sentence structure that fits the context.
- Return clean source text unchanged when no meaningful pattern cluster exists.

## Output

- For pasted text, return these sections in order: `Draft rewrite`, a brief `Still-AI audit`, and `Final rewrite`. Add a short change summary only when useful.
- Keep the audit concrete and limited to tells that remained after the draft.
- For an authorized file edit, write the final rewrite to the source file and report the changed path, the brief audit, and preservation checks.
