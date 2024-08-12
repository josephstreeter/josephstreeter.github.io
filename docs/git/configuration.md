# Configuration

Every time a git is used for the first time, two basic configurations must be set. Git must be told the name and the email address of the user that is using Git. This information will be used to identity a user's actions.

```bash
git config --global user.name First I Last
git config --global user.email first.last@gmail.com
```

When creating a new branch from the CLI, you may see the following message:

```bash
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
$ git config --global intit.defaultBranch main
```

## Conditional Configs

Separate config for git based on where the files are located.

```bash
# Configuration for "work" projects
[include “gitdir:~/projects/work/”]
path = ~/projects/work/.gitconfig
```

```bash
# Configuration for "personal" projects
[include “gitdir:~/projects/personal/”]
path = ~/projects/personal/.gitconfig
```

Below are the contents of the two config files specified above.

```bash
# Contents of "work" configuration file
cat ./work/.gitconfig
[user]
Email = first.last@work.com
[commit]
gpgsign = true

# Contents of "personal" configuration file
cat ./personal/.gitconfig
[user]
Email = first.last@gmail.com
[commit]
gpgsign = false
```
