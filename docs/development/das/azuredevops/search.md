---
title: "Search and Discoverability"
description: "Making documentation findable through wiki search, page structure, and external indexing"
author: "Joseph Streeter"
tags: ["azure devops", "documentation", "search", "discoverability"]
category: "development"
last_updated: "2026-08-01"
---
## 10. Search & Discoverability

### 10.1 Azure DevOps Wiki Search

**Built-in search capabilities:**

- **Full-text search:** Searches all wiki content
- **Filter by wiki:** Can search across all wikis or specific wiki
- **Relevance ranking:** Results sorted by relevance
- **Highlighting:** Search terms highlighted in results

**Location:** Top-right search bar in Azure DevOps (when on Wiki page)

**Search tips:**

- Use quotes for exact phrases: `"disaster recovery"`
- Use keywords, not full sentences
- Search is case-insensitive
- Results include page title, content, and file name

### 10.2 Improving Discoverability

#### 10.2.1 Clear Page Titles

**Best practices:**

- Use descriptive, specific titles
- Include keywords users might search for
- Avoid generic titles like "Overview" or "Documentation"

**Examples:**

❌ Poor:

```markdown
# Overview
```

✅ Good:

```markdown
# Email Gateway Service Overview
```

✅ Better:

```markdown
# Email Gateway (FortiMail) - SMTP Relay Service
```

#### 10.2.2 Rich Metadata

**Add metadata to top of pages:**

```markdown
# Service Name

**Keywords:** SMTP, email, relay, FortiMail, authentication, TLS  
**Owner:** IAM Team  
**Last Updated:** 2025-01-15

[Rest of content]
```

Keywords improve search relevance.

#### 10.2.3 Cross-Linking

**Link related pages extensively:**

At bottom of each page:

```markdown
## Related Documentation

- Operations Runbook - Day-to-day operational procedures
- Troubleshooting Guide - Common issues and solutions
- API Documentation - API reference and examples
- [Incident Response](/Operations/Incident-Response) - (Project Wiki)
```

**Benefits:**

- Helps users discover related content
- Improves navigation
- Search engines follow links to understand relationships

#### 10.2.4 Table of Contents

**For long pages, include ToC:**

```markdown
# Long Documentation Page

## Table of Contents
- [Section 1](#section-1)
- [Section 2](#section-2)
  - [Subsection 2.1](#subsection-21)
  - [Subsection 2.2](#subsection-22)
- [Section 3](#section-3)

## Section 1
[Content]

## Section 2
[Content]

### Subsection 2.1
[Content]
```

Azure DevOps automatically generates anchor links from headers.

#### 10.2.5 Service Catalog as Discovery Hub

**Central catalog page lists all services with:**

- Service name (searchable)
- Description with keywords
- Links to documentation
- Owner information
- Status

**Example:**

```markdown
| Service | Description | Keywords | Documentation |
|---------|-------------|----------|---------------|
| Email Gateway | FortiMail-based SMTP relay for applications | SMTP, email, relay, FortiMail, authentication, TLS, port 25, port 587 | [Docs](link) |
```

When user searches for "SMTP" or "email relay", this page will appear in results

### 10.3 External Search Indexing

**To make documentation searchable outside Azure DevOps:**

#### Option 1: Export and Publish

**Export wiki to static site:**

```bash
# Clone wiki
git clone https://dev.azure.com/org/project/_git/project.wiki

# Use static site generator
# Option A: MkDocs
mkdocs build

# Option B: Jekyll
jekyll build

# Option C: Hugo
hugo

# Deploy to web server or Azure Static Web Apps
```

**Benefits:**

- Public access (if desired)
- Custom domain
- Additional search tools (Google Custom Search, Algolia)

#### Option 2: Integrate with Enterprise Search

**If your organization has enterprise search (SharePoint, Elastic, Solr):**

- Export documentation periodically
- Index in enterprise search platform
- Provide links back to Azure DevOps wikis

### 10.4 AI-Powered Search (Future)

**Azure DevOps may integrate AI-powered search in future:**

- Semantic search (understand intent, not just keywords)
- Question answering (directly answer questions from docs)
- Related content recommendations

**Prepare for this:**

- Write clear, comprehensive documentation
- Use natural language (not just terse technical notes)
- Include FAQ sections
- Link related content

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
