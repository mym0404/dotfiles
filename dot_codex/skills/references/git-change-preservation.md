# Git Change Preservation Contract

Apply this contract to the entire current working tree:

- Account for every tracked and untracked entry in `git status`, including non-ignored dotfiles such as `.env` files.
- Preserve file contents and history. Limit mutations to staging, committing, branch attachment when the invoking skill requires it, and pushing or merging only when that skill explicitly includes those actions.
- Keep destructive worktree and history commands outside the workflow: `git reset`, `git restore`, `git stash`, `git checkout --`, `git clean`, rebases, and equivalent manual rewrites.
- Use concise English Conventional Commit messages without agent attribution unless the user supplied a message.
- Finish only when `git status --short` is empty or an exact blocking path and reason have been reported.
