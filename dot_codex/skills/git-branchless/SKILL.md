---
name: git-branchless
description: "Git-branchless and git-absorb workflows. Use for smartlog, commit-stack edits or sync, absorbing staged fixes into earlier commits, and branchless recovery."
---

# Git Branchless + Absorb

Use branchless for stack structure; use absorb to infer which earlier commits own staged fixes.
This skill supplies commands, not authorization to commit, rewrite, initialize, or publish.

## Workflow

1. Inspect `git status --short`, `git diff`, and `git diff --cached`; identify the target commits and unrelated work. Check installed tool versions when choosing version-sensitive flags. Before branchless operations, confirm `branchless/` exists under `git rev-parse --git-common-dir`; otherwise use plain Git or absorb, and initialize only when requested. Finish with the target range and staged scope known.
2. Read only the matching reference below. Choose explicit commit IDs or quoted revsets rather than relying on broad command defaults. Finish with the command's affected commits and side effects known.
3. Execute within the requested scope. Verify the resulting graph, status, and diff; run affected project checks when code changed. Finish only when the requested history change is visible, conflicts are resolved, unrelated work is preserved, and any remaining staged changes are accounted for.

| Task | Read |
|---|---|
| View or navigate commits; record, amend, reword, move, squash, split, or sync a stack | [references/branchless.md](references/branchless.md) |
| Distribute staged review fixes; preview ownership; fold generated fixups | [references/absorb.md](references/absorb.md) |
| Continue or abort a rebase; repair abandoned descendants; undo an operation | [references/recovery.md](references/recovery.md) |
