---
title: "Project Wiki Implementation"
description: "Creating and operating an Azure DevOps project wiki"
author: "Joseph Streeter"
tags: ["azure devops", "documentation", "project wiki", "implementation"]
category: "development"
last_updated: "2026-08-01"
---
## 3. Project Wiki Implementation

### 3.1 Creating a Project Wiki

**Via Azure DevOps Web UI:**

1. Navigate to your Azure DevOps project
2. Click **Overview** → **Wiki**
3. Click **Create Project Wiki**
4. Choose wiki name (e.g., "Enterprise IT Documentation")
5. Wiki is created with a default home page

**The wiki is now backed by a hidden Git repository.**

### 3.2 Working with Project Wiki

**Two methods to edit:**

#### Method A: Web-Based Editing (Simple)

**Best for:**

- Quick edits
- Non-technical users
- Single-page changes

**Process:**

1. Navigate to wiki page
2. Click **Edit**
3. Make changes in web editor
4. Click **Save** (commits directly to main branch)
5. Optionally add commit message

**Limitations:**

- No pull request workflow
- No local editing
- No branching
- Limited to one page at a time

#### Method B: Git-Based Editing (Recommended)

**Best for:**

- Large changes
- Multiple pages
- Technical users
- Pull request workflow
- Offline editing

**Process:**

#### Step 1: Clone the wiki repository

```bash
# Get the wiki clone URL from Azure DevOps
# Wiki → More options (...) → Clone wiki

git clone https://dev.azure.com/organization/project/_git/project.wiki
cd project.wiki
```

#### Step 2: Create a branch for your changes

```bash
git checkout -b docs/update-incident-response
```

#### Step 3: Make changes locally

```bash
# Edit files in your favorite editor
code Operations/Incident-Response.md

# Add images to .attachments folder if needed
cp ~/diagram.png .attachments/incident-flow.png
```

#### Step 4: Commit and push

```bash
git add .
git commit -m "docs: update incident response procedures with new escalation path"
git push origin docs/update-incident-response
```

#### Step 5: Create pull request

1. Go to Azure DevOps → Repos → Pull Requests
2. Create new pull request from your branch to `wikiMain`
3. Add reviewers
4. Link to work item if applicable
5. Reviewers approve
6. Complete pull request (squash or merge)
7. Wiki automatically updates

### 3.3 Project Wiki Best Practices

#### 3.3.1 Home Page Structure

**Recommended home page (`Home.md`):**

```markdown
# Enterprise IT Documentation

Welcome to the Enterprise IT documentation repository. This wiki contains operational procedures, standards, and guidelines for IT services.

## Quick Links

- [On-Call Procedures](/Operations/On-Call)
- [Incident Response](/Operations/Incident-Response)
- [Service Catalog](/Services/Catalog)
- [Team Directory](/About/Team-Directory)

## Documentation Sections

### [Getting Started](/Getting-Started)
New to the team? Start here for onboarding information.

### [Standards](/Standards)
Coding standards, security policies, and best practices.

### [Architecture](/Architecture)
Enterprise architecture documentation and diagrams.

### [Operations](/Operations)
Operational runbooks, procedures, and on-call guides.

### [Services](/Services)
Catalog of all IT services with links to detailed documentation.

## How to Contribute

See [Contributing Guide](/About/Contributing) for information on how to update this documentation.

## Support

For questions or issues with this documentation:
- Create an issue in the [documentation backlog](link-to-board)
- Contact: [documentation-team@company.com](mailto:documentation-team@company.com)

---
*Last updated: 2025-01-15*
```

#### 3.3.2 Table of Contents

##### Option 1: Use wiki navigation (automatic)

- Azure DevOps automatically generates left navigation from folder structure
- Use `.order` files to control ordering
- Good for most use cases

##### Option 2: Create explicit TOC page

- Create `Table-of-Contents.md` with links to major sections
- Good for large wikis with complex structure
- Provides "map" for readers

**Example TOC page:**

```markdown
# Documentation Table of Contents

## Operational Documentation
1. [Incident Response](/Operations/Incident-Response)
2. [Change Management](/Operations/Change-Management)
3. [On-Call Procedures](/Operations/On-Call)
4. [Monitoring and Alerting](/Operations/Monitoring)

## Service Documentation
- [Email Gateway (FortiMail)](/Services/Email-Gateway) → [Detailed Docs](link-to-code-wiki)
- [Database Platform](/Services/Database-Platform) → [Detailed Docs](link-to-code-wiki)
- [Monitoring Infrastructure](/Services/Monitoring) → [Detailed Docs](link-to-code-wiki)

## Architecture
- [Enterprise Architecture](/Architecture/Overview)
- [Network Architecture](/Architecture/Network)
- [Security Architecture](/Architecture/Security)
- [Cloud Architecture](/Architecture/Cloud)

## Standards & Policies
- [Coding Standards](/Standards/Coding)
- [Documentation Standards](/Standards/Documentation)
- [Security Standards](/Standards/Security)
- [Access Control Policy](/Policies/Access-Control)
```

#### 3.3.3 Cross-Linking Strategy

**Link types:**

**1. Internal wiki links (within same wiki):**

```markdown
See [Incident Response](/Operations/Incident-Response) for procedures.
```

**2. Links to code wikis:**

```markdown
For detailed technical documentation, see the [Email Gateway Code Wiki](https://dev.azure.com/org/project/_git/email-gateway.wiki).
```

**3. Links to Azure DevOps work items:**

```markdown
This addresses work item #12345.
```

**4. Links to repositories:**

```markdown
View the [source code](https://dev.azure.com/org/project/_git/email-gateway).
```

**5. Links to pipelines:**

```markdown
Deployment pipeline: [Email Gateway Deploy](https://dev.azure.com/org/project/_build?definitionId=42).
```

**Best practices for linking:**

- Use relative links within same wiki: `/Operations/Runbook` not full URL
- Always use descriptive link text: `[incident response procedures]` not `[click here]`
- Verify links don't break when pages are renamed
- Include links to related documentation at bottom of pages

### 3.4 Service Catalog Page

**Create a central service catalog in Project Wiki:**

**`/Services/Catalog.md`:**

```markdown
# IT Services Catalog

This page catalogs all IT services, their owners, and links to detailed documentation.

## Production Services

| Service Name | Description | Status | Owner | Documentation | Repository |
|--------------|-------------|--------|-------|---------------|------------|
| Email Gateway | FortiMail secure email relay | 🟢 Production | IAM Team | [Code Wiki](link) | [Repo](link) |
| Database Platform | SQL Server platform | 🟢 Production | Data Team | [Code Wiki](link) | [Repo](link) |
| Monitoring | Prometheus + Grafana | 🟢 Production | Ops Team | [Code Wiki](link) | [Repo](link) |
| Identity Platform | Active Directory | 🟢 Production | IAM Team | [Code Wiki](link) | [Repo](link) |

## In Development

| Service Name | Description | Status | Owner | Documentation | Repository |
|--------------|-------------|--------|-------|---------------|------------|
| API Gateway | Kong API gateway | 🟡 Development | Platform Team | [Code Wiki](link) | [Repo](link) |

## Legend
- 🟢 Production: Live and supported
- 🟡 Development: Under development
- 🔴 Deprecated: Being phased out
- ⚫ Decommissioned: No longer in use

## Adding a New Service

When creating a new service:
1. Create repository
2. Add `/docs` folder with documentation
3. Publish as code wiki
4. Add entry to this catalog
5. Notify [documentation-team@company.com](mailto:documentation-team@company.com)

See [Documentation Standards](/Standards/Documentation) for requirements.
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
