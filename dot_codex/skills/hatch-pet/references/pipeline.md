# Hatch Pet Execution Pipeline

Read this file immediately before executing a pet run. The parent agent runs every command, updates the manifest, and packages the result.

## Environment

Call `load_workspace_dependencies` and use the returned Python executable.

```bash
SKILL_DIR="${CODEX_HOME:-$HOME/.codex}/skills/hatch-pet"
PYTHON=<bundled-workspace-python>
RUN_DIR=/absolute/path/to/run
```

## 1. Prepare

Pass only the options needed to represent the request:

```bash
"$PYTHON" "$SKILL_DIR/scripts/prepare_pet_run.py" \
  --pet-name "<Name>" \
  --description "<one sentence>" \
  --reference /absolute/path/to/reference.png \
  --output-dir "$RUN_DIR" \
  --pet-notes "<stable identity description>" \
  --brand-discovery-file /absolute/path/to/brand-discovery.md \
  --brand-name "<brand>" \
  --brand-brief "<compact visual brief>" \
  --brand-source "https://example.com/source" \
  --style-preset auto \
  --style-notes "<optional style notes>"
```

For a text-only concept, pass `--pet-notes` and omit `--reference`. Inspect `pet_request.json` and `imagegen-jobs.json` before generation. A job is ready when all ids in `depends_on` are complete.

## 2. Record a selected visual job

Copy the worker-selected source to the manifest's `output_path`. For `base`, also copy it to `references/canonical-base.png`. Extract and inspect a standard row before marking its job complete. When the selected source is under `${CODEX_HOME:-$HOME/.codex}/generated_images`, remove that source and its empty generation directory after the decoded copy exists.

```bash
ROW_QA_DIR="$RUN_DIR/qa/rows/<job-id>"
"$PYTHON" "$SKILL_DIR/scripts/extract_strip_frames.py" \
  --decoded-dir "$RUN_DIR/decoded" \
  --output-dir "$ROW_QA_DIR/frames" \
  --states "<job-id>" \
  --method auto
"$PYTHON" "$SKILL_DIR/scripts/inspect_frames.py" \
  --frames-root "$ROW_QA_DIR/frames" \
  --json-out "$ROW_QA_DIR/review.json" \
  --states "<job-id>" \
  --require-components
```

Errors trigger row repair. Review warnings against the source strip. When component extraction alone causes visible motion popping and the source slots are stable, retry extraction with `--method stable-slots` and inspection with `--allow-stable-slots`.

Use the prepared `retry_prompt_file` once for a transport-level `Bad Request`. Preserve the same identity reference, frame count, state, and chroma key.

Derive a safe left-facing row with:

```bash
"$PYTHON" "$SKILL_DIR/scripts/derive_running_left_from_running_right.py" \
  --run-dir "$RUN_DIR" \
  --confirm-appropriate-mirror \
  --decision-note "<why identity and handed details remain correct>"
```

## 3. Build the standard intermediate

```bash
"$PYTHON" "$SKILL_DIR/scripts/extract_strip_frames.py" \
  --decoded-dir "$RUN_DIR/decoded" \
  --output-dir "$RUN_DIR/frames" \
  --states all \
  --method auto
"$PYTHON" "$SKILL_DIR/scripts/inspect_frames.py" \
  --frames-root "$RUN_DIR/frames" \
  --json-out "$RUN_DIR/qa/review.json" \
  --require-components
"$PYTHON" "$SKILL_DIR/scripts/compose_atlas.py" \
  --frames-root "$RUN_DIR/frames" \
  --output "$RUN_DIR/final/spritesheet.png" \
  --webp-output "$RUN_DIR/final/spritesheet.webp"
"$PYTHON" "$SKILL_DIR/scripts/make_contact_sheet.py" \
  "$RUN_DIR/final/spritesheet.webp" \
  --output "$RUN_DIR/qa/contact-sheet.png"
"$PYTHON" "$SKILL_DIR/scripts/render_animation_previews.py" \
  --frames-root "$RUN_DIR/frames" \
  --output-dir "$RUN_DIR/qa/previews"
```

Inspect the contact sheet and every row preview. Identity drift, wrong facing, broken cadence, clipping, or an effectively static loop triggers repair.

## 4. Approve cardinals and row 9

```bash
CHROMA_KEY=$(jq -r '.chroma_key.hex' "$RUN_DIR/pet_request.json")
"$PYTHON" "$SKILL_DIR/scripts/extract_cardinal_anchors.py" \
  --strip "$RUN_DIR/decoded/look-cardinals.png" \
  --output-dir "$RUN_DIR/decoded/look-anchors" \
  --chroma-key "$CHROMA_KEY" \
  --json-out "$RUN_DIR/qa/cardinal-anchors.json"
"$PYTHON" "$SKILL_DIR/scripts/compose_cardinal_anchor_strip.py" \
  --anchors-dir "$RUN_DIR/decoded/look-anchors" \
  --output "$RUN_DIR/decoded/look-anchors-approved.png"
```

After semantic approval, generate row 9 and register it with the final assembly transform:

```bash
"$PYTHON" "$SKILL_DIR/scripts/assemble_extended_atlas.py" \
  --base-atlas "$RUN_DIR/final/spritesheet.webp" \
  --look-row-9 "$RUN_DIR/decoded/look-row-9.png" \
  --neutral-cell "$RUN_DIR/frames/idle/00.png" \
  --chroma-key "$CHROMA_KEY" \
  --chroma-threshold 96 \
  --registered-row-output "$RUN_DIR/qa/look-row-9-registered.png" \
  --registration-manifest-output "$RUN_DIR/qa/look-row-9-registration.json"
```

