---
title: "DocFX Configuration"
description: "Configure DocFX for static documentation site generation"
tags: ["docfx", "configuration", "static-site", "markdown", "documentation"]
category: "development"
difficulty: "intermediate"
last_updated: "2025-07-06"
---

## DocFX Configuration

DocFX is Microsoft's static site generator designed specifically for documentation. This guide covers comprehensive configuration for a Documentation as Code implementation, including advanced features, customization options, and integration with Azure DevOps.

## Prerequisites

Before configuring DocFX, ensure you have:

- DocFX installed locally and in build environments
- Understanding of JSON configuration files
- Familiarity with Markdown syntax
- Access to your Azure DevOps repository

## Installation and Setup

### Local Installation

**Windows Installation:**

```powershell
# Install via Chocolatey (recommended)
choco install docfx

# Or install via .NET Tool
dotnet tool install -g docfx

# Verify installation
docfx --version
```

**Cross-Platform Installation:**

```bash
# Install via .NET Tool (recommended)
dotnet tool install -g docfx

# Or download from GitHub releases
wget https://github.com/dotnet/docfx/releases/latest/download/docfx.zip
unzip docfx.zip -d /usr/local/bin/docfx
```

### Project Initialization

**Initialize New DocFX Project:**

```bash
# Create new DocFX project
docfx init

# Or create with specific template
docfx init --output ./docs --template default
```

## Core Configuration

### docfx.json Structure

The `docfx.json` file is the heart of DocFX configuration:

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
      "disableGitFeatures": false,
      "disableDefaultFilter": false
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
          "templates/**",
          "**/bin/**",
          "**/obj/**"
        ]
      }
    ],
    "resource": [
      {
        "files": [
          "images/**",
          "files/**",
          "**/*.{png,jpg,jpeg,gif,svg,ico,pdf}"
        ],
        "exclude": [
          "_site/**",
          "templates/**"
        ]
      }
    ],
    "output": "_site",
    "template": [
      "default",
      "templates/custom"
    ],
    "globalMetadata": {
      "_appTitle": "Documentation Hub",
      "_appName": "Documentation Hub",
      "_appLogoPath": "images/logo.svg",
      "_appFaviconPath": "images/favicon.ico",
      "_enableSearch": true,
      "_disableContribution": false,
      "_disableBreadcrumb": false,
      "_enableNewTab": true,
      "_disableAffix": false,
      "_disableNavbar": false,
      "_disableSideFilter": false,
      "_gitContribute": {
        "repo": "https://dev.azure.com/organization/project/_git/docs",
        "branch": "main"
      },
      "_gitUrlPattern": "azure"
    },
    "fileMetadata": {
      "_keywords": {
        "articles/**/*.md": ["documentation", "guide", "tutorial"],
        "api/**/*.md": ["api", "reference", "documentation"]
      },
      "_description": {
        "articles/**/*.md": "Comprehensive documentation and guides",
        "api/**/*.md": "API reference documentation"
      }
    },
    "overwrite": [
      "apidoc/*.md"
    ],
    "xref": [
      "https://xref.docs.microsoft.com/query?uid={uid}"
    ],
    "dest": "_site"
  },
  "serve": {
    "port": 8080,
    "hostname": "localhost"
  }
}
```

### Content Organization

**Recommended Directory Structure:**

```text
docs/
├── articles/                  # Long-form documentation
│   ├── getting-started/       # Getting started guides
│   ├── tutorials/             # Step-by-step tutorials
│   ├── how-to/               # How-to guides
│   └── concepts/             # Conceptual information
├── api/                      # API documentation (auto-generated)
├── reference/                # Reference materials
│   ├── cli/                  # Command-line interface docs
│   ├── configuration/        # Configuration references
│   └── troubleshooting/      # Troubleshooting guides
├── images/                   # Image assets
│   ├── articles/             # Article-specific images
│   ├── api/                  # API documentation images
│   └── shared/               # Shared images
├── templates/                # Custom DocFX templates
│   └── custom/               # Custom template files
├── tools/                    # Build and utility scripts
├── docfx.json               # DocFX configuration
├── toc.yml                  # Global table of contents
├── index.md                 # Site homepage
└── README.md                # Repository documentation
```

### Table of Contents Configuration

**Global toc.yml:**

```yaml
# Main navigation structure
- name: Home
  href: index.md
- name: Getting Started
  href: articles/getting-started/toc.yml
- name: Tutorials
  href: articles/tutorials/toc.yml
- name: How-to Guides
  href: articles/how-to/toc.yml
- name: API Reference
  href: api/toc.yml
- name: Reference
  href: reference/toc.yml
```

**Section-specific toc.yml:**

```yaml
# articles/getting-started/toc.yml
- name: Overview
  href: index.md
