---
name: generate2dsprite
description: Generate and postprocess 2D game sprites. Use for characters, creatures, animation sheets, transparent props, projectiles, impacts, spells, FX, chroma cleanup, frame extraction, GIFs, or engine atlases; source raw art from built-in image generation.
---

# Generate 2D Sprite

Create the smallest complete sprite bundle that matches the target game. Raw production art comes from built-in `image_gen`; local scripts handle only layout guides and deterministic postprocessing.

## Resolve the asset plan

Infer the asset type, action, view, frame count, sheet shape, bundle, anchor, style, reference, and output name from the request and project. Ask only when a missing choice would change the visible result or runtime contract.

Read [asset and sheet modes](references/modes.md) when more than one plan fits. The plan is resolved when every requested action maps to a raw sheet or static asset and the delivery format is explicit.

Use these routing rules:

- Generate one coherent action family per raw sheet.
- Use a multi-row grid for animated bodies: `2x2` for four frames, `2x3` for six, and a compact larger grid for longer actions.
- Keep a canonical four-direction locomotion sheet together when the project expects it.
- Generate hero actions separately, inspect each, then assemble any mixed engine atlas deterministically.
- Keep wide slash arcs, muzzle flashes, projectiles, impacts, long trails, and detached dust separate from fixed-cell hero body sheets.
- Batch only compact, similarly sized props in square sheets; use individual images, strips, tiles, or wide cells for large or collision-aligned objects.

## Prepare the prompt and references

Read [prompt rules](references/prompt-rules.md) before every generation. Read [animation and sheet contracts](references/animation-contracts.md) before an animated, directional, bundled, mixed-action, or engine-atlas asset. Write the creative prompt directly and save it as `prompt-used.txt`.

When a visual reference matters:

1. Make the exact image visible in conversation context; use `view_image` for a local file.
2. State which identity, palette, silhouette, material, or style traits remain fixed.
3. State which pose, action, evolution, or effect may change.

Use a deterministic layout guide only when slot geometry needs reinforcement. Generate it with `scripts/make_layout_guide.py`, display it, and identify it as a layout-only reference. The output art must omit guide marks.

Every raw sheet uses a solid `#FF00FF` background, the exact requested grid, stable identity and scale, generous cell margins, and fully contained subjects. Match project or map style before selecting a generic pixel-art style.

## Generate and process

Call built-in `image_gen` for every raw image. Preserve the original generated image and process a working copy with:

```bash
python "$CODEX_HOME/skills/generate2dsprite/scripts/generate2dsprite.py" process \
  --input <raw-sheet.png> \
  --target <asset|creature|npc|player> \
  --mode <mode> \
  --rows <rows> \
  --cols <cols> \
  --output-dir <asset-output-dir> \
  --prompt-file <prompt-used.txt> \
  --align <center|bottom|feet> \
  --shared-scale \
  --reject-edge-touch
```

Choose only flags supported by `process --help`. Use `component-mode=largest` for body-only hero sheets and `component-mode=all` for intentionally detached FX, projectile, or impact elements.

## Inspect and iterate

Inspect the transparent sheet, individual frames, GIF, and `pipeline-meta.json` together. Regenerate or reprocess when:

- a subject or effect touches a cell edge;
- identity, scale, anchor, or frame order drifts;
- chroma-key fringe remains visible;
- a fixed-cell hero body is materially smaller than accepted idle or run frames;
- the animation no longer reads as one coherent sequence.

Processing may clean pixels and alignment, but it cannot repair a wrong pose, identity, composition, or source layout. Regenerate those failures.

## Deliver

Return the raw source, cleaned source, transparent sheet or static asset, extracted frames, GIF when animated, prompt file, and pipeline metadata. Bundles keep one folder per asset or action. Add a combined engine atlas only after its source sheets pass inspection.

Finish when every requested asset exists, matches the visual reference or project style, passes containment and scale checks, and is usable in the requested runtime format. Report any missing asset with the exact generation or processing blocker.
