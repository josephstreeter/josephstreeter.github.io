---
title: "Code Wiki Implementation"
description: "Publishing documentation from a Git repository as a code wiki"
author: "Joseph Streeter"
tags: ["azure devops", "documentation", "code wiki", "git", "implementation"]
category: "development"
last_updated: "2026-08-01"
---
## 4. Code Wiki Implementation

### 4.1 Creating a Code Wiki

**Prerequisites:**

- Git repository exists in Azure DevOps
- Repository contains a `/docs` folder with Markdown files
- At minimum, a `README.md` file in `/docs`

**Steps:**

1. **Navigate to repository**
   - Azure DevOps → Repos → Files
   - Select your repository

2. **Create /docs folder** (if it doesn't exist)

   ```bash
   # In your local clone
   mkdir docs
   cd docs
   
   # Create initial README
   cat > README.md << 'EOF'
   # Service Name
   
   ## Overview
   Brief description of this service.
   
   ## Documentation Sections
   - Architecture
   - Operations
   - Development
   EOF
   
   git add docs/
   git commit -m "docs: initialize documentation structure"
   git push
   ```

3. **Publish as code wiki**
   - Azure DevOps → Overview → Wiki
   - Click dropdown next to wiki name → **Publish code as wiki**
   - Select repository: [your-repo]
   - Select branch: `main` (or `master`)
   - Select folder: `/docs`
   - Wiki name: [Service Name Documentation]
   - Click **Publish**

4. **Wiki is now live**
   - Accessible via Wiki menu
   - Updates automatically when `/docs` changes are merged
   - Can publish multiple code wikis from different repos or folders

### 4.2 Standard Code Wiki Structure

**Template structure for every service:**

```text
/docs
├── .order                          # Page order configuration
├── README.md                       # Home page (service overview)
├── Architecture.md                 # Architecture documentation
├── .attachments/                   # Images and files
│   ├── architecture-diagram.png
│   ├── api-flow.png
│   └── monitoring-dashboard.png
│
├── Getting-Started.md              # Quick start guide
├── API/
│   ├── .order
│   ├── Overview.md
│   ├── Authentication.md
│   ├── Endpoints.md
│   ├── Rate-Limits.md
│   └── Examples.md
│
├── Operations/
│   ├── .order
│   ├── Deployment.md               # Deployment procedures
│   ├── Configuration.md            # Configuration guide
│   ├── Monitoring.md               # Monitoring and alerting
│   ├── Troubleshooting.md          # Common issues
│   ├── Runbook.md                  # Operational runbook
│   ├── Backup-Recovery.md          # Backup and recovery
│   └── Disaster-Recovery.md        # DR procedures
│
├── Development/
│   ├── .order
│   ├── Local-Setup.md              # Local dev environment
│   ├── Testing.md                  # Testing guide
│   ├── Contributing.md             # Contribution guidelines
│   ├── Code-Standards.md           # Coding standards
│   └── Release-Process.md          # Release procedures
│
└── Integration/
    ├── .order
    ├── Overview.md
    ├── Exchange-Online.md          # Specific integrations
    ├── Active-Directory.md
    └── Monitoring-System.md
```

### 4.3 README.md Template for Code Wiki

**Every service's `/docs/README.md` should follow this template:**

```markdown
# [Service Name]

## Overview

[2-3 sentence description of what this service does and why it exists]

**Status:** 🟢 Production  
**Team:** [Team Name]  
**Owner:** [Name/Email]

## Quick Links

- *Architecture* (*Architecture.md* - placeholder)
- *Operations Runbook* (*Operations/Runbook.md* - placeholder)
- *API Documentation* (*API/Overview.md* - placeholder)
- *Deployment Guide* (*Operations/Deployment.md* - placeholder)
- *Troubleshooting* (*Operations/Troubleshooting.md* - placeholder)

## Service Information

| Attribute | Value |
|-----------|-------|
| **Service Type** | [Web Service / Background Service / Database / Other] |
| **Technology Stack** | [.NET 6 / Python 3.9 / Java / etc.] |
| **Hosting** | [Azure App Service / Kubernetes / VMs / etc.] |
| **Dependencies** | [List key dependencies] |
| **Repository** | [Link to repo] |
| **CI/CD Pipeline** | [Link to pipeline] |
| **Monitoring Dashboard** | [Link to dashboard] |

## Architecture

[High-level architecture diagram or link to Architecture.md]

For detailed architecture documentation, see Architecture.

## Getting Started

### For Operators
- *Deployment Guide* (*Operations/Deployment.md* - placeholder)
- *Configuration Guide* (*Operations/Configuration.md* - placeholder)
- *Monitoring Guide* (*Operations/Monitoring.md* - placeholder)

### For Developers
- *Local Development Setup* (*Development/Local-Setup.md* - placeholder)
- *Contributing Guidelines* (*Development/Contributing.md* - placeholder)
- *Testing Guide* (*Development/Testing.md* - placeholder)

### For Consumers/Integrators
- *API Documentation* (*API/Overview.md* - placeholder)
- *Integration Examples* (*API/Examples.md* - placeholder)
- *Integration Guides* (*Integration/Overview.md* - placeholder)

## Support

- **On-Call:** [Link to PagerDuty/on-call schedule]
- **Team Email:** [team@company.com](mailto:team@company.com)
- **Slack Channel:** [#team-channel](https://slack.com/link)
- **Create Issue:** [Azure DevOps Backlog](link-to-board)

## Recent Changes

[Link to CHANGELOG.md or recent commits]

## Related Documentation

- [Enterprise Architecture](/Architecture) (Project Wiki)
- [Operational Procedures](/Operations) (Project Wiki)
- [Related Service A](link-to-code-wiki)
- [Related Service B](link-to-code-wiki)

---
*This documentation is maintained by [Team Name]. Last reviewed: [Date]*
```

### 4.4 Creating .order Files

**Purpose:** Controls the order of pages in wiki navigation

**Location:** Place `.order` file in each folder containing Markdown files

**Format:** One filename per line (without .md extension), one per line

**Example `/docs/.order`:**

```text
README
Getting-Started
Architecture
API
Operations
Development
Integration
```

**Example `/docs/Operations/.order`:**

```text
Deployment
Configuration
Monitoring
Troubleshooting
Runbook
Backup-Recovery
Disaster-Recovery
```

**Best practices:**

- Order from most commonly accessed to least
- Group related topics together
- Keep README/Overview first
- List "Getting Started" early
- Operational docs before development docs (for most audiences)

### 4.5 Multi-Version Documentation

**Challenge:** Code wikis can only show one branch at a time in the UI

**Solution options:**

#### Option 1: Document Multiple Versions in Same Wiki (Simple)

Create version-specific pages:

```text
/docs
├── README.md                    # Latest version
├── Versions/
│   ├── Version-2.0.md           # Version 2.0 documentation
│   ├── Version-1.5.md           # Version 1.5 documentation
│   └── Version-1.0.md           # Version 1.0 documentation (deprecated)
```

**Home page links to versions:**

```markdown
## Documentation Versions

- *Version 2.0 (Latest)* (*Versions/Version-2.0.md* - placeholder) - Current production
- *Version 1.5* (*Versions/Version-1.5.md* - placeholder) - Legacy production (supported until 2026)
- *Version 1.0* (*Versions/Version-1.0.md* - placeholder) - Deprecated (unsupported)
```

#### Option 2: Use Git Tags and Branches (Advanced)

**For major version branches:**

```bash
# Create long-lived branch for v1.x
git checkout -b release/v1.x

# Documentation in /docs reflects v1.x
# Continue maintaining v1.x docs on this branch

# Meanwhile, main branch has v2.x documentation
```

**Publish multiple code wikis:**

1. Publish wiki from `main` branch → "Service Name v2.x"
2. Publish wiki from `release/v1.x` branch → "Service Name v1.x"

**Pros:** True version separation, can maintain in parallel  
**Cons:** Multiple wikis to manage, users must know which to access

#### Option 3: Use Release Tags

**Tag releases in Git:**

```bash
git tag -a v2.0.0 -m "Version 2.0.0 release"
git push --tags
```

**In documentation, reference tags:**

```markdown
## Version History

- [v2.0.0](https://dev.azure.com/org/project/_git/repo?version=GTv2.0.0&path=/docs/README.md) - Latest
- [v1.5.0](https://dev.azure.com/org/project/_git/repo?version=GTv1.5.0&path=/docs/README.md) - Legacy
```

Users can browse Git repository at specific tags to see documentation for that version.

**Recommendation:** Start with Option 1 (version pages in same wiki). Move to Option 2 only if you need to actively maintain documentation for multiple major versions.

### 4.6 Connecting Code Wiki to Project Wiki

**In Project Wiki service catalog, link to code wikis:**

```markdown
## Email Gateway Service

**Description:** FortiMail-based secure email gateway for application SMTP relay

**Owner:** IAM Team  
**Status:** 🟢 Production

**Documentation:**
- [Code Wiki (Detailed Technical Docs)](https://dev.azure.com/org/project/_wiki/wikis/email-gateway-docs)
- [Repository](https://dev.azure.com/org/project/_git/email-gateway)
- [CI/CD Pipeline](https://dev.azure.com/org/project/_build?definitionId=42)
- [Monitoring Dashboard](https://grafana.company.com/email-gateway)

**Quick Links:**
- [Operations Runbook](https://dev.azure.com/org/project/_wiki/wikis/email-gateway-docs?pagePath=/Operations/Runbook)
- [API Documentation](https://dev.azure.com/org/project/_wiki/wikis/email-gateway-docs?pagePath=/API/Overview)
- [Troubleshooting](https://dev.azure.com/org/project/_wiki/wikis/email-gateway-docs?pagePath=/Operations/Troubleshooting)
```

**In code wiki home page, link back to Project Wiki:**

```markdown
# Email Gateway Documentation

For enterprise-wide operational procedures, see the [Enterprise IT Documentation](https://dev.azure.com/org/project/_wiki/wikis/enterprise-it-docs) project wiki:
- [Incident Response Procedures](/Operations/Incident-Response)
- [Change Management](/Operations/Change-Management)
- [On-Call Procedures](/Operations/On-Call)
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
