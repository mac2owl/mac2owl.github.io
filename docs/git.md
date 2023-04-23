## Add remote repo

```
git remote add origin https://github.com/OWNER/REPOSITORY.git
```

## List existing remotes

```
git remote -v
```

## Change remote repo's URL

```
git remote set-url origin https://github.com/OWNER/REPOSITORY.git
```

## Rebse branch to another

```
git rebase origin/branch_name
```

## Squash, amend, reword commits with interactive rebase (`git rebase -i`)

### Reword commit message

For example, I want to reword one of the last 3 commits

```
git rebase -i HEAD~3
```

will output the following

```
pick c2a4d95 reword me please
pick 2a4e409 update SQL query to insert new employee records
pick 08c8836 Refactor and clean up employee class

# Rebase 8d8a4b3..08c8836 onto 8d8a4b3 (3 commands)
#
# Commands:
# p, pick <commit> = use commit
# r, reword <commit> = use commit, but edit the commit message
# e, edit <commit> = use commit, but stop for amending
# s, squash <commit> = use commit, but meld into previous commit
# f, fixup [-C | -c] <commit> = like "squash" but keep only the previous
#                    commit's log message, unless -C is used, in which case
#                    keep only this commit's message; -c is same as -C but
#                    opens the editor
# x, exec <command> = run command (the rest of the line) using shell
# b, break = stop here (continue rebase later with 'git rebase --continue')
# d, drop <commit> = remove commit
# l, label <label> = label current HEAD with a name
# t, reset <label> = reset HEAD to a label
# m, merge [-C <commit> | -c <commit>] <label> [# <oneline>]
#         create a merge commit using the original merge commit's
#         message (or the oneline, if no original merge commit was
#         specified); use -c <commit> to reword the commit message
# u, update-ref <ref> = track a placeholder for the <ref> to be updated
#                       to this position in the new commits. The <ref> is
#                       updated at the end of the rebase
#
# These lines can be re-ordered; they are executed from top to bottom.
#
# If you remove a line here THAT COMMIT WILL BE LOST.
#
# However, if you remove everything, the rebase will be aborted.
#
```

To reword commit message `c2a4d95`, we replace `pick` with `reword`/`r` for that commit, then save and exit

```
reword c2a4d95 reword me please
pick 2a4e409 update SQL query to insert new employee records
pick 08c8836 Refactor and clean up employee class
```

we can now amend the commit message on the next "screen" - update the message then save and exit again:

```
Update documentation

# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
...
```

It should output a message similar to the one below if rebased successfully:

```
[detached HEAD 7a8daf8] Update documentation
 Date: Sat Apr 22 10:01:48 2023 +0100
 1 file changed, 71 insertions(+)
 create mode 100644 docs/docker.md
Successfully rebased and updated refs/heads/rebase-test.
```

### Squash commits

Using the same example from `reword` above, we now want to squash the three commits into one and amend the first commit message again:

```
reword 7a8daf8 Update documentation
fixup 96dce5b update SQL query to insert new employee records
fixup 467b4cc Refactor and clean up employee class
```

Here we use `fixup`/`f` instead of `squash`/`s` as we are discarding all the other commit messages except the top one.

Again we should get `Successfully rebased and updated ...` if rebased successfully.
