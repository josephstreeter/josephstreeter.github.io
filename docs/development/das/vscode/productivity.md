---
title: "Productivity Features"
description: "Advanced VS Code features, keyboard shortcuts, and workflow optimizations for maximum documentation productivity"
tags: ["productivity", "shortcuts", "workflow", "efficiency", "features"]
category: "productivity"
difficulty: "intermediate"
last_updated: "2025-07-06"
---

## Productivity Features

Maximize your documentation efficiency with advanced VS Code features, keyboard shortcuts, and workflow optimizations designed specifically for technical writing and Documentation as Code workflows.

## Essential Keyboard Shortcuts

### Markdown-Specific Shortcuts

Master these shortcuts for faster markdown editing:

| Shortcut | Action | Description |
|----------|--------|-------------|
| `Ctrl+Shift+V` | Preview Side by Side | Open markdown preview in split view |
| `Ctrl+K V` | Preview in Tab | Open markdown preview in new tab |
| `Ctrl+Shift+O` | Document Outline | Show document structure and navigation |
| `Ctrl+B` | Bold Text | Toggle bold formatting |
| `Ctrl+I` | Italic Text | Toggle italic formatting |
| `Ctrl+Shift+]` | Increase Heading Level | Convert text to heading (h1, h2, etc.) |
| `Ctrl+Shift+[` | Decrease Heading Level | Reduce heading level |

### Navigation Shortcuts

Efficiently navigate large documentation projects:

| Shortcut | Action | Description |
|----------|--------|-------------|
| `Ctrl+P` | Quick Open | Find and open files quickly |
| `Ctrl+Shift+P` | Command Palette | Access all VS Code commands |
| `Ctrl+G` | Go to Line | Jump to specific line number |
| `Ctrl+Shift+O` | Go to Symbol | Navigate to headings and sections |
| `F12` | Go to Definition | Follow cross-references and links |
| `Alt+Left/Right` | Navigate Back/Forward | Move through navigation history |

### Editing Shortcuts

Speed up content creation and editing:

| Shortcut | Action | Description |
|----------|--------|-------------|
| `Ctrl+D` | Select Next Occurrence | Multi-cursor editing |
| `Ctrl+Shift+L` | Select All Occurrences | Edit all instances simultaneously |
| `Alt+Up/Down` | Move Line | Reorder content lines |
| `Shift+Alt+Up/Down` | Copy Line | Duplicate lines or blocks |
| `Ctrl+/` | Toggle Comment | Comment/uncomment lines |
| `Ctrl+Shift+K` | Delete Line | Remove entire line |

## Advanced VS Code Features

### Multi-Cursor Editing

Use multi-cursor functionality for efficient batch editing:

#### Selecting Multiple Instances

1. **Select word**: `Ctrl+D` to select next occurrence
2. **Select all**: `Ctrl+Shift+L` to select all occurrences
3. **Column selection**: `Shift+Alt+Drag` for column editing

#### Practical Examples

**Updating multiple headings:**

```markdown
# Getting Started
# Configuration
# Deployment
```

Select "Getting Started", then `Ctrl+D` twice to select all headings, then type to replace all simultaneously.

**Formatting lists:**

```markdown
Item 1
Item 2  
Item 3
```

Use `Alt+Click` to place cursors, then type `-` to convert to bulleted list.

### Snippets and Templates

#### Built-in Markdown Snippets

VS Code includes helpful markdown snippets:

- `code` → Inline code span
- `codeblock` → Fenced code block
- `table` → Markdown table template
- `link` → Link reference
- `image` → Image reference

#### Custom Documentation Snippets

Create project-specific snippets for common patterns:

