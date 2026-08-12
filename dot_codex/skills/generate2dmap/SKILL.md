---
name: generate2dmap
description: Generate production-ready 2D game maps and runtime map data. Use for tilemaps, layered RPG scenes, parallax stages, tactical grids, modular rooms, arenas, battle backgrounds, collision, scene hooks, previews, or engine-native level integration; route actor art to generate2dsprite.
---

# Generate 2D Map

Build the smallest complete map bundle for the target game. A playable map exposes gameplay geometry and runtime objects; a flat image is complete only when the user requests a background or concept image.

## Route the request

Choose one product-level `map_mode` before selecting implementation details:

- `tile_mode`: editable RPG, monster-taming, platformer, or editor-driven tile maps.
- `scene_mode`: a foundation plus separate props for top-down exploration, tower defense, or arena play.
- `side_scroll_mode`: parallax scenery plus separate platforms and objects.
- `grid_mode`: tactical, factory, build-grid, or terrain-cost maps.
- `room_chunk_mode`: reusable procedural rooms or connected chunks.
- `baked_scene_mode`: a fixed battle background, menu, visual-novel scene, or explicit concept image.

Then choose the lightest compatible `visual_model`, runtime object model, collision model, and engine/export target. Read [map strategies](references/map-strategies.md) when the genre, mode, or export route is ambiguous.

The route is resolved when the mode, camera or canvas size, perspective, editing needs, collision needs, and target format are explicit. Preserve project-native formats and coordinate conventions when they already exist.

## Plan the deliverables

For a playable map, define these outputs before generating art:

- foundation, tile, or named parallax layers;
- separate runtime props and interactive objects;
- collision, walkability, zones, exits, spawns, camera bounds, and other scene hooks;
- placement or engine-native scene data;
- a composed QA preview.

For `side_scroll_mode`, lock one `stage_canvas` first. Use the project viewport aspect ratio or `1536x864` when no project convention exists. Primary parallax layers and previews share its size, framing, horizon, and top-left anchor.

Route character, enemy, NPC, projectile, and animation assets to `$generate2dsprite`. Map data may still include their spawn markers and encounter zones.

## Generate visible art

Use built-in `image_gen` for new production art unless the user supplies assets or explicitly requests placeholders. Write creative prompts directly; scripts may crop, assemble, key, validate, preview, and emit metadata, but they do not invent final art.

For playable layered maps:

1. Generate a foundation-only base or scenery-only parallax layers.
2. Keep collidable, interactive, replaceable, reusable, animated, or independently sorted objects out of that foundation.
3. Make the saved foundation visible with `view_image` immediately before the next related generation.
4. Generate a sparse in-world reference mockup that preserves the visible framing and contains at most nine distinct runtime object candidates.
5. Keep labels, arrows, callouts, UI, and metadata overlays out of the mockup.

If generated foundation art contains runtime objects, regenerate a clean foundation or retain it only as concept art. A reference mockup is an intermediate checkpoint, not a playable deliverable.

Read the [layered map contract](references/layered-map-contract.md) before implementing a layered raster map.

Save each accepted creative prompt next to its asset as `<asset>.prompt.txt` or in a manifest field.

## Produce runtime objects

Inspect the visible foundation and reference mockup together. List each runtime object with its id, type, approximate position and size, render layer, collision role, and asset strategy.

- Batch only compact, similarly sized static props in square sheets.
- Generate wide, tall, identity-sensitive, animated, or collision-aligned objects individually, as strips, as tiles, or in purpose-built wide cells.
- Use `$generate2dsprite` for reusable transparent props when its pipeline fits.
- Keep placement, collision, triggers, camera bounds, exits, and spawns in structured data.

Read the [prop pack contract](references/prop-pack-contract.md) before generating or extracting a prop sheet. Use the included extraction and preview scripts only for their documented deterministic operations.

## Integrate and verify

Wire assets and metadata into the requested engine or project format. Then verify:

- every expected file exists and parses;
- dimensions, alpha, anchors, layer order, and coordinate spaces agree;
- playable routes, critical collision boundaries, exits, and trigger zones work;
- side-scroll parallax layers align to `stage_canvas` and have explicit scroll factors;
- room chunks connect at their declared sockets;
- the QA preview is composed from the actual runtime layers and objects.

Finish only when the requested map mode has art, gameplay data, engine integration when requested, prompt provenance for new art, and an inspected preview. Report any omitted deliverable with its blocking reason.
