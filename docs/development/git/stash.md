# Git Stash: Complete Guide to Temporary Storage

Git stash is a powerful feature that provides temporary storage for uncommitted changes, allowing developers to quickly switch contexts without losing work in progress. This comprehensive guide covers stashing strategies, advanced techniques, and best practices for professional Git workflows.

## Understanding Git Stash

### What is Git Stash?

Git stash temporarily saves your uncommitted changes (both staged and unstaged) and reverts your working directory to match the HEAD commit¹. This creates a clean working directory while preserving your modifications in a retrievable format.

#### The Stash Stack Structure

Git stash operates as a stack (Last In, First Out - LIFO) where:

- **Recent stashes** are at the top of the stack (`stash@{0}`)
- **Older stashes** move down in the stack (`stash@{1}`, `stash@{2}`, etc.)
- **Multiple stashes** can exist simultaneously
- **Each stash** contains a snapshot of your working directory and staging area

#### When to Use Git Stash

**Appropriate Scenarios:**

- **Branch switching**: Need to switch branches with uncommitted changes
- **Emergency fixes**: Handle urgent issues without committing incomplete work
- **Experimental work**: Save experimental changes while testing alternatives
- **Pull operations**: Clean working directory before pulling upstream changes
- **Code reviews**: Temporarily save changes while reviewing others' work

**Alternative Approaches:**

- **Work-in-progress commits**: `git commit -m "WIP: feature implementation"`
- **Feature branches**: Create dedicated branches for experimental work
- **Git worktrees**: Use separate working directories for parallel development

## Basic Stash Operations

### Creating Stashes

#### Simple Stash Commands

```bash
# Stash tracked files (basic usage)
git stash

# Stash with descriptive message
git stash push -m "Work in progress on user authentication"

# Stash including untracked files
git stash -u
git stash push -u -m "Include new configuration files"

# Stash including ignored files (use carefully)
git stash -a
git stash push -a -m "Stash everything including ignored files"
```

#### Advanced Stash Creation

```bash
# Stash only specific files
git stash push -m "Database config changes" config/database.yml config/secrets.yml

# Stash with pathspec patterns
git stash push -m "Frontend changes" "src/components/*.js" "public/styles/*.css"

# Interactive stash creation
git stash push -p -m "Selective stash"

# Keep index (staged changes) while stashing unstaged changes
git stash --keep-index
```

### Viewing Stashes

#### Stash List and Information

```bash
# List all stashes with basic info
git stash list

# List stashes with detailed information
git stash list --stat

# Show stash content (latest stash)
git stash show

# Show specific stash content
git stash show stash@{2}

# Show detailed diff of stash
git stash show -p
git stash show -p stash@{1}

# Show stash with word-level diff
git stash show --word-diff
```

#### Advanced Stash Inspection

```bash
# Show stash as a commit
git show stash@{0}

# Show stash commit tree
git log --oneline --graph stash@{0}^..stash@{0}

# Show files in specific stash
git stash show --name-only stash@{1}

# Show stash statistics
git stash show --shortstat stash@{0}

# Compare stash with current branch
git diff stash@{0}
git diff HEAD stash@{0}
```

### Applying and Managing Stashes

#### Stash Application Methods

```bash
# Apply latest stash (keeps stash in list)
git stash apply

# Apply specific stash
git stash apply stash@{2}

# Pop latest stash (applies and removes from list)
git stash pop

# Pop specific stash
git stash pop stash@{1}

# Apply stash to different branch
git stash branch feature-branch stash@{0}
```

#### Advanced Application Techniques

```bash
# Apply stash with conflict resolution
git stash apply
# Resolve conflicts manually
git add resolved-files
# No commit needed - stash application complete

# Apply only specific files from stash
git checkout stash@{0} -- path/to/file.txt

# Apply stash as a patch
git stash show -p stash@{0} | git apply

# Reverse apply stash (undo stash application)
git stash show -p stash@{0} | git apply -R
```

## Advanced Stash Techniques

### Partial Stashing

#### Interactive Stashing

```bash
# Interactive stash creation (patch mode)
git stash push -p

# Example interactive session:
# Stage this hunk [y,n,q,a,d,/,j,J,g,e,?]? y
# y - yes, stash this hunk
# n - no, don't stash this hunk  
# q - quit, don't stash remaining hunks
# a - stash this and all remaining hunks in the file
# d - don't stash this or remaining hunks in the file
```

