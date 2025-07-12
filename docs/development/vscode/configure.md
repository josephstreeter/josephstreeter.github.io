---
title: "VS Code Configuration for PowerShell Development"
description: "Complete guide to configuring Visual Studio Code for PowerShell development, including extensions, settings, and code snippets."
author: "Joseph Streeter"
ms.date: "2024-01-15"
ms.topic: "how-to"
ms.service: "vscode"
keywords: ["Visual Studio Code", "VS Code", "PowerShell", "configuration", "extensions", "snippets"]
---

## Visual Studio Code Configuration

This guide provides comprehensive instructions for configuring Visual Studio Code as a powerful PowerShell development environment. The configuration focuses on PowerShell and complementary technologies for enhanced productivity.

---

## Extensions and Installation

VS Code is designed to be very extensible. There are a few extensions that we will install to make it possible to develop PowerShell code.

### Installing Extensions

Extensions can be installed through multiple methods:

**Via Extensions View:**

1. Open Extensions view with `Ctrl+Shift+X`
2. Search for the extension name
3. Click **Install**

**Via Command Line:**

```bash
# Install PowerShell extension
code --install-extension ms-vscode.PowerShell

# Install additional recommended extensions
code --install-extension ms-vscode.vscode-json
code --install-extension redhat.vscode-yaml
code --install-extension streetsidesoftware.code-spell-checker
code --install-extension davidanson.vscode-markdownlint
code --install-extension eamodio.gitlens
```

### Configuring Extensions

To configure an extension:

1. Click the Settings Sprocket in the lower left-hand corner
2. Select **Settings** from the menu
3. Select the **User** tab at the top of the screen
4. Scroll down and expand **Extensions** in the left pane
5. Click on the extension and update settings in the right pane as needed

## Essential Extensions for PowerShell Development

The following extensions are essential for PowerShell development in VS Code:

### Core Extensions

#### PowerShell Extension

**Publisher:** Microsoft  
**ID:** `ms-vscode.PowerShell`

The Microsoft PowerShell extension provides comprehensive language support including:

- Syntax highlighting and IntelliSense
- Code completion and parameter hints
- Definition tracking and symbol navigation
- Integrated PowerShell console
- Debugging capabilities
- Script analysis with PSScriptAnalyzer
- Code formatting and refactoring

**Installation:**

```bash
code --install-extension ms-vscode.PowerShell
```

#### GitLens Extension

**Publisher:** GitKraken  
**ID:** `eamodio.gitlens`

Enhances Git capabilities within VS Code:

- Line-by-line Git blame annotations
- Commit and file history
- Repository and branch insights
- Advanced Git visualization

### Additional Recommended Extensions

| Extension | Publisher | Purpose |
|-----------|-----------|---------|
| **JSON** | Microsoft | JSON file support and validation |
| **YAML** | Red Hat | YAML syntax support |
| **Code Spell Checker** | Street Side Software | Spell checking for code and comments |
| **markdownlint** | David Anson | Markdown linting and formatting |
| **GitHub Copilot** | GitHub | AI-powered code completion |

## VS Code Configuration for PowerShell

### PowerShell Extension Settings

Configure the PowerShell extension for optimal development experience:

#### Recommended Settings

Add these settings to your VS Code `settings.json` file:

```json
{
    // PowerShell extension configuration
    "powershell.codeFormatting.preset": "OTBS",
    "powershell.codeFormatting.openBraceOnSameLine": false,
    "powershell.codeFormatting.newLineAfterOpenBrace": true,
    "powershell.codeFormatting.newLineAfterCloseBrace": true,
    "powershell.codeFormatting.addWhitespaceAroundPipe": true,
    "powershell.codeFormatting.autoCorrectAliases": true,
    "powershell.codeFormatting.avoidSemicolonsAsLineTerminators": true,
    "powershell.codeFormatting.trimWhitespaceAroundPipe": true,
    "powershell.codeFormatting.useCorrectCasing": true,
    "powershell.scriptAnalysis.enable": true,
    "powershell.integratedConsole.showOnStartup": false,
    "powershell.debugging.createTemporaryIntegratedConsole": true,
    
    // General editor settings for PowerShell
    "editor.tabSize": 4,
    "editor.insertSpaces": true,
    "editor.detectIndentation": false,
    "editor.wordWrap": "on",
    "editor.formatOnSave": true,
    "files.trimTrailingWhitespace": true,
    "files.insertFinalNewline": true
}
```

#### PowerShell Extension Configuration Summary

| **Setting** | **Recommended Value** | **Description** |
|-------------|----------------------|-----------------|
| Code Folding | Enable | Allows collapsing code blocks |
| Add Whitespace Around Pipe | Enable | Improves readability of pipeline commands |
| Auto Correct Aliases | Enable | Expands aliases to full cmdlet names |
| Avoid Semicolons As Line Terminators | Enable | Follows PowerShell best practices |
| Open Brace On Same Line | Disable | Places opening braces on new lines |
| Trim Whitespace Around Pipe | Enable | Removes extra spaces around pipes |
| Use Correct Casing | Enable | Corrects cmdlet and parameter casing |

