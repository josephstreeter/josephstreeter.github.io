---
title: "Local Development Setup"
description: "Configure local development environment for Documentation as Code"
tags: ["local-development", "docfx", "vscode", "git", "workflow"]
category: "development"
difficulty: "beginner"
last_updated: "2025-07-06"
---

## Local Development Setup

Setting up an effective local development environment is crucial for productive Documentation as Code workflows. This guide covers installation, configuration, and optimization of tools for writing, building, and previewing documentation locally.

## Prerequisites

### System Requirements

**Minimum Requirements:**

| Component | Requirement | Recommended |
|-----------|-------------|-------------|
| **Operating System** | Windows 10, macOS 10.14, Ubuntu 18.04 | Latest versions |
| **RAM** | 4 GB | 8 GB or more |
| **Storage** | 5 GB free space | 10 GB or more |
| **Network** | Internet connection | Broadband |

### Account Prerequisites

- **Azure DevOps** account with repository access
- **Git** credentials configured
- **Node.js** for package management
- **Administrative** privileges for software installation

## Core Tool Installation

### Git Installation and Configuration

**Install Git:**

```bash
# Windows (using Chocolatey)
choco install git

# macOS (using Homebrew)
brew install git

# Ubuntu/Debian
sudo apt update && sudo apt install git
```

**Configure Git:**

```bash
# Set global configuration
git config --global user.name "Your Name"
git config --global user.email "your.email@organization.com"
git config --global init.defaultBranch main

# Configure line endings
git config --global core.autocrlf input  # macOS/Linux
git config --global core.autocrlf true   # Windows

# Configure credential helper
git config --global credential.helper manager-core
```

### Node.js and Package Management

**Install Node.js:**

```bash
# Using Node Version Manager (recommended)
# Install nvm first, then:
nvm install 18
nvm use 18

# Verify installation
node --version
npm --version
```

**Global Package Installation:**

```bash
# Essential packages for documentation development
npm install -g markdownlint-cli
npm install -g markdown-link-check
npm install -g live-server
npm install -g json-server
```

### DocFX Installation

**Windows Installation:**

```powershell
# Using Chocolatey (recommended)
choco install docfx

# Using .NET CLI
dotnet tool install -g docfx

# Verify installation
docfx --version
```

**Cross-Platform Installation:**

```bash
# Using .NET CLI (all platforms)
dotnet tool install -g docfx

# Alternative: Download binary
wget https://github.com/dotnet/docfx/releases/latest/download/docfx.zip
unzip docfx.zip -d ~/.local/bin/docfx
```

## Development Environment Setup

### Visual Studio Code Configuration

**Essential Extensions:**

```json
{
  "recommendations": [
    "ms-vscode.vscode-markdown",
    "davidanson.vscode-markdownlint",
    "bierner.markdown-preview-enhanced",
    "ms-vscode.vscode-json",
    "redhat.vscode-yaml",
    "ms-vscode.powershell",
    "ms-vscode.azure-account",
    "ms-azuretools.vscode-azurestaticwebapps",
    "github.vscode-pull-request-github",
    "gruntfuggly.todo-tree",
    "streetsidesoftware.code-spell-checker"
  ]
}
```

**VS Code Settings:**

```json
{
  "markdown.preview.scrollEditorWithPreview": true,
  "markdown.preview.scrollPreviewWithEditor": true,
  "markdownlint.config": {
    "MD013": { "line_length": 120 },
    "MD033": false,
    "MD041": false
  },
  "files.associations": {
    "*.yml": "yaml",
    "*.yaml": "yaml",
    "toc.yml": "yaml"
  },
  "yaml.schemas": {
    "https://json.schemastore.org/docfx.json": "docfx.json"
  },
  "git.enableSmartCommit": true,
  "git.autofetch": true,
  "editor.wordWrap": "on",
  "editor.tabSize": 2,
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true
}
```

**Workspace Configuration (.vscode/settings.json):**

