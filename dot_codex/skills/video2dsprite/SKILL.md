---
name: video2dsprite
description: "Grok Build only: turn a 2D character still into dense run, walk, idle, or other animation sprites through image-to-video, frame extraction, chroma cleanup, normalized sampling, strips, grids, and GIFs. Use only when Grok video tools are available and the user explicitly wants a video-sourced motion path."
---

# Video to 2D Sprite

Use this optional Grok Build pipeline when the user wants dense video-sourced motion. `$generate2dsprite` remains the production default for crisp grids, identity-critical characters, multi-action kits, FX, projectiles, and prop packs.

## Check the runtime

Confirm that the tool list contains Grok's `image_to_video` or `reference_to_video` capability before planning outputs.

- When the video tool exists, continue with this skill.
- When it is absent, explain that this pipeline requires Grok Build and offer `$generate2dsprite`.

The platform gate closes before any files are created. Code-drawn frames are outside this pipeline.

## Resolve the run

Infer the subject or source still, action, view, duration, sample counts, cell size, anchor, output slug, and working directory. Default to a six-second side-view run in place, `8,16,24,48` comparison exports, a `128` pixel cell, feet anchoring, and solid `#FF00FF` chroma.

Read [prompt rules](references/prompt-rules.md) before generation and [the processing pipeline](references/pipeline.md) before running scripts.

Tell the user once that this route trades crisper pixels and tighter identity for denser intermediate motion. Keep experimental outputs outside game code unless integration was requested.

## Stage the base still

Use an existing image or Grok's image generation/editing tools to produce one full-body, centered character with generous margin on a flat `#FF00FF` background. Match supplied identity and project style. Save the exact prompt in `prompt-used.txt`.

The base is ready when the subject, scale, costume, view, silhouette, and chroma background are unambiguous.

## Generate one locked shot

Animate the staged still with `image_to_video`:

- one continuous in-place action;
- a locked camera;
- a stable subject identity, costume, and palette;
- a flat magenta background for the complete shot;
- six seconds at `480p` unless the user requests another supported setting.

Save the returned video under `<out-dir>/video/`. A drifting camera, moving background, traveling subject, scene change, or major identity morph requires one tighter regeneration before processing.

## Extract and sample

Run the deterministic processor:

```bash
python "$CODEX_HOME/skills/video2dsprite/scripts/video2dsprite.py" process \
  --video <out-dir>/video/<name>-6s.mp4 \
  --out-dir <out-dir> \
  --name <name> \
  --frame-counts 8,16,24,48 \
  --cell-size 128 \
  --body-height 100 \
  --foot-y 118 \
  --anchor feet \
  --fps 0
```

The script uses ffmpeg for decoding, removes corner-connected magenta, normalizes scale and anchor, and exports frames, strips, grids, GIFs, and metadata. A missing ffmpeg binary is an environment blocker.

For engine use, visually isolate one coherent cycle and export the smallest frame count that preserves it; `12` to `16` frames often fits locomotion better than all decoded frames.

## Inspect and deliver

Compare the exported GIFs and frames for loop pops, chroma blocks or fringe, baseline hopping, subject translation, identity drift, and softness. A result that loses identity or cannot form a coherent cycle becomes motion reference only; use `$generate2dsprite` for the production sheet.

Finish when the selected set has a stable anchor, readable identity, clean transparent background, coherent loop, prompt provenance, and `pipeline-meta.json`. Report absolute paths for the source video, cleaned frames, chosen sprite set, strip or grid, GIF, and metadata. Modify game code only when the request includes integration.