#### Selective File Stashing

```bash
# Stash specific files
git stash push src/main.py tests/test_main.py

# Stash files matching pattern
git stash push "*.js" "*.css"

# Stash files in specific directory
git stash push src/components/

# Stash with exclusion patterns
git add .
git stash push --staged -m "Everything except tests"
git reset HEAD tests/
```

### Stash Branching

#### Creating Branches from Stashes

```bash
# Create and checkout new branch from stash
git stash branch new-feature-branch

# Create branch from specific stash
git stash branch bugfix-branch stash@{2}

# Create branch without applying stash
git branch stash-backup stash@{0}
git checkout stash-backup
```

#### Workflow Integration

```bash
# Workflow: Save experimental work as branch
git stash push -m "Experimental API design"
git stash branch experiment-api
# Continue development on new branch

# Later: Merge successful experiment
git checkout main
git merge experiment-api
git branch -d experiment-api
```

### Stash Management

#### Organizing Stashes

```bash
# Create descriptive stash messages
git stash push -m "WIP: User authentication - before refactor"
git stash push -m "Bug fix: Memory leak in data processing"
git stash push -m "Experiment: Alternative sorting algorithm"

# Stash with author information (for team environments)
git -c user.name="John Doe" -c user.email="john@company.com" stash push -m "John's WIP"
```

#### Stash Cleanup

```bash
# Remove specific stash
git stash drop stash@{1}

# Remove all stashes
git stash clear

# Remove stashes older than specific date
git reflog expire --expire-unreachable=30.days refs/stash

# Backup stashes before cleanup
git log --oneline refs/stash > stash-backup.txt
```

## Stash in Different Scenarios

### Merge and Rebase Workflows

#### Pre-Merge Stashing

```bash
# Typical workflow before merge
git status  # Check for uncommitted changes
git stash push -m "Save work before merge"
git pull origin main
git stash pop

# Handle conflicts during stash pop
git stash pop
# Resolve conflicts
git add resolved-files
# Stash pop complete (no commit needed)
```

#### Rebase with Stash

```bash
# Stash before rebase
git stash push -m "Work in progress before rebase"
git rebase main
git stash pop

# Auto-stash during rebase (Git 2.14+)
git rebase --autostash main

# Configure automatic stashing
git config rebase.autoStash true
```

### Hotfix Workflows

#### Emergency Bug Fix Process

```bash
# Scenario: Working on feature when critical bug reported
# 1. Stash current work
git stash push -m "Feature XYZ - half complete"

# 2. Switch to main branch
git checkout main

# 3. Create hotfix branch
git checkout -b hotfix-critical-bug

# 4. Implement fix and deploy
# ... fix implementation ...
git add .
git commit -m "Fix critical security vulnerability"

# 5. Merge hotfix
git checkout main
git merge hotfix-critical-bug
git push origin main

# 6. Return to feature work
git checkout feature-branch
git stash pop

# 7. Merge hotfix into feature branch if needed
git merge main
```

### Experimental Development

#### Safe Experimentation Pattern

```bash
# Pattern: Try different implementation approaches
# 1. Save current implementation
git stash push -m "Current approach - working but slow"

# 2. Try alternative approach
# ... implement alternative ...

# 3. Compare approaches
git diff stash@{0}  # Compare with stashed version

# 4. Decision point:
# If new approach is better:
git stash drop stash@{0}  # Remove old approach

# If old approach was better:
git reset --hard HEAD~1  # Remove new approach
git stash pop             # Restore old approach
```

## Stash Best Practices

### Naming and Organization

#### Descriptive Stash Messages

```bash
# Good stash messages
git stash push -m "API refactor: half-way through extracting service layer"
git stash push -m "Bug investigation: added debugging logs (remove before commit)"
git stash push -m "Performance test: comparing array vs map implementations"

# Poor stash messages (avoid)
git stash push -m "work"
git stash push -m "stuff"
git stash push -m "temp"
```

#### Stash Hygiene

```bash
# Regular stash maintenance script
#!/bin/bash
echo "=== Git Stash Status ==="
echo "Total stashes: $(git stash list | wc -l)"
echo
echo "Current stashes:"
git stash list --date=relative

echo
echo "Old stashes (consider reviewing):"
git stash list --date=relative | grep -E "(months?|years?) ago"

# Warning about stash limits
if [ $(git stash list | wc -l) -gt 10 ]; then
    echo "⚠ Warning: You have more than 10 stashes. Consider cleanup."
fi
```

