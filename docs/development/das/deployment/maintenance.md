---
title: Maintenance and Updates
description: Best practices for maintaining and updating your Documentation as Code implementation over time
---

## Maintenance and Updates

Establish processes for keeping your Documentation as Code implementation current, secure, and performant.

## Overview

Regular maintenance ensures your documentation infrastructure remains reliable, secure, and aligned with evolving organizational needs.

## Routine Maintenance Tasks

### Daily Operations

#### Automated Monitoring

```yaml
# Azure DevOps scheduled checks
schedules:
- cron: "0 */6 * * *"  # Every 6 hours
  displayName: Health Check
  branches:
    include:
    - main
  always: true

jobs:
- job: HealthCheck
  steps:
  - task: PowerShell@2
    displayName: 'Check Site Health'
    inputs:
      targetType: 'inline'
      script: |
        # Check site availability
        $response = Invoke-WebRequest -Uri "https://docs.yoursite.com" -UseBasicParsing
        if ($response.StatusCode -ne 200) {
          Write-Error "Site health check failed: $($response.StatusCode)"
          exit 1
        }
        
        # Check search functionality
        $searchResponse = Invoke-WebRequest -Uri "https://docs.yoursite.com/search?q=test" -UseBasicParsing
        if ($searchResponse.StatusCode -ne 200) {
          Write-Warning "Search functionality may be impaired"
        }
```

#### Link Validation

```bash
#!/bin/bash
# daily-link-check.sh

echo "Running daily link validation..."

# Check internal links
find docs/ -name "*.md" -exec markdown-link-check {} \; > link-check-results.txt

# Check for broken links
if grep -q "ERROR" link-check-results.txt; then
    echo "Broken links found. Creating issue..."
    # Create GitHub/Azure DevOps issue for broken links
    gh issue create --title "Broken Links Detected" --body "$(cat link-check-results.txt)"
fi
```

### Weekly Maintenance

#### Content Review

```powershell
# weekly-content-review.ps1

# Check for outdated content
$outdatedThreshold = (Get-Date).AddDays(-90)
$outdatedFiles = Get-ChildItem -Path "docs" -Recurse -Include "*.md" | 
    Where-Object { $_.LastWriteTime -lt $outdatedThreshold }

if ($outdatedFiles.Count -gt 0) {
    Write-Host "Found $($outdatedFiles.Count) files not updated in 90+ days:"
    $outdatedFiles | ForEach-Object { Write-Host "  - $($_.FullName)" }
    
    # Create review tasks
    foreach ($file in $outdatedFiles) {
        # Create work item for content review
        az boards work-item create --type "Task" --title "Review outdated content: $($file.Name)"
    }
}
```

#### Performance Analysis

```sql
-- Weekly performance review query
SELECT 
    page_url,
    AVG(load_time_ms) as avg_load_time,
    COUNT(*) as page_views,
    AVG(bounce_rate) as avg_bounce_rate
FROM page_analytics 
WHERE timestamp >= DATEADD(week, -1, GETDATE())
GROUP BY page_url
HAVING AVG(load_time_ms) > 3000 OR AVG(bounce_rate) > 0.7
ORDER BY page_views DESC
```

### Monthly Maintenance

#### Security Updates

```yaml
# Monthly security scan
name: Security Scan
trigger:
  schedules:
  - cron: "0 2 1 * *"  # First day of month at 2 AM
    displayName: Monthly Security Scan
    branches:
      include:
      - main

jobs:
- job: SecurityScan
  steps:
  - task: WhiteSource@21
    displayName: 'WhiteSource Security Scan'
  
  - task: SonarCloudAnalyze@1
    displayName: 'SonarCloud Analysis'
  
  - task: PowerShell@2
    displayName: 'Check for Vulnerable Dependencies'
    inputs:
      targetType: 'inline'
      script: |
        npm audit --audit-level high
        if ($LASTEXITCODE -ne 0) {
          Write-Error "Security vulnerabilities found in dependencies"
          exit 1
        }
```

#### Dependency Updates

```json
{
  "name": "dependency-updates",
  "version": "1.0.0",
  "scripts": {
    "update-check": "npm outdated",
    "update-minor": "npm update",
    "update-major": "npx npm-check-updates -u"
  },
  "devDependencies": {
    "npm-check-updates": "^16.0.0",
    "audit-ci": "^6.6.1"
  }
}
```

## Update Management

### DocFX Updates

#### Version Management Strategy

