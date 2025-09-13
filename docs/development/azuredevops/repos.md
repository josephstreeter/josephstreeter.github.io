---
title: Azure DevOps Repos - Git Repository Management
description: Comprehensive guide to Azure Repos for Git repository management, branch policies, pull requests, code reviews, and collaborative development workflows
author: Joseph Streeter
date: 2025-09-13
tags: [azure-devops, repos, git, version-control, branch-policies, pull-requests, code-review]
---

Azure Repos provides enterprise-grade Git repository hosting with advanced security, collaboration features, and seamless integration with Azure DevOps services.

## 🎯 **Overview**

Azure Repos enables development teams to:

- **Host unlimited private Git repositories** with enterprise security and compliance
- **Collaborate effectively** through pull requests, code reviews, and branch policies
- **Enforce code quality** with automated policies and security scanning
- **Scale development workflows** from small teams to large enterprises
- **Integrate seamlessly** with Azure Pipelines, Boards, and third-party tools
- **Maintain code history** with comprehensive audit trails and analytics

### Key Features

| Feature | Description | Benefits |
|---------|-------------|----------|
| **Unlimited Private Repos** | Host any number of private Git repositories | No restrictions on repository count or size |
| **Advanced Branch Policies** | Enforce code review and quality gates | Automated quality assurance and compliance |
| **Pull Request Integration** | Rich PR experience with discussions and approvals | Collaborative code review and knowledge sharing |
| **Security Scanning** | Built-in vulnerability and secret scanning | Proactive security threat detection |
| **Large File Support** | Git LFS integration for large binary files | Efficient handling of assets and binaries |
| **Web-based Editing** | Edit files directly in the browser | Quick fixes without local development setup |

## 🚀 **Getting Started with Azure Repos**

### Repository Creation and Setup

#### Creating a New Repository

```bash
# Option 1: Create repository through Azure DevOps portal
# Navigate to Repos → Files → Create repository

# Option 2: Create via Azure CLI
az repos create --name "MyNewRepository" \
                --project "MyProject" \
                --organization "https://dev.azure.com/MyOrg"

# Option 3: Import existing repository
az repos import create --git-source-url "https://github.com/user/repo.git" \
                       --repository "MyImportedRepo" \
                       --project "MyProject"
```

#### Initial Repository Setup

```bash
# Clone the empty repository
git clone https://dev.azure.com/MyOrg/MyProject/_git/MyRepository
cd MyRepository

# Initialize with common files
cat > README.md << 'EOF'
# MyRepository

## Description
Brief description of the project

## Getting Started
Instructions for setting up the development environment

## Contributing
Guidelines for contributing to the project
EOF

cat > .gitignore << 'EOF'
# Build outputs
bin/
obj/
*.exe
*.dll
*.pdb

# User-specific files
*.user
*.suo
.vs/

# Package files
packages/
node_modules/
*.nupkg

# Environment files
.env
.env.local
appsettings.Development.json
EOF

# Create initial commit
git add .
git commit -m "Initial commit: Add README and .gitignore"
git push origin main
```

### Authentication and Access

#### Personal Access Tokens (PAT)

```bash
# Configure Git credentials with PAT
git config --global credential.helper store

# Clone using PAT (prompted for credentials)
git clone https://dev.azure.com/MyOrg/MyProject/_git/MyRepository

# Alternative: Include PAT in URL (less secure)
git clone https://PAT@dev.azure.com/MyOrg/MyProject/_git/MyRepository
```

#### SSH Key Authentication

```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -C "your.email@company.com" -f ~/.ssh/azure_devops_rsa

# Add public key to Azure DevOps
# Navigate to User Settings → SSH public keys → Add

# Configure SSH
cat >> ~/.ssh/config << 'EOF'
Host ssh.dev.azure.com
  HostName ssh.dev.azure.com
  User git
  IdentityFile ~/.ssh/azure_devops_rsa
  IdentitiesOnly yes
EOF

# Clone using SSH
git clone ssh://git@ssh.dev.azure.com:v3/MyOrg/MyProject/MyRepository
```

