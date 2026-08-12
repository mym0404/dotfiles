# Hatch Pet Worker Contracts

Read this file before delegating a hatch-pet subtask. Every worker receives one bounded scope, explicit readable inputs, allowed output, forbidden mutations, and a verification responsibility. Use `fork_turns="none"` for visual and blind-review workers and inherit the parent model and reasoning settings.

## Shared generation contract

Give each generation worker exactly one `imagegen-jobs.json` entry.

- Scope: generate `base`, one standard row, the cardinal strip, or one complete look row.
- Readable inputs: that job's prompt, retry prompt, input images with role labels, and the pet-specific look-mechanics file when applicable.
- Allowed mutation: built-in image generation output only.
- Parent-owned state: run manifest, decoded files, extracted frames, QA files, repair decisions, packaging, and cleanup.
- Expected response: `selected_source=<absolute path>` and `qa_note=<one sentence>` only.
- Verification: confirm frame count, one stable pet identity, flat chroma background, separated unclipped poses, and absence of guide marks, text, scenery, or unrelated objects.

The parent copies the selected output, runs deterministic checks, and marks the job complete.

## Brand discovery worker

- Scope: research one named brand for mascot-safe cues.
- Sources: official brand, product, documentation, about, press, and brand pages first; narrow reputable secondary sources only when needed.
- Output file: one parent-specified `brand-discovery.md`.
- Required handoff fields: `brand_name`, `brand_brief`, `avatar_seed`, `avoid`, and `brand_sources`.
- Verification: every factual brand cue is traceable to a listed source, and the brief contains no logo-copying instruction.

The worker may write only its brief and returns its absolute path plus the five handoff fields.

## Base worker

Generate one centered full-body pet from the prepared base prompt and listed references. Confirm readable silhouette, stable identity cues, the requested style, one flat chroma background, and enough cell-safe margin. Return only the shared two-line response.

## Standard-row worker

Generate one complete row strip from the canonical base, prepared row prompt, and matching layout guide. Preserve face, proportions, palette, materials, markings, props, lighting, and scale. Confirm the exact pose count and the requested state motion. Return only the shared two-line response.

## Cardinal and look-row workers

The cardinal worker generates the four poses together in `000`, `090`, `180`, `270` order and verifies screen-coordinate direction from visible facial or body landmarks.

Each look-row worker generates eight poses as one coherent family. It reads `qa/look-mechanics.md`, the canonical base, approved cardinal strip, and the prepared row prompt. Row 10 also receives completed row 9. The worker verifies ordered direction progression, stable anchor and scale, complete pose separation, and continuous pet-specific mechanics.

## Blind direction workers

Use three isolated workers. Each receives only the randomized unlabeled direction-pair sheet and its output path. It cannot receive degree labels, expected directions, the labeled sheet, answer key, prompts, or another verdict.

Each worker writes the schema requested by the sheet-generation workflow, classifying the designated axis of A and B as `screen-left`, `screen-right`, `up`, `down`, or `ambiguous`. The parent combines the three files by strict majority and applies the hidden answer key afterward.

## Final visual QA worker

Use one worker that did not generate the reviewed rows. Give it the standard and extended contact sheets, direction sheet, motion previews, deterministic validation, blind consensus, and continuity report.

- Scope: review identity, animation semantics, direction semantics, continuity, geometry, and packaging readiness.
- Mutation: none.
- Expected response: overall `pass` or `fail`, one verdict for every standard row and direction, evidence for each failure, and the smallest package-eligible repair scope.
- Verification: separate hard failures from subtle intermediate-direction warnings using the QA rubric.

The parent records accepted semantic verdicts and decides repairs. A user inspection may replace this worker when the user explicitly chooses to review the artifacts.