```json
{
  "workbench.colorCustomizations": {
    "activityBar.background": "#1f4e79",
    "activityBar.foreground": "#ffffff"
  },
  "markdown.preview.fontFamily": "Segoe UI, system-ui, sans-serif",
  "markdown.preview.fontSize": 14,
  "spellright.language": ["en"],
  "spellright.documentTypes": ["markdown", "plaintext"],
  "todo-tree.tree.showScanModeButton": false,
  "todo-tree.highlights.defaultHighlight": {
    "icon": "alert",
    "type": "tag",
    "foreground": "red",
    "background": "white",
    "opacity": 50,
    "iconColour": "blue"
  },
  "todo-tree.highlights.customHighlight": {
    "TODO": {
      "icon": "check",
      "iconColour": "yellow"
    },
    "FIXME": {
      "icon": "alert",
      "iconColour": "red"
    },
    "NOTE": {
      "icon": "note",
      "iconColour": "blue"
    }
  }
}
```

### Repository Setup

**Clone Repository:**

```bash
# Clone the documentation repository
git clone https://dev.azure.com/organization/project/_git/docs
cd docs

# Set up upstream remote (if forking workflow)
git remote add upstream https://dev.azure.com/organization/project/_git/docs

# Verify remotes
git remote -v
```

**Local Branch Setup:**

```bash
# Create and switch to development branch
git checkout -b feature/local-setup

# Set up branch tracking
git push -u origin feature/local-setup

# Create standard branch aliases
git config alias.co checkout
git config alias.br branch
git config alias.ci commit
git config alias.st status
```

## Local Build Configuration

### DocFX Project Setup

**Initialize Local Configuration:**

```bash
# Navigate to project root
cd docs

# Verify DocFX configuration
docfx docfx.json --dry-run

# Create local serving configuration
cp docfx.json docfx.local.json
```

**Local DocFX Configuration (docfx.local.json):**

```json
{
  "metadata": [
    {
      "src": [
        {
          "files": ["**/*.csproj"],
          "exclude": ["**/bin/**", "**/obj/**"],
          "src": "../src"
        }
      ],
      "dest": "api",
      "disableGitFeatures": true
    }
  ],
  "build": {
    "content": [
      {
        "files": [
          "**/*.{md,yml}",
          "toc.yml",
          "index.md"
        ],
        "exclude": [
          "_site/**",
          "node_modules/**",
          ".git/**"
        ]
      }
    ],
    "resource": [
      {
        "files": [
          "images/**",
          "**/*.{png,jpg,jpeg,gif,svg,ico}"
        ]
      }
    ],
    "output": "_site",
    "template": ["default"],
    "globalMetadata": {
      "_appTitle": "Documentation Hub (Local)",
      "_enableSearch": true,
      "_disableContribution": true
    },
    "serve": {
      "port": 8080,
      "hostname": "localhost"
    }
  }
}
```

### Build Scripts

**Package.json for Local Development:**

```json
{
  "name": "documentation-site",
  "version": "1.0.0",
  "description": "Documentation as Code local development",
  "scripts": {
    "build": "docfx docfx.local.json",
    "serve": "docfx serve _site --port 8080",
    "build-serve": "docfx docfx.local.json --serve",
    "clean": "rimraf _site",
    "lint": "markdownlint content/**/*.md",
    "lint-fix": "markdownlint content/**/*.md --fix",
    "link-check": "markdown-link-check content/**/*.md",
    "validate": "npm run lint && npm run link-check",
    "watch": "chokidar 'content/**/*.md' 'toc.yml' 'docfx.json' -c 'npm run build'"
  },
  "devDependencies": {
    "chokidar-cli": "^3.0.0",
    "markdownlint-cli": "^0.37.0",
    "markdown-link-check": "^3.11.2",
    "rimraf": "^5.0.5"
  }
}
```

**PowerShell Build Script (build.ps1):**

