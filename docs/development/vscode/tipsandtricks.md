---
title: "VS Code Tips and Tricks"
description: "Master Visual Studio Code with productivity tips, keyboard shortcuts, and advanced features for PowerShell development and general coding workflows."
author: "Joseph Streeter"
ms.date: "2024-01-15"
ms.topic: "how-to"
ms.service: "vscode"
keywords: ["Visual Studio Code", "VS Code", "PowerShell", "tips", "tricks", "shortcuts", "productivity"]
---

## VS Code Tips and Tricks

Master Visual Studio Code with these productivity tips, keyboard shortcuts, and advanced features designed to enhance your PowerShell development and general coding workflows.

---

## Essential Keyboard Shortcuts

### Navigation and File Management

| Shortcut | Action | Description |
|----------|--------|-------------|
| `Ctrl+P` | **Quick Open** | Find and open files instantly |
| `Ctrl+Shift+P` | **Command Palette** | Access all VS Code commands |
| `Ctrl+Shift+E` | **Explorer Focus** | Navigate to file explorer |
| `Ctrl+Shift+F` | **Global Search** | Search across all project files |
| `Ctrl+G` | **Go to Line** | Jump to specific line number |
| `Ctrl+T` | **Go to Symbol** | Find symbols across workspace |
| `Alt+Left/Right` | **Navigate History** | Move through navigation history |
| `Ctrl+Tab` | **Switch Tabs** | Cycle through open editors |

### Editing and Text Manipulation

| Shortcut | Action | Description |
|----------|--------|-------------|
| `Ctrl+D` | **Select Next Occurrence** | Multi-cursor editing of same text |
| `Ctrl+Shift+L` | **Select All Occurrences** | Edit all instances simultaneously |
| `Alt+Click` | **Multi-cursor** | Add cursor at click position |
| `Ctrl+Alt+Up/Down` | **Multi-cursor Lines** | Add cursors above/below |
| `Alt+Up/Down` | **Move Line** | Move current line up/down |
| `Shift+Alt+Up/Down` | **Copy Line** | Duplicate line above/below |
| `Ctrl+/` | **Toggle Comment** | Comment/uncomment lines |
| `Ctrl+Shift+K` | **Delete Line** | Remove entire line |
| `Ctrl+Enter` | **Insert Line Below** | New line below cursor |
| `Ctrl+Shift+Enter` | **Insert Line Above** | New line above cursor |

### PowerShell-Specific Shortcuts

| Shortcut | Action | Description |
|----------|--------|-------------|
| `F5` | **Run Script** | Execute PowerShell script |
| `F8` | **Run Selection** | Execute selected PowerShell code |
| `Ctrl+F5` | **Run Without Debugging** | Execute script without debugger |
| `F9` | **Toggle Breakpoint** | Add/remove debug breakpoint |
| `F10` | **Step Over** | Debug step over function calls |
| `F11` | **Step Into** | Debug step into function calls |
| `Shift+F5` | **Stop Debugging** | Terminate debug session |

### Editor and Window Management

| Shortcut | Action | Description |
|----------|--------|-------------|
| `Ctrl+\` | **Split Editor** | Split editor vertically |
| `Ctrl+Shift+\` | **Split Horizontal** | Split editor horizontally |
| `Ctrl+W` | **Close Editor** | Close current editor tab |
| `Ctrl+Shift+T` | **Reopen Closed Tab** | Restore recently closed editor |
| `Ctrl+K Ctrl+W` | **Close All** | Close all open editors |
| `Ctrl+K Z` | **Zen Mode** | Distraction-free editing |
| `Ctrl+B` | **Toggle Sidebar** | Show/hide file explorer |
| `` Ctrl+` `` | **Toggle Terminal** | Show/hide integrated terminal |

---

## Advanced VS Code Features

### Multi-Cursor Editing

Efficiently edit multiple locations simultaneously:

#### Selection Techniques

