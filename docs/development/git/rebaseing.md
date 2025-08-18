# Git Rebasing Guide

Git rebasing is a powerful feature that allows you to move or combine a sequence of commits to a new base commit. It's a fundamental tool for maintaining clean, linear project history and integrating changes between branches effectively. This comprehensive guide covers rebasing concepts, techniques, and best practices for professional Git workflows.

## Understanding Git Rebase

### What is Rebasing?

Rebasing is the process of moving or combining a sequence of commits to a new base commit¹. Unlike merging, which creates a new commit that combines two branch histories, rebasing replays your commits on top of another branch, creating a linear history.

### Rebase vs. Merge

Understanding when to use rebase versus merge is crucial for effective Git workflow management²:

#### Merge Characteristics

- **Preserves context**: Shows when feature branches were integrated
- **Creates merge commits**: Additional commits that combine branches
- **Non-destructive**: Original branch history remains intact
- **Safe for shared branches**: Doesn't rewrite existing commit history

#### Rebase Characteristics

- **Creates linear history**: Results in a straight line of commits
- **Rewrites history**: Changes commit hashes and timestamps
- **Cleaner history**: Eliminates unnecessary merge commits
- **Dangerous for shared branches**: Can cause conflicts for collaborators

### The Golden Rule of Rebasing

**Never rebase commits that exist outside your repository and that people may have based work on³**. This is the most important rule to remember when using rebase.

## Basic Rebase Operations

### Simple Rebase

To rebase your current branch onto another branch (e.g., `main`):

```bash
# Switch to your feature branch
git checkout feature-branch

# Rebase onto main
git rebase main

# Alternative: specify both branches explicitly
git rebase main feature-branch
```

This replays your commits on top of the latest commit in `main`, creating a linear history.

### Rebasing Process Visualization

```text
Before rebase:
    A---B---C topic
   /
  D---E---F---G main

After rebase (git rebase main topic):
              A'--B'--C' topic
             /
  D---E---F---G main
```

### Checking Rebase Status

```bash
# Check if a rebase is in progress
git status

# View commits that will be rebased
git log --oneline HEAD..main

# See the rebase plan
git rebase --show-current-patch
```

## Interactive Rebase

Interactive rebase is one of Git's most powerful features, allowing you to edit, reorder, squash, or drop commits before applying them⁴.

### Starting Interactive Rebase

```bash
# Rebase last 3 commits interactively
git rebase -i HEAD~3

# Rebase all commits since main branch
git rebase -i main

# Rebase from a specific commit
git rebase -i abc1234

# Rebase with root option to include initial commit
git rebase -i --root
```

### Interactive Rebase Commands

When you start an interactive rebase, Git opens your editor with a list of commits and available actions:

```text
pick f7f3f6d Changed my name a bit
pick 310154e Updated README formatting and added blame
pick a5f4a0d Added cat-file

# Rebase 710f0f8..a5f4a0d onto 710f0f8 (3 commands)
#
# Commands:
# p, pick <commit> = use commit
# r, reword <commit> = use commit, but edit the commit message  
# e, edit <commit> = use commit, but stop for amending
# s, squash <commit> = use commit, but meld into previous commit
# f, fixup <commit> = like "squash", but discard this commit's log message
# x, exec <command> = run command (the rest of the line) using shell
# b, break = stop here (continue rebase later with 'git rebase --continue')
# d, drop <commit> = remove commit
# l, label <label> = label current HEAD with a name
# t, reset <label> = reset HEAD to a label
# m, merge [-C <commit> | -c <commit>] <label> [# <oneline>]
#   create a merge commit using the original merge commit's message
```

### Common Interactive Rebase Actions

#### Squashing Commits

```bash
# Example: Squash last 3 commits into one
git rebase -i HEAD~3

# In the editor, change:
pick f7f3f6d First commit
pick 310154e Second commit  
pick a5f4a0d Third commit

# To:
pick f7f3f6d First commit
squash 310154e Second commit
squash a5f4a0d Third commit
```

#### Reordering Commits

```bash
# Reorder commits by changing the order in the editor
pick a5f4a0d Third commit    # This will be applied first
pick f7f3f6d First commit    # This will be applied second
pick 310154e Second commit   # This will be applied third
```

#### Editing Commits

```bash
# Mark commit for editing
edit f7f3f6d Changed my name a bit
pick 310154e Updated README formatting
pick a5f4a0d Added cat-file

# When rebase stops at the commit:
# Make your changes
git add .
git commit --amend
git rebase --continue
```

