---
name: knowledge
description: Maintain durable repository knowledge in the root AGENTS.md and explicitly routed topic documents.
---

# Knowledge

## Storage Contract

- Treat an owner as the only document that contains a fact.
- Use the current repository's root `AGENTS.md` as the default owner and only router to topic documents.
- Let each routed topic document own only the facts assigned by its root route.
- Synchronize knowledge by updating facts in their owners and root routes when ownership or paths change. Do not duplicate facts across documents.
- Create a topic document only when the user explicitly requests one. Reuse a matching document or create one short English kebab-case filename directly under `.agents/knowledge/`.
- Preserve user-created knowledge files and locations. Repair a broken route by updating the root link, and move a file only when the user explicitly requests that move.
- Keep repository facts in the repository and reusable maintenance rules in this global skill.
- Apply requests to the target repository. Edit this global skill only when the user explicitly requests a change to it; invoking or naming the skill alone leaves it unchanged.

## Knowledge Threshold

Keep information that survives a behavior-preserving refactor:

- project purpose, stack, and stable runtime or verification entrypoints
- subsystem responsibilities and ownership boundaries
- cross-component contracts and durable invariants
- critical code anchors only when an incorrect change could bypass access control, lose data, miscalculate money, violate an external contract, break recovery, or violate a hard-to-find domain invariant

Keep implementation traces, progress, plans, inventories, selectors, fixtures, line numbers, and task-local examples in code or task artifacts.

## Workflow

1. Resolve the repository root and read the root `AGENTS.md`, every routed topic document, and the authoritative repository sources for facts considered for retention. Complete discovery when every fact considered for retention has an authoritative source.
2. Assign one owner to each retained fact: root `AGENTS.md` by default, an existing routed document for its assigned topic, or a matching topic document when the user explicitly requests topic work. Before structural reorganization, inventory every retained fact and route. Complete planning when each retained fact has one owner and each topic owner has one root route.
3. Write the smallest current-state update at responsibility and contract level. For a bare invocation, synchronize root `AGENTS.md` and existing routed documents without creating a topic document. For an explicit topic request, reuse a matching document or create the requested topic document. Repair routes in root and preserve file locations unless the user explicitly requests a move. Complete writing when every planned fact appears only in its owner and every planned root route resolves to its topic owner.
4. Reread every changed document and verify each route, path, and high-value behavior claim against its authoritative source. When documentation names a wrapper command, inspect its underlying script and state the command's real coverage and blind spots. Complete verification when every retained fact has one owner, every root route resolves, and every changed line remains useful after a behavior-preserving refactor.

## Root AGENTS.md Contract

Keep one compact `Knowledge System` section that states:

- Root `AGENTS.md` owns durable repository facts by default and is the only router to topic documents; each routed topic document owns its assigned facts; each fact appears in one owner.

For Markdown-only edits, verify paths and diffs by rereading the files; browser validation adds no evidence.