```yaml
# docfx-update-pipeline.yml
parameters:
- name: docfxVersion
  displayName: 'DocFX Version'
  type: string
  default: 'latest'

stages:
- stage: TestUpdate
  displayName: 'Test DocFX Update'
  jobs:
  - job: TestBuild
    steps:
    - task: DotNetCoreCLI@2
      displayName: 'Install DocFX'
      inputs:
        command: 'custom'
        custom: 'tool'
        arguments: 'install -g docfx --version ${{ parameters.docfxVersion }}'
    
    - task: PowerShell@2
      displayName: 'Test Build'
      inputs:
        targetType: 'inline'
        script: |
          docfx build docfx.json --warningsAsErrors
          if ($LASTEXITCODE -ne 0) {
            Write-Error "Build failed with new DocFX version"
            exit 1
          }

- stage: DeployUpdate
  displayName: 'Deploy Update'
  condition: succeeded('TestUpdate')
  jobs:
  - deployment: UpdateProduction
    environment: 'production'
    strategy:
      runOnce:
        deploy:
          steps:
          - template: deploy-steps.yml
```

### Content Migration

#### Automated Migration Scripts

```python
# migrate_content.py
import re
import os
from pathlib import Path

def migrate_markdown_syntax(file_path):
    """Update markdown syntax to latest standards"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Update code block syntax
    content = re.sub(r'```(\w+)(\w+)', r'```\1', content)
    
    # Fix heading syntax
    content = re.sub(r'^#{1,6}\s*([^#\n]+)\s*#{1,6}\s*$', 
                     lambda m: '#' * len(m.group(0).split()[0]) + ' ' + m.group(1).strip(), 
                     content, flags=re.MULTILINE)
    
    # Update link syntax
    content = re.sub(r'\[([^\]]+)\]\s*\(([^)]+)\)', r'[\1](\2)', content)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

def batch_migrate(directory):
    """Migrate all markdown files in directory"""
    for md_file in Path(directory).rglob('*.md'):
        print(f"Migrating {md_file}")
        migrate_markdown_syntax(md_file)

if __name__ == "__main__":
    batch_migrate("docs/")
```

### Template Updates

#### Template Versioning System

```yaml
# template-update.yml
name: Template Update Pipeline

trigger:
  paths:
    include:
    - templates/*

variables:
  templateVersion: $[counter(variables['Build.SourceBranch'], 1)]

stages:
- stage: ValidateTemplates
  jobs:
  - job: TemplateValidation
    steps:
    - task: PowerShell@2
      displayName: 'Validate Template Syntax'
      inputs:
        targetType: 'inline'
        script: |
          $templates = Get-ChildItem -Path "templates" -Include "*.md" -Recurse
          foreach ($template in $templates) {
            # Validate front matter
            $content = Get-Content $template.FullName -Raw
            if (-not ($content -match '^---\s*\n(.|\n)*?\n---\s*\n')) {
              Write-Error "Invalid front matter in $($template.Name)"
              exit 1
            }
            
            # Validate markdown syntax
            markdownlint $template.FullName
            if ($LASTEXITCODE -ne 0) {
              Write-Error "Markdown validation failed for $($template.Name)"
              exit 1
            }
          }

- stage: DeployTemplates
  dependsOn: ValidateTemplates
  jobs:
  - job: UpdateTemplates
    steps:
    - task: PowerShell@2
      displayName: 'Update Template References'
      inputs:
        targetType: 'inline'
        script: |
          # Update template version in configuration
          $config = Get-Content "docfx.json" | ConvertFrom-Json
          $config.templateVersion = "$(templateVersion)"
          $config | ConvertTo-Json -Depth 10 | Set-Content "docfx.json"
```

## Backup and Recovery

### Data Backup Strategy

#### Repository Backup

```bash
#!/bin/bash
# backup-repository.sh

BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/docs-repo-$BACKUP_DATE"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Clone repository
git clone --mirror https://dev.azure.com/org/project/_git/docs-repo "$BACKUP_DIR/repo.git"

# Export work items and configurations
az boards query --wiql "SELECT [System.Id] FROM WorkItems" --output table > "$BACKUP_DIR/work-items.txt"
az pipelines build list --output json > "$BACKUP_DIR/pipelines.json"

# Compress backup
tar -czf "/backups/docs-backup-$BACKUP_DATE.tar.gz" -C "/backups" "docs-repo-$BACKUP_DATE"

# Upload to Azure Storage
az storage blob upload --file "/backups/docs-backup-$BACKUP_DATE.tar.gz" \
  --container-name "backups" --name "docs-backup-$BACKUP_DATE.tar.gz"

echo "Backup completed: docs-backup-$BACKUP_DATE.tar.gz"
```

