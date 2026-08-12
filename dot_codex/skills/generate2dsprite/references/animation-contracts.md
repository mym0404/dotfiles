# Animation And Sheet Contracts

Read this file before prompting any animated, directional, bundled, mixed-action, or engine-atlas sprite.

## Action Rules

### `idle`

Use:

- neutral stance
- subtle motion
- weight shift or aura pulse
- strongest idle accent before looping

Prefer:

- `2x2` for standard actors
- `3x3` for large creatures and showcase idles

### `cast`

A `2x3` cast is often the best default:

- readiness
- energy gather
- stronger gather
- release start
- release peak
- settle or hold

### `attack`

For a compact attack-only sheet, describe:

- wind-up
- strike
- follow-through
- recovery

For controllable heroes, main characters, and fixed-cell game sprites, write attack body prompts as body-only:

- no detached slash arc
- no wide weapon trail
- no muzzle flash
- no projectile
- no impact burst
- no detached dust cloud
- weapon remains close enough that the body bbox stays near idle/run size
- body height and feet/bottom anchor match the accepted idle/run sheet

If the attack needs a large slash arc, sword trail, muzzle flash, or hit spark, generate it as a separate `fx`, `projectile`, or `impact` sheet and layer it in the runtime.

### `hurt`

For a hurt-only sheet, describe:

- impact
- recoil
- stagger
- recovery

### `combat`

For a compact combined sheet:

- top-left: attack wind-up
- top-right: attack strike
- bottom-left: hurt impact
- bottom-right: hurt recovery

### `projectile`

Usually prefer `1x4` or `2x2`.

Describe:

- same projectile identity in all frames
- travel direction stays consistent
- shape changes are small and loopable
- glow or trail stays inside the frame

### `impact` / `explode`

Usually prefer `2x2`.

Describe:

- ignition or contact
- expansion
- peak burst
- fade or collapse

### `walk` / `run` / `hover`

State the travel behavior clearly:

- grounded stride
- hover bob
- crawl
- slither
- mechanical glide

## Sheet-Specific Rules

### Mixed-action atlas guardrail

Do not use a single raw generated sheet to pack unrelated actions just because the target engine wants a `4x4`, `5x5`, or custom atlas.

Avoid prompts like:

- row 1 idle, row 2 run, row 3 shoot, row 4 jump
- first row walk, second row attack, third row hurt, fourth row death
- one big atlas containing every hero action

For controllable heroes, main characters, and high-value player assets:

1. Generate each action as its own multi-row grid sheet, usually `2x2` for 4-frame actions, `2x3` for 6-frame actions, and `2x4`, `3x3`, `3x4`, or `4x4` for longer actions.
2. Keep attack/shoot/cast body animation separate from projectile, muzzle flash, slash arc, weapon trail, impact, and dust unless the runtime explicitly supports wider per-action cells plus explicit origins.
3. Process and visually QC each action independently for feet line, body center, scale, silhouette, and edge safety.
4. Reject a body action when the body appears more than about 10-15% smaller than idle/run because a wide FX bbox forced it to shrink.
5. Assemble a `4x4`, `5x5`, or custom engine atlas only after the separate action sheets pass QC.

Allowed raw multi-row sheets:

- canonical four-direction locomotion sheets where every row is the same walk/run action in a different direction
- one continuous non-directional long action sequence, read left-to-right across rows
- prop packs or tileset-like atlases where each cell is intentionally a separate object
- compact low-stakes enemy combat sheets, but not controllable hero production assets

### `4x4` player sheet

Use:

- row 1: down
- row 2: left
- row 3: right
- row 4: up
- column 1: neutral
- column 2: left foot forward
- column 3: neutral again
- column 4: right foot forward

Do not use a layout guide by default for this sheet. Try an unguided prompt first unless the previous result crossed cell edges or failed the grid shape.

### `3x3` large idle

Say:

- exactly 9 equal cells in a `3x3` grid
- same bounding box in all 9 cells
- subject fills only about 55% to 65% of each cell
- no edge crossing anywhere

Use a layout guide when a previous 3x3 result has uneven spacing, inconsistent scale, or edge-touching frames.

### `4x4` non-directional action sequence

Use for casting, summoning, charging, transformation, death, and other single-action loops:

- exactly 16 equal cells in a `4x4` grid
- read frames left-to-right across each row, then continue on the next row
- describe each phase in order, from anticipation through peak action to settle or loop return
- keep the subject identity stable while allowing pose, energy, and compact attached effects to change
- use a layout guide when the action includes VFX, portals, circles, summons, or other elements that might cross cell boundaries

Do not use this format as a shortcut for four unrelated hero actions. If the requested rows are different actions, treat it as a `hero_action_bundle` or `engine_atlas` delivery problem instead.

### `5x5` and custom grids

Use raw `5x5` or custom-grid generation only when the entire sheet is one coherent action family, a prop pack, a tileset-like atlas, or a single long sequence.

For mixed action requirements, generate each action separately and assemble the final grid after QC. The assembled atlas is a delivery artifact, not the raw image-generation target.

### `1x4` projectile

Say:

- exactly 4 equal cells in one row
- same projectile size in every frame
- only the internal energy or shape pulse changes

## Bundle Prompting

When generating a bundle, write each asset prompt independently.

Good default decomposition:

- caster unit
- projectile
- impact

or:

- idle
- combat
- walk

Do not try to force unrelated assets into one giant sheet.
