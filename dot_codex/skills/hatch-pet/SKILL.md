---
name: hatch-pet
description: Create or repair Codex v2 animated pets. Use for concept-, reference-, atlas-, or brand-based mascots that need nine standard animation rows, sixteen look directions, deterministic QA, and spriteVersionNumber 2 packaging.
---

# Hatch Pet

Produce a validated Codex v2 pet package, not only character art. Every new pet ends as an `8x11` transparent atlas with `192x208` cells, a `1536x2288` final size, and `spriteVersionNumber: 2`.

Read the [v2 package contract](references/codex-pet-contract.md) before starting. Read the [animation row table](references/animation-rows.md) when planning or reviewing rows.

## Resolve the source of truth

Accept a concept, brand or company name, reference images, generated character art, an existing `8x9` standard atlas, or an existing `8x11` v2 atlas.

- Infer a short friendly name and one-sentence description when the user omits them.
- Treat every image that defines identity, palette, materials, markings, props, or look mechanics as a grounding input.
- Use a validated `8x9` atlas as the rows `0-8` intermediate and add the v2 look rows.
- Preserve approved rows from an existing `8x11` atlas and repair only the smallest package-eligible row scope.

When the input is only a brand, product, company, or prospect name, delegate one narrow discovery pass before generation. Prefer official sources and capture only palette, motifs, personality, domain cues, an avatar seed, exclusions, and source URLs. Brand cues inspire the mascot; logos, readable marks, slogans, and interface screenshots stay out of the pet art.

The source is resolved when the pet name, description, stable identity cues, style, references, and chroma key are explicit.

## Prepare the run

Load the bundled workspace dependencies and use their Python executable. Run `scripts/prepare_pet_run.py` to create the run folder, prompts, layout guides, request data, and `imagegen-jobs.json`.

Read the [execution pipeline](references/pipeline.md) before running scripts. Use only documented script flags and keep the prepared manifest as the job graph.

Show this compact progress sequence during a full run:

1. Getting `<Pet>` ready.
2. Imagining `<Pet>`'s main look.
3. Picturing `<Pet>`'s poses.
4. Hatching `<Pet>`.

## Generate the standard rows

Use isolated visual workers for image-heavy jobs. Read the [worker contracts](references/worker-contracts.md) before delegation. Keep at most three independent generation workers active, and let the parent own manifests, copies, scripts, repair decisions, packaging, and cleanup.

Follow the prepared dependencies:

1. Generate the canonical base with `$imagegen`.
2. Generate and inspect `idle` and `running-right` as the identity and gait gates.
3. Generate the remaining standard rows from the canonical base and their prepared prompts.
4. Derive `running-left` with the mirror script only after confirming that handed props, markings, lighting, and direction semantics remain valid; otherwise generate the row.
5. Extract and inspect every standard row immediately, then mark that job complete.

Each visual job uses every input listed in its manifest entry. A worker may retry one transport-level `Bad Request` with the prepared retry prompt; a second transport failure blocks that job. Keep raw image payloads inside isolated workers: the parent uses worker QA, deterministic row checks, and checkpoint contact sheets instead of opening every generated PNG.

Compose the intermediate `8x9` atlas only after all nine rows pass deterministic extraction and visual motion review. This atlas is QA input and never the packaged pet.

## Generate the look directions

After standard-row approval, write `qa/look-mechanics.md` and follow the [look-direction contract](references/look-direction-contract.md).

1. Generate one four-cardinal strip in `000`, `090`, `180`, `270` order.
2. Extract and approve all cardinals at final display size.
3. Generate row 9 as one coherent eight-pose family from the approved cardinals.
4. Register and inspect row 9 before unlocking row 10.
5. Generate row 10 from the approved cardinals and completed row 9.
6. Assemble the full v2 atlas and run labeled, continuity, and blind direction QA.

Direction rows remain coherent row generations. A failed look cell triggers repair of its complete containing row; final packaging never mixes a one-off generated repair cell into a newly generated row.

## Validate and package

Run the complete [QA rubric](references/qa-rubric.md) before installation. The gate includes:

- deterministic frame and atlas validation;
- standard-row contact sheet and motion previews;
- cardinal approval and all sixteen labeled semantic verdicts;
- continuity measurement across the complete clockwise loop;
- three isolated blind classifications of the horizontal and vertical direction pairs;
- `qa/direction-semantics.json` with `verdict`, `expected`, `observed`, and `reason` for all sixteen directions;
- one final visual review independent from the generation workers;
- one final chroma-despill pass followed by `validate_atlas.py --require-v2`.

Cardinal ambiguity, wrong-quadrant poses, visible loop reversal, identity drift, clipping, broken attachments, deterministic failure, or a conspicuous registration jump blocks packaging. A subtle intermediate cue may remain a documented warning only when labeled normal-size review and loop continuity confirm the intended direction. Record any accepted minor blind or final-QA failure in `qa/blind-review-resolution.json`; never override a cardinal, structural, identity, or visible continuity failure.

Install the accepted files under `${CODEX_HOME:-$HOME/.codex}/pets/<pet-id>/` as `pet.json` and `spritesheet.webp`. Keep the final atlas, validation, contact sheets, motion previews, direction evidence, repair resolutions, and run summary in the run folder.

## Repair and finish

Repair the smallest package-eligible scope:

- one complete standard row for a standard animation defect;
- one cardinal anchor before look-row generation;
- one complete coherent look row for a final direction defect;
- deterministic reassembly for registration, chroma, or packaging defects.

After each repair, rerun every downstream check affected by that scope. Finish only when the installed package exists, the manifest declares v2, the final atlas has the required geometry, deterministic validation passes, visual QA has no unresolved hard failure, and `qa/run-summary.json` points to the retained evidence.
