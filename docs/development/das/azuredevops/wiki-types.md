---
title: "Azure DevOps Wiki Types"
description: "Project wikis versus code wikis, and choosing between them"
author: "Joseph Streeter"
tags: ["azure devops", "documentation", "wiki", "project wiki", "code wiki"]
category: "development"
last_updated: "2026-08-01"
---
## 1. Azure DevOps Wiki Types

Azure DevOps provides two types of wikis, each serving different purposes.

### 1.1 Project Wiki

**What it is:**

- A wiki provisioned for an entire Azure DevOps project
- Backed by a hidden Git repository (you can clone and work locally)
- One per project (but can have multiple projects)
- Managed via Git or through the Azure DevOps web interface

**Best used for:**

- ✅ Cross-cutting documentation (affects multiple services/repos)
- ✅ Operational procedures and runbooks
- ✅ Organizational standards and policies
- ✅ Project management documentation
- ✅ Team onboarding and training materials
- ✅ Index/catalog of all services and their documentation

**Characteristics:**

- Central location for project-wide documentation
- Not tied to specific code repositories
- Survives even if code repositories are deleted
- Easier to manage permissions at project level

**Example structure:**

```text
Project Wiki: "Enterprise IT Documentation"
├── Getting Started
│   ├── Welcome
│   ├── Team Directory
│   └── How to Contribute
├── Standards
│   ├── Coding Standards
│   ├── Documentation Standards
│   └── Security Standards
├── Architecture
│   ├── Enterprise Architecture Overview
│   ├── Network Architecture
│   └── Security Architecture
├── Operations
│   ├── On-Call Procedures
│   ├── Incident Response
│   └── Change Management
├── Services Catalog
│   ├── Service A (link to code wiki)
│   ├── Service B (link to code wiki)
│   └── Service C (link to code wiki)
└── Policies
    ├── Access Control
    └── Data Classification
```

### 1.2 Code Wiki

**What it is:**

- A wiki published from a specific folder in a Git repository
- Lives alongside the code it documents, if code exists
- Can have multiple code wikis (one per repo or even multiple per repo)
- Automatically updated when repository changes are merged

**Best used for:**

- ✅ Service-specific technical documentation
- ✅ Architecture for specific applications
- ✅ Setup and configuration guides
- ✅ Runbooks specific to one service
- ✅ API documentation
- ✅ Developer guides for specific codebases

**Characteristics:**

- Tightly coupled to code repository
- Documentation versions match code versions (branches, tags)
- Deleted when repository is deleted (unless backed up)
- Technical documentation for a specific solution or service
- Changes go through same pull request process as code

**Example structure:**

```text
Code Repository: "email-gateway-service"
└── /docs (published as code wiki)
    ├── README.md (Overview)
    ├── Architecture.md
    ├── API
    │   ├── Authentication.md
    │   ├── Endpoints.md
    │   └── Examples.md
    ├── Operations
    │   ├── Deployment.md
    │   ├── Monitoring.md
    │   ├── Troubleshooting.md
    │   └── Runbook.md
    ├── Development
    │   ├── Getting-Started.md
    │   ├── Local-Development.md
    │   └── Testing.md
    └── Integration
        ├── Exchange-Online.md
        └── Active-Directory.md
```

### 1.3 When to Use Which

| Use Case                                      | Project Wiki | Code Wiki |
|-----------------------------------------------|--------------|-----------|
| Cross-service operational procedures          | ✅           |           |
| Enterprise architecture                       | ✅           |           |
| Onboarding documentation                      | ✅           |           |
| Service catalog/index                         | ✅           |           |
| Incident response procedures                  | ✅           |           |
| Standards and policies                        | ✅           |           |
| Documentation accessed by non-technical users | ✅           |           |
| Service-specific technical documentation      |              | ✅        |
| Code setup and development guide              |              | ✅        |
| API documentation for one service             |              | ✅        |
| Documentation that versions with code         |              | ✅        |

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