- name: Prerequisites
  href: prerequisites.md
- name: Quick Start
  href: quick-start.md
- name: First Steps
  href: first-steps.md
  items:
  - name: Installation
    href: installation.md
  - name: Configuration
    href: configuration.md
  - name: Verification
    href: verification.md
```

## Advanced Configuration

### Custom Templates

**Creating Custom Templates:**

```text
templates/custom/
├── partials/
│   ├── head.tmpl.partial      # Custom head section
│   ├── navbar.tmpl.partial    # Custom navigation
│   ├── footer.tmpl.partial    # Custom footer
│   └── breadcrumb.tmpl.partial # Custom breadcrumb
├── styles/
│   ├── main.css              # Custom styles
│   └── docfx.css             # DocFX overrides
├── fonts/                    # Custom fonts
├── layout/
│   ├── _master.tmpl          # Master layout
│   └── conceptual.html.primary.tmpl # Content templates
└── ManagedReference.html.primary.tmpl # API reference template
```

**Custom CSS Example:**

```css
/* templates/custom/styles/main.css */
:root {
  --primary-color: #0078d4;
  --secondary-color: #106ebe;
  --accent-color: #005a9e;
  --text-color: #323130;
  --background-color: #ffffff;
  --border-color: #edebe9;
}

.navbar-brand {
  font-weight: 600;
  color: var(--primary-color);
}

.article {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.alert {
  border-radius: 4px;
  border-left: 4px solid var(--primary-color);
  padding: 15px;
  margin: 20px 0;
}

.code-header {
  background-color: var(--border-color);
  padding: 10px 15px;
  border-radius: 4px 4px 0 0;
  font-weight: 600;
}

pre {
  border-radius: 0 0 4px 4px;
  margin-top: 0;
}

@media (max-width: 768px) {
  .article {
    padding: 10px;
  }
  
  .sidetoc {
    position: relative;
    width: 100%;
  }
}
```

### Metadata Configuration

**Front Matter Standards:**

```yaml
---
title: "Page Title"
description: "Page description for SEO and previews"
author: "Author Name"
ms.author: "author-alias"
ms.date: "2025-07-06"
ms.topic: "conceptual" # or "reference", "tutorial", "how-to"
ms.custom: "tags"
keywords: ["keyword1", "keyword2", "keyword3"]
uid: "unique-identifier"
---
```

**Global Metadata Configuration:**

```json
{
  "globalMetadata": {
    "_appTitle": "Your Documentation Site",
    "_appName": "Your App Name",
    "_appLogoPath": "images/logo.svg",
    "_appFaviconPath": "images/favicon.ico",
    "_enableSearch": true,
    "_gitContribute": {
      "repo": "https://dev.azure.com/org/project/_git/docs",
      "branch": "main",
      "path": "/"
    },
    "_gitUrlPattern": "azure",
    "author": "Your Organization",
    "ms.prod": "your-product",
    "ms.technology": "documentation",
    "feedback_system": "Azure DevOps",
    "feedback_product_url": "https://dev.azure.com/org/project/_workitems"
  }
}
```

### Plugin Configuration

**Available Plugins:**

```json
{
  "build": {
    "plugins": [
      "memberpage",
      "rest.tagpage",
      "Microsoft.DocAsCode.EntityModel.Plugins.PlantUmlPlugin"
    ],
    "pluginConfigurations": {
      "memberpage": {
        "enabled": true
      },
      "rest.tagpage": {
        "enabled": true,
        "groupByTag": true
      }
    }
  }
}
```

## Integration Features

### Azure DevOps Integration

**Git Configuration:**

```json
{
  "globalMetadata": {
    "_gitContribute": {
      "repo": "https://dev.azure.com/organization/project/_git/repository",
      "branch": "main",
      "path": "/"
    },
    "_gitUrlPattern": "azure"
  }
}
```

### Search Configuration

**Built-in Search:**

```json
{
  "globalMetadata": {
    "_enableSearch": true,
    "_disableContribution": false,
    "_searchScope": ["articles", "api", "reference"]
  }
}
```

**External Search Integration:**

```html
<!-- Custom search integration -->
<script>
(function() {
  var searchConfig = {
    apiKey: 'your-search-api-key',
    indexName: 'documentation',
    inputSelector: '#search-input',
    debug: false
  };
  
  // Initialize search functionality
  docsearch(searchConfig);
})();
</script>
```

## Build Optimization

### Performance Configuration

**Build Performance Settings:**

```json
{
  "build": {
    "markdownEngineName": "markdig",
    "markdownEngineProperties": {
      "enableSourceMap": false,
      "tabSize": 2
    },
    "intermediate": "tmp",
    "cleanupCacheHistory": true,
    "maxParallelism": 4,
    "keepFileLink": false,
    "disableGitFeatures": false
  }
}
```

### Asset Optimization

**Image Processing:**

```json
{
  "build": {
    "postProcessors": [
      {
        "name": "image-optimizer",
        "settings": {
          "quality": 85,
          "progressive": true,
          "optimizationLevel": 7
        }
      }
    ]
  }
}
```

## Validation and Testing

### Build Validation

**Local Build Testing:**

```bash
# Clean build
docfx docfx.json --cleanupCacheHistory

# Build with verbose logging
docfx docfx.json --logLevel Verbose

# Serve locally for testing
docfx serve _site --port 8080

# Build and serve in one command
docfx docfx.json --serve --port 8080
```

**Automated Validation Scripts:**

```powershell
# build-and-validate.ps1
param(
    [string]$ConfigFile = "docfx.json",
    [string]$OutputPath = "_site",
    [switch]$Validate,
    [switch]$Serve
)

Write-Host "Building DocFX site..." -ForegroundColor Green

# Clean previous build
if (Test-Path $OutputPath) {
    Remove-Item $OutputPath -Recurse -Force
}

# Build documentation
$buildResult = docfx $ConfigFile
if ($LASTEXITCODE -ne 0) {
    Write-Error "DocFX build failed"
    exit 1
}

if ($Validate) {
    Write-Host "Validating build output..." -ForegroundColor Yellow
    
    # Check for required files
    $requiredFiles = @("index.html", "toc.html", "manifest.json")
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path $OutputPath $file
        if (-not (Test-Path $filePath)) {
            Write-Error "Required file missing: $file"
            exit 1
        }
    }
    
    # Validate HTML
    Write-Host "HTML validation passed" -ForegroundColor Green
}