- **Select word**: `Ctrl+D` to select next occurrence
- **Select all**: `Ctrl+Shift+L` to select all occurrences  
- **Column selection**: `Shift+Alt+Drag` for rectangular selection
- **Manual placement**: `Alt+Click` to place cursors manually

#### Practical Examples

**Updating variable names:**

```powershell
$userName = "john.doe"
$userName = Get-User $userName
Write-Host "User: $userName"
```

Select first `$userName`, press `Ctrl+D` twice to select all instances, then type new name.

**Formatting lists:**

```text
PowerShell
Python  
JavaScript
```

Use `Alt+Click` at start of each line, then type `-` to create bulleted list.

### Snippet System

VS Code's snippet system provides instant access to code templates for faster development. Access snippets through IntelliSense (`Tab` completion), Command Palette (`Ctrl+Shift+P` → "Insert Snippet"), or Quick Actions (`Ctrl+.`).

**Built-in PowerShell snippets** include `function`, `if`, `foreach`, `param`, and `try` for common code structures.

**For comprehensive snippet guides**, including custom creation, advanced templates, and PowerShell-specific examples, see: **[VS Code Snippets for PowerShell](snippets.md)**

### Workspace Management

#### Multi-root Workspaces

Organize related projects in a single workspace:

1. **File** → **Add Folder to Workspace**
2. **File** → **Save Workspace As...**
3. Configure workspace-specific settings in `.vscode/settings.json`

#### Workspace-Specific Settings

```json
{
    "powershell.powerShellDefaultVersion": "PowerShell (x64)",
    "files.associations": {
        "*.ps1": "powershell",
        "*.psm1": "powershell",
        "*.psd1": "powershell"
    },
    "editor.defaultFormatter": "ms-vscode.powershell"
}
```

### Search and Replace Mastery

#### Advanced Search Features

| Feature | Shortcut | Description |
|---------|----------|-------------|
| **Case Sensitive** | `Alt+C` | Toggle case-sensitive search |
| **Whole Word** | `Alt+W` | Match whole words only |
| **Regex Search** | `Alt+R` | Enable regular expressions |
| **Search in Selection** | `Alt+L` | Limit search to selection |

#### Regular Expression Examples

**Find email addresses:**

```regex
\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b
```

**Find PowerShell variables:**

```regex
\$\w+
```

**Find function definitions:**

```regex
^function\s+(\w+)
```

### Git Integration

#### Built-in Git Commands

| Shortcut | Action | Description |
|----------|--------|-------------|
| `Ctrl+Shift+G` | **Source Control** | Open Git panel |
| `Ctrl+Shift+G G` | **Git Status** | View repository status |
| `Ctrl+Enter` | **Commit** | Commit staged changes |
| `Ctrl+Shift+P` → "Git" | **Git Commands** | Access all Git operations |

#### Git Workflow Tips

1. **Stage files**: Click `+` next to changed files
2. **Commit with message**: Type message and press `Ctrl+Enter`
3. **View diff**: Click file name to see changes
4. **Discard changes**: Click `⟲` to revert file

---

## PowerShell Development Features

### IntelliSense and Code Completion

#### Enhanced Features

- **Parameter completion**: Automatic parameter suggestions
- **Variable completion**: IntelliSense for defined variables
- **Module completion**: Auto-complete for imported modules
- **Path completion**: File and folder path suggestions

#### Configuration

```json
{
    "powershell.integratedConsole.showOnStartup": false,
    "powershell.scriptAnalysis.enable": true,
    "powershell.codeFormatting.preset": "OTBS",
    "powershell.debugging.createTemporaryIntegratedConsole": true
}
```

### Debugging Capabilities

#### Setting Up Debugging

1. **Set breakpoints**: Click line numbers or press `F9`
2. **Start debugging**: Press `F5` or use Command Palette
3. **Debug console**: View variables and execute commands
4. **Call stack**: Navigate through function calls

#### Debug Configuration (launch.json)

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

### Script Analysis

PowerShell extension includes PSScriptAnalyzer for code quality:

#### Common Analysis Rules