Approve its eight ordered cells before generating row 10.

## 5. Assemble, clean, and validate v2

```bash
"$PYTHON" "$SKILL_DIR/scripts/assemble_extended_atlas.py" \
  --base-atlas "$RUN_DIR/final/spritesheet.webp" \
  --registered-row-9 "$RUN_DIR/qa/look-row-9-registered.png" \
  --row-9-registration "$RUN_DIR/qa/look-row-9-registration.json" \
  --look-row-10 "$RUN_DIR/decoded/look-row-10.png" \
  --neutral-cell "$RUN_DIR/frames/idle/00.png" \
  --chroma-key "$CHROMA_KEY" \
  --chroma-threshold 96 \
  --output "$RUN_DIR/final/spritesheet-extended.png" \
  --webp-output "$RUN_DIR/final/spritesheet-extended.webp" \
  --manifest-output "$RUN_DIR/final/spritesheet-extended.json"
"$PYTHON" "$SKILL_DIR/scripts/despill_chroma_edges.py" \
  "$RUN_DIR/final/spritesheet-extended.png" \
  --output "$RUN_DIR/final/spritesheet-extended.png" \
  --webp-output "$RUN_DIR/final/spritesheet-extended.webp" \
  --chroma-key "$CHROMA_KEY" \
  --json-out "$RUN_DIR/qa/chroma-despill-extended.json"
"$PYTHON" "$SKILL_DIR/scripts/validate_atlas.py" \
  "$RUN_DIR/final/spritesheet-extended.webp" \
  --json-out "$RUN_DIR/final/validation-extended.json" \
  --chroma-key "$CHROMA_KEY" \
  --require-v2
```

The despill report and v2 validation are authoritative for chroma acceptance. A failure here is a deterministic pipeline blocker, not an image-generation retry.

## 6. Produce direction evidence

```bash
"$PYTHON" "$SKILL_DIR/scripts/make_contact_sheet.py" \
  "$RUN_DIR/final/spritesheet-extended.webp" \
  --output "$RUN_DIR/qa/contact-sheet-extended.png"
"$PYTHON" "$SKILL_DIR/scripts/make_direction_qa_sheet.py" \
  "$RUN_DIR/final/spritesheet-extended.webp" \
  --output "$RUN_DIR/qa/look-directions.png"
"$PYTHON" "$SKILL_DIR/scripts/make_direction_blind_qa_sheet.py" \
  "$RUN_DIR/final/spritesheet-extended.webp" \
  --output "$RUN_DIR/qa/direction-blind-pairs.png" \
  --answer-key "$RUN_DIR/qa/direction-blind-answer-key.json"
"$PYTHON" "$SKILL_DIR/scripts/measure_direction_continuity.py" \
  "$RUN_DIR/final/spritesheet-extended.webp" \
  --json-out "$RUN_DIR/qa/look-continuity.json"
```

Collect three isolated blind verdict files, combine them, then apply the hidden answer key:

```bash
"$PYTHON" "$SKILL_DIR/scripts/combine_direction_blind_verdicts.py" \
  --verdicts "$RUN_DIR/qa/direction-blind-verdicts-1.json" \
  --verdicts "$RUN_DIR/qa/direction-blind-verdicts-2.json" \
  --verdicts "$RUN_DIR/qa/direction-blind-verdicts-3.json" \
  --json-out "$RUN_DIR/qa/direction-blind-verdicts.json"
"$PYTHON" "$SKILL_DIR/scripts/validate_direction_blind_verdicts.py" \
  --answer-key "$RUN_DIR/qa/direction-blind-answer-key.json" \
  --verdicts "$RUN_DIR/qa/direction-blind-verdicts.json" \
  --json-out "$RUN_DIR/qa/direction-blind-validation.json"
```

Write `qa/direction-semantics.json` from an independent final visual review or explicit user inspection. It must contain all sixteen expected degrees with `verdict`, `expected`, `observed`, and `reason`; packaging allows `pass` and reviewed `warning` entries but no `fail` entry.

When blind or final visual QA returns a failure, classify it against the look-direction contract before regenerating. Only an intermediate-direction uncertainty with passing labeled normal-size and loop-continuity evidence may be accepted as minor. Record that decision, the failed checks, supporting evidence, and reviewer in `qa/blind-review-resolution.json`. Cardinal ambiguity, wrong quadrants, reversal, clipping, identity drift, broken attachments, registration jumps, and deterministic failures are never overridable.

## 7. Package

After every deterministic and visual gate passes, install `final/spritesheet-extended.webp` as `spritesheet.webp` and write the manifest shape from the v2 package contract. Then write `qa/run-summary.json` with paths to the installed package and all retained validation artifacts.

Keep the request, accepted v2 atlas, validation, despill report, contact sheets, direction semantics, blind evidence, accepted resolution when used, continuity report, motion previews, review, and run summary. Remove prompts, layout guides, generated row strips, extracted frames, PNG intermediates, the `8x9` atlas, and the job manifest unless the user requests debug artifacts.

## Convergence Contract

- Treat thirty minutes as a planning target, never as permission to skip a gate.
- Classify every failure as visual semantics, identity, source geometry, component connectivity, extraction, chroma, continuity, or final QA.
- Use deterministic correction for deterministic failures before regenerating art, and preserve every property that already passed.
- When the same root failure recurs twice or a repair merely moves the defect, change strategy instead of varying the same prompt again.
- Continue until the pet passes, the user cancels, or a genuine external blocker prevents further progress.