## 🌿 **Branch Management and Workflows**

### Git Flow Implementation

#### Branch Naming Conventions

```yaml
Branch Types:
  main: Production-ready code
  develop: Integration branch for features
  feature/*: New feature development
    - feature/user-authentication
    - feature/payment-integration
    - feature/reporting-dashboard
  
  release/*: Release preparation
    - release/v1.2.0
    - release/2025-q1
  
  hotfix/*: Critical production fixes
    - hotfix/security-patch
    - hotfix/performance-fix
  
  bugfix/*: Bug fixes for develop branch
    - bugfix/login-validation
    - bugfix/api-timeout
```

#### Git Flow Workflow

```bash
# Initialize Git Flow
git flow init

# Start a new feature
git flow feature start user-authentication
# Work on feature...
git add .
git commit -m "Implement OAuth 2.0 authentication"

# Finish feature (merges to develop)
git flow feature finish user-authentication

# Start a release
git flow release start v1.2.0
# Prepare release (version bumps, documentation)
git commit -m "Prepare release v1.2.0"

# Finish release (merges to main and develop, creates tag)
git flow release finish v1.2.0

# Hotfix workflow
git flow hotfix start security-patch
# Fix critical issue...
git commit -m "Fix XSS vulnerability in user input"
git flow hotfix finish security-patch
```

### GitHub Flow (Simplified)

```bash
# Create feature branch from main
git checkout main
git pull origin main
git checkout -b feature/new-dashboard

# Develop feature with regular commits
git add src/Dashboard/
git commit -m "Add dashboard components"

git add tests/Dashboard/
git commit -m "Add dashboard unit tests"

git add docs/dashboard.md
git commit -m "Add dashboard documentation"

# Push feature branch
git push origin feature/new-dashboard

# Create pull request through Azure DevOps portal
# After approval and CI/CD validation, merge to main
```

## 🔀 **Pull Requests and Code Review**

### Creating Effective Pull Requests

#### Pull Request Template

```markdown
<!-- .azuredevops/pull_request_template.md -->
## Description
Brief description of changes made

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that causes existing functionality to change)
- [ ] Documentation update

## Changes Made
- List specific changes
- Include any architectural decisions
- Note any breaking changes

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed
- [ ] All tests pass

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No merge conflicts
- [ ] Linked work items updated

## Screenshots (if applicable)
Include screenshots for UI changes

## Additional Notes
Any additional context for reviewers
```

#### Advanced Pull Request Configuration

```yaml
# Pull request policies and automation
pr_policies:
  required_reviewers:
    - minimum_count: 2
    - reset_on_source_push: true
    - allow_requestor_vote: false
  
  build_validation:
    - build_definition: "CI Pipeline"
      queue_on_source_update: true
      manual_queue_only: false
      valid_duration: 1440 # 24 hours
  
  status_checks:
    - context: "security-scan"
      required: true
    - context: "code-coverage"
      required: true
      minimum_coverage: 80
  
  auto_completion:
    - squash_merge: true
    - delete_source_branch: true
    - complete_associated_work_items: true
```

### Code Review Best Practices

#### Reviewer Guidelines

```markdown
### Code Review Checklist

**Functionality**
- [ ] Code accomplishes intended functionality
- [ ] Edge cases are handled appropriately
- [ ] Error handling is comprehensive
- [ ] Performance implications considered

**Code Quality**
- [ ] Code is readable and well-structured
- [ ] Naming conventions followed
- [ ] Comments explain complex logic
- [ ] No code duplication

**Security**
- [ ] Input validation implemented
- [ ] Authentication/authorization checked
- [ ] No hardcoded secrets or credentials
- [ ] SQL injection prevention

**Testing**
- [ ] Adequate test coverage
- [ ] Tests are meaningful and comprehensive
- [ ] Mock usage appropriate
- [ ] Integration scenarios covered

**Documentation**
- [ ] Code is self-documenting
- [ ] API documentation updated
- [ ] README updated if needed
- [ ] Configuration changes documented
```