if ($Serve) {
    Write-Host "Starting local server..." -ForegroundColor Blue
    docfx serve $OutputPath --port 8080
}

Write-Host "Build completed successfully!" -ForegroundColor Green
```

### Link Validation

**Markdown Link Checker:**

```json
{
  "scripts": {
    "validate-links": "markdown-link-check articles/**/*.md",
    "validate-local-links": "markdown-link-check --config .mlc-config.json articles/**/*.md"
  }
}
```

**Link Checker Configuration (.mlc-config.json):**

```json
{
  "ignorePatterns": [
    {
      "pattern": "^https://localhost"
    },
    {
      "pattern": "^https://dev.azure.com/.*/_git/.*#"
    }
  ],
  "timeout": "20s",
  "retryOn429": true,
  "retryCount": 3,
  "fallbackRetryDelay": "30s",
  "aliveStatusCodes": [200, 206]
}
```

## Troubleshooting

### Common Issues

**Build Failures:**

```bash
# Common error diagnostics
docfx docfx.json --logLevel Verbose --debug

# Check file permissions
find . -name "*.md" -not -readable

# Validate JSON configuration
python -m json.tool docfx.json

# Check for encoding issues
file -bi **/*.md | grep -v "utf-8"
```

**Template Issues:**

```bash
# Reset to default template
docfx template export default

# Validate custom template
docfx template validate templates/custom
```

**Performance Issues:**

```json
{
  "build": {
    "maxParallelism": 2,
    "keepFileLink": false,
    "disableGitFeatures": true,
    "intermediate": "tmp"
  }
}
```

### Debugging Tools

**Diagnostic Commands:**

```bash
# Check DocFX version and environment
docfx --version
dotnet --info

# Validate configuration
docfx docfx.json --dryRun

# Generate detailed logs
docfx docfx.json --logLevel Diagnostic --logFilePath build.log
```

## Next Steps

After configuring DocFX:

1. **[Set up Azure App Service](azure-app-service.md)** - Configure hosting infrastructure
2. **[Configure CI/CD Pipeline](cicd-pipeline.md)** - Automate build and deployment
3. **[Content Strategy](../content/content-strategy.md)** - Plan your documentation approach
4. **[Custom Themes](../advanced/custom-themes.md)** - Customize appearance and branding

## Additional Resources

- [DocFX Official Documentation](https://dotnet.github.io/docfx/index.md)
- [DocFX Template Reference](https://dotnet.github.io/docfx/tutorial/intro_template.html)
- [Markdown Extensions](https://dotnet.github.io/docfx/spec/docfx_flavored_markdown.html)
- [Custom Plugin Development](https://dotnet.github.io/docfx/tutorial/howto_build_your_own_type_of_documentation_with_plugin.html)

---

*This DocFX configuration guide provides a comprehensive foundation for professional documentation site generation with advanced customization and optimization capabilities.*