- **PSAvoidUsingCmdletAliases**: Use full cmdlet names
- **PSAvoidUsingPlainTextForPassword**: Secure credential handling
- **PSUseApprovedVerbs**: Use standard PowerShell verbs
- **PSUseSingularNouns**: Function naming conventions

#### Custom Analysis Settings

```json
{
    "powershell.scriptAnalysis.settingsPath": ".vscode/PSScriptAnalyzerSettings.psd1"
}
```

---

## Essential Extensions for PowerShell Development

### Core Extensions

#### PowerShell Extension Pack

```bash
code --install-extension ms-vscode.PowerShell
```

**Features:**

- Syntax highlighting and IntelliSense
- Debugging support
- Integrated console
- Script analysis
- Code formatting

#### Git Extensions

```bash
code --install-extension eamodio.gitlens
code --install-extension mhutchie.git-graph
```

#### Productivity Extensions

```bash
code --install-extension streetsidesoftware.code-spell-checker
code --install-extension davidanson.vscode-markdownlint
code --install-extension ms-vscode.vscode-json
code --install-extension redhat.vscode-yaml
```

### Extension Configuration

#### GitLens Settings

```json
{
    "gitlens.advanced.messages": {
        "suppressCommitHasNoPreviousCommitWarning": false,
        "suppressCommitNotFoundWarning": false
    },
    "gitlens.blame.compact": false,
    "gitlens.blame.format": "${message|50?} ${agoOrDate|14-}",
    "gitlens.defaultDateFormat": "MMMM Do, YYYY h:mma"
}
```

---

## Workflow Optimization

### Task Automation

#### Common Tasks Configuration (.vscode/tasks.json)

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
            "label": "PowerShell Analyze",
            "type": "shell",
            "command": "pwsh",
            "args": ["-Command", "Invoke-ScriptAnalyzer -Path ${file}"],
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

### Custom Keybindings

#### PowerShell-Specific Bindings (.vscode/keybindings.json)

```json
[
    {
        "key": "ctrl+f5",
        "command": "workbench.action.tasks.runTask",
        "args": "Run PowerShell Script"
    },
    {
        "key": "ctrl+shift+a",
        "command": "workbench.action.tasks.runTask", 
        "args": "PowerShell Analyze"
    },
    {
        "key": "ctrl+shift+r",
        "command": "powershell.refactorCode"
    }
]
```

### File Templates

Create project templates for consistent structure:

#### PowerShell Module Template

```text
MyModule/
├── MyModule.psm1
├── MyModule.psd1
├── Public/
├── Private/
├── Tests/
├── docs/
└── .vscode/
    ├── settings.json
    ├── tasks.json
    └── launch.json
```

---

## Performance Optimization

### VS Code Settings for Better Performance

```json
{
    "files.exclude": {
        "**/.git": true,
        "**/.svn": true,
        "**/.hg": true,
        "**/CVS": true,
        "**/.DS_Store": true,
        "**/node_modules": true,
        "**/*.exe": true,
        "**/*.dll": true
    },
    "search.exclude": {
        "**/node_modules": true,
        "**/bower_components": true,
        "**/*.code-search": true
    },
    "files.watcherExclude": {
        "**/.git/objects/**": true,
        "**/.git/subtree-cache/**": true,
        "**/node_modules/*/**": true
    }
}
```

### Memory Management

#### Tips for Large Projects

1. **Close unused tabs**: `Ctrl+K Ctrl+W` to close all
2. **Exclude large directories**: Use `.vscode/settings.json`
3. **Disable unused extensions**: Check extension impact
4. **Use workspace folders**: Organize related projects
5. **Regular restarts**: Clear accumulated memory

---

## Troubleshooting Common Issues

### PowerShell Extension Problems

#### Extension Not Loading

```powershell
# Check PowerShell version
$PSVersionTable

# Update PowerShell
winget upgrade Microsoft.PowerShell

# Reload VS Code window
# Ctrl+Shift+P → "Developer: Reload Window"
```

#### IntelliSense Not Working

