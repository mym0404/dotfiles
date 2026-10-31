# Branchless: choose the operation

Prefer branchless commands for stack edits in initialized repositories. Keep existing named-branch workflows; detached HEAD is useful for independent stacks, not a prerequisite for every operation.

| When | Command | Effect |
|---|---|---|
| Inspect the current stack | `git sl 'stack()'` (`git sls`) | Focus smartlog on the current stack and its context. |
| Inspect all visible local work | `git sl` | Show smartlog's default overview. |
| Move toward older / newer commits | `git prev <n>` / `git next <n>` | Follow parent / child links; a fork may require selection. |
| Choose a commit interactively | `git branchless switch -i` | Open the commit selector. |
| Start a new independent stack | `git record -d --untracked skip -m '<type>: <subject>'` | Detach and record a new commit. |
| Fix HEAD, owner already known | `git amend --untracked skip` | Amend HEAD and restack descendants. |
| Change one commit's message | `git reword <commit> -m '<message>'` | Rewrite that message and affected descendants. |
| Extract files into a separate commit | `git split <commit> <paths>...` | Split those files' changes into a following commit. |
| Move a commit and every descendant | `git move -s <source> -d <destination>` | Relocate the subtree. |
| Move only selected commits | `git move -x '<revset>' -d <destination>` | Extract those commits; reattach unselected children. |
| Fold a known fixup into its owner | `git move -x <fixup> -d <owner> --fixup` | Squash exactly that fixup into its destination. |
| Insert a subtree between destination and children | `git move -s <source> -d <destination> --insert` | Requires a single-headed moved subtree. |
| Preview a move | Add `--dry-run` to the chosen `git move` | Test the in-memory rebase without applying it. |
| Rebase the current stack onto local main | `git sync 'stack()'` (`git syncs`) | Sync this stack without fetching. |
| Fetch main, then sync this stack | `git sync --pull 'stack()'` | Fetch remote refs before rebasing. |

## Scope that changes behavior

- Before `record` or `amend`, stage the intended paths and require a nonempty, scoped `git diff --cached`. With no staged changes, these commands may include unstaged tracked changes.
- `git reword` without a target defaults broadly; name the commit. `git move` without `-s`, `-b`, or `-x` moves the current stack. `git sync` without a revset targets all draft stacks.
- `-b <commit>` moves the subtree containing that commit from its base on main; it is broader than `-s <commit>`. Choose `-x` for exact membership.
- Prefer the default in-memory rewrite. It does not run `post-commit` hooks; run the relevant checks explicitly. If conflicts require an on-disk rebase, use `--merge` and follow [recovery.md](recovery.md).
- Sync updates a stack's base; for descendants left behind by a rewrite, follow [recovery.md](recovery.md).

## Revsets

| Expression | Selects |
|---|---|
| `@` | HEAD |
| `stack()` | Current draft stack |
| `main()` | Configured main tip |
| `draft()` | All draft commits |
| `ancestors(x)` / `descendants(x)` | Ancestors / descendants of `x` |

Quote shell-sensitive revsets, for example `'stack()'`. Resolve them with `git query '<revset>'` when membership needs checking. Plain Git and absorb accept Git refs, not branchless revset syntax.

Source: [git-branchless command documentation](https://github.com/arxanas/git-branchless/wiki). For additional flags, consult `git-branchless <command> --help` on the installed version.
