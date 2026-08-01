---
title: "CI/CD Pipelines for Documentation"
description: "Validating, publishing, and generating documentation with Azure Pipelines"
author: "Joseph Streeter"
tags: ["azure devops", "documentation", "ci-cd", "pipelines", "automation"]
category: "development"
last_updated: "2026-08-01"
---
## 7. CI/CD Pipelines for Documentation

### 7.1 Why CI/CD for Documentation?

**Benefits:**

- **Quality assurance:** Automated checks catch issues before merge
- **Consistency:** Enforce standards automatically
- **Efficiency:** Reduce manual review burden
- **Notifications:** Alert stakeholders of documentation changes
- **Publishing:** Automatically publish to multiple formats (HTML, PDF)

### 7.2 Documentation Validation Pipeline

**Purpose:** Run automated checks on pull requests to ensure documentation quality

**Create: `azure-pipelines-docs-validation.yml`**

```yaml
# Documentation Validation Pipeline
# Runs on PR to validate documentation quality

name: Documentation Validation

# Trigger on PR to main branch, only when /docs changes
trigger: none  # Manual or PR only

pr:
  branches:
    include:
      - main
  paths:
    include:
      - docs/**
      - .azuredevops/azure-pipelines-docs-validation.yml

pool:
  vmImage: 'ubuntu-latest'

steps:
  # Step 1: Checkout repository
  - checkout: self
    fetchDepth: 1

  # Step 2: Install Node.js (for markdown linting)
  - task: NodeTool@0
    inputs:
      versionSpec: '18.x'
    displayName: 'Install Node.js'

  # Step 3: Install markdown linting tool
  - script: |
      npm install -g markdownlint-cli
    displayName: 'Install markdownlint'

  # Step 4: Run markdown linting
  - script: |
      markdownlint 'docs/**/*.md' --config .markdownlint.json
    displayName: 'Lint Markdown files'
    continueOnError: true  # Don't fail build, but report issues

  # Step 5: Check for broken links
  - script: |
      npm install -g markdown-link-check
      find docs -name \*.md -exec markdown-link-check --config .markdown-link-check.json {} \;
    displayName: 'Check for broken links'
    continueOnError: true

  # Step 6: Spell check
  - script: |
      npm install -g cspell
      cspell "docs/**/*.md" --config .cspell.json
    displayName: 'Spell check'
    continueOnError: true

  # Step 7: Validate file naming conventions
  - script: |
      # Check for spaces in filenames (should use hyphens)
      if find docs -name "* *.md" | grep -q .; then
        echo "Error: Found files with spaces in names. Use hyphens instead."
        find docs -name "* *.md"
        exit 1
      fi
      echo "File naming conventions check passed."
    displayName: 'Check file naming conventions'

  # Step 8: Check for required sections in README files
  - script: |
      python3 .azuredevops/scripts/check-readme-structure.py
    displayName: 'Validate README structure'

  # Step 9: Publish validation results
  - task: PublishTestResults@2
    inputs:
      testResultsFormat: 'JUnit'
      testResultsFiles: '**/test-results.xml'
      failTaskOnFailedTests: false
    displayName: 'Publish validation results'
    condition: always()
```

**Supporting files:**

**`.markdownlint.json` (markdown linting rules):**

```json
{
  "default": true,
  "MD003": { "style": "atx" },
  "MD007": { "indent": 2 },
  "MD013": false,
  "MD024": { "allow_different_nesting": true },
  "MD033": false,
  "MD041": false
}
```

**`.markdown-link-check.json` (link checking configuration):**

```json
{
  "ignorePatterns": [
    {
      "pattern": "^https://dev.azure.com"
    }
  ],
  "httpHeaders": [
    {
      "urls": ["https://example.com"],
      "headers": {
        "Authorization": "Bearer token"
      }
    }
  ],
  "timeout": "20s",
  "retryOn429": true,
  "retryCount": 3,
  "fallbackRetryDelay": "30s"
}
```

**`.cspell.json` (spell check configuration):**

```json
{
  "version": "0.2",
  "language": "en",
  "words": [
    "Azure",
    "DevOps",
    "FortiMail",
    "repo",
    "repos",
    "SMTP",
    "DNS",
    "DKIM",
    "SPF"
  ],
  "ignorePaths": [
    "node_modules/**",
    ".git/**",
    "*.png",
    "*.jpg"
  ]
}
```