#### Review Comments Framework

```markdown
### Comment Types and Examples

**Nitpick (optional):**
> nitpick: Consider using a more descriptive variable name here
> `userCount` instead of `count` would be clearer

**Suggestion (improvement):**
> suggestion: This could be simplified using LINQ
> `users.Where(u => u.IsActive).Count()` instead of the foreach loop

**Issue (must fix):**
> issue: This creates a potential SQL injection vulnerability
> Use parameterized queries instead of string concatenation

**Question (clarification needed):**
> question: Why do we need this additional validation step?
> The upstream service should already validate this data

**Praise (positive feedback):**
> praise: Excellent error handling implementation!
> This covers all the edge cases we discussed
```

## 🛡️ **Branch Policies and Security**

### Comprehensive Branch Protection

#### Main Branch Policies

```json
{
  "branchPolicies": {
    "main": {
      "minimumApproverCount": 2,
      "resetOnSourcePush": true,
      "allowRequestorToApproveOwnChanges": false,
      "requireCommentResolution": true,
      "enforceLinkedWorkItems": true,
      
      "buildValidation": [
        {
          "displayName": "CI Build",
          "buildDefinitionId": 123,
          "queueOnSourceUpdateOnly": true,
          "manualQueueOnly": false,
          "validDuration": 1440
        },
        {
          "displayName": "Security Scan",
          "buildDefinitionId": 124,
          "queueOnSourceUpdateOnly": false,
          "manualQueueOnly": false,
          "validDuration": 720
        }
      ],
      
      "statusChecks": [
        {
          "context": "sonarcloud",
          "applicability": "conditional",
          "description": "SonarCloud quality gate"
        },
        {
          "context": "security-scan",
          "applicability": "conditional", 
          "description": "Security vulnerability scan"
        }
      ],
      
      "pathBasedRules": [
        {
          "path": "/docs/*",
          "minimumApproverCount": 1,
          "requireLinkedWorkItems": false
        },
        {
          "path": "/src/Security/*",
          "minimumApproverCount": 3,
          "requiredReviewerGroups": ["security-team"]
        }
      ]
    }
  }
}
```

#### Development Branch Policies

```bash
# PowerShell script to configure branch policies
$Organization = "https://dev.azure.com/MyOrg"
$Project = "MyProject" 
$Repository = "MyRepository"
$Pat = $env:AZURE_DEVOPS_PAT

$Headers = @{
    Authorization = "Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$Pat")))"
    'Content-Type' = 'application/json'
}

# Configure develop branch policy
$DevelopPolicy = @{
    isEnabled = $true
    isBlocking = $true
    type = @{
        id = "fa4e907d-c16b-4a4c-9dfa-4906e5d171dd"  # Minimum approvers policy
    }
    settings = @{
        minimumApproverCount = 1
        creatorVoteCounts = $false
        allowDownvotes = $false
        resetOnSourcePush = $true
        scope = @(
            @{
                repositoryId = $RepositoryId
                refName = "refs/heads/develop"
                matchKind = "exact"
            }
        )
    }
} | ConvertTo-Json -Depth 10

$Uri = "$Organization/$Project/_apis/policy/configurations?api-version=6.0"
Invoke-RestMethod -Uri $Uri -Method Post -Body $DevelopPolicy -Headers $Headers
```

### Security Scanning Integration

#### Secret Scanning Configuration