```json
{
  "API Endpoint Documentation": {
    "prefix": "api-endpoint",
    "body": [
      "### ${1:METHOD} ${2:/api/endpoint}",
      "",
      "**Description:** ${3:Endpoint description}",
      "",
      "**Parameters:**",
      "",
      "| Parameter | Type | Required | Description |",
      "|-----------|------|----------|-------------|",
      "| ${4:param} | ${5:string} | ${6:Yes} | ${7:Description} |",
      "",
      "**Response:**",
      "",
      "```json",
      "{",
      "  \"${8:key}\": \"${9:value}\"",
      "}",
      "```",
      "$0"
    ],
    "description": "API endpoint documentation template"
  }
}
```

### Zen Mode and Focus

#### Distraction-Free Writing

Enable Zen Mode for focused writing sessions:

- **Toggle Zen Mode**: `Ctrl+K Z`
- **Exit Zen Mode**: `Escape` twice

#### Centered Layout

Configure centered layout for better reading experience:

```json
{
  "zenMode.centerLayout": true,
  "zenMode.hideTabs": true,
  "zenMode.hideStatusBar": true,
  "zenMode.hideActivityBar": true,
  "zenMode.fullScreen": false
}
```

### File Management

#### Quick File Operations

Efficiently manage documentation files:

| Action | Shortcut | Description |
|--------|----------|-------------|
| New File | `Ctrl+N` | Create new document |
| Save | `Ctrl+S` | Save current file |
| Save All | `Ctrl+K S` | Save all open files |
| Close Tab | `Ctrl+W` | Close current tab |
| Reopen Tab | `Ctrl+Shift+T` | Reopen recently closed tab |

#### File Explorer Productivity

Navigate and manage files efficiently:

- **Toggle Sidebar**: `Ctrl+B`
- **Focus Explorer**: `Ctrl+Shift+E`
- **Create File**: `a` (when explorer is focused)
- **Create Folder**: `Shift+a` (when explorer is focused)
- **Rename**: `F2` (when file is selected)

## Search and Replace Mastery

### Advanced Search Features

#### Multi-file Search

Search across entire documentation projects:

1. **Open Search**: `Ctrl+Shift+F`
2. **Include/Exclude**: Use glob patterns to filter files
3. **Regex Search**: Enable regex for complex patterns
4. **Replace All**: Batch replace across multiple files

#### Search Patterns for Documentation

**Find broken links:**

```regex
\[.*?\]\((?!http).*?\)
```

**Find TODO comments:**

```regex
<!-- TODO.*? -->
```

**Find missing alt text:**

```regex
!\[?\]\(.*?\)
```

### Find and Replace Workflows

#### Standardizing Terminology

Use find and replace to maintain consistent terminology:

1. **Case-sensitive replacement**: Toggle case sensitivity
2. **Whole word matching**: Avoid partial replacements
3. **Preview changes**: Review before applying

#### Batch Formatting Updates

**Converting heading styles:**

- Find: `# (.+)`
- Replace: `## $1`

**Updating link formats:**

- Find: `\[(.+?)\]\((.+?)\)`
- Replace: `[$1]($2){:target="_blank"}`

## Live Preview and Editing

### Split View Productivity

Optimize split view for efficient writing:

#### Horizontal vs Vertical Split

- **Vertical Split**: `Ctrl+\` - Better for wide monitors
- **Horizontal Split**: `Ctrl+Shift+\` - Better for reviewing long content

#### Synchronized Scrolling

Enable synchronized scrolling between editor and preview:

```json
{
  "markdown.preview.scrollPreviewWithEditor": true,
  "markdown.preview.scrollEditorWithPreview": true
}
```

### Real-time Collaboration

#### Live Share for Documentation

Use Live Share for collaborative editing:

1. **Start Session**: `Ctrl+Shift+P` → "Live Share: Start Session"
2. **Share Link**: Send invitation to collaborators
3. **Shared Terminal**: Collaborate on builds and deployments
4. **Voice Chat**: Integrated communication

## Task and Project Management

### Integrated Terminal

Maximize terminal productivity for documentation workflows:

#### Multiple Terminal Sessions

- **New Terminal**: `Ctrl+Shift+`` (backtick)
- **Split Terminal**: `Ctrl+Shift+5`
- **Switch Terminal**: `Ctrl+PageUp/PageDown`

#### Terminal Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+C` | Copy selection |
| `Ctrl+V` | Paste |
| `Ctrl+A` | Select all |
| `Ctrl+L` | Clear terminal |

### Tasks and Build Automation

#### Predefined Tasks

Configure common documentation tasks:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Build DocFX",
      "type": "shell",
      "command": "docfx",
      "args": ["build"],
      "group": "build",
      "problemMatcher": []
    },
    {
      "label": "Serve DocFX",
      "type": "shell", 
      "command": "docfx",
      "args": ["serve", "_site"],
      "group": "build",
      "isBackground": true
    }
  ]
}
```

#### Task Shortcuts

- **Run Task**: `Ctrl+Shift+P` → "Tasks: Run Task"
- **Build**: `Ctrl+Shift+B` (if configured as build task)

## Extensions for Enhanced Productivity

### Must-Have Productivity Extensions

#### Core Extensions

```bash
# Bracket management
code --install-extension ms-vscode.bracketPairColorizer

# Git integration
code --install-extension mhutchie.git-graph

# File management
code --install-extension alefragnani.project-manager

# Productivity tools
code --install-extension formulahendry.auto-rename-tag
code --install-extension ms-vscode.vscode-json
```

#### Documentation-Specific Extensions

```bash
# Enhanced markdown editing
code --install-extension yzhang.markdown-all-in-one
code --install-extension shd101wyy.markdown-preview-enhanced

