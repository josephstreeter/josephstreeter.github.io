---
title: "Troubleshooting Guide"
description: "Comprehensive troubleshooting guide for VS Code documentation environments, performance optimization, and common issue resolution"
tags: ["troubleshooting", "performance", "issues", "optimization", "debugging"]
category: "support"
difficulty: "advanced"
last_updated: "2025-07-06"
---

## Troubleshooting Guide

This comprehensive guide addresses common issues, performance problems, and configuration challenges when using VS Code for Documentation as Code workflows.

## Common VS Code Issues

### Extension-Related Problems

#### Extension Loading Failures

**Symptoms:**

- Extensions not activating
- Missing functionality
- Error messages in extension host

**Diagnosis:**

1. **Check Extension Status**:
   - Open Extensions panel (`Ctrl+Shift+X`)
   - Look for disabled or failed extensions
   - Check for update notifications

2. **Review Extension Host Log**:

   ```text
   Help → Toggle Developer Tools → Console
   Look for extension-related errors
   ```

**Solutions:**

```bash
# Reload VS Code window
Ctrl+Shift+P → "Developer: Reload Window"

# Disable problematic extensions
Ctrl+Shift+P → "Extensions: Disable All Installed Extensions"

# Reset extension settings
# Delete .vscode/extensions.json and reinstall
```

#### Extension Conflicts

**Common Conflicts:**

- Multiple markdown preview extensions
- Conflicting spell checkers
- Duplicate formatting extensions

**Resolution Steps:**

1. **Identify Conflicts**:

   ```text
   Use Extension Bisect to isolate problems:
   Ctrl+Shift+P → "Help: Start Extension Bisect"
   ```

2. **Disable Conflicting Extensions**:

   ```json
   // .vscode/settings.json
   {
     "extensions.ignoreRecommendations": true,
     "markdown.extension.preview.autoShowPreviewToSide": false
   }
   ```

### Markdown Preview Issues

#### Preview Not Rendering

**Check List:**

- [ ] Markdown extension installed and enabled
- [ ] File saved with `.md` extension
- [ ] Valid markdown syntax
- [ ] Security settings allow preview

**Solutions:**

```json
// .vscode/settings.json
{
  "markdown.preview.breaks": true,
  "markdown.preview.linkify": true,
  "security.workspace.trust.untrustedFiles": "open"
}
```

#### Broken Cross-References

**Common Causes:**

- Incorrect file paths
- Missing files
- Case sensitivity issues

**Diagnostic Commands:**

```bash
# Check for broken links (requires markdown-link-check)
npx markdown-link-check docs/**/*.md

# Validate internal links
find docs -name "*.md" -exec grep -l "\[.*\](.*\.md)" {} \;
```

### Performance Issues

#### Slow File Opening

**Symptoms:**

- Long delays when opening files
- Unresponsive editor
- High CPU usage

**Performance Optimization:**

```json
// .vscode/settings.json
{
  // Reduce file watching overhead
  "files.watcherExclude": {
    "**/.git/**": true,
    "**/node_modules/**": true,
    "**/_site/**": true,
    "**/dist/**": true,
    "**/bin/**": true,
    "**/obj/**": true
  },
  
  // Optimize search performance
  "search.exclude": {
    "**/node_modules": true,
    "**/bower_components": true,
    "**/_site": true,
    "**/coverage": true
  },
  
  // Reduce extension overhead
  "extensions.autoCheckUpdates": false,
  "extensions.autoUpdate": false
}
```

#### Memory Usage Problems

**Monitoring Memory Usage:**

1. **Check Process Memory**:

   ```bash
   # Windows
   tasklist /fi "imagename eq code.exe"
   
   # macOS/Linux
   ps aux | grep -i "visual studio code"
   ```

2. **VS Code Developer Tools**:

   ```text
   Help → Toggle Developer Tools → Performance tab
   Record performance while experiencing issues
   ```

**Memory Optimization:**

```json
{
  // Limit suggestion features
  "editor.suggest.showWords": false,
  "editor.hover.delay": 1000,
  
  // Reduce syntax highlighting overhead
  "editor.semanticHighlighting.enabled": false,
  
  // Limit undo history
  "editor.undoStopHistory": 20
}
```

## Git Integration Issues

### Authentication Problems

#### Git Credentials

**Common Issues:**

- Expired authentication tokens
- Two-factor authentication conflicts
- SSH key problems

**Solutions:**

```bash
# Reset Git credentials
git config --global --unset credential.helper
git config --global credential.helper manager-core

# Check SSH configuration
ssh -T git@github.com

# Regenerate GitHub token
# GitHub → Settings → Developer settings → Personal access tokens
```

#### VS Code Git Integration

```json
// .vscode/settings.json
{
  "git.enableCommitSigning": false,  // Disable if causing issues
  "git.autofetch": false,            // Disable automatic fetching
  "git.confirmSync": true,           // Require confirmation for sync
  "git.enableSmartCommit": false     // Disable smart commit
}
```