```yaml
# Security scanning pipeline integration
trigger:
  branches:
    include:
    - main
    - develop
    - feature/*

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: CredScan@3
  displayName: 'Credential Scanner'
  inputs:
    toolMajorVersion: 'V2'
    outputFormat: 'sarif'
    debugMode: false
  continueOnError: false

- task: Semmle@1
  displayName: 'CodeQL Security Analysis'
  inputs:
    sourceCodeDirectory: '$(Build.SourcesDirectory)'
    language: 'csharp'
    buildCommandLine: 'dotnet build --configuration Release'

- task: SonarCloudPrepare@1
  displayName: 'Prepare SonarCloud Analysis'
  inputs:
    SonarCloud: 'sonarcloud-connection'
    organization: 'myorg'
    scannerMode: 'MSBuild'
    projectKey: 'myproject'

- task: DotNetCoreCLI@2
  displayName: 'Build with SonarCloud'
  inputs:
    command: 'build'
    arguments: '--configuration Release'

- task: SonarCloudAnalyze@1
  displayName: 'Run SonarCloud Analysis'

- task: SonarCloudPublish@1
  displayName: 'Publish SonarCloud Results'
```

## 📁 **Repository Organization and Structure**

### Monorepo vs Multi-repo Strategies

#### Monorepo Structure

```text
enterprise-monorepo/
├── .azuredevops/
│   ├── pull_request_template.md
│   └── pipelines/
│       ├── ci-frontend.yml
│       ├── ci-backend.yml
│       └── ci-mobile.yml
├── apps/
│   ├── web-frontend/
│   │   ├── src/
│   │   ├── tests/
│   │   └── package.json
│   ├── mobile-app/
│   │   ├── ios/
│   │   ├── android/
│   │   └── shared/
│   └── admin-portal/
├── services/
│   ├── user-service/
│   ├── payment-service/
│   └── notification-service/
├── shared/
│   ├── libraries/
│   ├── types/
│   └── configs/
├── infrastructure/
│   ├── terraform/
│   ├── kubernetes/
│   └── scripts/
└── docs/
    ├── architecture/
    ├── api/
    └── deployment/
```

#### Multi-repo Organization

```yaml
Repository Strategy:
  Frontend Repositories:
    - web-app-frontend
    - mobile-app-ios
    - mobile-app-android
    - admin-dashboard
  
  Backend Services:
    - user-management-service
    - payment-processing-service
    - notification-service
    - api-gateway
  
  Shared Libraries:
    - shared-ui-components
    - shared-business-logic
    - shared-utilities
    - shared-types
  
  Infrastructure:
    - infrastructure-as-code
    - deployment-scripts
    - monitoring-configs
    - security-policies

Dependencies:
  - Package feeds for shared libraries
  - Git submodules for common configurations
  - Pipeline triggers across repositories
  - Unified versioning strategy
```

### File Organization Best Practices

#### Standard Repository Structure

```markdown
### Recommended Structure

```text
project-repository/
├── .azuredevops/           # Azure DevOps specific files
│   ├── pull_request_template.md
│   └── pipelines/
├── .github/                # GitHub integration (if applicable)
├── src/                    # Source code
│   ├── ProjectName/
│   ├── ProjectName.Tests/
│   └── ProjectName.Integration.Tests/
├── docs/                   # Documentation
│   ├── api/
│   ├── architecture/
│   └── user-guides/
├── scripts/                # Build and deployment scripts
├── infrastructure/         # IaC templates
├── tests/                  # Additional test files
├── .gitignore             # Git ignore rules
├── .gitattributes         # Git attributes
├── README.md              # Project overview
├── CONTRIBUTING.md        # Contribution guidelines
├── CHANGELOG.md           # Version history
└── LICENSE                # License information
```

### Branch Strategy Implementation

```bash
# Automated branch creation script
#!/bin/bash

# Function to create standardized branches
create_feature_branch() {
    local feature_name=$1
    local work_item_id=$2
    
    # Ensure we're on develop
    git checkout develop
    git pull origin develop
    
    # Create feature branch
    git checkout -b "feature/${work_item_id}-${feature_name}"
    
    # Push to remote
    git push -u origin "feature/${work_item_id}-${feature_name}"
    
    echo "Created feature branch: feature/${work_item_id}-${feature_name}"
}

