# Subagent Review Pass

Use this reference after the context sufficiency gate passes and the first neutral context envelope is ready.

This file defines the lens menu, context envelope, reuse rules, and output contract for `agent-review`.

## How To Use

- Run subagents only after the context gate passes and the neutral envelope is complete.
- Do local work only to gather facts, choose lenses, and assemble the envelope.
- Spawn each lens with:
  - `fork_turns: "none"`
- Inherit the parent model and reasoning effort. Provide only the neutral envelope or rerun delta you want the lens to use; keep hidden thread history and unstated conclusions outside the payload.
- Fit every material prior decision and explicit exclusion into the envelope before spawning; otherwise stop at `REVIEW CONTEXT NEEDED`.
- Run the three required core lenses on the first full review:
  - `Review-Target Isolation`
  - `Outcome Contract Fit`
  - `Residual Change Risk`
- Add `Maintainability` only when the local facts show real structural risk or the reviewed surface is broad enough that long-term cost matters now.
- Add `Visual Checker` only when the reviewed result materially changes UI or user-visible output and a realistic local verification path exists.
- Add domain reviewers only when trusting the result depends on knowledge narrower than the core lenses.
- Add `Challenge Lens` only to compare two plausible, evidence-backed interpretations independently.
- Reuse existing lens agents whenever practical. Send delta reruns with `followup_task` instead of spawning replacements.
- Keep at most one in-flight agent per lens.
- If a required lens cannot start, times out without a usable response, or fails the shared output shape, retry once with the same or narrower neutral payload. If it still fails, stop at `SUBAGENT REVIEW BLOCKED`.
- If a response arrives with an older `Revision`, discard it as stale.
- Promote only findings that still appear actionable inside the current scope. Leave optional tightenings and out-of-scope work for `Rejected concerns` in the final synthesis.

## Revision Rules

Start the first full review at `Revision: 1`.

Increment the revision whenever one of these changes:

- review target surface
- contract source
- baseline or recheck boundary
- scope boundaries
- evidence set used for synthesis
- local smoke verification adds or rejects a material concern
- rerun focus changes which finding is being confirmed or rejected

Keep the current revision for polling that adds no material change.

## Lens Selection Rules

- `Maintainability` is worth adding when the reviewed surface spans shared ownership, introduces brittle abstractions, duplicates logic, or creates cleanup debt that clearly matters now.
- Add a domain specialist when trusting the result depends on narrower expertise than the core lenses.
- Common examples:
  - `Frontend` for user-visible interaction contracts
  - `Infra` for execution, readiness, cleanup, or environment behavior
  - `Security` for auth, permission, exposure, or secret handling
  - `Data` for schema, migration, persistence, or serialized contract behavior
  - `API` for request or response contract correctness and compatibility
- Other valid examples include `Platform`, `Mobile / React Native`, `Statistics / Experimentation`, `Algorithm / Math`, or another specialist that better fits the reviewed surface.
- Keep all three required core lenses when adding a specialist.
- Read [optional-lenses.md](optional-lenses.md) only after one of these optional triggers fires.

## Shared Context Envelope

Use this envelope for the first full review:

```text
Review target: <surface under review>
Repo root or artifact root: <path-or-N/A>
Revision: <review-revision>

Contract source:
<what defines the intended result>

Intended outcome:
<what this work meant to ship or prove>

Material prior decisions:
<accepted tradeoffs, already-made decisions, or `none`>

Explicit exclusions / non-goals:
<what should not be treated as missing scope, or `none`>

Baseline or recheck boundary:
<base sha, diff boundary, previous revision, or explicit as-is review anchor>

Original request or handoff summary:
<1-3 short paragraphs>

Available evidence:
<logs, screenshots, verification output, document evidence, or N/A>

Known facts:
<only the repo or artifact facts that matter for this lens>

Scope boundaries:
<in-scope and out-of-scope constraints>
```

Use this envelope for reruns:

```text
Review target: <surface under review>
Repo root or artifact root: <path-or-N/A>
Revision: <review-revision>

Changed focus:
<newly checked files, rerun command, or narrowed concern>

Previous finding:
<finding being confirmed or rejected>

Relevant prior decisions or exclusions:
<only what the rerun needs>

Known facts:
<only what the rerun needs>

Scope boundaries:
<only if the rerun depends on them>
```

## Output Shape

Every lens must return exactly:

```text
Revision: <review-revision>
Summary: <1-2 sentences>
Findings:
1. <finding or N/A>
2. <finding or N/A>
3. <finding or N/A>
Evidence:
- <path, diff fact, artifact fact, or verification fact>
- <optional>
Suggested Follow-up:
- <smallest useful next step>
- <optional>
Confidence: High | Medium | Low
```

Use the language of the review request or handoff packet.

## Required Lens Menu

### Review-Target Isolation

```text
You are the Review-Target Isolation reviewer for a finished agent work result. Your job is to decide whether the surface under review really matches the intended target and boundary.

Review only the target named in the provided context envelope.

Check only these things:
1. the named review target is coherent with the available revision and artifact evidence
2. later unrelated changes or artifacts are not being silently mixed into the review
3. the current boundary is precise enough that the next lenses can trust it
4. the report can name a real recheck boundary for the next consumer

Focus exclusively on isolating the right review target; implementation quality and future architecture belong to other lenses.

Return exactly the shared output shape.
```
### Outcome Contract Fit

```text
You are the Outcome Contract Fit reviewer for a finished agent work result. Your job is to decide whether the delivered result still fits the intended contract and outcome.

Review only the target named in the provided context envelope.

Check only these things:
1. the reviewed result fits the stated contract source and task intent
2. the available evidence and actual result still align
3. promised behavior, content, or deliverables were not silently skipped, substituted, or misinterpreted
4. the final externally visible result still matches what the work meant to ship

Keep findings inside the current contract and outcome; leave long-term architecture and speculative future work outside this lens.

Return exactly the shared output shape.
```

### Residual Change Risk

```text
You are the Residual Change Risk reviewer for a finished agent work result. Your job is to decide whether the current result leaves regression, rollout, coordination, or quality risk that the next consumer should know about.

Review only the target named in the provided context envelope.

Check only these things:
1. likely regression paths or partial landings
2. hidden coordination or shared-surface risks
3. risky assumptions that current evidence does not fully cover
4. failure modes that could surface soon after this result is accepted
5. whether the reviewed surface still leaves mixed-state risk across the relevant artifacts

Surface only near-term residual risk tied to the named result.

Return exactly the shared output shape.
```
