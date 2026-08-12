---
name: comment
description: Add concise, accurate code comments within the user-requested scope.
---

# Comment

Treat comments as part of the abstraction and a test of the design, not decoration.

## Commenting Philosophy

- Let precise, intuitive, consistent names form the reader's first correct guess. Use comments to complete what names and types cannot express; clear code reduces comments but does not replace them.
- Make an abstraction usable without reading its implementation. Capture the high-level purpose and responsibility, parameter and return meaning, preconditions, errors, boundary behavior, invariants, units, ownership, lifetime, design rationale, external constraints, and nonlocal dependencies when they matter to the reader.
- Explain why an implementation exists rather than narrating visible control flow. Record code truth, not the user request or chat history.
- Treat a hard-to-pick name or a long, complicated explanation as evidence that the role or abstraction may be unclear. Keep code and names unchanged during a comment-only request; report the design concern instead of hiding it behind prose.
- Draft or update the contract comment before implementing a new or changed interface. For existing code, reconstruct the current contract from the implementation and its consumers before commenting.
- Keep each fact in one authoritative comment beside the code it governs. This lowers cognitive load, exposes otherwise hidden dependencies, and reduces duplication and drift.
- Write comments in English by default. Follow an explicit user instruction or repository rule when it requires another language.

## Workflow

1. **Discover.** Resolve the exact files, symbols, or lines requested. Read applicable ancestor `AGENTS.md` files, contribution or style guides, lint configuration, and nearby comment conventions. Inspect the target code and relevant callers, tests, and configuration until the scope, governing rules, and every fact needed for the comments are known.
2. **Comment.** Apply the philosophy only within the requested scope and use the repository's native documentation syntax. Add or revise comments that convey information unavailable from the code itself. Leave a target unchanged when no useful comment is warranted and record the reason. When a target is hard to describe, preserve its implementation and report the design concern. Complete this step when every requested target has a useful comment or an explicit reason for no change.
3. **Audit and loop.** Inspect the full diff and run all checks below. If any check fails, return to step 2, revise the comments, and repeat the entire audit.
   - **Duplication:** Each comment adds information not already conveyed by names, types, visible control flow, or nearby documentation.
   - **Drift:** Every claim matches the current implementation, callers, tests, and configuration; no claim relies on speculation or obsolete behavior.
   - **Scope:** Every changed line is a comment inside the requested scope; unrelated code, names, formatting, and existing comments remain intact.
   - **Syntax:** Run `git diff --check` in a Git worktree and the smallest repository-native check that parses or validates the changed comment form when one exists.
   Complete the audit only when every check passes.
4. **Report.** List the added, revised, and intentionally skipped comments with exact file locations. Include design concerns and the commands and results used for verification.