create_release_branch() {
    local version=$1
    
    git checkout develop
    git pull origin develop
    git checkout -b "release/${version}"
    
    # Update version files
    echo $version > VERSION
    git add VERSION
    git commit -m "Bump version to ${version}"
    
    git push -u origin "release/${version}"
    
    echo "Created release branch: release/${version}"
}

# Usage examples
create_feature_branch "user-authentication" "US-123"
create_release_branch "v1.2.0"
```

## 🔍 **Advanced Git Operations**

### Git Hooks and Automation

#### Pre-commit Hook Setup

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Run linting
echo "Running code linting..."
npm run lint
if [ $? -ne 0 ]; then
    echo "Linting failed. Please fix errors before committing."
    exit 1
fi

# Run unit tests
echo "Running unit tests..."
npm test
if [ $? -ne 0 ]; then
    echo "Tests failed. Please fix failing tests before committing."
    exit 1
fi

# Check for secrets
echo "Scanning for secrets..."
git diff --cached --name-only | xargs grep -l "password\|secret\|key\|token" && {
    echo "Potential secrets detected. Please review your changes."
    exit 1
}

# Check commit message format
commit_msg=$(cat .git/COMMIT_EDITMSG)
if ! echo "$commit_msg" | grep -qE "^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?: .{1,50}"; then
    echo "Commit message must follow conventional commits format:"
    echo "type(scope): description"
    echo "Example: feat(auth): add OAuth 2.0 support"
    exit 1
fi

echo "Pre-commit checks passed!"
exit 0
```

#### Automated Workflow Scripts

```powershell
# PowerShell automation for common Git operations
function New-FeatureBranch {
    param(
        [Parameter(Mandatory)]
        [string]$FeatureName,
        [Parameter(Mandatory)]
        [string]$WorkItemId
    )
    
    # Validate work item exists
    $workItem = az boards work-item show --id $WorkItemId --org $Organization --query "fields.'System.Title'" -o tsv
    if (-not $workItem) {
        Write-Error "Work item $WorkItemId not found"
        return
    }
    
    # Create branch
    $branchName = "feature/$WorkItemId-$($FeatureName.ToLower() -replace '\s+', '-')"
    
    git checkout develop
    git pull origin develop
    git checkout -b $branchName
    git push -u origin $branchName
    
    # Link branch to work item
    az repos ref create --name "refs/heads/$branchName" --object-id (git rev-parse HEAD) --repository $Repository --project $Project
    
    Write-Host "Created feature branch: $branchName" -ForegroundColor Green
    Write-Host "Linked to work item: $WorkItemId - $workItem" -ForegroundColor Cyan
}

function Complete-FeatureBranch {
    param(
        [string]$TargetBranch = "develop",
        [switch]$DeleteSource,
        [switch]$SquashMerge
    )
    
    $currentBranch = git branch --show-current
    
    # Create pull request
    $prTitle = (git log --oneline -1 --pretty=format:"%s")
    $workItemId = ($currentBranch -split '-')[1]
    
    $pr = az repos pr create --title $prTitle --description "Resolves #$workItemId" --source-branch $currentBranch --target-branch $TargetBranch --work-items $workItemId --project $Project
    
    if ($pr) {
        Write-Host "Pull request created successfully!" -ForegroundColor Green
        Write-Host "URL: $($pr | ConvertFrom-Json | Select-Object -ExpandProperty url)" -ForegroundColor Cyan
    }
}
```

### Large File Management

#### Git LFS Configuration

```bash
# Install Git LFS
git lfs install

# Track file types
git lfs track "*.psd"
git lfs track "*.zip"
git lfs track "*.exe"
git lfs track "*.dll"
git lfs track "*.mp4"
git lfs track "*.mkv"
git lfs track "*.iso"

# Track specific directories
git lfs track "assets/**"
git lfs track "binaries/**"

# Commit .gitattributes
git add .gitattributes
git commit -m "Configure Git LFS tracking"

# Migration existing files to LFS
git lfs migrate import --include="*.psd,*.zip" --everything
```

#### LFS Best Practices