### Team Collaboration

#### Shared Repository Considerations

```bash
# Stashes are local - not pushed to remote
# Good: Personal workflow management
git stash push -m "Local debugging - not for sharing"

# Avoid: Relying on stashes for team coordination
# Instead use branches for shared work:
git checkout -b feature/shared-work
git add .
git commit -m "WIP: Shared work in progress"
git push -u origin feature/shared-work
```

#### Code Review Workflows

```bash
# Pattern: Pause feature work for code review
# 1. Stash current work
git stash push -m "Feature ABC - paused for code review"

# 2. Switch to review branch
git fetch origin
git checkout review-branch-xyz

# 3. Review and provide feedback
# ... review process ...

# 4. Return to feature work
git checkout feature-branch
git stash pop

# 5. Apply insights from review
# ... incorporate feedback ...
```

## Troubleshooting Stash Issues

### Common Problems and Solutions

#### Stash Pop Conflicts

**Problem**: Conflicts when applying stash

```bash
# When git stash pop creates conflicts
git stash pop
# Output: CONFLICT (content): Merge conflict in file.py

# Resolution process:
# 1. Resolve conflicts manually
vim file.py  # Edit conflicted file

# 2. Stage resolved files
git add file.py

# 3. Stash pop is now complete (no commit needed)
# The stash is automatically removed after successful resolution
```

#### Lost Stashes

**Problem**: Accidentally dropped stash

```bash
# Find lost stash using reflog
git fsck --unreachable | grep commit | cut -d\  -f3 | xargs git log --merges --no-walk --grep=WIP

# Or search reflog for stash operations
git log --graph --oneline --all $(git reflog --pretty=format:"%h" refs/stash)

# Recover dropped stash if found
git stash apply <commit-hash>
```

#### Stash Apply Failures

**Problem**: Stash won't apply due to changes

```bash
# Check what's blocking stash application
git diff HEAD stash@{0}

# Options to resolve:
# 1. Commit or stash current changes first
git stash push -m "Current work before applying old stash"
git stash apply stash@{1}

# 2. Force apply with conflicts
git checkout -f stash@{0} -- .
git reset HEAD  # Unstage all changes

# 3. Apply to clean branch
git stash branch temp-stash-branch stash@{0}
```

### Advanced Troubleshooting

#### Stash Corruption Recovery

```bash
# Check stash integrity
git fsck refs/stash

# Rebuild stash if corrupted
git update-ref -d refs/stash
git stash clear

# Backup and restore stashes
git log --pretty=format:"%H %s" refs/stash > stash-backup.txt
# Restore individual stashes from backup if needed
```

#### Performance Issues with Many Stashes

```bash
# Check stash count and sizes
git stash list | wc -l
git stash list --stat | grep -E "files? changed"

# Clean up old stashes
git reflog expire --expire=30.days refs/stash
git gc --prune=now

# Configure automatic cleanup
git config gc.reflogExpire 30
git config gc.reflogExpireUnreachable 30
```

## Stash Automation and Scripting

### Automated Workflows

#### Pre-commit Stash Hooks

```bash
#!/bin/bash
# .git/hooks/pre-commit
# Auto-stash untracked changes before commit

# Check for untracked files
if git status --porcelain | grep -q "^??"; then
    echo "Auto-stashing untracked files..."
    git stash push -u -m "Auto-stash: untracked files before commit"
    
    # Store stash reference for post-commit hook
    git rev-parse refs/stash > .git/PRE_COMMIT_STASH
fi
```

```bash
#!/bin/bash
# .git/hooks/post-commit
# Restore auto-stashed changes after commit

if [ -f .git/PRE_COMMIT_STASH ]; then
    echo "Restoring auto-stashed untracked files..."
    stash_ref=$(cat .git/PRE_COMMIT_STASH)
    
    if git rev-parse --verify $stash_ref >/dev/null 2>&1; then
        git stash pop
    fi
    
    rm .git/PRE_COMMIT_STASH
fi
```

#### Smart Stash Scripts

```bash
#!/bin/bash
# smart-stash.sh - Enhanced stash with automatic naming

get_branch_name() {
    git branch --show-current
}

get_stash_message() {
    local branch=$(get_branch_name)
    local timestamp=$(date "+%Y-%m-%d %H:%M")
    local files_changed=$(git status --porcelain | wc -l | tr -d ' ')
    
    echo "[$branch] $timestamp - $files_changed files changed"
}

# Create smart stash
git stash push -m "$(get_stash_message)" "$@"

echo "Stashed with message: $(get_stash_message)"
git stash list | head -1
```

