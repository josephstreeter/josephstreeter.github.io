---
title: "Documentation as Code - Quick Reference"
description: "Quick reference guide for Documentation as Code commands, configurations, and best practices"
tags: ["documentation", "docfx", "azure-devops", "quick-reference", "cheat-sheet"]
category: "development"
difficulty: "beginner"
last_updated: "2025-07-06"
---

## Quick Reference Guide

## Essential Commands

### DocFX Commands

```bash
# Initialize new DocFX project
docfx init -q

# Build documentation locally
docfx build

# Serve documentation locally
docfx serve _site

# Build and serve in one command
docfx docfx.json --serve

# Clean build artifacts
docfx build --clean
```

### Git Workflow Commands

```bash
# Create feature branch for documentation
git checkout -b docs/feature-name

# Stage and commit changes
git add .
git commit -m "docs: add new feature documentation"

# Push and create pull request
git push origin docs/feature-name

# Sync with main branch
git checkout main
git pull origin main
git checkout docs/feature-name
git merge main
```

### Azure CLI Commands

```bash
# Create resource group
az group create --name rg-docs --location eastus

# Create App Service plan
az appservice plan create --name plan-docs --resource-group rg-docs --sku B1

# Create web app
az webapp create --name app-docs --resource-group rg-docs --plan plan-docs

# Deploy from Azure DevOps
az webapp deployment source config --name app-docs --resource-group rg-docs \
  --repo-url https://dev.azure.com/org/project/_git/repo --branch main
```

## Configuration Files

### Basic docfx.json

```json
{
  "build": {
    "content": [
      {
        "files": ["**/*.md", "**/*.yml"],
        "exclude": ["_site/**", "**/_theme/**"]
      }
    ],
    "resource": [
      {
        "files": ["images/**", "**/images/**"]
      }
    ],
    "dest": "_site",
    "template": ["default", "_theme"],
    "globalMetadata": {
      "_appName": "Documentation Site",
      "_appTitle": "Documentation as Code",
      "_gitContribute": {
        "repo": "https://dev.azure.com/org/project/_git/repo",
        "branch": "main"
      }
    }
  }
}
```

### Azure Pipeline YAML

```yaml
trigger:
  branches:
    include:
    - main
    - develop
  paths:
    include:
    - docs/*

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: NodeTool@0
  inputs:
    versionSpec: '16.x'

- task: DotNetCoreCLI@2
  inputs:
    command: 'custom'
    custom: 'tool'
    arguments: 'install -g docfx'

- script: docfx build
  displayName: 'Build Documentation'

- task: AzureWebApp@1
  inputs:
    azureSubscription: 'Azure-Connection'
    appType: 'webApp'
    appName: 'app-docs'
    package: '_site'
```

## File Structure Template

```text
project-root/
├── docs/
│   ├── articles/
│   │   ├── getting-started.md
│   │   └── advanced-topics.md
│   ├── api/
│   │   └── toc.yml
│   ├── images/
│   │   └── architecture/
│   ├── _theme/
│   │   ├── layout/
│   │   └── styles/
│   ├── toc.yml
│   └── index.md
├── src/
├── tests/
├── azure-pipelines.yml
├── docfx.json
└── README.md
```

## Markdown Templates

### Article Template

```markdown
---
title: "Article Title"
description: "Brief description of the article content"
tags: ["tag1", "tag2", "tag3"]
category: "category-name"
difficulty: "beginner|intermediate|advanced"
last_updated: "YYYY-MM-DD"
---

# Article Title

Brief introduction paragraph.

## Overview

Content overview and what readers will learn.

## Prerequisites

- Required knowledge
- Required tools
- Required access

## Step-by-Step Instructions

### Step 1: First Action

Detailed instructions with code examples.

### Step 2: Next Action

Continue with numbered steps.

## Conclusion

Summary of what was accomplished.

## Next Steps

- Link to related articles
- Suggested follow-up actions

## Additional Resources

- [External Link](https://example.com)
- [Internal Link](relative-path.md)
```

### API Documentation Template

```markdown
---
title: "API Reference"
description: "API documentation for service endpoints"
tags: ["api", "reference", "endpoints"]
category: "api"
---

# API Reference

## Authentication

Authentication requirements and examples.

## Endpoints

### GET /api/resource

Description of the endpoint.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | string | Yes | Resource identifier |
| format | string | No | Response format |

**Response:**

```json
{
  "id": "string",
  "name": "string",
  "status": "active"
}
```

**Example:**

```bash
curl -X GET "https://api.example.com/resource/123" \
  -H "Authorization: Bearer TOKEN"
```

## Common Issues and Solutions

### Build Failures

| Issue | Cause | Solution |
|-------|-------|----------|
| "docfx.json not found" | Missing configuration file | Run `docfx init` to create configuration |
| "Template not found" | Missing theme files | Install theme or update template path |
| "Broken links detected" | Invalid internal links | Check and fix link references |
| "Image not found" | Missing image files | Verify image paths and file existence |

### Deployment Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| "Site not updating" | Cache issues | Clear CDN cache or browser cache |
| "404 errors" | Incorrect routing | Check web.config or .htaccess rules |
| "Build timeout" | Large repository | Optimize build process or increase timeout |
| "Permission denied" | Authentication failure | Verify service connection credentials |

### Content Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| "TOC not updating" | Cache or build issue | Rebuild site and clear cache |
| "Formatting broken" | Markdown syntax error | Validate markdown syntax |
| "Search not working" | Index not built | Rebuild search index |
| "Cross-references broken" | File moved/renamed | Update all references |

## Best Practice Checklist

### Content Quality

- [ ] All pages have proper frontmatter
- [ ] Images have alt text
- [ ] Links are tested and functional
- [ ] Code examples are syntax highlighted
- [ ] TOC is up to date

### Repository Management

- [ ] Clear commit messages
- [ ] Branch protection rules enabled
- [ ] Pull request templates configured
- [ ] Automated testing enabled
- [ ] Security scanning configured

### Deployment

- [ ] Staging environment configured
- [ ] Production deployment tested
- [ ] Rollback procedure documented
- [ ] Monitoring and alerts configured
- [ ] Performance metrics tracked

## Useful Resources

### Documentation Tools

- **DocFX**: [https://dotnet.github.io/docfx/](https://dotnet.github.io/docfx/index.md)
- **Markdown Guide**: [https://www.markdownguide.org/](https://www.markdownguide.org/index.md)
- **Azure DevOps**: [https://docs.microsoft.com/en-us/azure/devops/](https://docs.microsoft.com/en-us/azure/devops/index.md)

### Style Guides

- **Microsoft Writing Style Guide**: [https://docs.microsoft.com/en-us/style-guide/](https://docs.microsoft.com/en-us/style-guide/index.md)
- **Google Developer Documentation Style Guide**: [https://developers.google.com/style](https://developers.google.com/style)

### Community Resources

- **DocFX GitHub**: [https://github.com/dotnet/docfx](https://github.com/dotnet/docfx)
- **Azure DevOps Community**: [https://developercommunity.visualstudio.com/spaces/21/index.html](https://developercommunity.visualstudio.com/spaces/21/index.html)

---

*Keep this reference guide bookmarked for quick access to common commands, templates, and troubleshooting solutions.*
