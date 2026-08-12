# V2 Look-Direction Contract

Use this contract after rows `0-8` pass.

## Plan natural mechanics

Write `qa/look-mechanics.md` before generation. Define:

- the grounded anchor that stays registered;
- which feature leads the gaze;
- how eyes, eyelids, head, torso, flexible parts, and props follow;
- the visible pose family for up, screen-right, down, and screen-left;
- one consistent motion budget for each `22.5` degree step.

Use the pet's physical construction. Soft bodies may deform, separate heads may turn, ears or antennae may follow through, physical eyeballs rotate as complete eye surfaces, printed or screen faces may move drawn features, and attached props follow their real anchor. Humanoid pets preserve facial proportions and use restrained eye, eyelid, head, neck, and torso motion. Whole-sprite rotation fits only a pet that is literally intended to rotate as one rigid object.

## Establish direction anchors

Generate one coherent cardinal strip in this screen-coordinate order:

```text
000 up, 090 right, 180 down, 270 left
```

Extract and approve all four at normal pet size. The face, aiming feature, silhouette, or body mechanics must make each direction unmistakable without labels. Repair an ambiguous cardinal anchor before creating either final row.

## Generate the two coherent rows

```text
row 9:  000, 022.5, 045, 067.5, 090, 112.5, 135, 157.5
row 10: 180, 202.5, 225, 247.5, 270, 292.5, 315, 337.5
```

Generate row 9 from the canonical base and approved cardinals. Register its eight ordered pose groups with one shared scale, baseline, and lower-body anchor. Approve edge safety, semantic direction, and adjacent continuity before generating row 10.

Generate row 10 from the same references plus completed row 9. The `157.5 -> 180` and `337.5 -> 000` boundaries must continue the same clockwise family without a snap, reversal, identity change, scale pop, or prop detachment.

The final rows contain transparent cells with stable volume, baseline, silhouette, materials, face, markings, and props. Every pose differs visibly from neutral at normal display size.

## Decide failures

Regenerate the complete containing row when any of these hard failures is confirmed:

- a cardinal is wrong or ambiguous;
- labeled review confirms a wrong principal quadrant or loop reversal;
- adjacent poses show a conspicuous registration jump, scale pop, identity change, broken attachment, clipping, seam, or interior hole;
- the generated mechanics replace the pet's eyes or distort its defining anatomy;
- deterministic extraction, registration, chroma, or v2 validation fails.

Record a warning instead when an intermediate cue is subtle or blind reviewers disagree, provided labeled normal-size review confirms the intended axes and the ordered loop remains coherent. Every accepted override records the failed check, why it is minor, the labeled or continuity evidence, and the reviewer.

Final acceptance requires labeled verdicts for all sixteen directions, continuity metrics reviewed in motion context, and strict-majority blind results from three isolated workers. Cardinal blind mismatches remain hard failures.
