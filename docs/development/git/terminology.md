# Terminology

The following covers a number of terms commonly encountered when using Git and related services. The relationship of these terms is somewhat circular, so you may need to read them all and then revisit them to fully understand how they relate to each other.

- **Index (Staging Area)** – The area where changes are collected before being committed to the repository. You add files to the index with `git add`.
- **Working Tree** – The directory, including all its files and subdirectories, that make up a repository. The top level of a working tree can be identified by the existence of a `.git` directory.
- **Commit** – A snapshot of the working tree at a specific point in time. Each commit records the state of the project and references its parent commit(s), forming the history of the repository.
- **HEAD** – A symbolic reference to the currently checked-out branch or commit. If a branch is checked out, HEAD points to that branch. If a specific commit is checked out (detached HEAD), HEAD points directly to that commit.
- **Repository** – A collection of commits, branches, and tags, along with all the project’s history and configuration. The repository is typically stored in the `.git` directory.
- **Branch** – A movable pointer to a commit, representing an independent line of development. Branches allow for parallel work and experimentation.
- **Tag** – A named reference to a specific commit, often used to mark release points (e.g., v1.0). Tags can have their own descriptions and are not intended to move.
- **Master/Main** – The default branch that represents the main line of development for a repository. Traditionally called `master`, but many projects now use `main` or, less commonly, `trunk`.
- **Remote** – A version of your repository hosted on another server, typically used for collaboration (e.g., `origin`). Remotes allow you to share work and synchronize changes between repositories.
- **Origin** – The default name given to the main remote repository when you clone a project. It acts as a shorthand reference for push, pull, and fetch operations.
- **Clone** – A local copy of a remote repository, including all its history, branches, and tags, created with `git clone <url>`.
- **Fork** – A server-side copy of someone else's repository, usually on a platform like GitHub or GitLab, allowing you to propose changes without affecting the original project.
- **Merge** – The process of integrating changes from one branch into another. Merging preserves the history of both branches.
- **Rebase** – The process of moving or combining a sequence of commits to a new base commit, often used to maintain a linear project history. Rebasing rewrites commit history.
- **Pull** – Fetches changes from a remote repository and merges them into your current branch (`git pull` is equivalent to `git fetch` followed by `git merge`).
- **Push** – Sends your local commits to a remote repository (`git push`).
- **Stash** – Temporarily saves changes that are not yet ready to be committed, allowing you to work on something else and reapply the changes later (`git stash` and `git stash pop`).
- **Tracking Branch** – A local branch that is set to track a remote branch, making it easier to push and pull changes.
- **Detached HEAD** – A state where `HEAD` points directly to a commit instead of a branch. Changes made in this state are not associated with any branch.
- **Upstream/Downstream** – "Upstream" usually refers to the repository or branch your work is based on or tracking (often the main project or a remote branch). "Downstream" refers to your local or forked copy that receives changes from upstream.
- **Blame** – A command (`git blame`) that shows who last modified each line of a file, useful for tracking changes and understanding the history of a file.
