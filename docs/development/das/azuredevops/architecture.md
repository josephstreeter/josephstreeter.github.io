---
title: "Architecture and Organization"
description: "Structuring documentation across repositories, projects, and wikis"
author: "Joseph Streeter"
tags: ["azure devops", "documentation", "architecture", "organization"]
category: "development"
last_updated: "2026-08-01"
---
## 2. Architecture & Organization

### 2.1 Recommended Structure

**High-Level Strategy:**

```text
Azure DevOps Organization: "Contoso"
│
├── Project: "Enterprise IT"
│   │
│   ├── Project Wiki: "Enterprise IT Documentation"
│   │   ├── (Cross-cutting documentation)
│   │   └── Services Catalog (links to code wikis)
│   │
│   ├── Repository: "fortimail-service"
│   │   └── Code Wiki from /docs folder
│   │
│   ├── Repository: "database-platform"
│   │   └── Code Wiki from /docs folder
│   │
│   └── Repository: "monitoring-infrastructure"
│       └── Code Wiki from /docs folder
│
└── Project: "Product Development"
    │
    ├── Project Wiki: "Product Documentation"
    │   └── (Product-wide documentation)
    │
    ├── Repository: "api-backend"
    │   └── Code Wiki from /docs folder
    │
    └── Repository: "web-frontend"
        └── Code Wiki from /docs folder
```

### 2.2 Folder Structure for Code Wikis

**Standard /docs folder structure in every repository:**

```text
/docs
├── .order                          # Controls page ordering in wiki
├── README.md                       # Wiki home page (overview of service)
├── Architecture.md                 # Architecture documentation
├── .attachments/                   # Images, diagrams, files
│   ├── architecture-diagram.png
│   └── network-diagram.png
├── API/                            # API documentation folder
│   ├── .order
│   ├── Overview.md
│   ├── Authentication.md
│   ├── Endpoints.md
│   └── Examples.md
├── Operations/                     # Operational documentation
│   ├── .order
│   ├── Deployment.md
│   ├── Configuration.md
│   ├── Monitoring.md
│   ├── Troubleshooting.md
│   └── Runbook.md
├── Development/                    # Developer documentation
│   ├── .order
│   ├── Getting-Started.md
│   ├── Local-Setup.md
│   ├── Testing.md
│   └── Contributing.md
└── Integration/                    # Integration documentation
    ├── .order
    ├── Overview.md
    ├── System-A-Integration.md
    └── System-B-Integration.md
```

**Key files:**

**`.order` file:**
Controls the order of pages in the wiki navigation. One filename per line.

Example `.order` file in `/docs`:

```text
README
Architecture
API
Operations
Development
Integration
```

**`.attachments/` folder:**

- Store all images, diagrams, PDFs here
- Reference in Markdown: `![Architecture Diagram](.attachments/architecture-diagram.png)`
- Azure DevOps automatically serves these files

### 2.3 Naming Conventions

**File naming standards:**

✅ **Good:**

- `README.md` (always the entry point)
- `Getting-Started.md` (capitalize words, use hyphens)
- `API-Authentication.md`
- `Troubleshooting-Guide.md`

❌ **Avoid:**

- `getting started.md` (spaces break links)
- `api_authentication.md` (underscores are harder to read)
- `TroubleshootingGuide.md` (no separation between words)
- `readme.txt` (not Markdown)

**Folder naming standards:**

✅ **Good:**

- `API/`
- `Operations/`
- `Development/`

❌ **Avoid:**

- `api docs/` (spaces)
- `Ops_Docs/` (underscores)

**Branch naming for documentation changes:**

✅ **Good:**

- `docs/update-runbook`
- `docs/add-api-examples`
- `docs/fix-broken-links`

### 2.4 Project Organization Strategies

#### Option 1: Single Project (Recommended for Most)

- One Azure DevOps project for all IT services
- One Project Wiki for operational/cross-cutting docs
- Many Code Wikis (one per service repository)
- **Pros:** Centralized, easier to search across, simpler permissions
- **Cons:** Can become large, may need good organization

#### Option 2: Multiple Projects by Domain

- Separate projects for: Infrastructure, Applications, Security, etc.
- Each project has its own Project Wiki
- Each repository has Code Wiki
- **Pros:** Clear separation, better for large organizations
- **Cons:** Documentation fragmented, harder to search across

#### Option 3: Hybrid

- One "Central IT" project with Project Wiki for org-wide docs
- Domain-specific projects (Infrastructure, Security) with their own wikis
- All have Code Wikis per repository
- **Pros:** Balance of centralization and separation
- **Cons:** Most complex to manage

**Recommendation:** Start with Option 1 (single project). Move to Option 3 only when you have >100 services or clear organizational boundaries.

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
