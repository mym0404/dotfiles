# Review Loop

Use this rubric after the context gate passes and all required lens responses match the current revision.

## Scope Isolation

Name the exact review surface before judging substance. Valid surfaces include a working tree, commit range, file set, bundle, document set, or named artifact. Keep later unrelated changes outside that boundary and preserve a recheck anchor the next consumer can use.

Read evidence in this order unless the caller narrows it:

1. review brief or handoff packet
2. contract artifacts
3. verification evidence
4. revision signals such as git status, log, and diff when relevant
5. targeted artifact reads

Complete isolation when the artifacts being judged and the artifacts being excluded are both explicit.

## Review Rubric

Promote a concern only when it materially helps the next consumer and remains actionable inside the current scope.

- `Review-Target Isolation`: the reported surface matches the real revision and artifacts.
- `Outcome Contract Fit`: the delivered result satisfies the intended outcome, decisions, and exclusions.
- `Residual Change Risk`: regression, rollout, coordination, mixed-state, or quality risk remains after delivery.
- `Maintainability`: use only for avoidable structural weakness with current payoff.
- `Visual Checker`: use only for material user-visible output with a realistic verification path.
- `Domain Risk`: use a specialist only when core lenses cannot judge the relevant invariant.

Treat completed checks as evidence. Run one smaller check only when it can change the disposition of a high-value concern.

## Priority

- `P0`: the result cannot be trusted before this issue is fixed.
- `P1`: clear contract, regression, or quality risk warrants follow-up.
- `P2`: non-blocking concern remains inside current scope and is worth fixing now.

Reject concerns driven by taste, new scope, speculative redesign, repeated verification, missing contract context, or optional future tightening.

## Synthesis

For every candidate concern:

1. confirm it uses the current revision
2. confirm the evidence belongs to the named review surface
3. confirm it violates or risks the current contract
4. choose the smallest useful follow-up
5. assign `accept` or `screen first`

Complete synthesis when every promoted finding passes all five checks and every rejected concern has a short reason.