1. **Restart PowerShell session**: Terminal → New Terminal
2. **Check module imports**: Verify required modules are available
3. **Clear cache**: Restart VS Code
4. **Update extension**: Check for PowerShell extension updates

### Performance Issues

#### Slow Startup

```json
{
    "extensions.autoUpdate": false,
    "extensions.autoCheckUpdates": false,
    "telemetry.enableTelemetry": false,
    "update.enableWindowsBackgroundUpdates": false
}
```

#### High CPU Usage

1. **Check running tasks**: Terminal → Running Tasks
2. **Disable file watchers**: Exclude large directories
3. **Close unused editors**: `Ctrl+K Ctrl+W`
4. **Monitor extensions**: Developer Tools (`Ctrl+Shift+I`)

### Git Integration Issues

#### Authentication Problems

```bash
# Configure Git credentials
git config --global user.name "Your Name"
git config --global user.email "your.email@domain.com"

# Set up credential helper
git config --global credential.helper manager
```

#### Line Ending Issues

```bash
# Configure line endings
git config --global core.autocrlf true  # Windows
git config --global core.autocrlf input # Linux/Mac
```

---

## References and Additional Resources

### Official Documentation

- **[VS Code Keyboard Shortcuts](https://code.visualstudio.com/shortcuts/keyboard-shortcuts-windows.pdf)** - Official shortcut reference (PDF)
- **[VS Code Tips and Tricks](https://code.visualstudio.com/docs/getstarted/tips-and-tricks)** - Microsoft's official tips collection
- **[PowerShell Extension Documentation](https://code.visualstudio.com/docs/languages/powershell)** - PowerShell development guide
- **[VS Code User Guide](https://code.visualstudio.com/docs/editor/codebasics)** - Comprehensive editing features guide

### Extension Resources

- **[PowerShell Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell)** - Official PowerShell extension
- **[GitLens Extension](https://marketplace.visualstudio.com/items?itemName=eamodio.gitlens)** - Git supercharged
- **[VS Code Extension Marketplace](https://marketplace.visualstudio.com/vscode)** - Browse all available extensions

### Configuration Guides

- **[VS Code Settings](https://code.visualstudio.com/docs/getstarted/settings)** - User and workspace settings
- **[Custom Keybindings](https://code.visualstudio.com/docs/getstarted/keybindings)** - Keyboard shortcut customization
- **[Tasks Configuration](https://code.visualstudio.com/docs/editor/tasks)** - Automate development tasks
- **[Debugging Guide](https://code.visualstudio.com/docs/editor/debugging)** - Debug configuration and usage

### PowerShell Resources

- **[PowerShell Documentation](https://learn.microsoft.com/en-us/powershell/index.md)** - Official PowerShell documentation
- **[PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer)** - PowerShell code analysis tool
- **[PowerShell Best Practices](https://github.com/PoshCode/PowerShellPracticeAndStyle)** - Community style guide

### Community Resources

- **[VS Code Blog](https://code.visualstudio.com/blogs)** - Latest features and updates
- **[r/vscode](https://www.reddit.com/r/vscode/index.md)** - VS Code community on Reddit
- **[Stack Overflow - VS Code](https://stackoverflow.com/questions/tagged/visual-studio-code)** - Q&A and troubleshooting
- **[VS Code GitHub](https://github.com/microsoft/vscode)** - Report issues and feature requests

### Video Tutorials

- **[VS Code YouTube Channel](https://www.youtube.com/channel/UCs5Y5_7XK8HLDX0SLNwkd3w)** - Official tutorials and tips
- **[PowerShell on YouTube](https://www.youtube.com/channel/UCMhQH-yJlr4_XHkwNunfMog)** - PowerShell team content

### Learning Resources

- **[Learn VS Code](https://code.visualstudio.com/learn)** - Interactive tutorials
- **[PowerShell Learning Path](https://learn.microsoft.com/en-us/training/paths/powershell/index.md)** - Microsoft Learn courses
- **[Git Learning Resources](https://git-scm.com/doc)** - Git documentation and tutorials

---

Last updated: {{ site.time | date: "%Y-%m-%d" }}
