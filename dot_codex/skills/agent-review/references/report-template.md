# Report Template

Use this exact section order for the final `agent-review` output.

This template is for successful reviews only.
If the skill stops at `REVIEW CONTEXT NEEDED` or `SUBAGENT REVIEW BLOCKED`, return that stop response instead of this template.

## Template

```md
# Agent Review Report: <short title>

## Summary

<2-4 sentences on overall confidence, what appears complete, whether follow-up is needed, the exact review target surface, the contract source used for the review, the intended outcome, any material prior decisions or explicit exclusions that changed screening, the baseline or recheck boundary, and the context source that made the review possible.>

## Priority Findings

<Only include findings that still appear actionable inside the current scope. Put optional tightenings, future work, and other out-of-scope concerns under `Rejected concerns` instead.>

### 1. `<P0|P1|P2> - <short title>`
- `Priority`: <P0|P1|P2>
- `Why it matters`: <short explanation>
- `Evidence`: <artifact fact, diff fact, verification fact, or file reference>
- `Recommended action`: <smallest useful next step>
- `Disposition`: accept | screen first

### 2. `<next finding>`

If there are no findings, write:

`None.`

## Accepted / Rejected Notes

- `Accepted concerns`: <which candidate concerns survived screening, or `none`>
- `Rejected concerns`: <what was screened out from `Priority Findings`, including stale, duplicate, weak, or out-of-scope concerns, or `none`>

## Handoff Note

Treat this review as screened candidates. Verify each finding against the current contract source, evidence, and exact target surface named in `Summary`; retain findings that still hold, apply accepted follow-up inside the current scope, and rerun the smallest fitting verification after each change. If the surface moved again, isolate the reported boundary from later unrelated changes before deciding a finding is stale. Hand a surviving out-of-scope finding to its owner before widening.
```

## Guidance

- Order findings by priority first, then by user impact.
- Keep the level-3 finding headings and number them consecutively in the same priority-ordered list.
- Keep each finding compact and evidence-backed.
- Use `screen first` only for findings that still appear to fit the current scope but need local confirmation before acting.
- If a lens suggested a concern that you screened out, mention it under `Rejected concerns` instead of creating a low-value finding.
- Return only the sections in this template.
