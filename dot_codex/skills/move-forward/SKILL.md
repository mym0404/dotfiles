---
name: move-forward
description: Investigate a project, lock one evidence-backed initiative, implement it autonomously, and verify the result.
---

# Move Forward

## 1. Reconnaissance

- Inspect applicable instructions, source, product or design documents, active plans or issues, recent change history, and repository-native verification entrypoints before choosing an initiative.
- Exercise the current product through its real interface when runnable; observe behavior instead of inferring it from code alone.
- Research current alternatives, substitutes, user pain, and ecosystem norms from primary or direct sources. For an internal or non-market project, compare analogous tools and current technical practice.
- For each opportunity retained for ranking, record its supporting project and external evidence. When research splits into independent evidence streams, delegate bounded streams and reconcile their evidence yourself.

Complete reconnaissance when recorded evidence covers current behavior, intended direction, constraints, verification surfaces, and compared alternatives, and the initiative ranking remains stable under each recorded uncertainty.

## 2. Lock One Initiative

- Rank retained opportunities by expected impact, evidence strength, strategic fit, cost, risk, and direct verifiability.
- Select one initiative that can reach a verified result in the current task. Lock its problem, why it matters now, intended user-visible outcome, scope, non-goals, constraints, and exact acceptance evidence.
- Falsify the choice with its strongest counterargument, best competing opportunity, and most fragile assumption. Resolve material doubt with evidence or return to reconnaissance.

Complete the lock after recording why the selected initiative ranks above each alternative on the stated factors and confirming that its acceptance evidence is observable end to end. Treat every other improvement as out of scope after the lock.

## 3. Plan

Complete the plan only after every locked outcome maps to the smallest implementation step that produces it and an observable check that proves it.

## 4. Execute

- Proceed autonomously with project-local, reversible changes within the locked scope and existing authorization. Resolve choices from evidence; when evidence does not distinguish them, select the reversible option with the smallest scope and data impact and record the assumption.
- Delegate only bounded subtasks within the locked initiative.
- Cross deployment, purchase, external communication, destructive data, credential, worktree, branch, commit, push, or pull-request boundaries only with the user's prior authorization for the exact action and target. When an unapproved boundary is required and no local substitute exists, stop with the exact blocker.

Move to verification after every planned implementation step is done and the diff is limited to those steps.

## 5. Verify

- Inspect the complete diff, run the smallest repository-native checks that cover the change, and exercise the changed behavior through its real interface when possible.
- Compare observed evidence with the locked acceptance evidence rather than treating command success as proof.

Complete verification when every locked outcome has its planned observed evidence, every planned check passes, and the diff review traces every changed line to the initiative. Report the initiative, its evidence-backed rationale, changed behavior, verification, assumptions, and remaining risk.

## Evidence-Driven Backtracking

At any stage, return to the earliest invalidated stage: implementation defects to Execute, missing or incorrect steps to Plan, a false value or scope premise to Lock, and missing project or market facts to Reconnaissance. Backtrack only for cited counterevidence or a named defect; before advancing again, record the evidence that resolves it.
