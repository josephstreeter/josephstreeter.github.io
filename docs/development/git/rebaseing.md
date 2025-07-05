# Rebase

Rebasing is a process in Git that allows you to move or combine a sequence of commits to a new base commit. It is often used to maintain a linear project history and to integrate changes from one branch onto another.

## Basic Rebase

To rebase your current branch onto another branch (e.g., `main`):

```bash
git rebase main
```

This will replay your commits on top of the latest commit in `main`.

## Interactive Rebase

Interactive rebase lets you edit, reorder, squash, or drop commits before applying them.

```bash
git rebase -i HEAD~3
```

This command opens an editor with the last 3 commits, allowing you to choose actions for each commit.

> [!WARNING]
> **Do NOT use interactive rebase on commits that have already been pushed to a remote repository** that others may have based work on, as this rewrites commit history.

## Rebasing onto Another Branch

To rebase your current branch onto another branch (e.g., `feature_branch`):

```bash
git rebase feature_branch
```

## Resolving Conflicts During Rebase

If you encounter conflicts during a rebase:

1. Edit the conflicted files to resolve the conflicts.
2. Stage the resolved files:

    ```bash
    git add <file>
    ```

3. Continue the rebase:

    ```bash
    git rebase --continue
    ```

4. If you want to abort the rebase:

    ```bash
    git rebase --abort
    ```

## References

- [Git Documentation: git-rebase](https://git-scm.com/docs/git-rebase)
