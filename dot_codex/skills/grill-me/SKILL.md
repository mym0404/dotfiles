---
name: grill-me
description: Relentlessly stress-test a plan, decision, idea, or proposed project change through a read-only interview before implementation. Use when the user asks to be grilled or deeply challenged.
---

# Grill Me

Investigate and question relentlessly while preserving files and external state. Treat implementation requests and approvals as future intent; implementation starts from a separate explicit request after this interview closes.

## Workflow

Repeat Frame -> Question -> Synthesize until the Closure Gate passes and the user confirms the shared understanding.

### Phase 1: Investigate

- Restate the goal in one short sentence.
- Inspect the relevant project structure, source-of-truth documents, constraints, entrypoints, current patterns, and likely affected surfaces.
- Build the decision tree of result-changing assumptions and decisions, ordered by dependency.
- Investigate discoverable facts instead of asking the user; reserve questions for their decisions.
- Complete this phase when known facts ground the largest unresolved decision and its dependencies.

### Phase 2: Frame and Question

- State the relevant facts, current decision, and consequences.
- Ask exactly one focused decision question, then wait for the answer.
- Provide a recommended answer and reason with every question. When choices help, present two to three distinct options and use `request_user_input` when its format fits.
- Complete this phase when the user confirms or reframes the current decision.

### Phase 3: Synthesize and Zoom Out

- Convert each answer into a confirmed decision or an open assumption.
- Update the decision tree and trace the answer through dependent branches.
- Return to Phase 2 with the next unresolved, result-changing decision.
- Complete this phase when the Closure Gate passes.

### Phase 4: Close

- Summarize the shared understanding, distinguishing confirmed decisions, open assumptions, and excluded work.
- Ask the user to confirm the summary and wait for the answer.
- After confirmation, close with the clarified recommendation or plan and name implementation as a separate task requiring a new explicit request.
- Complete this phase when the confirmation and future implementation boundary are explicit.

## Closure Gate

Closure passes only when every result-changing branch and each item below is confirmed or explicitly not applicable:

- intended outcome and decision criteria
- affected surfaces and source of truth
- scope boundaries and excluded work
- user-visible behavior
- constraints, risks, rollout, and reversibility
- verification expectations for future implementation
