---
name: cm
description: Group the entire working tree into logical Conventional Commits without pushing.
---

# Smart Commit

Read [Git Change Preservation Contract](../references/git-change-preservation.md) before staging.

## Workflow

1. Inspect `git status`, staged and unstaged diffs, untracked files, and the latest three commits in parallel. Complete inspection when every status entry has an understood intent.
2. Group files by one user-visible feature, fix, or task. Use functional dependency next and file type only when intent remains unclear. Complete grouping when every status entry belongs to exactly one group.
3. Stage one group by exact path, review the staged diff, and create its Conventional Commit. Repeat until every group is committed.
4. Verify `git status --short` is empty and report the created commit hashes and messages. Leave the remote unchanged.
