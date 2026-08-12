---
name: worktree-merge
description: Commit a worktree branch, merge the default branch into it, then merge it back without pushing.
---

# Worktree Merge

Read [Git Change Preservation Contract](../references/git-change-preservation.md) before staging.

## Workflow

1. Inspect `git status`, both diffs, the current branch, recent commits, and `git worktree list --porcelain` in parallel. Complete preflight when the current worktree, branch, default branch, and default-branch worktree are identified.
2. Attach a detached worktree to a descriptive, non-conflicting `feat/` branch. Stop with the missing evidence when the default branch or its worktree cannot be identified.
3. Confirm the default-branch worktree is clean. Commit every current-worktree change in logical Conventional Commit groups. Complete this phase when the current worktree is clean.
4. Fetch the latest remote state when needed, then merge the default branch into the current worktree branch.
5. From the default-branch worktree, merge the current worktree branch into the default branch.
6. Verify both worktrees are clean and the default branch contains the worktree branch tip. Report the created commits and merge result, leaving the remote unchanged.

## Merge Failure Contract

Preserve unresolved conflicts for the user. When a merge step fails, stop further mutation and report:

- the failing merge direction and command
- every conflicted file
- what each side changed
- the safe resolution strategy for each conflicted hunk
- the exact commands that resume the workflow after resolution

Keep conflict resolution and pushing outside this invocation unless the user explicitly adds them.