#### Application Backup

```yaml
# backup-pipeline.yml
name: Backup Documentation Site

schedules:
- cron: "0 3 * * 0"  # Weekly on Sunday at 3 AM
  displayName: Weekly Backup
  branches:
    include:
    - main

jobs:
- job: BackupSite
  steps:
  - task: AzureCLI@2
    displayName: 'Backup App Service'
    inputs:
      azureSubscription: 'production-subscription'
      scriptType: 'bash'
      scriptLocation: 'inlineScript'
      inlineScript: |
        # Create backup of App Service
        az webapp config backup create \
          --resource-group "docs-rg" \
          --webapp-name "docs-app" \
          --backup-name "weekly-backup-$(date +%Y%m%d)" \
          --container-url "$(BACKUP_STORAGE_URL)"
        
        # Backup database if applicable
        az sql db export \
          --server "docs-sql-server" \
          --database "docs-db" \
          --admin-user "$(SQL_ADMIN_USER)" \
          --admin-password "$(SQL_ADMIN_PASSWORD)" \
          --storage-key "$(STORAGE_KEY)" \
          --storage-key-type "StorageAccessKey" \
          --storage-uri "$(BACKUP_STORAGE_URL)/db-backup-$(date +%Y%m%d).bacpac"
```

### Disaster Recovery

#### Recovery Procedures

```powershell
# disaster-recovery.ps1
param(
    [Parameter(Mandatory=$true)]
    [string]$BackupDate,
    
    [Parameter(Mandatory=$true)]
    [string]$TargetEnvironment
)

Write-Host "Starting disaster recovery for backup: $BackupDate"

# Download backup
az storage blob download \
  --container-name "backups" \
  --name "docs-backup-$BackupDate.tar.gz" \
  --file "backup-$BackupDate.tar.gz"

# Extract backup
tar -xzf "backup-$BackupDate.tar.gz"

# Restore repository
$repoPath = "docs-repo-$BackupDate/repo.git"
git clone --mirror $repoPath "recovered-repo"

# Deploy to target environment
Push-Location "recovered-repo"
git remote set-url origin "https://dev.azure.com/org/project/_git/docs-repo-$TargetEnvironment"
git push --mirror
Pop-Location

Write-Host "Disaster recovery completed for environment: $TargetEnvironment"
```

## Monitoring and Alerting

### Health Monitoring

#### Synthetic Monitoring

```yaml
# synthetic-monitoring.yml
name: Synthetic Monitoring

schedules:
- cron: "*/15 * * * *"  # Every 15 minutes
  displayName: Synthetic Tests
  branches:
    include:
    - main

jobs:
- job: SyntheticTests
  steps:
  - task: PowerShell@2
    displayName: 'Run Synthetic Tests'
    inputs:
      targetType: 'inline'
      script: |
        $tests = @(
          @{ Name = "Homepage"; Url = "https://docs.yoursite.com"; ExpectedStatus = 200 }
          @{ Name = "Search"; Url = "https://docs.yoursite.com/search?q=test"; ExpectedStatus = 200 }
          @{ Name = "API Docs"; Url = "https://docs.yoursite.com/api/"; ExpectedStatus = 200 }
        )
        
        $failures = @()
        foreach ($test in $tests) {
          try {
            $response = Invoke-WebRequest -Uri $test.Url -UseBasicParsing -TimeoutSec 30
            if ($response.StatusCode -ne $test.ExpectedStatus) {
              $failures += "Test '$($test.Name)' failed: Expected $($test.ExpectedStatus), got $($response.StatusCode)"
            }
          } catch {
            $failures += "Test '$($test.Name)' failed: $($_.Exception.Message)"
          }
        }
        
        if ($failures.Count -gt 0) {
          Write-Error "Synthetic tests failed:`n$($failures -join "`n")"
          exit 1
        }
```

### Alert Configuration

#### Azure Monitor Alerts

```json
{
  "alertRules": [
    {
      "name": "Documentation Site Down",
      "description": "Alert when documentation site is not responding",
      "condition": {
        "metric": "availability",
        "operator": "LessThan",
        "threshold": 95,
        "timeAggregation": "Average",
        "windowSize": "PT5M"
      },
      "actions": [
        {
          "type": "email",
          "recipients": ["docs-team@company.com"]
        },
        {
          "type": "webhook",
          "url": "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
        }
      ]
    },
    {
      "name": "High Error Rate",
      "description": "Alert when error rate exceeds threshold",
      "condition": {
        "metric": "exceptions/rate",
        "operator": "GreaterThan",
        "threshold": 10,
        "timeAggregation": "Average",
        "windowSize": "PT15M"
      },
      "actions": [
        {
          "type": "email",
          "recipients": ["docs-team@company.com"]
        }
      ]
    }
  ]
}
```

## Performance Optimization

### Regular Performance Reviews

#### Performance Audit Script

```bash
#!/bin/bash
# performance-audit.sh