#### Dropping Commits

```bash
# Remove commits by deleting lines or using 'drop'
pick f7f3f6d Keep this commit
drop 310154e Remove this commit  
pick a5f4a0d Keep this commit
```

## Advanced Rebase Techniques

### Rebase onto Specific Commits

```bash
# Rebase onto a specific commit hash
git rebase abc1234

# Rebase onto a tag
git rebase v1.2.0

# Rebase onto a commit relative to HEAD
git rebase HEAD~5
```

### Rebase with Preserve Merges

```bash
# Preserve merge commits during rebase (deprecated in Git 2.18)
git rebase -p main

# Modern alternative: use --rebase-merges
git rebase --rebase-merges main

# Interactive rebase with merge preservation
git rebase -i --rebase-merges main
```

### Rebase with Strategy Options

```bash
# Use specific merge strategy during rebase
git rebase -X ours main           # Prefer current branch changes
git rebase -X theirs main         # Prefer main branch changes
git rebase -X patience main       # Use patience diff algorithm

# Use different merge strategy
git rebase -s recursive -X ours main
git rebase -s ort main            # Use ORT merge strategy (Git 2.33+)
```

### Rebase with Exec Commands

```bash
# Run tests after each commit during rebase
git rebase -i --exec "npm test" HEAD~5

# Run multiple commands
git rebase -i --exec "npm test && npm run lint" main

# Example in interactive rebase editor:
pick f7f3f6d First commit
exec npm test
pick 310154e Second commit  
exec npm test && npm run lint
```

## Conflict Resolution During Rebase

### Understanding Rebase Conflicts

Conflicts occur when Git cannot automatically merge changes. During rebase, you may encounter conflicts when⁵:

- Two branches modified the same lines in a file
- One branch deleted a file that another branch modified
- Binary files were changed differently in both branches

### Resolving Conflicts Step by Step

#### 1. Identify Conflicted Files

```bash
# Check status during rebase
git status

# View conflicted files
git diff --name-only --diff-filter=U

# See conflict markers in files
git diff
```

#### 2. Resolve Conflicts

```bash
# Open conflicted files and look for conflict markers:
Current branch content

# Edit files to resolve conflicts, removing markers
# Choose to keep current changes, incoming changes, or combine both
```

#### 3. Stage Resolved Files

```bash
# Add resolved files
git add <resolved-file>

# Add all resolved files
git add .

# Verify no conflicts remain
git status
```

#### 4. Continue or Abort Rebase

```bash
# Continue rebase after resolving conflicts
git rebase --continue

# Skip current commit (use with caution)
git rebase --skip

# Abort rebase and return to original state
git rebase --abort

# View current patch being applied
git rebase --show-current-patch
```

### Advanced Conflict Resolution

#### Using Merge Tools

```bash
# Configure merge tool
git config --global merge.tool vimdiff
git config --global merge.tool "code --wait"

# Launch merge tool for conflicts
git mergetool

# Launch specific merge tool
git mergetool --tool=vimdiff
```

#### Resolving Conflicts with Git Attributes

Create a `.gitattributes` file to specify merge strategies:

```gitattributes
# Use ours strategy for specific files
config.xml merge=ours

# Use union merge for changelog files
CHANGELOG.md merge=union

# Treat binary files properly
*.jpg binary
*.png binary
```

## Rebase Best Practices

### When to Use Rebase

#### Appropriate Use Cases

1. **Cleaning up local commits** before pushing to remote
2. **Updating feature branches** with latest main branch changes
3. **Creating linear history** for better readability
4. **Preparing commits for review** by squashing related changes

```bash
# Good: Clean up local feature branch before pushing
git checkout feature-branch
git rebase -i HEAD~5    # Clean up last 5 commits
git push origin feature-branch

# Good: Update feature branch with latest main
git checkout feature-branch
git fetch origin
git rebase origin/main
```

#### When NOT to Use Rebase

1. **Public/shared branches**: Don't rebase commits others are working on
2. **Main/master branches**: Keep merge commits for context
3. **Release branches**: Preserve exact history for debugging
4. **When merge context matters**: Some workflows require merge commits

### Rebase Safety Guidelines

#### Pre-Rebase Checklist

