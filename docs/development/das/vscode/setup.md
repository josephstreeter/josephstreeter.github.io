---
title: "Setup and Configuration"
description: "Complete guide to setting up Visual Studio Code with essential extensions and configurations for documentation workflows"
tags: ["vscode", "setup", "configuration", "extensions", "workspace"]
category: "setup"
difficulty: "beginner"
last_updated: "2025-07-06"
---

## Setup and Configuration

This guide walks you through setting up Visual Studio Code with all the essential extensions, configurations, and workspace settings needed for optimal documentation workflows.

## Prerequisites

Before starting, ensure you have:

- **Visual Studio Code** (latest stable version)
- **Git** configured with your credentials
- **GitHub account** with Copilot access (if using Copilot features)
- **Node.js** (for DocFX and related tools)

## Essential Extensions

Install these key extensions to optimize VS Code for documentation work.

### Core Documentation Extensions

Install via VS Code Extensions marketplace or command line:

```bash
# Essential markdown and documentation extensions
code --install-extension ms-vscode.vscode-markdown
code --install-extension bierner.markdown-mermaid
code --install-extension davidanson.vscode-markdownlint
code --install-extension ms-vscode.wordcount
code --install-extension streetsidesoftware.code-spell-checker
```

**Extension Details:**

| Extension | Purpose | Key Features |
|-----------|---------|--------------|
| **Markdown All in One** | Enhanced markdown editing | Table of contents, shortcuts, live preview |
| **Markdown Mermaid** | Diagram support | Syntax highlighting for Mermaid diagrams |
| **markdownlint** | Markdown linting | Style checking, formatting validation |
| **Word Count** | Writing metrics | Track progress, estimate reading time |
| **Code Spell Checker** | Spell checking | Multi-language support, custom dictionaries |

### GitHub and Copilot Extensions

```bash
# GitHub integration and AI assistance
code --install-extension github.vscode-pull-request-github
code --install-extension eamodio.gitlens
code --install-extension github.copilot
code --install-extension github.copilot-chat
```

### DocFX and Azure Extensions

```bash
# DocFX and Azure-specific extensions
code --install-extension ms-azuretools.vscode-azureappservice
code --install-extension ms-vscode.azure-account
code --install-extension ms-azuretools.vscode-azureresourcegroups
```

### Additional Productivity Extensions

```bash
# Enhanced productivity and workflow extensions
code --install-extension ms-vscode.vscode-json
code --install-extension redhat.vscode-yaml
code --install-extension ms-vscode.powershell
code --install-extension bradlc.vscode-tailwindcss
```

## Workspace Configuration

Create a comprehensive workspace configuration for your documentation project.

### .vscode/settings.json

Create this file in your documentation repository root:

```json
{
  // Markdown configuration
  "markdown.preview.fontSize": 14,
  "markdown.preview.lineHeight": 1.6,
  "markdown.preview.fontFamily": "system-ui, -apple-system, sans-serif",
  "markdown.extension.toc.levels": "1..3",
  "markdown.extension.toc.omittedFromToc": {},
  
  // Editor settings for documentation
  "editor.wordWrap": "on",
  "editor.lineNumbers": "on",
  "editor.rulers": [80, 120],
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.markdownlint": true
  },
  
  // Spell checker configuration
  "cSpell.words": [
    "docfx",
    "yaml",
    "frontmatter",
    "DevOps",
    "repo",
    "toc",
    "xref"
  ],
  "cSpell.enabledLanguageIds": [
    "markdown",
    "yaml",
    "json"
  ],
  
  // File associations
  "files.associations": {
    "*.md": "markdown",
    "toc.yml": "yaml",
    "docfx.json": "json"
  },
  
  // Git configuration
  "git.enableSmartCommit": true,
  "git.confirmSync": false,
  "git.autofetch": true,
  
  // Explorer configuration
  "explorer.fileNesting.enabled": true,
  "explorer.fileNesting.patterns": {
    "*.md": "${capture}.yml, ${capture}.yaml"
  },
  
  // Terminal configuration
  "terminal.integrated.defaultProfile.windows": "PowerShell",
  "terminal.integrated.defaultProfile.linux": "bash",
  
  // Copilot configuration
  "github.copilot.enable": {
    "*": true,
    "markdown": true,
    "yaml": true
  }
}
```

### .vscode/extensions.json

Recommend extensions to team members:

```json
{
  "recommendations": [
    "ms-vscode.vscode-markdown",
    "bierner.markdown-mermaid", 
    "davidanson.vscode-markdownlint",
    "ms-vscode.wordcount",
    "streetsidesoftware.code-spell-checker",
    "github.vscode-pull-request-github",
    "eamodio.gitlens",
    "github.copilot",
    "github.copilot-chat",
    "ms-azuretools.vscode-azureappservice",
    "redhat.vscode-yaml"
  ]
}
```

## Workspace Snippets

Create custom snippets to speed up common documentation tasks.

### .vscode/markdown.json

