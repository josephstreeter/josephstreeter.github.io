---
title: "Azure DevOps Repository Setup"
description: "Configure Azure DevOps for Documentation as Code implementation"
tags: ["azure-devops", "git", "repository", "collaboration", "version-control"]
category: "development"
difficulty: "intermediate"
last_updated: "2025-07-06"
---

## Azure DevOps Repository Setup

This guide walks through configuring Azure DevOps as the foundation for your Documentation as Code implementation. Azure DevOps provides enterprise-grade source control, collaboration tools, and integration capabilities essential for professional documentation workflows.

## Prerequisites

Before starting, ensure you have:

- Azure DevOps organization access with Project Administrator permissions
- Basic understanding of Git workflows
- Team member list with assigned roles
- Project naming and structure decisions made

## Organization Setup

### Creating or Accessing Organization

**New Organization Creation:**

1. Navigate to [dev.azure.com](https://dev.azure.com)
2. Sign in with your Azure account
3. Click "New organization" if needed
4. Choose organization name and region
5. Configure initial security settings

**Existing Organization Access:**

1. Verify organization permissions
2. Check available project limits
3. Review billing and licensing
4. Validate security policies

### Organization Configuration

**Security Settings:**

```yaml
# Example organization security configuration
security:
  policies:
    - name: "Require branch policies"
      enabled: true
    - name: "Limit visibility to organization"
      enabled: true
    - name: "Restrict external guest access"
      enabled: true
  
  authentication:
    - method: "Azure AD integration"
      required: true
    - method: "Multi-factor authentication"
      required: true
```

**Billing Configuration:**

- Set up appropriate billing account
- Configure user licensing (Basic vs. Basic + Test Plans)
- Set spending limits if applicable
- Enable required extensions

## Project Creation

### Project Setup

**Creating Documentation Project:**

1. **Project Details:**
   - **Name**: `Documentation-as-Code` or organization-specific name
   - **Description**: "Central documentation repository and deployment pipeline"
   - **Visibility**: Private (recommended) or Public based on requirements
   - **Version Control**: Git
   - **Work Item Process**: Agile (recommended for documentation workflows)

2. **Initial Configuration:**

```bash
# Create project using Azure CLI
az devops project create \
  --name "Documentation-as-Code" \
  --description "Documentation as Code implementation" \
  --visibility private \
  --process agile
```

### Team Setup

**Team Configuration:**

| Role | Responsibilities | Permissions |
|------|----------------|------------|
| **Documentation Owners** | Content strategy, final approvals | Project Administrator |
| **Content Authors** | Writing, editing, reviewing | Contributor |
| **Developers** | Technical content, API docs | Contributor |
| **Reviewers** | Quality assurance, editing | Reader + specific repo permissions |

**Adding Team Members:**

```bash
# Add users to project
az devops user add \
  --email-id user@organization.com \
  --license-type basic \
  --project-id PROJECT_ID
```

## Repository Configuration

### Repository Creation

**Main Documentation Repository:**

1. **Repository Details:**
   - **Name**: `docs` or `documentation`
   - **Type**: Git
   - **Initialize**: Add README and .gitignore
   - **Default Branch**: `main`

2. **Repository Structure:**

```text
docs/
├── .azure-pipelines/          # CI/CD pipeline definitions
├── .github/                   # GitHub integration (if applicable)
├── .vscode/                   # VS Code settings and extensions
├── content/                   # Documentation content
│   ├── articles/              # Long-form articles
│   ├── tutorials/             # Step-by-step guides
│   ├── reference/             # Reference documentation
│   └── api/                   # API documentation
├── templates/                 # DocFX templates and themes
├── tools/                     # Build and deployment scripts
├── .gitignore                 # Git ignore patterns
├── README.md                  # Repository documentation
├── docfx.json                 # DocFX configuration
└── toc.yml                    # Table of contents
```

### Branch Policies

**Main Branch Protection:**

```json
{
  "isEnabled": true,
  "isBlocking": true,
  "settings": {
    "minimumApproverCount": 2,
    "creatorVoteCounts": false,
    "allowDownvotes": true,
    "resetOnSourcePush": true,
    "requireCommenterResolution": true,
    "blockLastPusherVote": true
  }
}
```

**Policy Configuration Steps:**

1. Navigate to **Repos** → **Branches** → **main branch**
2. Click **Branch policies**
3. Configure required policies:

**Required Policies:**

- **Require a minimum number of reviewers**: 2 reviewers minimum
- **Check for linked work items**: Optional but recommended
- **Check for comment resolution**: All comments must be resolved
- **Limit merge types**: Squash merge recommended
- **Build validation**: Require successful build

**Build Validation Policy:**

```yaml
# Build validation configuration
trigger:
  branches:
    include:
    - main
    - develop
    - feature/*

pr:
  branches:
    include:
    - main
    - develop

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: DocfxTask@0
  displayName: 'Build Documentation'
  inputs:
    solution: 'docfx.json'
```

### Security Configuration

**Repository Permissions:**

| Group | Permissions | Justification |
|-------|------------|---------------|
| **Project Administrators** | Full Control | Complete repository management |
| **Build Service** | Contribute | Automated build and deployment |
| **Content Authors** | Contribute | Create and edit content |
| **Reviewers** | Read | Review and comment on changes |

**Service Connections:**

Set up service connections for:

- Azure subscription (for App Service deployment)
- Package feeds (for DocFX packages)
- External repositories (if needed)
- Notification services (Slack, Teams, etc.)

## Workflow Configuration

### Git Workflow Strategy

**Recommended Branching Strategy:**

```text
main                    # Production-ready content
├── develop            # Integration branch
├── feature/new-guide  # Feature branches for content
├── hotfix/typo-fix    # Critical fixes
└── release/v1.2       # Release preparation
```

**Branch Naming Conventions:**

- **Feature branches**: `feature/topic-name` or `feature/author-topic`
- **Hotfix branches**: `hotfix/issue-description`
- **Release branches**: `release/version-number`
- **Documentation branches**: `docs/section-name`

### Pull Request Templates

**PR Template Configuration:**

Create `.azuredevops/pull_request_template.md`:

```markdown
## Documentation Change Summary

### Type of Change
- [ ] New content creation
- [ ] Content update/revision
- [ ] Structure/navigation changes
- [ ] Template/styling updates
- [ ] Configuration changes

### Description
Brief description of the changes made.

### Content Areas Affected
- [ ] Getting Started
- [ ] API Documentation
- [ ] Tutorials
- [ ] Reference Materials
- [ ] Templates/Themes

### Review Checklist
- [ ] Content follows style guide
- [ ] Links are working and appropriate
- [ ] Images are optimized and have alt text
- [ ] Metadata is complete and accurate
- [ ] Table of contents updated if needed
- [ ] Build succeeds locally

### Testing Performed
- [ ] Local build successful
- [ ] Links validated
- [ ] Content preview reviewed
- [ ] Cross-browser testing (if applicable)

### Additional Notes
Any additional context or notes for reviewers.
```

## Integration Setup

### Work Item Integration

**Linking Documentation to Work Items:**

1. **Epic Level**: Major documentation initiatives
2. **Feature Level**: Specific content areas or guides
3. **User Story Level**: Individual articles or updates
4. **Task Level**: Specific writing or editing tasks

**Work Item Templates:**

```json
{
  "name": "Documentation User Story",
  "description": "Template for documentation content creation",
  "fields": {
    "Title": "Create [Content Type] for [Topic]",
    "Description": "Detailed description of content requirements",
    "AcceptanceCriteria": "Content quality and completeness criteria",
    "Tags": "documentation, content-type, priority"
  }
}
```

### Notification Configuration

**Team Notifications:**

Configure notifications for:

- Pull request creation and updates
- Build successes and failures
- Code review assignments
- Work item updates
- Release deployments

**Notification Channels:**

```yaml
# Example notification configuration
notifications:
  channels:
    - type: "email"
      events: ["pull-request-created", "build-failed"]
      recipients: ["documentation-team@organization.com"]
    
    - type: "teams"
      webhook: "https://organization.webhook.office.com/..."
      events: ["deployment-completed", "release-created"]
    
    - type: "slack"
      webhook: "https://hooks.slack.com/services/..."
      events: ["pull-request-merged", "build-successful"]
```

## Quality Gates

### Automated Validation

**Pre-commit Hooks:**

```bash
#!/bin/sh
# .git/hooks/pre-commit
# Validate markdown and run basic checks

echo "Running pre-commit validation..."

# Check for large files
find . -size +5M -type f -not -path "./.git/*" | grep -E '\.(jpg|jpeg|png|gif|pdf)$' && {
    echo "Error: Large files detected. Please optimize images or use Git LFS."
    exit 1
}

# Validate markdown
markdownlint content/**/*.md || {
    echo "Error: Markdown validation failed."
    exit 1
}

# Check for broken internal links
markdown-link-check content/**/*.md || {
    echo "Warning: Broken links detected. Please review."
}

echo "Pre-commit validation passed."
```

**Pull Request Validation:**

1. **Automated Build**: DocFX build must succeed
2. **Link Validation**: Internal and external links checked
3. **Style Validation**: Markdown linting passes
4. **Content Review**: Human review required
5. **Approval Gates**: Minimum reviewer requirements met

## Monitoring and Analytics

### Repository Analytics

**Key Metrics to Track:**

- Commit frequency and authors
- Pull request metrics (time to merge, review cycles)
- Build success/failure rates
- Content addition/modification patterns
- User engagement with documentation

**Azure DevOps Analytics:**

Configure dashboards to monitor:

```yaml
# Example analytics configuration
dashboards:
  - name: "Documentation Metrics"
    widgets:
      - type: "build-history"
        query: "Build Definition: Documentation"
      - type: "pull-request-metrics"
        timeframe: "30 days"
      - type: "code-coverage"
        source: "documentation-coverage"
      - type: "work-item-progress"
        area: "Documentation"
```

## Troubleshooting

### Common Issues

**Permission Problems:**

- Verify organization and project permissions
- Check service connection authentication
- Validate branch policy configurations
- Review security group memberships

**Build Failures:**

- Check DocFX configuration syntax
- Verify file paths and references
- Review build agent capabilities
- Validate package dependencies

**Integration Issues:**

- Test service connections
- Verify webhook configurations
- Check notification settings
- Validate work item linking

### Resolution Steps

**Diagnostic Process:**

1. **Check Azure DevOps Service Health**: Verify no platform issues
2. **Review Activity Logs**: Examine recent changes and events
3. **Validate Configurations**: Compare with working examples
4. **Test Incrementally**: Isolate issues through minimal reproductions
5. **Engage Support**: Use Azure DevOps support channels if needed

## Next Steps

After completing Azure DevOps setup:

1. **[Configure DocFX Project](docfx-configuration.md)** - Set up static site generation
2. **[Create Azure App Service](azure-app-service.md)** - Configure hosting infrastructure
3. **[Team Onboarding](../advanced/team-training.md)** - Train team members on workflows
4. **[Content Planning](../content/content-strategy.md)** - Develop content strategy

## Additional Resources

- [Azure DevOps Git Documentation](https://docs.microsoft.com/en-us/azure/devops/repos/git/index.md)
- [Branch Policies Reference](https://docs.microsoft.com/en-us/azure/devops/repos/git/branch-policies)
- [Pull Request Best Practices](https://docs.microsoft.com/en-us/azure/devops/repos/git/pull-requests)
- [Azure DevOps Security Guide](https://docs.microsoft.com/en-us/azure/devops/organizations/security/index.md)

---

*This Azure DevOps setup provides a robust foundation for collaborative documentation development with enterprise-grade security and workflow management.*
