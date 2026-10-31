# Absorb: infer the owner of staged fixes

Use absorb for review fixes belonging to earlier commits. For a known single owner, use the amend or exact-fixup command in [branchless.md](branchless.md). A new feature belongs in a new commit.

## Preview, then apply

1. Stage only the intended paths or hunks: `git add -- <paths>` or `git add -p -- <paths>`. Inspect `git diff --cached` and existing `absorb.*` config.
2. Identify `<base>`, the excluded commit below the editable range; inspect `git log --oneline <base>..HEAD`. Use a real Git ref or SHA. An explicit base bypasses protection for commits reachable from other local branches, so confirm this range belongs to the requested rewrite.
3. Preview `git ab --dry-run --verbose --base <base>`; include `--and-rebase` when choosing immediate folding. On intentional detached HEAD, add `--force-detach` to preview and execution. Finish with each proposed owner checked against the requested range.
4. Choose one execution mode below, using the same base and matching flags as the preview.

| When | Command | Result |
|---|---|---|
| Inspect generated fixups before folding | `git ab --base <base>` | Append `fixup!` commits; originals are not yet rewritten. |
| Create and immediately fold the fixups | `GIT_SEQUENCE_EDITOR=: git ab --base <base> --and-rebase` | Generate fixups and autosquash without opening the todo editor. |
| Fold previously generated fixups | `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash <base>` | Accept the generated todo without opening an editor. |

Use the last row only after reviewing the fixup commits and autosquash scope. `git restack` is not an autosquash substitute. `git ab` is the personal alias for `git absorb`.

## Branchless integration and limits

- Detect detached HEAD with `git symbolic-ref --quiet HEAD` (exit 1) and inspect smartlog. `--force-detach` bypasses only that check; keep the bounded base and author checks.
- The default search limit is 10 commits. An explicit `--base` gives the intended range without a blanket `--no-limit`; merge and author boundaries can still prevent matching.
- `--whole-file` broadens ownership from edited lines to a file; use it only when that file-level ownership is intended. Keep `--force` and `--force-author` out of the default recipe.
- Plain absorb leaves unmatched hunks staged. After `--and-rebase` uses autostash, inspect both `git diff` and `git diff --cached` for residual changes.
- Check `git status` after folding even if absorb exits successfully: git-absorb 0.9.0 does not propagate the child rebase's failure status.
- After autosquash, inspect smartlog for descendants left on rewritten ancestors; use the targeted repair in [recovery.md](recovery.md) if needed.

Source: [git-absorb manual](https://github.com/tummychow/git-absorb/blob/master/Documentation/git-absorb.adoc). Use `git-absorb --help` for installed flags.
