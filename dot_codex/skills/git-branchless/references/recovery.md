# Recovery: distinguish the state first

Inspect `git status` before choosing a recovery command. An unsuccessful in-memory move may leave no active rebase; `--continue` and `--abort` apply only to an actual on-disk rebase.

| When | Command | Completion check |
|---|---|---|
| Locate unresolved files | `git diff --name-only --diff-filter=U` | Every conflict file is identified. |
| Continue after resolving a rebase conflict | `git add -- <resolved-paths>` then `git rebase --continue` (`git rec`) | No unresolved paths; rebase finishes or reports the next conflict. |
| Edit remaining rebase steps | `git rebase --edit-todo` (`git ree`) | Pending steps match the intended commits and order. |
| Abandon the active rebase | `git rebase --abort` (`git rea`) | The rebase ends and the pre-rebase state is restored. |
| Repair children of a rewritten original commit | `git restack <original-commit>` | The intended descendants attach to its rewritten replacement. |
| Inspect and undo the latest branchless operation | `git undo` | The proposed undo matches the requested operation before confirmation. |
| Recover an earlier recorded state | `git undo -i` | Select the intended event; verify graph and worktree afterward. |

Use the concrete original commit for targeted restacking; bare `git restack` can repair all draft work. `git amend`, `git reword`, and `git move` normally restack automatically, so manual repair is conditional on the resulting graph.

`git undo` uses this clone's branchless event log; it does not recover operations from another clone or machine. Preserve unrelated working-tree and staged changes before any recovery that could replace them.

Sources: [restack](https://github.com/arxanas/git-branchless/wiki/Command:-git-restack), [undo](https://github.com/arxanas/git-branchless/wiki/Command:-git-undo), [Git rebase](https://git-scm.com/docs/git-rebase).