```bash
# 1. Ensure working directory is clean
git status

# 2. Create backup branch
git branch backup-feature-branch

# 3. Fetch latest changes
git fetch origin

# 4. Check what will be rebased
git log --oneline HEAD..origin/main
```

#### Post-Rebase Verification

```bash
# 1. Verify commit history looks correct
git log --oneline -10

# 2. Run tests to ensure functionality
npm test  # or your test command

# 3. Check diff against original branch
git diff backup-feature-branch

# 4. Force push if needed (be careful!)
git push --force-with-lease origin feature-branch
```

### Team Collaboration with Rebase

#### Establishing Team Policies

1. **Define rebase boundaries**: Which branches allow rebasing
2. **Communication protocols**: Notify team before force-pushing
3. **Code review integration**: Rebase before creating pull requests
4. **Merge strategies**: When to rebase vs. merge

#### Safe Force-Push Practices

```bash
# Use --force-with-lease instead of --force
git push --force-with-lease origin feature-branch

# Check remote state before force-push
git fetch origin
git log --oneline origin/feature-branch..feature-branch

# Alternative: delete and recreate branch
git push origin :feature-branch
git push origin feature-branch
```

## Rebase Workflows and Patterns

### Feature Branch Workflow

```bash
# 1. Create feature branch
git checkout -b feature/user-authentication
git push -u origin feature/user-authentication

# 2. Work on feature with multiple commits
git add .
git commit -m "Add login form"
git add .  
git commit -m "Add validation logic"
git add .
git commit -m "Fix validation bug"

# 3. Clean up commits before review
git rebase -i HEAD~3    # Squash related commits

# 4. Update with latest main
git fetch origin
git rebase origin/main

# 5. Push cleaned branch
git push --force-with-lease origin feature/user-authentication
```

### GitFlow with Rebase

```bash
# Update develop branch
git checkout develop
git pull origin develop

# Rebase feature onto updated develop
git checkout feature/new-feature
git rebase develop

# Interactive cleanup
git rebase -i develop

# Merge back to develop (no-ff to preserve branch context)
git checkout develop
git merge --no-ff feature/new-feature
```

### Release Branch Preparation

```bash
# Create release branch from develop
git checkout -b release/v1.2.0 develop

# Clean up commits for release
git rebase -i develop

# Fix any release-specific issues
git add .
git commit -m "Update version number"

# Merge to main
git checkout main
git merge --no-ff release/v1.2.0

# Tag release
git tag -a v1.2.0 -m "Release version 1.2.0"
```

## Troubleshooting Rebase Issues

### Common Rebase Problems

#### Empty Commits After Rebase

```bash
# Skip empty commits during rebase
git rebase --skip

# Allow empty commits
git rebase --keep-empty

# Remove empty commits during interactive rebase
git rebase -i HEAD~5    # Delete lines for empty commits
```

#### Lost Commits After Rebase

```bash
# Find lost commits using reflog
git reflog

# Recover lost commits
git checkout -b recovery-branch abc1234

# Reset to previous state
git reset --hard HEAD@{5}    # Use reflog reference
```

#### Rebase Conflicts on Binary Files

```bash
# Accept current version
git checkout --ours binary-file.jpg
git add binary-file.jpg

# Accept incoming version
git checkout --theirs binary-file.jpg  
git add binary-file.jpg

# Continue rebase
git rebase --continue
```

#### Detached HEAD After Rebase

```bash
# Create branch from detached HEAD
git checkout -b recovered-branch

# Or reset existing branch to current HEAD
git branch -f feature-branch HEAD
git checkout feature-branch
```

### Recovery Strategies

#### Using Git Reflog

```bash
# View reflog to find lost commits
git reflog

# Detailed reflog with timestamps
git reflog --date=iso

# Reflog for specific branch
git reflog feature-branch

# Reset to previous state
git reset --hard HEAD@{2}
```

#### Creating Recovery Points

```bash
# Create backup before risky operations
git branch backup-$(date +%Y%m%d-%H%M%S)

# Use stash as backup
git stash push -m "Before rebase backup"

# Tag current state
git tag backup-before-rebase
```

## Rebase Configuration and Customization

### Global Rebase Configuration

```bash
# Configure default rebase behavior
git config --global rebase.autosquash true
git config --global rebase.autostash true  
git config --global rebase.updateRefs true

# Set pull to rebase by default
git config --global pull.rebase true

# Configure merge conflict style
git config --global merge.conflictstyle diff3
```

### Rebase-Specific Configurations

