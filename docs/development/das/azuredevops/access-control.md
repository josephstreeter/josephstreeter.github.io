---
title: "Access Control and Permissions"
description: "Permission levels, recommended permission structures, branch policies, and handling sensitive content"
author: "Joseph Streeter"
tags: ["azure devops", "documentation", "permissions", "access control", "security"]
category: "development"
last_updated: "2026-08-01"
---
## 9. Access Control & Permissions

### 9.1 Permission Levels

Azure DevOps wikis support granular permissions:

### 9.1.1 Permission Levels

| Permission Level | Can Read | Can Edit (Web) | Can Edit (Git) | Can Admin |
|------------------|----------|----------------|----------------|-----------|
| **Readers** | ✅ | ❌ | ❌ | ❌ |
| **Contributors** | ✅ | ✅ | ✅ | ❌ |
| **Project Administrators** | ✅ | ✅ | ✅ | ✅ |

**Additional permissions:**

- **Read:** View wiki pages
- **Contribute:** Edit via web UI
- **Create Repository:** Edit via Git (for Project Wiki)
- **Manage Permissions:** Change who can access wiki

### 9.2 Recommended Permission Structure

**Project Wiki:**

| Group | Permission Level | Rationale |
|-------|------------------|-----------|
| [All authenticated users] | Read | Everyone can view operational documentation |
| [Documentation Team] | Contribute | Can edit via web UI and Git |
| [Project Administrators] | Admin | Full control |

**Code Wiki (per repository):**

Inherits from repository permissions:

| Group | Repository Permission | Wiki Access |
|-------|----------------------|-------------|
| [Team Members] | Contribute | Can edit documentation via PRs |
| [Readers] | Read | Can view documentation only |
| [Project Administrators] | Admin | Full control |

### 9.3 Configuring Permissions

**For Project Wiki:**

1. Azure DevOps → Overview → Wiki
2. Click wiki dropdown → Security
3. Add groups/users and assign permissions

**For Code Wiki:**

Code wikis inherit repository permissions. To restrict access:

1. Azure DevOps → Repos → [repository] → Settings → Security
2. Adjust permissions for groups
3. Specifically, can restrict `/docs` folder:
   - Repos → [repository] → branch security
   - Set permissions on `/docs` path

### 9.4 Branch Policies for Protection

**Protect documentation via branch policies (already covered in Section 6.6):**

- Require pull requests
- Require reviewers
- Require linked work items
- Run validation pipeline

**This ensures:**

- No direct commits to main
- All changes peer-reviewed
- Quality checks pass before merge

### 9.5 Sensitive Documentation

**For sensitive content (security procedures, credentials, disaster recovery plans):**

#### Option 1: Private Repository

- Create separate repository for sensitive docs
- Restrict access to security team only
- Publish as code wiki (visible only to those with repo access)

#### Option 2: Azure DevOps Project Security

- Create separate Azure DevOps project for sensitive documentation
- Restrict project access to authorized users only
- Use Project Wiki in that restricted project

#### Option 3: External Secure Platform

- For highly sensitive content (DR plans with credentials, security runbooks), consider:
  - Password manager (1Password, LastPass) with secure notes
  - Encrypted file storage (Azure Key Vault, encrypted SharePoint)
  - Physical copies in secure location

**Best practice:** Keep operational runbooks in wiki (without secrets), store secrets separately with references.

Example:

```markdown
## Database Connection

**Connection String:** Stored in Azure Key Vault as secret `db-connection-string`

To retrieve:
```bash
az keyvault secret show --vault-name mykeyvault --name db-connection-string
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
