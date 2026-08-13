---
name: knowledge
description: Maintain durable repository knowledge in the root AGENTS.md and automatically routed topic documents.
disable-model-invocation: true
---

# Knowledge

## Ownership

- Give each fact one owner. Root `AGENTS.md` owns facts by default and is the only router to topic documents; each topic document owns only the facts assigned by its root route.
- Write repository file routes as plain repository-relative paths such as `.agents/knowledge/design.md`. Keep labels and Markdown link syntax out of routes so a path has one textual source of truth.
- Synchronize an owner and its root route when ownership or paths change.
- Preserve user-created knowledge files and locations. Repair their routes in root; move a file only when the user explicitly requests the move.
- Keep repository facts in the repository and reusable maintenance rules in this global skill.
- Apply requests to the target repository. Edit this global skill only when the user explicitly requests a change to it; invoking or naming the skill alone leaves it unchanged.

## Retention Gate

Keep information that survives a behavior-preserving refactor:

- project purpose, stack, and stable runtime or verification entrypoints
- subsystem responsibilities and ownership boundaries
- cross-component contracts and durable invariants
- critical code anchors only when an incorrect change could bypass access control, lose data, miscalculate money, violate an external contract, break recovery, or violate a hard-to-find domain invariant

Keep implementation traces, progress, plans, inventories, selectors, fixtures, line numbers, and task-local examples in code or task artifacts.

## Steps

1. Resolve the repository root. Read root `AGENTS.md`, every routed topic document, and the authoritative repository sources for candidate facts. Discovery is complete when every candidate fact has an authoritative source.
2. Assign each retained fact to root by default. Reuse a matching topic document, or create one when a coherent topic would crowd root. Prefer `.agents/knowledge/design.md`, `.agents/knowledge/code-style.md`, and `.agents/knowledge/domain.md` when they match; otherwise use one short English kebab-case filename under `.agents/knowledge/`. Keep compact topics in root and leave no empty topic documents. Before reorganizing, inventory every retained fact and route. Routing is complete when each fact has one owner and each topic owner has one root route.
3. Write the smallest current-state update at responsibility and contract level. Update only owners, required root sections, and affected plain-path routes. Writing is complete when every retained fact appears once and every root route resolves to its owner.
4. Reread every changed document. Resolve every route and verify every changed behavior claim against its authoritative source. If a document names a wrapper command, inspect its underlying script and state its real coverage and blind spots. Verification is complete when every retained fact has one owner, every route resolves, and every changed line survives a behavior-preserving refactor.

## Root AGENTS.md Contract

Keep these compact current-state sections in the root `AGENTS.md`, creating any that are missing:

- `Project Purpose`: what the project does and who or what it serves.
- `Tech Stack`: the verified primary languages, frameworks, runtimes, data stores, and build or verification tools.
- `Project Tree`: a responsibility-oriented map of major directories and entrypoints, not an exhaustive file inventory.
- `Knowledge System`: the ownership contract and the plain repository-relative path of every topic document.

The `Knowledge System` section states that root is the default fact owner and only router, each fact has one owner, and each topic document owns the facts assigned by its route.

For Markdown-only edits, verify paths and diffs by rereading the files; browser validation adds no evidence.