```markdown
### Git LFS Guidelines

**File Types for LFS:**
- Binary assets (images, videos, audio)
- Compiled binaries and libraries
- Archive files (zip, tar, etc.)
- Design files (PSD, AI, etc.)
- Documentation PDFs
- Large datasets

**Workflow Considerations:**
- Regular cleanup of LFS cache
- Bandwidth monitoring for large teams
- Storage quota management
- Backup strategies for LFS objects

**Commands:**
```bash
# View LFS files
git lfs ls-files

# Check LFS storage usage
git lfs env

# Clean LFS cache
git lfs prune

# Download all LFS objects
git lfs pull
```

## 📊 **Repository Analytics and Insights**

### Code Quality Metrics

#### Repository Health Dashboard

```json
{
  "repositoryMetrics": {
    "codeChurn": {
      "description": "Lines added/removed over time",
      "threshold": {
        "warning": ">50% weekly change",
        "critical": ">100% weekly change"
      }
    },
    "contributorActivity": {
      "description": "Number of active contributors",
      "threshold": {
        "healthy": ">3 regular contributors",
        "warning": "1-2 contributors",
        "critical": "Single contributor"
      }
    },
    "branchHealth": {
      "description": "Branch management metrics",
      "metrics": [
        "Average PR lifetime",
        "Stale branch count",
        "Merge conflicts frequency"
      ]
    },
    "securityMetrics": {
      "description": "Security-related indicators",
      "metrics": [
        "Secret scanning alerts",
        "Vulnerability scan results",
        "Dependency security issues"
      ]
    }
  }
}
```

#### Analytics PowerShell Script

```powershell
# Repository analytics script
function Get-RepositoryInsights {
    param(
        [string]$Organization,
        [string]$Project,
        [string]$Repository,
        [int]$DaysBack = 30
    )
    
    $headers = @{
        Authorization = "Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$Pat")))"
    }
    
    # Get commits
    $fromDate = (Get-Date).AddDays(-$DaysBack).ToString("yyyy-MM-ddTHH:mm:ssZ")
    $commitsUri = "$Organization/$Project/_apis/git/repositories/$Repository/commits?searchCriteria.fromDate=$fromDate&api-version=6.0"
    $commits = Invoke-RestMethod -Uri $commitsUri -Headers $headers
    
    # Get pull requests
    $prsUri = "$Organization/$Project/_apis/git/repositories/$Repository/pullrequests?searchCriteria.status=completed&api-version=6.0"
    $pullRequests = Invoke-RestMethod -Uri $prsUri -Headers $headers
    
    # Calculate metrics
    $insights = [PSCustomObject]@{
        Period = "$DaysBack days"
        TotalCommits = $commits.count
        UniqueContributors = ($commits.value | Group-Object { $_.author.email }).Count
        AverageCommitsPerDay = [math]::Round($commits.count / $DaysBack, 2)
        CompletedPullRequests = $pullRequests.count
        AveragePRLifetime = if ($pullRequests.count -gt 0) {
            $prLifetimes = $pullRequests.value | ForEach-Object {
                ([datetime]$_.closedDate - [datetime]$_.creationDate).TotalHours
            }
            [math]::Round(($prLifetimes | Measure-Object -Average).Average, 2)
        } else { 0 }
        TopContributors = $commits.value | Group-Object { $_.author.name } | 
                         Sort-Object Count -Descending | 
                         Select-Object -First 5 Name, Count
    }
    
    return $insights
}

# Usage
$insights = Get-RepositoryInsights -Organization "https://dev.azure.com/MyOrg" -Project "MyProject" -Repository "MyRepo"
$insights | Format-List
```

### Compliance and Audit

#### Audit Trail Configuration

```yaml
# Compliance monitoring configuration
compliance_settings:
  audit_logging:
    - repository_access: enabled
    - branch_policy_changes: enabled
    - permission_modifications: enabled
    - secret_access: enabled
  
  retention_policies:
    - audit_logs: 7_years
    - repository_data: permanent
    - pull_request_history: permanent
    - build_logs: 2_years
  
  compliance_reports:
    - frequency: monthly
    - recipients: ["compliance-team@company.com"]
    - include_metrics:
      - code_review_coverage
      - security_scan_results
      - policy_violations
      - access_control_changes
  
  data_classification:
    - public: open_source_projects
    - internal: business_applications
    - confidential: security_sensitive
    - restricted: regulated_data
