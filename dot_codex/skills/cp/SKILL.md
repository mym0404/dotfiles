---
name: cp
description: Group the entire working tree into logical commits and push the current branch.
---

# Smart Commit And Push

Read [Git Change Preservation Contract](../references/git-change-preservation.md) before staging.

## Workflow

1. Inspect `git status`, staged and unstaged diffs, untracked files, the current branch, its upstream, and the latest three commits in parallel. Complete inspection when every status entry and the push target are known.
2. Group files by one user-visible feature, fix, or task. Use functional dependency next and file type only when intent remains unclear. Complete grouping when every status entry belongs to exactly one group.
3. Stage one group by exact path, review the staged diff, and create its Conventional Commit. Repeat until every group is committed.
4. Push the current branch to its configured upstream. When no upstream exists, push it to `origin` with upstream tracking.
5. Verify `git status --short` is empty and the remote contains the final commit, then report the commit hashes and pushed branch.
