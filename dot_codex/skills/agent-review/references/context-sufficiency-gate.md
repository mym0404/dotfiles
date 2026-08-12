# Context Sufficiency Gate

Apply this gate before substantive review work. Pass only when one finished-work signal and all four anchors are recoverable without guessing.

## Evidence authority

Use current thread instructions, a caller-provided handoff, stable repository or workspace artifacts, and local revision evidence. Archived fragments, opaque storage, reconstructed intent, and packets derived from partial or guessed context are insufficient authority.

## Finished-work signal

Require one of these:

- the user or producing agent marks the target finished and ready for review;
- a task or artifact state marks the relevant slice complete;
- verification evidence clearly belongs to a completed delivery.

A request to review unfinished work belongs to a different review contract.

## Four anchors

### 1. Review target

Name the exact surface: working tree, commit range, file or document set, bundle, output directory, or named artifact. Include the repository or artifact root when paths depend on it.

### 2. Contract source

Name what defines correctness: current requirements, a handoff, plan, checklist, brief, specification, or an explicit as-is quality-and-risk request.

For scoped work, recover the intended outcome, material accepted decisions, and exclusions that affect screening.

### 3. Comparison boundary

Name the baseline or recheck anchor: base SHA, commit range, previous artifact revision, before/after pointer, or explicit current-artifact-only review.

### 4. Evidence surface

Name the reliable artifacts available for judgment: changed files, document contents, logs, screenshots, notes, verification output, or bundle evidence.

## Narrow discovery

Before the gate passes, inspect only enough local state to identify the four anchors and whether evidence exists. When they remain unavailable, request a minimum handoff rather than expanding into open-ended logs, notes, history, or artifact sweeps.

A minimum handoff contains only missing fields from:

```text
repo_root or cwd
review_target
comparison_base
task_intent
acceptance_criteria
prior_decisions
non_goals
scope_in
scope_out
artifacts
```

## Completion and stop response

Pass when the finished signal and every anchor are explicit enough that all required lenses can judge from one neutral envelope.

Otherwise return:

```text
REVIEW CONTEXT NEEDED
- Missing: <anchor>
- Needed: <minimum fact or artifact>
```

Return only missing anchors and the minimum evidence needed to fill them. End the review at this response.