```bash
# Configure rebase editor
git config --global sequence.editor "code --wait"

# Enable abbreviate commands in interactive rebase
git config --global rebase.abbreviateCommands true

# Automatically move fixup commits
git config --global rebase.autosquash true
```

### Custom Rebase Scripts

Create shell functions for common rebase operations:

```bash
# Add to ~/.bashrc or ~/.zshrc
function git-cleanup() {
    git rebase -i HEAD~"${1:-5}"
}

function git-sync() {
    local branch=${1:-main}
    git fetch origin
    git rebase "origin/$branch"
}

function git-squash() {
    local count=${1:-2}
    git reset --soft HEAD~"$count"
    git commit
}
```

## Performance and Optimization

### Large Repository Considerations

```bash
# Use partial clone for large repositories
git clone --filter=blob:limit=1m <url>

# Optimize rebase performance
git config --global rebase.useBuiltin true
git config --global core.preloadindex true

# Use sparse checkout during rebase
git config core.sparseCheckout true
```

### Rebase Performance Tips

1. **Limit scope**: Rebase only necessary commits
2. **Use --onto**: Specify exact range for rebasing
3. **Avoid unnecessary rebases**: Don't rebase if linear history isn't needed
4. **Use shallow clones**: For CI/CD pipelines

```bash
# Efficient targeted rebase
git rebase --onto main~3 main~1 feature-branch

# Shallow clone for rebasing
git clone --depth=50 <url>
```

---

## Footnotes and References

¹ **Git Rebase Fundamentals**: Chacon, S., & Straub, B. (2014). *Pro Git - Git Branching - Rebasing*. Available at: [Git Rebase Documentation](https://git-scm.com/book/en/v2/Git-Branching-Rebasing)

² **Merge vs. Rebase Comparison**: Atlassian. (2024). *Merging vs. Rebasing*. Available at: [Merging vs Rebasing Guide](https://www.atlassian.com/git/tutorials/merging-vs-rebasing)

³ **The Golden Rule of Rebasing**: Chacon, S., & Straub, B. (2014). *Pro Git - The Perils of Rebasing*. Available at: [Rebasing Perils](https://git-scm.com/book/en/v2/Git-Branching-Rebasing#_rebase_peril)

⁴ **Interactive Rebase**: Git Documentation Team. (2024). *git-rebase Manual - Interactive Mode*. Available at: [Interactive Rebase Documentation](https://git-scm.com/docs/git-rebase#_interactive_mode)

⁵ **Conflict Resolution**: GitHub, Inc. (2024). *Resolving a merge conflict using the command line*. Available at: [GitHub Conflict Resolution](https://docs.github.com/en/github/collaborating-with-pull-requests/addressing-merge-conflicts/resolving-a-merge-conflict-using-the-command-line)

## Additional Resources

### Official Documentation

- [Git Rebase Manual](https://git-scm.com/docs/git-rebase)
- [Pro Git Book - Rebasing Chapter](https://git-scm.com/book/en/v2/Git-Branching-Rebasing)
- [Git Reference - Rebase](https://git-scm.com/docs/gitrevisions)
- [Git Workflows Documentation](https://git-scm.com/book/en/v2/Distributed-Git-Distributed-Workflows)

### Platform-Specific Guides

- [GitHub Rebase and Merge](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges)
- [GitLab Rebase Documentation](https://docs.gitlab.com/ee/topics/git/git_rebase.html)
- [Atlassian Rebase Tutorials](https://www.atlassian.com/git/tutorials/rewriting-history/git-rebase)
- [Azure DevOps Git Rebase](https://docs.microsoft.com/en-us/azure/devops/repos/git/rebase)

### Advanced Topics and Tools

- [Git Interactive Rebase Tool (GIT)](https://github.com/MitMaro/git-interactive-rebase-tool)
- [Rebase Workflow Patterns](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)
- [Git Hooks for Rebase Safety](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)
- [Conflict Resolution Tools](https://git-scm.com/docs/git-mergetool)

### Community Resources

- [Stack Overflow Git Rebase Questions](https://stackoverflow.com/questions/tagged/git-rebase)
- [Git Rebase Best Practices](https://www.atlassian.com/git/tutorials/merging-vs-rebasing)
- [Interactive Learning: Learn Git Branching](https://learngitbranching.js.org/)
- [Git Rebase Cheat Sheet](https://www.atlassian.com/git/tutorials/atlassian-git-cheatsheet)