# Diagram support
code --install-extension bierner.markdown-mermaid
code --install-extension hediet.vscode-drawio

# Table management
code --install-extension phplasma.csv-to-table
```

### Extension Configuration

#### Optimized Settings

```json
{
  // Auto-save for continuous backup
  "files.autoSave": "afterDelay",
  "files.autoSaveDelay": 10000,
  
  // Enhanced search
  "search.smartCase": true,
  "search.useGlobalIgnoreFiles": true,
  
  // Improved Git integration
  "git.enableCommitSigning": true,
  "git.autofetch": true,
  
  // Bracket pair colorization
  "editor.bracketPairColorization.enabled": true,
  "editor.guides.bracketPairs": "active"
}
```

## Workflow Optimization

### Documentation Project Templates

#### Project Structure Template

Create standardized project structures:

```text
docs/
├── .vscode/
│   ├── settings.json
│   ├── extensions.json
│   └── tasks.json
├── images/
├── templates/
├── index.md
├── toc.yml
└── docfx.json
```

#### Automated Setup Script

```powershell
# Setup new documentation project
param(
    [string]$ProjectName
)

New-Item -Path $ProjectName -ItemType Directory
Set-Location $ProjectName

# Create directory structure
@('docs', 'images', 'templates', '.vscode') | ForEach-Object {
    New-Item -Path $_ -ItemType Directory
}

# Copy configuration templates
Copy-Item -Path "..\.templates\.vscode\*" -Destination ".vscode\"
Copy-Item -Path "..\.templates\docfx.json" -Destination "."

Write-Host "Documentation project '$ProjectName' created successfully!"
```

### Content Management Workflows

#### Content Planning

Use VS Code for content planning and organization:

1. **Create outline files**: Use `.md` files for planning
2. **Use TODO comments**: Track content requirements
3. **Link drafts**: Connect related content pieces
4. **Version control**: Track content evolution

#### Review and Quality Assurance

Implement systematic review processes:

1. **Spell checking**: Use Code Spell Checker extension
2. **Link validation**: Check internal and external links
3. **Style consistency**: Apply markdown linting rules
4. **Content review**: Use Live Share for collaborative reviews

## Performance Optimization

### VS Code Performance Settings

Optimize VS Code for large documentation projects:

```json
{
  // Reduce file watching overhead
  "files.watcherExclude": {
    "**/.git/**": true,
    "**/node_modules/**": true,
    "**/_site/**": true,
    "**/dist/**": true
  },
  
  // Limit search scope
  "search.exclude": {
    "**/node_modules": true,
    "**/bower_components": true,
    "**/_site": true
  },
  
  // Optimize editor performance
  "editor.suggest.showWords": false,
  "editor.hover.delay": 1000,
  "search.searchOnType": false
}
```

### Memory Management

Monitor and optimize VS Code memory usage:

- **Check Extension Impact**: Use Developer Tools (`Ctrl+Shift+I`)
- **Disable Unused Extensions**: Reduce memory footprint
- **Restart Regularly**: Clear accumulated memory usage
- **Use Workspaces**: Organize projects efficiently

## Automation and Scripts

### VS Code Tasks for Documentation

#### Common Documentation Tasks

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Check Links",
      "type": "shell",
      "command": "markdown-link-check",
      "args": ["**/*.md"],
      "group": "test"
    },
    {
      "label": "Spell Check All",
      "type": "shell",
      "command": "cspell",
      "args": ["**/*.md"],
      "group": "test"
    },
    {
      "label": "Generate TOC",
      "type": "shell",
      "command": "doctoc",
      "args": ["**/*.md"],
      "group": "build"
    }
  ]
}
```

### PowerShell Integration

Leverage PowerShell for documentation automation:

```powershell
# Generate file listing for documentation
function Get-DocStructure {
    param([string]$Path = ".")
    
    Get-ChildItem -Path $Path -Recurse -Name | 
    Where-Object { $_ -like "*.md" } |
    ForEach-Object {
        $relativePath = $_.Replace('\', '/')
        "- [$_]($relativePath)"
    }
}

# Word count for documentation project
function Get-DocWordCount {
    Get-ChildItem -Filter "*.md" -Recurse |
    ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        $wordCount = ($content -split '\s+').Count
        [PSCustomObject]@{
            File = $_.Name
            Words = $wordCount
            Path = $_.FullName
        }
    } | Sort-Object Words -Descending
}
```

---

*Next: Learn about [collaboration workflows](collaboration.md) for team-based documentation projects.*
