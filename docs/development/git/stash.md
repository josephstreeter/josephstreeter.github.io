# Git Stash

`git stash` is a useful command that allows you to temporarily save changes in your working directory that are not yet ready to be committed. This is helpful if you need to quickly switch branches or work on something else without losing your current progress.

## Common Commands

- **Stash your changes:**

    ```bash
    git stash
    ```

- **List all stashes:**

    ```bash
    git stash list
    ```

- **Apply the most recent stash and keep it in the stash list:**

    ```bash
    git stash apply
    ```

- **Apply and remove the most recent stash:**

    ```bash
    git stash pop
    ```

- **Drop a specific stash:**

    ```bash
    git stash drop stash@{0}
    ```

- **Clear all stashes:**

    ```bash
    git stash clear
    ```

## Example Workflow

1. Make some changes to your files.
2. Run `git stash` to save your changes and revert your working directory to the last commit.
3. Switch to another branch or pull updates.
4. Run `git stash pop` to reapply your stashed changes.

## Notes

- Stashed changes are not committed and can be lost if not applied or saved elsewhere.
- You can stash untracked files with `git stash -u`.
