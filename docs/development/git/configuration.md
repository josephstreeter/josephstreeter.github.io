# Configuration

Every time Git is used for the first time, two basic configurations must be set: your name and email address. This information is used to identify your actions in the repository.

```bash
git config --global user.name "First I Last"
git config --global user.email "first.last@gmail.com"
```

When creating a new repository from the CLI, you may see the following message:

```text
$ git init
hint: Using 'master' as the name for the initial branch. This default branch name
hint: is subject to change. To configure the initial branch name to use in all
hint: of your new repositories, which will suppress this warning, call:
hint: 
hint:   git config --global init.defaultBranch <name>
hint: 
hint: Names commonly chosen instead of 'master' are 'main', 'trunk' and
hint: 'development'. The just-created branch can be renamed via this command:
hint: 
hint:   git branch -m <name>
Initialized empty Git repository in /home/hades/Documents/repos/AzureTerraform/.git/
$ git config --global init.defaultBranch main
```

## Configuration Scopes

Git configuration can be set at different levels:

- **System:** Applies to every user and repository on the system (`/etc/gitconfig`)
- **Global:** Applies to all repositories for the current user (`~/.gitconfig`)
- **Local:** Applies only to the current repository (`.git/config`)

You can view your current configuration with:

```bash
git config --list --show-origin
```

## Conditional Configs

You can use conditional includes to apply different Git configurations based on the directory. This is useful for separating work and personal projects.

**Example: Add these lines to your `~/.gitconfig`:**

```ini
[includeIf "gitdir:~/projects/work/"]
    path = ~/projects/work/.gitconfig

[includeIf "gitdir:~/projects/personal/"]
    path = ~/projects/personal/.gitconfig
```

Below are the contents of the two config files specified above.

**Contents of `~/projects/work/.gitconfig`:**

```ini
[user]
    email = first.last@work.com
[commit]
    gpgsign = true
```

**Contents of `~/projects/personal/.gitconfig`:**

```ini
[user]
    email = first.last@gmail.com
[commit]
    gpgsign = false
```

## Other Useful Configuration Options

- **Set your default text editor:**

    ```bash
    git config --global core.editor "nano"
    ```

- **Enable colored output:**

    ```bash
    git config --global color.ui auto
    ```

- **Set up a useful alias:**

    ```bash
    git config --global alias.st status
    ```

## Editing Configuration Directly

You can edit your global config file directly with:

```bash
git config --global --edit
```

Or open the config file in your preferred editor:

```bash
vi ~/.gitconfig
```

## Viewing Effective Configuration

To see the effective configuration and where each value is set:

```bash
git config --list --show-origin
```

## References

- [Git Configuration Documentation](https://git-scm.com/docs/git-config)