#### Stash Management Scripts

```bash
#!/bin/bash
# stash-manager.sh - Interactive stash management

stash_menu() {
    echo "=== Git Stash Manager ==="
    echo "1. List all stashes"
    echo "2. Show stash content"
    echo "3. Apply stash"
    echo "4. Drop stash"
    echo "5. Clean old stashes"
    echo "6. Exit"
    echo
    read -p "Choose option [1-6]: " choice
    
    case $choice in
        1) git stash list --date=relative ;;
        2) show_stash_content ;;
        3) apply_stash ;;
        4) drop_stash ;;
        5) clean_old_stashes ;;
        6) exit 0 ;;
        *) echo "Invalid option" ;;
    esac
}

show_stash_content() {
    git stash list --oneline
    read -p "Enter stash number to show: " num
    git stash show -p "stash@{$num}"
}

apply_stash() {
    git stash list --oneline
    read -p "Enter stash number to apply: " num
    read -p "Pop (remove) after apply? [y/N]: " pop
    
    if [[ $pop =~ ^[Yy]$ ]]; then
        git stash pop "stash@{$num}"
    else
        git stash apply "stash@{$num}"
    fi
}

# Run menu in loop
while true; do
    stash_menu
    echo
    read -p "Press Enter to continue..."
    clear
done
```

### CI/CD Integration

#### Stash in Build Scripts

```bash
#!/bin/bash
# build-with-stash-safety.sh

# Save any uncommitted changes before build
if ! git diff-index --quiet HEAD --; then
    echo "Uncommitted changes detected, stashing..."
    git stash push -m "Auto-stash before build - $(date)"
    STASHED=true
fi

# Run build process
npm run build
BUILD_STATUS=$?

# Restore stashed changes
if [ "$STASHED" = true ]; then
    echo "Restoring stashed changes..."
    git stash pop
fi

exit $BUILD_STATUS
```

## Advanced Stash Workflows

### Stash-Based Feature Development

#### Feature Branch with Stash Checkpoints

```bash
# Pattern: Use stashes as development checkpoints
git checkout -b feature/new-api

# Checkpoint 1: Basic structure
# ... implement basic structure ...
git stash push -m "Checkpoint 1: Basic API structure complete"

# Checkpoint 2: Add validation
# ... implement validation ...  
git stash push -m "Checkpoint 2: Input validation added"

# Checkpoint 3: Add tests
# ... implement tests ...
git stash push -m "Checkpoint 3: Unit tests complete"

# Review checkpoints
git stash list

# Final implementation (apply all checkpoints)
git stash apply stash@{2}  # Basic structure
git add .
git commit -m "Add basic API structure"

git stash apply stash@{1}  # Validation  
git add .
git commit -m "Add input validation"

git stash apply stash@{0}  # Tests
git add .
git commit -m "Add comprehensive unit tests"

# Clean up stashes
git stash clear
```

### Multi-Repository Stash Management

#### Cross-Repository Workflow

```bash
#!/bin/bash
# multi-repo-stash.sh - Manage stashes across multiple repositories

REPOS=("frontend" "backend" "shared-lib")
BASE_DIR="/path/to/projects"

stash_all() {
    local message="$1"
    for repo in "${REPOS[@]}"; do
        echo "Stashing in $repo..."
        (cd "$BASE_DIR/$repo" && git stash push -m "$message")
    done
}

apply_all() {
    for repo in "${REPOS[@]}"; do
        echo "Applying stash in $repo..."
        (cd "$BASE_DIR/$repo" && git stash pop)
    done
}

list_all() {
    for repo in "${REPOS[@]}"; do
        echo "=== $repo ==="
        (cd "$BASE_DIR/$repo" && git stash list)
        echo
    done
}

case "$1" in
    "stash") stash_all "$2" ;;
    "apply") apply_all ;;
    "list") list_all ;;
    *) echo "Usage: $0 {stash|apply|list} [message]" ;;
esac
```

## Performance and Optimization

### Stash Performance Considerations

#### Optimizing Large Stashes

