# Resolving Merge Conflicts

When a merge conflict occurs, Git will mark the conflicted areas in the affected files. To resolve the conflict:

1. Edit each conflicted file to keep the code you want and remove the conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`).

2. Stage the updated files:

    ```bash
    git add <file>
    ```

3. Once all conflicts are resolved and staged, create a commit:

    ```bash
    git commit -m "Resolve merge conflict"
    ```

**Tip:**  
You can use `git status` at any time to see which files