```

## 🔧 **Integration and Automation**

### Azure DevOps Services Integration

#### Boards Integration

```yaml
# Work item linking in commits and PRs
commit_conventions:
  formats:
    - "#{work_item_id}: {description}"
    - "Fixes #{work_item_id}: {description}"
    - "Closes AB#{work_item_id}: {description}"
  
  examples:
    - "#123: Implement user authentication"
    - "Fixes #456: Resolve login timeout issue"
    - "Closes AB#789: Add payment processing feature"

pull_request_automation:
  - auto_link_work_items: true
  - complete_work_items_on_merge: true
  - transition_work_items: 
      from: "Active"
      to: "Resolved"
  - add_comments_to_work_items: true
```

#### Pipelines Integration

```yaml
# Repository triggers for pipelines
trigger:
  branches:
    include:
    - main
    - develop
    - release/*
  paths:
    include:
    - src/*
    - tests/*
    exclude:
    - docs/*
    - README.md

# Multi-repository triggers
resources:
  repositories:
  - repository: shared-libraries
    type: git
    name: MyProject/SharedLibraries
    trigger:
      branches:
        include:
        - main
  
  - repository: infrastructure
    type: git
    name: MyProject/Infrastructure
    trigger:
      branches:
        include:
        - main

stages:
- stage: Build
  condition: or(eq(variables['Build.SourceBranch'], 'refs/heads/main'), startsWith(variables['Build.SourceBranch'], 'refs/heads/feature/'))
  jobs:
  - job: BuildJob
    steps:
    - checkout: self
    - checkout: shared-libraries
    - script: echo "Building with shared libraries"
```

### Third-party Tool Integration

#### GitHub Integration

```yaml
# GitHub mirror setup
github_integration:
  mirror_settings:
    - source: "Azure DevOps Repo"
    - target: "GitHub Repository"
    - sync_frequency: "real-time"
    - sync_direction: "bidirectional"
  
  webhook_configuration:
    - events: ["push", "pull_request", "issues"]
    - target_url: "https://dev.azure.com/webhook/github"
    - secret: "${GITHUB_WEBHOOK_SECRET}"
  
  action_workflows:
    - trigger_azure_pipelines: true
    - sync_work_items: true
    - mirror_releases: true
```

#### IDE Integration

```json
{
  "vscode_settings": {
    "git.enableSmartCommit": true,
    "git.autofetch": true,
    "azureDevOps.organization": "https://dev.azure.com/MyOrg",
    "azureDevOps.project": "MyProject",
    "azureDevOps.workItemTracking": true,
    
    "extensions": [
      "ms-vscode.azure-repos",
      "ms-azure-devops.azure-pipelines",
      "ms-vscode.vscode-pull-request-azuredevops"
    ]
  },
  
  "visual_studio_settings": {
    "teamExplorer.defaultCollection": "https://dev.azure.com/MyOrg",
    "sourceControl.autoCommitWorkItems": true,
    "codeReview.enableInlineComments": true
  }
}
```

## 🛠️ **Troubleshooting and Best Practices**

### Common Issues and Solutions

#### Large Repository Management

```bash
# Repository cleanup and optimization
#!/bin/bash

# Clean up large files and optimize repository
git_cleanup() {
    echo "Starting repository cleanup..."
    
    # Remove deleted files from history
    git filter-branch --force --index-filter \
        'git rm --cached --ignore-unmatch *.log *.tmp' \
        --prune-empty --tag-name-filter cat -- --all
    
    # Clean up references
    git for-each-ref --format='delete %(refname)' refs/original | git update-ref --stdin
    git reflog expire --expire=now --all
    git gc --prune=now --aggressive
    
    echo "Repository cleanup completed!"
}

# Monitor repository size
check_repo_size() {
    echo "Repository size analysis:"
    echo "========================"
    
    # Total repository size
    du -sh .git
    
    # Largest files in repository
    git rev-list --objects --all | 
    git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' |
    sed -n 's/^blob //p' |
    sort --numeric-sort --key=2 |
    tail -20
}

# Usage
# git_cleanup
# check_repo_size
```

#### Permission and Access Issues

```powershell
# Diagnose and fix common access issues
function Test-RepositoryAccess {
    param(
        [string]$RepositoryUrl,
        [string]$Username,
        [string]$Pat
    )
    
    try {
        # Test basic authentication
        $headers = @{
            Authorization = "Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$Username`:$Pat")))"
        }
        
        # Extract org and project from URL
        $urlParts = $RepositoryUrl -split '/'
        $org = $urlParts[3]
        $project = $urlParts[4]
        $repo = $urlParts[6]
        
        # Test repository access
        $uri = "https://dev.azure.com/$org/$project/_apis/git/repositories/$repo?api-version=6.0"
        $response = Invoke-RestMethod -Uri $uri -Headers $headers
        
        Write-Host "✓ Repository access successful" -ForegroundColor Green
        Write-Host "Repository: $($response.name)" -ForegroundColor Cyan
        Write-Host "Default Branch: $($response.defaultBranch)" -ForegroundColor Cyan
        
        # Test clone access
        $cloneTest = git ls-remote $RepositoryUrl
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Clone access successful" -ForegroundColor Green
        } else {
            Write-Host "✗ Clone access failed" -ForegroundColor Red
        }
        
    } catch {
        Write-Host "✗ Repository access failed: $($_.Exception.Message)" -ForegroundColor Red
        
        # Common troubleshooting steps
        Write-Host "`nTroubleshooting steps:" -ForegroundColor Yellow
        Write-Host "1. Verify PAT has correct permissions (Code: Read/Write)" -ForegroundColor White
        Write-Host "2. Check PAT expiration date" -ForegroundColor White
        Write-Host "3. Verify repository URL format" -ForegroundColor White
        Write-Host "4. Ensure user has access to the project" -ForegroundColor White
    }
}
```

### Performance Optimization

#### Repository Performance Tuning

```markdown
### Performance Best Practices

**Repository Structure:**
- Keep repositories focused and cohesive
- Separate large binary assets to different repos
- Use Git LFS for large files (>100MB)
- Implement proper .gitignore patterns

**Branch Management:**
- Regular cleanup of merged branches
- Limit long-running branches
- Use shallow clones for CI/CD
- Implement branch naming conventions

**Clone Optimization:**
```bash
# Shallow clone for CI/CD
git clone --depth 1 --single-branch --branch main <repo-url>

# Partial clone (Git 2.19+)
git clone --filter=blob:none <repo-url>

# Sparse checkout for large repositories
git clone --filter=blob:none --sparse <repo-url>
cd <repo>
git sparse-checkout init --cone
git sparse-checkout set src/ docs/
```

**Build Performance:**

- Use build caching strategies
- Implement incremental builds
- Parallel pipeline execution
- Artifact reuse across stages

```bash

---

## 📖 **Additional Resources**

- [Azure Repos Documentation](https://docs.microsoft.com/en-us/azure/devops/repos/)
- [Git Best Practices](https://docs.microsoft.com/en-us/azure/devops/repos/git/git-best-practices)
- [Branch Policies Reference](https://docs.microsoft.com/en-us/azure/devops/repos/git/branch-policies)
- [Pull Request Guidelines](https://docs.microsoft.com/en-us/azure/devops/repos/git/pullrequest)

[Back to Azure DevOps Getting Started](getting-started.md) | [Back to Development Home](../index.md)