```json
{
  "DocFX Frontmatter": {
    "prefix": "frontmatter",
    "body": [
      "---",
      "title: \"${1:Page Title}\"",
      "description: \"${2:Page description}\"",
      "tags: [\"${3:tag1}\", \"${4:tag2}\"]",
      "category: \"${5:category}\"",
      "difficulty: \"${6|beginner,intermediate,advanced|}\"",
      "last_updated: \"${CURRENT_YEAR}-${CURRENT_MONTH}-${CURRENT_DATE}\"",
      "---",
      "",
      "## ${7:Main Heading}",
      "",
      "$0"
    ],
    "description": "Insert DocFX frontmatter template"
  },
  
  "Code Block with Language": {
    "prefix": "codeblock",
    "body": [
      "```${1|bash,powershell,json,yaml,csharp,javascript,typescript,python|}",
      "${2:code content}",
      "```",
      "$0"
    ],
    "description": "Insert code block with language selection"
  },
  
  "Table Template": {
    "prefix": "table",
    "body": [
      "| ${1:Column 1} | ${2:Column 2} | ${3:Column 3} |",
      "|${1/./=/g}|${2/./=/g}|${3/./=/g}|",
      "| ${4:Value 1} | ${5:Value 2} | ${6:Value 3} |",
      "$0"
    ],
    "description": "Insert markdown table template"
  },
  
  "Alert Block": {
    "prefix": "alert",
    "body": [
      "> [!${1|NOTE,TIP,IMPORTANT,CAUTION,WARNING|}]",
      "> ${2:Alert content}",
      "$0"
    ],
    "description": "Insert DocFX alert block"
  },
  
  "Cross-reference": {
    "prefix": "xref",
    "body": [
      "<xref:${1:target}>"
    ],
    "description": "Insert DocFX cross-reference"
  }
}
```

## User Settings Optimization

Configure global VS Code settings for documentation work.

### Recommended User Settings

Add these to your global VS Code settings:

```json
{
  // Editor improvements for long-form writing
  "editor.detectIndentation": true,
  "editor.insertSpaces": true,
  "editor.tabSize": 2,
  "editor.trimAutoWhitespace": true,
  "editor.renderWhitespace": "boundary",
  
  // Markdown-specific settings
  "markdown.validate.enabled": true,
  "markdown.validate.ignoredLinks": [],
  
  // File handling
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "files.trimFinalNewlines": true,
  
  // Search and replace optimization
  "search.useGlobalIgnoreFiles": true,
  "search.exclude": {
    "**/node_modules": true,
    "**/bower_components": true,
    "**/_site": true,
    "**/dist": true
  }
}
```

## Keyboard Shortcuts

Customize keyboard shortcuts for documentation workflows.

### .vscode/keybindings.json

```json
[
  {
    "key": "ctrl+shift+v",
    "command": "markdown.showPreviewToSide",
    "when": "editorLangId == 'markdown'"
  },
  {
    "key": "ctrl+k v",
    "command": "markdown.showPreview",
    "when": "editorLangId == 'markdown'"
  },
  {
    "key": "ctrl+shift+o",
    "command": "markdown.showDocumentOutline",
    "when": "editorLangId == 'markdown'"
  },
  {
    "key": "ctrl+shift+t",
    "command": "markdown.extension.editing.toggleCodeBlock",
    "when": "editorLangId == 'markdown'"
  }
]
```

## Theme and Font Recommendations

Optimize visual settings for extended documentation work.

### Recommended Themes

- **Light themes**: Default Light+, Quiet Light, GitHub Light
- **Dark themes**: Default Dark+, One Dark Pro, Dracula Official

### Font Configuration

```json
{
  "editor.fontFamily": "'Cascadia Code', 'Fira Code', 'JetBrains Mono', Consolas, monospace",
  "editor.fontLigatures": true,
  "editor.fontSize": 14,
  "editor.lineHeight": 1.6,
  "markdown.preview.fontFamily": "system-ui, -apple-system, BlinkMacSystemFont, sans-serif"
}
```

## Performance Optimization

Configure VS Code for optimal performance with large documentation projects.

### Performance Settings

```json
{
  // Reduce resource usage
  "search.searchOnType": false,
  "editor.hover.delay": 1000,
  "editor.suggest.showWords": false,
  
  // File watching optimization
  "files.watcherExclude": {
    "**/.git/objects/**": true,
    "**/.git/subtree-cache/**": true,
    "**/node_modules/**": true,
    "**/_site/**": true
  },
  
  // Extension management
  "extensions.autoCheckUpdates": false,
  "telemetry.telemetryLevel": "off"
}
```

## Troubleshooting Setup Issues

### Common Problems and Solutions

**Extension conflicts:**

- Disable conflicting markdown extensions
- Check extension compatibility in VS Code marketplace
- Use Extension Bisect to identify problematic extensions

**Performance issues:**

- Exclude large directories from file watching
- Disable unnecessary extensions for documentation workspaces
- Increase VS Code memory limits if needed

**Spell checker problems:**

- Add project-specific words to workspace dictionary
- Configure language-specific spell checking rules
- Verify spell checker language settings

## Verification Checklist

After completing setup, verify your configuration:

- [ ] All recommended extensions installed and enabled
- [ ] Workspace settings file created and configured
- [ ] Custom snippets working correctly
- [ ] Markdown preview functioning properly
- [ ] Spell checker detecting and correcting errors
- [ ] Git integration working with your repository
- [ ] GitHub Copilot activated (if applicable)
- [ ] DocFX builds successfully with your configuration

---

*Next: Learn how to effectively use [GitHub Copilot for documentation](copilot-usage.md) to enhance your writing productivity.*