### Additional Extension Configuration

#### GitHub Copilot

If you have a GitHub Copilot subscription, this extension provides AI-powered code completion:

```bash
code --install-extension github.copilot
```

#### markdownlint

For documentation and README files, install markdownlint:

```bash
code --install-extension davidanson.vscode-markdownlint
```

Configure markdownlint with these settings:

```json
{
    "markdownlint.config": {
        "MD013": { "line_length": 120 },
        "MD033": false,
        "MD041": false
    }
}
```

## Custom Code Snippets

VS Code provides the ability to create custom code snippets for frequently used code patterns. This is particularly useful for PowerShell development where you might have standard function templates or common script patterns.

### Quick Overview

**Benefits of using snippets:**

- Faster code development with templates
- Consistent code patterns across projects
- Reduced typing for repetitive structures
- Customizable placeholders and tab stops

**Access snippet configuration:**

1. Open Command Palette (`Ctrl+Shift+P`)
2. Type "Configure User Snippets"
3. Select the language (e.g., "powershell.json")

### Comprehensive Snippet Guide

For detailed information on creating, configuring, and using snippets, including:

- Advanced PowerShell function templates
- Administrative automation snippets
- Documentation and knowledge base templates
- Best practices and advanced features

See the dedicated guide: **[VS Code Snippets for PowerShell](snippets.md)**

---

## Advanced Configuration

### Workspace Settings

For project-specific settings, create a `.vscode/settings.json` file in your project root:

```json
{
    // PowerShell-specific workspace settings
    "powershell.scriptAnalysis.settingsPath": ".vscode/PSScriptAnalyzerSettings.psd1",
    "powershell.codeFormatting.preset": "Custom",
    "powershell.developer.bundledModulesPath": "./modules",
    
    // File associations
    "files.associations": {
        "*.ps1xml": "xml",
        "*.psd1": "powershell",
        "*.psm1": "powershell"
    },
    
    // Explorer settings
    "files.exclude": {
        "**/bin": true,
        "**/obj": true,
        "**/.vs": true
    }
}
```

### Task Configuration

Create a `.vscode/tasks.json` file for common PowerShell tasks:

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Run PowerShell Script",
            "type": "shell",
            "command": "pwsh",
            "args": ["-File", "${file}"],
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            }
        },
        {
            "label": "Analyze Script",
            "type": "shell",
            "command": "pwsh",
            "args": ["-Command", "Invoke-ScriptAnalyzer -Path '${file}' -Severity Warning,Error"],
            "group": "test",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            }
        }
    ]
}
```

### Debug Configuration

Create a `.vscode/launch.json` file for debugging:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "PowerShell: Launch Current File",
            "type": "PowerShell",
            "request": "launch",
            "script": "${file}",
            "cwd": "${workspaceFolder}"
        },
        {
            "name": "PowerShell: Interactive Session",
            "type": "PowerShell",
            "request": "launch",
            "cwd": "${workspaceFolder}"
        }
    ]
}
```

---

## References and Additional Resources

### Official Documentation

- **[VS Code PowerShell Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell)** - Official extension page
- **[VS Code Snippets Documentation](https://code.visualstudio.com/docs/editor/userdefinedsnippets)** - Complete guide to creating custom snippets
- **[VS Code Settings Reference](https://code.visualstudio.com/docs/getstarted/settings)** - User and workspace settings guide
- **[PowerShell Extension Documentation](https://code.visualstudio.com/docs/languages/powershell)** - Official PowerShell development guide

### Configuration Resources

- **[PSScriptAnalyzer Rules](https://github.com/PowerShell/PSScriptAnalyzer/tree/master/RuleDocumentation)** - Complete list of analysis rules
- **[VS Code Tasks Documentation](https://code.visualstudio.com/docs/editor/tasks)** - Task automation guide
- **[PowerShell Best Practices](https://github.com/PoshCode/PowerShellPracticeAndStyle)** - Community style guide
- **[VS Code Debugging](https://code.visualstudio.com/docs/editor/debugging)** - Debugging configuration and usage

### Extension Resources

- **[GitLens Extension](https://marketplace.visualstudio.com/items?itemName=eamodio.gitlens)** - Enhanced Git capabilities
- **[GitHub Copilot](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot)** - AI-powered code completion
- **[markdownlint](https://marketplace.visualstudio.com/items?itemName=DavidAnson.vscode-markdownlint)** - Markdown linting
- **[Code Spell Checker](https://marketplace.visualstudio.com/items?itemName=streetsidesoftware.code-spell-checker)** - Spell checking for code

### Community Resources

- **[PowerShell Community](https://github.com/PowerShell/PowerShell)** - PowerShell GitHub repository
- **[VS Code PowerShell Issues](https://github.com/PowerShell/vscode-powershell/issues)** - Extension support and issues
- **[r/PowerShell](https://www.reddit.com/r/PowerShell/)** - PowerShell community on Reddit
- **[PowerShell.org](https://powershell.org/)** - PowerShell community hub

---

Last updated: {{ site.time | date: "%Y-%m-%d" }}