### Branch and Merge Issues

#### Merge Conflicts in Documentation

**Prevention Strategies:**

1. **Frequent Synchronization**:

   ```bash
   # Sync before starting work
   git fetch origin
   git rebase origin/main
   
   # Regular commits during work
   git add -A && git commit -m "WIP: section update"
   ```

2. **Granular File Organization**:

   ```text
   Break large files into smaller, focused files:
   - getting-started.md
   - configuration.md
   - deployment.md
   ```

**Resolution Process:**

```bash
# Identify conflicted files
git status

# Use VS Code merge editor
code --merge file1.md file2.md merged.md

# Mark conflicts as resolved
git add resolved-file.md
git commit -m "Resolve merge conflict in documentation"
```

### Repository Synchronization

#### Out-of-Sync Repositories

**Symptoms:**

- Local changes not reflecting in remote
- Missing commits in local history
- Divergent branch warnings

**Diagnostic Commands:**

```bash
# Check repository status
git status --porcelain
git log --oneline --graph --all -10

# Check remote configuration
git remote -v
git fetch --dry-run
```

**Synchronization Solutions:**

```bash
# Force synchronization (use with caution)
git fetch origin
git reset --hard origin/main

# Safer synchronization with local changes
git stash
git pull origin main
git stash pop
```

## Copilot-Specific Issues

### Copilot Not Responding

#### Activation Problems

**Check Copilot Status:**

1. **Extension Status**: Ensure GitHub Copilot extension is enabled
2. **Authentication**: Verify GitHub account connection
3. **Subscription**: Confirm active Copilot subscription

**Diagnostic Steps:**

```text
1. Command Palette: "GitHub Copilot: Check Status"
2. Output Panel: Select "GitHub Copilot" from dropdown
3. Developer Tools: Check for JavaScript errors
```

**Common Solutions:**

```bash
# Restart Copilot service
Ctrl+Shift+P → "GitHub Copilot: Restart Language Server"

# Re-authenticate
Ctrl+Shift+P → "GitHub Copilot: Sign Out"
Ctrl+Shift+P → "GitHub Copilot: Sign In"
```

### Poor Suggestion Quality

#### Context Optimization

**Improve suggestion context:**

```markdown
<!-- Provide clear context for better suggestions -->
<!-- 
Project: Documentation site using DocFX
Audience: Developer teams new to Azure
Goal: Create step-by-step deployment guide
-->

## Azure App Service Deployment
<!-- Copilot now has better context for suggestions -->
```

**File Organization for Better Context:**

```text
Organize files to provide Copilot with better context:
- Keep related files in same directory
- Use descriptive file names
- Include relevant frontmatter
- Cross-reference related content
```

### Copilot Chat Issues

#### Chat Not Working

**Common Causes:**

- Network connectivity issues
- Extension version conflicts
- Chat feature not enabled

**Troubleshooting Steps:**

```text
1. Check internet connection
2. Update GitHub Copilot Chat extension
3. Restart VS Code
4. Clear VS Code cache
```

**Cache Clearing:**

```bash
# Windows
%APPDATA%\Code\User\workspaceStorage\
%APPDATA%\Code\logs\

# macOS
~/Library/Application Support/Code/User/workspaceStorage/
~/Library/Application Support/Code/logs/

# Linux
~/.config/Code/User/workspaceStorage/
~/.config/Code/logs/
```

## DocFX Integration Issues

### Build Failures

#### Common Build Errors

**Missing Dependencies:**

```bash
# Install DocFX globally
dotnet tool install -g docfx

# Verify installation
docfx --version

# Update to latest version
dotnet tool update -g docfx
```

**Configuration Issues:**

```json
// docfx.json validation
{
  "metadata": [
    {
      "src": [
        {
          "files": ["**/*.cs"],
          "exclude": ["**/bin/**", "**/obj/**"]
        }
      ],
      "dest": "api"
    }
  ],
  "build": {
    "content": [
      {
        "files": ["**/*.md", "**/*.yml"],
        "exclude": ["**/bin/**", "**/obj/**", "**/.*/**"]
      }
    ],
    "dest": "_site"
  }
}
```

#### Build Performance

**Optimization Strategies:**

```json
// docfx.json performance settings
{
  "build": {
    "globalMetadata": {
      "_enableSearch": false,  // Disable for faster builds
      "_disableContribution": true
    },
    "template": ["default", "modern"],
    "keepFileLink": false,
    "cleanupCacheHistory": true
  }
}
```

### Template and Styling Issues

#### Custom Template Problems

**Common Issues:**

- Template not loading
- CSS not applying
- JavaScript errors

**Debugging Steps:**

