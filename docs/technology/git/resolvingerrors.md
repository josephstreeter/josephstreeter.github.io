# Resolving Errors

## Divergent Branch Error

A divergent branch error occurs when your local branch and the remote branch have both made unique commits that are not shared. This often happens if someone else has pushed changes to the remote branch after you created your local branch or after your last pull.

**Symptoms:**  

- You see messages like:  
  `fatal: The current branch feature has diverged from origin/feature.`  
  or  
  `error: failed to push some refs to ...`  
- `git status` or `git pull` warns about divergent branches.

**How to resolve:**

1. Switch to your feature branch:

    ```bash
    git switch <feature-branch>
    ```

2. Rebase your branch onto the latest main branch:

    ```bash
    git fetch origin
    git rebase origin/main
    ```

    > If your main branch is called `master`, use `origin/master` instead.

3. Resolve any conflicts that arise during the rebase:

    - Edit the conflicted files to resolve conflicts.
    - Stage the resolved files:

        ```bash
        git add <file>
        ```

    - Continue the rebase:

        ```bash
        git rebase --continue
        ```

    - If you want to abort the rebase:

        ```bash
        git rebase --abort
        ```

4. Once the rebase is complete, switch to the main branch and merge:

    ```bash
    git switch main
    git merge <feature-branch>
    ```

    > If main/master is protected, push your feature branch and create a Pull Request to merge the changes.

**Tip:**  
If you have already pushed your feature branch before rebasing, you may need to force-push after the rebase:

```bash
git push --force-with-lease
```

Use force-push with caution, especially if others are working on the same branch.