```bash
# Monitor stash sizes
git stash list --stat | head -20

# Optimize stash performance for large repositories
git config stash.showPatch false  # Disable automatic patch display
git config stash.showStat true    # Show only statistics

# Use shallow stashing for large binaries
git stash push --include-untracked --exclude="*.jpg,*.png,*.pdf"
```

#### Memory and Storage Optimization

```bash
# Clean up stash-related objects
git reflog expire --expire-unreachable=7.days refs/stash
git gc --aggressive --prune=now

# Monitor stash storage usage
git count-objects -v | grep "in-pack\|packs"

# Configure automatic cleanup
git config gc.reflogExpire 30
git config gc.reflogExpireUnreachable 7
git config gc.auto 256
```

---

## Footnotes and References

¹ **Git Stash Fundamentals**: Chacon, S., & Straub, B. (2014). *Pro Git - Git Tools - Stashing and Cleaning*. Available at: [Pro Git Stashing](https://git-scm.com/book/en/v2/Git-Tools-Stashing-and-Cleaning)

² **Stash Internal Mechanics**: Git Documentation Team. (2024). *git-stash Manual Page*. Available at: [Git Stash Manual](https://git-scm.com/docs/git-stash)

³ **Advanced Stash Techniques**: Atlassian. (2024). *Git Stash Tutorial and Best Practices*. Available at: [Atlassian Git Stash](https://www.atlassian.com/git/tutorials/saving-changes/git-stash)

⁴ **Stash Workflow Patterns**: GitHub, Inc. (2024). *Git Workflow Best Practices*. Available at: [GitHub Git Workflows](https://docs.github.com/en/get-started/quickstart/github-flow)

⁵ **Performance Optimization**: Git Development Community. (2024). *Git Performance and Optimization Guide*. Available at: [Git Performance Tips](https://git-scm.com/docs/git-gc)

## Additional Resources

### Official Documentation

- [Git Stash Manual](https://git-scm.com/docs/git-stash) - Complete git-stash command reference
- [Pro Git Book - Stashing](https://git-scm.com/book/en/v2/Git-Tools-Stashing-and-Cleaning) - Comprehensive stashing guide
- [Git Internals - Stash Implementation](https://git-scm.com/book/en/v2/Git-Internals-Git-References) - Technical details of stash storage
- [Git FAQ - Stash Questions](https://git.wiki.kernel.org/index.php/GitFaq#Stash) - Common stash-related questions

### Platform-Specific Guides

- [GitHub Stash Documentation](https://docs.github.com/en/get-started/using-git/saving-changes-to-your-repository) - GitHub-specific stash workflows
- [GitLab Stash Best Practices](https://docs.gitlab.com/ee/topics/git/useful_git_commands.html) - GitLab stash recommendations
- [Azure DevOps Git Stash](https://docs.microsoft.com/en-us/azure/devops/repos/git/save-work-with-stashes) - Azure DevOps stash integration
- [Bitbucket Stash Guide](https://support.atlassian.com/bitbucket-cloud/docs/save-changes-with-git-stash/) - Bitbucket stash workflows

### Tools and Extensions

- [Git Stash GUI Tools](https://git-scm.com/downloads/guis) - Graphical stash management
- [VS Code Git Stash Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode.vscode-git-stash) - IDE integration
- [tig - Text-mode Git Interface](https://github.com/jonas/tig) - Terminal-based Git browser with stash support
- [Lazygit](https://github.com/jesseduffield/lazygit) - Terminal UI for Git with stash management

### Advanced Topics and Tutorials

- [Git Hooks and Stash Automation](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks) - Automated stash workflows
- [Git Workflow Patterns](https://www.atlassian.com/git/tutorials/comparing-workflows) - Stash in different workflow contexts
- [Git Performance Tuning](https://github.blog/2021-04-29-scaling-monorepo-maintenance/) - Optimizing Git operations including stash
- [Git Troubleshooting Guide](https://git-scm.com/book/en/v2/Git-Internals-Maintenance-and-Data-Recovery) - Recovering from stash-related issues

### Community Resources

- [Stack Overflow Git Stash Questions](https://stackoverflow.com/questions/tagged/git-stash) - Community Q&A
- [Reddit r/git](https://reddit.com/r/git) - Git community discussions
- [Git Users Mailing List](https://git-scm.com/community) - Official Git community
- [Git Tips and Tricks Blog](https://github.blog/2015-06-08-how-to-undo-almost-anything-with-git/) - Advanced Git techniques
