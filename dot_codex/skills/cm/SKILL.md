---
name: cm
description: Commit only the latest completed task from the current conversation.
---

# Commit Recent Work

Use the current conversation as the scope. Take the fast path: scoped Git inspection, one commit, and no push.

1. Identify the exact repository paths changed for the latest completed task. Scope is complete when every target path belongs wholly to that task. If a path also contains older or unrelated changes, report the path and stop.
2. Run `git status --short -- <paths>` and `git diff -- <paths>`. Include `git diff --cached -- <paths>` for already staged targets. Review is complete when the changes are non-empty and every hunk matches the task.
3. Run `git add -- <paths>`, review `git diff --cached -- <paths>`, and run `git diff --cached --check -- <paths>`. Create one concise English Conventional Commit with `git commit --only -m "<message>" -- <paths>`.
4. Verify the commit paths with `git diff-tree --no-commit-id --name-only -r HEAD` and confirm `git status --short -- <paths>` is empty. Report the commit hash and message. Leave unrelated changes and the remote untouched.
