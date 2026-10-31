---
name: cm
description: Split all working-tree changes into logical commits and leave a clean Git status.
---

# Commit All Changes

Commit all changes in the current repository, including earlier tasks, on the current branch without pushing. Preserve file contents and existing history; obtain a clean status by committing, never by discarding, stashing, or hiding changes. Honor Git ignore rules.

1. **Inspect.** From the repository root, run `git status --short --untracked-files=all`, `git diff`, and `git diff --cached`; read every untracked file. Account for every changed hunk and file. If status is empty, report that there is nothing to commit.
2. **Group.** Assign every change to exactly one atomic commit: one independently reviewable purpose, with its required tests, documentation, and dependencies. Keep a single commit for a single purpose; order prerequisites first. Briefly state the groups and proceed autonomously.
3. **Commit.** Stage only the current group's changes, preserving changes assigned to other groups. Use partial staging when a file spans groups; `git commit --only` includes all working-tree changes in the named files, so use it only for whole-file groups. Review the full diff to be committed and check it with `git diff --cached --check`. Create a concise English Conventional Commit and verify its diff matches the group.
4. **Verify.** Rerun the unfiltered status command from the repository root. Inspect and commit any changes left by hooks through the same process. Finish only when status is empty, then report each commit hash and message and the clean status.

If a commit fails or a change cannot be committed safely, stop and report completed commits, every remaining path, and the blocker.