1. **Validate Template Structure**:

   ```text
   template/
   ├── partials/
   ├── styles/
   ├── layout/
   └── ManagedReference.html.primary.tmpl
   ```

2. **Check Browser Console**:

   ```text
   F12 → Console tab
   Look for CSS/JavaScript errors
   ```

3. **Test with Default Template**:

   ```json
   // Temporarily use default template
   {
     "build": {
       "template": ["default"]
     }
   }
   ```

## Environment-Specific Issues

### Windows-Specific Problems

#### File Path Length Limitations

**Symptoms:**

- Files not opening
- Build failures with long paths
- Git operations failing

**Solutions:**

```powershell
# Enable long path support (Admin required)
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
  -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force

# Use shorter workspace paths
# Instead of: C:\Users\Username\Very\Long\Path\To\Documentation
# Use: C:\Docs\ProjectName
```

#### PowerShell Execution Policy

```powershell
# Check current policy
Get-ExecutionPolicy

# Set policy for documentation scripts
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### macOS-Specific Problems

#### Permission Issues

```bash
# Fix VS Code permissions
sudo xattr -r -d com.apple.quarantine /Applications/Visual\ Studio\ Code.app

# Git credential helper setup
git config --global credential.helper osxkeychain
```

### Linux-Specific Problems

#### Package Dependencies

```bash
# Ubuntu/Debian dependencies
sudo apt update
sudo apt install git curl wget gnupg2 software-properties-common

# Install .NET for DocFX
wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update
sudo apt install dotnet-sdk-6.0
```

## Diagnostic Tools and Techniques

### VS Code Diagnostics

#### Built-in Diagnostic Tools

```text
1. Developer Tools (F12)
   - Console for JavaScript errors
   - Network tab for loading issues
   - Performance tab for profiling

2. Extension Host Log
   Help → Toggle Developer Tools → Console
   Look for extension-related errors

3. Process Explorer
   Ctrl+Shift+P → "Developer: Open Process Explorer"
   Monitor CPU and memory usage
```

#### Log File Locations

```bash
# Windows
%APPDATA%\Code\logs\

# macOS  
~/Library/Application Support/Code/logs/

# Linux
~/.config/Code/logs/
```

### External Diagnostic Tools

#### Network Connectivity

```bash
# Test GitHub connectivity
curl -I https://api.github.com

# Test npm registry
npm ping

# Test DocFX templates
curl -I https://api.nuget.org/v3-flatcontainer/docfx.console/
```

#### System Resources

```bash
# Monitor system resources
# Windows: Task Manager or Resource Monitor
# macOS: Activity Monitor or htop
# Linux: htop, top, or system monitor
```

## Prevention Strategies

### Proactive Monitoring

#### Regular Maintenance Tasks

```bash
# Weekly maintenance script
#!/bin/bash

# Update VS Code extensions
code --list-extensions | xargs -L 1 code --install-extension

# Clean Git repository
git gc --prune=now
git remote prune origin

# Verify DocFX build
docfx build --dry-run

# Check for broken links
markdown-link-check docs/**/*.md
```

#### Health Checks

```json
// .vscode/tasks.json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Health Check",
      "type": "shell",
      "command": "echo",
      "args": ["Running documentation health check..."],
      "dependsOrder": "sequence",
      "dependsOn": [
        "Check Links",
        "Spell Check",
        "Build Test"
      ]
    }
  ]
}
```

### Backup and Recovery

#### Configuration Backup

```bash
# Backup VS Code settings
cp -r .vscode/ backup-$(date +%Y%m%d)/
git add .vscode/
git commit -m "Backup VS Code configuration"
```

#### Content Recovery

```bash
# Git-based recovery
git reflog                    # Find lost commits
git cherry-pick <commit-id>   # Recover specific changes
git fsck --lost-found         # Find orphaned content
```

## Getting Additional Help

### Community Resources

#### Official Documentation

- [VS Code Documentation](https://code.visualstudio.com/docs)
- [GitHub Copilot Documentation](https://docs.github.com/copilot)
- [DocFX Documentation](https://dotnet.github.io/docfx/)

#### Community Forums

- [VS Code GitHub Issues](https://github.com/microsoft/vscode/issues)
- [Stack Overflow VS Code Tag](https://stackoverflow.com/questions/tagged/visual-studio-code)
- [DocFX GitHub Discussions](https://github.com/dotnet/docfx/discussions)

### Professional Support

#### Enterprise Support Options

- **GitHub Enterprise Support**: For Copilot-related issues
- **Microsoft Support**: For VS Code enterprise deployments
- **Azure Support**: For Azure DevOps integration issues

#### Consulting Services

- **Documentation Strategy**: Professional documentation consulting
- **Tool Integration**: Custom toolchain development
- **Team Training**: Professional training services

---

*This troubleshooting guide covers the most common issues in VS Code documentation environments. For additional support, consult the community resources or consider professional support options.*