**`.azuredevops/scripts/check-readme-structure.py`:**

```python
#!/usr/bin/env python3
"""
Validate that README.md files contain required sections
"""

import os
import sys
import re

REQUIRED_SECTIONS = [
    "## Overview",
    "## Quick Links",
    "## Service Information"
]

def check_readme(filepath):
    """Check if README has required sections"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    missing = []
    for section in REQUIRED_SECTIONS:
        if section not in content:
            missing.append(section)
    
    if missing:
        print(f"❌ {filepath} missing required sections:")
        for section in missing:
            print(f"   - {section}")
        return False
    else:
        print(f"✅ {filepath} has all required sections")
        return True

def main():
    """Check all README.md files in docs folder"""
    docs_root = "docs"
    all_valid = True
    
    for root, dirs, files in os.walk(docs_root):
        if "README.md" in files:
            readme_path = os.path.join(root, "README.md")
            if not check_readme(readme_path):
                all_valid = False
    
    if not all_valid:
        sys.exit(1)
    
    print("\n✅ All README files are valid")

if __name__ == "__main__":
    main()
```

### 7.3 Status Checks in Pull Requests

**Configure pipeline as branch policy:**

1. Azure DevOps → Repos → Branches
2. Main branch → Branch Policies
3. Build Validation → Add build policy
4. Select: `Documentation Validation` pipeline
5. Trigger: Automatic
6. Policy requirement: Required
7. Build expiration: Immediately
8. Display name: "Documentation Quality Checks"

**Result:** PR cannot be completed until validation pipeline passes

### 7.4 Documentation Publishing Pipeline

**Purpose:** Generate additional formats (HTML, PDF) from Markdown

**Create: `azure-pipelines-docs-publish.yml`**

```yaml
# Documentation Publishing Pipeline
# Generates HTML and PDF from Markdown

name: Documentation Publishing

trigger:
  branches:
    include:
      - main
  paths:
    include:
      - docs/**

pool:
  vmImage: 'ubuntu-latest'

variables:
  docsVersion: '$(Build.BuildNumber)'

steps:
  # Step 1: Checkout
  - checkout: self
    fetchDepth: 1

  # Step 2: Install Pandoc (for PDF generation)
  - script: |
      sudo apt-get update
      sudo apt-get install -y pandoc texlive-xetex
    displayName: 'Install Pandoc and LaTeX'

  # Step 3: Generate HTML
  - script: |
      mkdir -p $(Build.ArtifactStagingDirectory)/html
      
      # Convert all markdown to HTML
      find docs -name "*.md" | while read file; do
        output="${file%.md}.html"
        output="$(Build.ArtifactStagingDirectory)/html/${output#docs/}"
        mkdir -p "$(dirname "$output")"
        pandoc "$file" -o "$output" --standalone --toc
      done
    displayName: 'Generate HTML documentation'

  # Step 4: Generate PDF
  - script: |
      mkdir -p $(Build.ArtifactStagingDirectory)/pdf
      
      # Combine all markdown into single PDF
      pandoc docs/**/*.md \
        -o $(Build.ArtifactStagingDirectory)/pdf/documentation-$(docsVersion).pdf \
        --toc \
        --pdf-engine=xelatex
    displayName: 'Generate PDF documentation'

  # Step 5: Publish artifacts
  - task: PublishBuildArtifacts@1
    inputs:
      pathToPublish: '$(Build.ArtifactStagingDirectory)/html'
      artifactName: 'documentation-html'
    displayName: 'Publish HTML artifacts'

  - task: PublishBuildArtifacts@1
    inputs:
      pathToPublish: '$(Build.ArtifactStagingDirectory)/pdf'
      artifactName: 'documentation-pdf'
    displayName: 'Publish PDF artifacts'

  # Step 6: (Optional) Upload to blob storage or file share
  - task: AzureFileCopy@4
    inputs:
      SourcePath: '$(Build.ArtifactStagingDirectory)/html'
      azureSubscription: 'Azure-Subscription'
      Destination: 'AzureBlob'
      storage: 'documentationstorage'
      ContainerName: 'documentation'
    displayName: 'Upload to Azure Storage'
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
```

### 7.5 Notification Pipeline

**Purpose:** Notify stakeholders when documentation changes