echo "Running performance audit..."

# Test page load times
echo "Testing page load times..."
curl -w "@curl-format.txt" -o /dev/null -s "https://docs.yoursite.com" > load-times.txt

# Test search performance
echo "Testing search performance..."
START_TIME=$(date +%s%N)
curl -s "https://docs.yoursite.com/search?q=performance" > /dev/null
END_TIME=$(date +%s%N)
SEARCH_TIME=$(( (END_TIME - START_TIME) / 1000000 ))
echo "Search response time: ${SEARCH_TIME}ms"

# Check image optimization
echo "Checking image sizes..."
find _site/images -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" | while read img; do
  SIZE=$(stat -f%z "$img" 2>/dev/null || stat -c%s "$img")
  if [ $SIZE -gt 500000 ]; then
    echo "Large image detected: $img ($SIZE bytes)"
  fi
done
```

### Cache Optimization

```json
{
  "caching": {
    "staticFiles": {
      "maxAge": "31536000",
      "headers": {
        "Cache-Control": "public, max-age=31536000, immutable"
      }
    },
    "htmlFiles": {
      "maxAge": "3600",
      "headers": {
        "Cache-Control": "public, max-age=3600, must-revalidate"
      }
    },
    "apiResponses": {
      "maxAge": "300",
      "headers": {
        "Cache-Control": "public, max-age=300"
      }
    }
  }
}
```

## Troubleshooting

### Common Maintenance Issues

#### Build Failures

```yaml
# build-troubleshooting.yml
steps:
- task: PowerShell@2
  displayName: 'Diagnose Build Issues'
  inputs:
    targetType: 'inline'
    script: |
      # Check DocFX version compatibility
      $docfxVersion = docfx --version
      Write-Host "DocFX Version: $docfxVersion"
      
      # Validate configuration
      $config = Get-Content "docfx.json" | ConvertFrom-Json
      if (-not $config.metadata) {
        Write-Warning "No metadata configuration found"
      }
      
      # Check for common issues
      $commonIssues = @(
        @{ File = "toc.yml"; Description = "Table of contents validation" }
        @{ File = "docfx.json"; Description = "Configuration validation" }
      )
      
      foreach ($issue in $commonIssues) {
        if (Test-Path $issue.File) {
          Write-Host "✓ $($issue.Description): File exists"
        } else {
          Write-Error "✗ $($issue.Description): File missing"
        }        }
```

#### Performance Degradation

```sql
-- Query to identify performance issues
WITH performance_trends AS (
  SELECT 
    DATE(timestamp) as date,
    AVG(page_load_time) as avg_load_time,
    COUNT(*) as requests
  FROM performance_metrics 
  WHERE timestamp >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  GROUP BY DATE(timestamp)
)
SELECT 
  date,
  avg_load_time,
  requests,
  LAG(avg_load_time) OVER (ORDER BY date) as prev_load_time,
  (avg_load_time - LAG(avg_load_time) OVER (ORDER BY date)) / LAG(avg_load_time) OVER (ORDER BY date) * 100 as performance_change_pct
FROM performance_trends
HAVING performance_change_pct > 20 OR avg_load_time > 3000
ORDER BY date DESC
```

## Best Practices

### Maintenance Planning

- **Regular Schedule**: Establish consistent maintenance windows
- **Change Management**: Use formal change control processes
- **Testing**: Test all updates in staging before production
- **Documentation**: Keep maintenance procedures documented
- **Rollback Plans**: Always have rollback procedures ready

### Automation

- **Automate Routine Tasks**: Reduce manual intervention
- **Monitor Automation**: Ensure automated processes are working
- **Alert on Failures**: Get notified when automation fails
- **Regular Reviews**: Review and update automation regularly

### Team Coordination

- **Shared Responsibility**: Distribute maintenance tasks
- **Knowledge Sharing**: Document all procedures
- **Training**: Keep team updated on new tools and processes
- **Communication**: Coordinate maintenance activities

---

Last updated: July 6, 2025 | For maintenance support, contact the DevOps team