```powershell
#!/usr/bin/env pwsh
param(
    [Parameter(Position=0)]
    [ValidateSet("build", "serve", "clean", "validate", "watch")]
    [string]$Action = "build",
    
    [switch]$Production,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

function Write-Status {
    param([string]$Message)
    Write-Host "🔄 $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

# Configuration
$ConfigFile = if ($Production) { "docfx.json" } else { "docfx.local.json" }
$OutputDir = "_site"

switch ($Action) {
    "clean" {
        Write-Status "Cleaning output directory..."
        if (Test-Path $OutputDir) {
            Remove-Item $OutputDir -Recurse -Force
        }
        Write-Success "Clean completed"
    }
    
    "validate" {
        Write-Status "Running validation checks..."
        
        # Markdown linting
        Write-Status "Checking markdown formatting..."
        markdownlint content/**/*.md
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Markdown linting failed"
            exit 1
        }
        
        # Link checking
        Write-Status "Checking links..."
        markdown-link-check content/**/*.md --config .mlc-config.json
        
        Write-Success "Validation completed"
    }
    
    "build" {
        Write-Status "Building documentation..."
        
        # Clean first
        & $PSScriptRoot/build.ps1 -Action clean
        
        # Build
        $buildArgs = @($ConfigFile)
        if ($Verbose) { $buildArgs += "--logLevel", "Verbose" }
        
        docfx @buildArgs
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Build failed"
            exit 1
        }
        
        Write-Success "Build completed successfully"
        Write-Host "📂 Output: $OutputDir" -ForegroundColor Yellow
    }
    
    "serve" {
        Write-Status "Starting local server..."
        if (-not (Test-Path $OutputDir)) {
            Write-Status "No build found, building first..."
            & $PSScriptRoot/build.ps1 -Action build
        }
        
        Write-Success "Server starting at http://localhost:8080"
        docfx serve $OutputDir --port 8080
    }
    
    "watch" {
        Write-Status "Starting watch mode..."
        Write-Host "Watching for file changes... Press Ctrl+C to stop" -ForegroundColor Yellow
        
        # Initial build
        & $PSScriptRoot/build.ps1 -Action build
        
        # Watch for changes
        chokidar "content/**/*.md" "toc.yml" "docfx.json" --command "pwsh -File $PSScriptRoot/build.ps1 -Action build"
    }
}
```

## Development Workflow

### Daily Workflow

**Morning Setup:**

```bash
# 1. Start your development session
cd docs

# 2. Update from remote
git fetch origin
git pull origin main

# 3. Create or switch to feature branch
git checkout -b feature/new-documentation
# or
git checkout existing-feature-branch

# 4. Install/update dependencies
npm install

# 5. Start development server
npm run build-serve
```

**Development Loop:**

```bash
# 1. Make changes to markdown files
# 2. Preview in browser (http://localhost:8080)
# 3. Validate changes
npm run validate

# 4. Commit changes
git add .
git commit -m "Add: new documentation section"

# 5. Push to remote
git push origin feature/new-documentation
```

### File Organization

**Local Workspace Structure:**

```text
docs/
├── .vscode/                    # VS Code configuration
│   ├── settings.json          # Workspace settings
│   ├── extensions.json        # Recommended extensions
│   └── tasks.json             # Build tasks
├── content/                   # Documentation content
│   ├── articles/              # Long-form articles
│   ├── tutorials/             # Step-by-step guides
│   ├── reference/             # Reference materials
│   └── api/                   # API documentation
├── images/                    # Image assets
├── templates/                 # Custom DocFX templates
├── tools/                     # Build and utility scripts
├── _site/                     # Generated output (gitignored)
├── node_modules/              # Node.js dependencies (gitignored)
├── .gitignore                 # Git ignore patterns
├── docfx.json                 # Production DocFX config
├── docfx.local.json           # Local development config
├── package.json               # Node.js dependencies
├── README.md                  # Repository documentation
└── toc.yml                    # Table of contents
```

## Quality Assurance Tools

### Pre-commit Hooks

**Git Pre-commit Hook (.git/hooks/pre-commit):**

```bash
#!/bin/sh
# Documentation pre-commit hook

echo "🔍 Running pre-commit checks..."

# Check for large files
echo "📁 Checking file sizes..."
large_files=$(find . -size +5M -type f -not -path "./.git/*" -not -path "./node_modules/*")
if [ -n "$large_files" ]; then
    echo "❌ Large files detected (>5MB):"
    echo "$large_files"
    echo "💡 Consider optimizing images or using Git LFS"
    exit 1
fi

# Markdown linting
echo "📝 Checking markdown formatting..."
if command -v markdownlint >/dev/null 2>&1; then
    if ! markdownlint content/**/*.md; then
        echo "❌ Markdown linting failed"
        echo "💡 Run 'npm run lint-fix' to automatically fix issues"
        exit 1
    fi
else
    echo "⚠️  markdownlint not found, skipping markdown checks"
fi

# DocFX build test
echo "🏗️  Testing DocFX build..."
if command -v docfx >/dev/null 2>&1; then
    if ! docfx docfx.local.json --dry-run >/dev/null 2>&1; then
        echo "❌ DocFX build validation failed"
        exit 1
    fi
else
    echo "⚠️  DocFX not found, skipping build test"
fi

echo "✅ Pre-commit checks passed!"
```

