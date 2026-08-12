---
name: agent-review
description: Review one finished agent-produced result against its contract and return one screened read-only Markdown report.
---

# Agent Review

Review the named artifact surface without editing it. Use independent lenses for judgments and local work for neutral fact gathering, narrow verification, screening, and synthesis.

## Workflow

1. Read [context-sufficiency-gate.md](references/context-sufficiency-gate.md) and apply every required anchor. Complete the gate only when the finished-work signal, review target, contract source, comparison boundary, and evidence surface are recoverable without guessing. Otherwise return `REVIEW CONTEXT NEEDED` with only the missing anchors and minimum requested evidence.
2. Build one neutral context envelope containing the exact target, repository or artifact root, revision, contract source, intended outcome, material prior decisions, exclusions, baseline, available evidence, known facts, and scope boundaries. Complete the envelope when every required lens can judge from it without hidden thread context.
3. Read [subagent-review-pass.md](references/subagent-review-pass.md). Run the three core lenses with isolated context:
   - `Review-Target Isolation`
   - `Outcome Contract Fit`
   - `Residual Change Risk`

Read [optional-lenses.md](references/optional-lenses.md) only when the actual surface triggers an optional lens. Complete the pass when every required lens returns the shared output shape for the current revision. Retry one malformed or failed required lens with a narrower neutral payload; a second failure returns `SUBAGENT REVIEW BLOCKED` with the blocked lens and smallest retry context.

4. Read [review-loop.md](references/review-loop.md). Reconcile current-revision lens findings with artifact evidence and the current contract. Run at most one narrow local smoke check when it can confirm or reject a high-value concern. Complete reconciliation when each candidate finding is tied to current evidence or rejected with a reason.
5. Screen out stale, duplicate, taste-only, speculative, optional, and out-of-scope concerns. Complete screening when every surviving finding is actionable inside the current contract and supported by named evidence.
6. Read [report-template.md](references/report-template.md) and return exactly one Markdown report in its section order. Complete the review when the report names the target and contract boundary, orders findings by priority, records rejected concerns, and tells the next consumer to verify each finding before acting.

## Review Boundary

- Preserve reviewed source files, documents, prompts, specs, and input artifacts.
- Trust completed verification unless artifact reality supplies contradictory evidence.
- Keep optional improvements and scope expansion out of `Priority Findings`.
- Discard lens responses from an older revision.
- Keep the final output to one report or one stop response.