**Create: `azure-pipelines-docs-notify.yml`**

```yaml
# Documentation Notification Pipeline
# Sends notifications when documentation is updated

name: Documentation Notifications

trigger:
  branches:
    include:
      - main
  paths:
    include:
      - docs/**

pool:
  vmImage: 'ubuntu-latest'

steps:
  - checkout: self
    fetchDepth: 2  # Need 2 commits to see what changed

  # Step 1: Determine what changed
  - script: |
      # Get list of changed files
      git diff --name-only HEAD~1 HEAD -- docs/ > changed-files.txt
      
      # Categorize changes
      if grep -q "docs/Operations" changed-files.txt; then
        echo "##vso[task.setvariable variable=OperationsChanged]true"
      fi
      
      if grep -q "docs/API" changed-files.txt; then
        echo "##vso[task.setvariable variable=APIChanged]true"
      fi
      
      if grep -q "docs/Development" changed-files.txt; then
        echo "##vso[task.setvariable variable=DevelopmentChanged]true"
      fi
      
      # Output for logging
      echo "Changed files:"
      cat changed-files.txt
    displayName: 'Detect documentation changes'

  # Step 2: Send email to operations team
  - task: SendEmail@1
    inputs:
      to: 'operations-team@company.com'
      subject: '📚 Operations Documentation Updated'
      body: |
        Operations documentation has been updated in the $(Build.Repository.Name) repository.
        
        View changes: $(Build.Repository.Uri)/commit/$(Build.SourceVersion)
        View documentation: [Wiki Link]
        
        Build: $(Build.BuildNumber)
    displayName: 'Notify operations team'
    condition: and(succeeded(), eq(variables['OperationsChanged'], 'true'))

  # Step 3: Send Teams notification
  - task: PowerShell@2
    inputs:
      targetType: 'inline'
      script: |
        $body = @{
          text = "📚 Documentation updated in $(Build.Repository.Name)`n`nChanges: $(Build.Repository.Uri)/commit/$(Build.SourceVersion)"
        } | ConvertTo-Json
        
        Invoke-RestMethod -Uri "$(TeamsWebhookURL)" -Method Post -Body $body -ContentType 'application/json'
    displayName: 'Send Teams notification'
    condition: succeeded()
```

### 7.6 Automated Documentation Generation

**For API documentation (if you have REST APIs):**

**Create: `azure-pipelines-api-docs.yml`**

```yaml
# API Documentation Generation
# Generates API docs from OpenAPI/Swagger specs

name: API Documentation

trigger:
  branches:
    include:
      - main
  paths:
    include:
      - src/api/**
      - openapi.yaml

pool:
  vmImage: 'ubuntu-latest'

steps:
  - checkout: self

  # Step 1: Install Swagger/OpenAPI tools
  - script: |
      npm install -g @redocly/cli
    displayName: 'Install Redocly CLI'

  # Step 2: Generate API documentation
  - script: |
      # Bundle OpenAPI spec
      redocly bundle openapi.yaml -o docs/API/openapi-bundled.yaml
      
      # Generate HTML documentation
      redocly build-docs openapi.yaml -o docs/API/api-reference.html
    displayName: 'Generate API documentation'

  # Step 3: Commit generated docs back to repo
  - script: |
      git config user.email "azure-pipelines@company.com"
      git config user.name "Azure Pipelines"
      git add docs/API/
      git commit -m "docs: auto-generate API documentation" || echo "No changes to commit"
      git push origin HEAD:$(Build.SourceBranchName)
    displayName: 'Commit generated documentation'
```

---

## Related Topics

- [Overview](index.md)
- [Azure DevOps Wiki Types](wiki-types.md)
- [Architecture and Organization](architecture.md)
- [Project Wiki Implementation](project-wiki.md)
- [Code Wiki Implementation](code-wiki.md)
- [Markdown Standards and Best Practices](markdown-standards.md)
- [Version Control Workflow](version-control.md)
- [CI/CD Pipelines for Documentation](cicd-pipelines.md)
- [Documentation Templates](templates.md)
- [Template Repository and Automation](automation.md)
- [Access Control and Permissions](access-control.md)
- [Search and Discoverability](search.md)
- [Migration Strategy](migration.md)
- [Maintenance and Governance](governance.md)
- [Appendices](appendices.md)