### Live Validation

**VS Code Tasks (.vscode/tasks.json):**

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Build Documentation",
      "type": "shell",
      "command": "docfx",
      "args": ["docfx.local.json"],
      "group": {
        "kind": "build",
        "isDefault": true
      },
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      },
      "problemMatcher": "$docfx"
    },
    {
      "label": "Serve Documentation",
      "type": "shell",
      "command": "docfx",
      "args": ["serve", "_site", "--port", "8080"],
      "group": "test",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      },
      "isBackground": true
    },
    {
      "label": "Validate Content",
      "type": "shell",
      "command": "npm",
      "args": ["run", "validate"],
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

## Troubleshooting

### Common Issues

**Build Failures:**

```bash
# Clear cache and rebuild
rm -rf _site node_modules
npm install
docfx docfx.local.json --cleanupCacheHistory

# Check for file permission issues
find . -name "*.md" -not -readable

# Validate JSON configuration
node -e "console.log(JSON.parse(require('fs').readFileSync('docfx.local.json')))"
```

**Performance Issues:**

```bash
# Optimize image assets
npm install -g imagemin-cli
imagemin "images/*.{jpg,png}" --out-dir="images" --plugin=mozjpeg --plugin=pngquant

# Check for large files
find . -size +1M -type f -not -path "./.git/*" -not -path "./node_modules/*"
```

**Sync Issues:**

```bash
# Reset local repository state
git fetch origin
git reset --hard origin/main
git clean -fd

# Resolve merge conflicts
git status
git mergetool
```

### Diagnostic Tools

**System Health Check Script:**

```bash
#!/bin/bash
# health-check.sh

echo "🏥 Documentation Development Environment Health Check"
echo "=================================================="

# Check Node.js
echo -n "Node.js: "
if command -v node >/dev/null 2>&1; then
    echo "✅ $(node --version)"
else
    echo "❌ Not installed"
fi

# Check npm
echo -n "npm: "
if command -v npm >/dev/null 2>&1; then
    echo "✅ $(npm --version)"
else
    echo "❌ Not installed"
fi

# Check DocFX
echo -n "DocFX: "
if command -v docfx >/dev/null 2>&1; then
    echo "✅ $(docfx --version)"
else
    echo "❌ Not installed"
fi

# Check Git
echo -n "Git: "
if command -v git >/dev/null 2>&1; then
    echo "✅ $(git --version)"
else
    echo "❌ Not installed"
fi

# Check markdownlint
echo -n "markdownlint: "
if command -v markdownlint >/dev/null 2>&1; then
    echo "✅ Available"
else
    echo "⚠️  Not installed (npm install -g markdownlint-cli)"
fi

# Check project files
echo ""
echo "📁 Project Files:"
echo -n "docfx.json: "
if [ -f "docfx.json" ]; then echo "✅ Found"; else echo "❌ Missing"; fi

echo -n "package.json: "
if [ -f "package.json" ]; then echo "✅ Found"; else echo "❌ Missing"; fi

echo -n "toc.yml: "
if [ -f "toc.yml" ]; then echo "✅ Found"; else echo "❌ Missing"; fi

echo ""
echo "🔗 Git Status:"
git status --porcelain | head -5
```

## Next Steps

After setting up your local development environment:

1. **[Collaboration Process](collaboration.md)** - Learn team collaboration workflows
2. **[Quality Assurance](quality-assurance.md)** - Implement quality checks
3. **[Content Creation](../content/templates.md)** - Start creating documentation
4. **[Style Guide](../content/style-guide.md)** - Follow writing standards

## Additional Resources

- [Visual Studio Code Documentation](https://code.visualstudio.com/docs)
- [DocFX Getting Started](https://dotnet.github.io/docfx/tutorial/docfx_getting_started.html)
- [Git Documentation](https://git-scm.com/doc)
- [Node.js Documentation](https://nodejs.org/en/docs/index.md)

---

*This local development setup guide provides everything needed to create an efficient and productive documentation development environment.*
