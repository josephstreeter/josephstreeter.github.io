---
title: "Documentation as Code in Azure DevOps"
description: "Implementing Documentation-as-Code in Azure DevOps: wiki types, architecture, Markdown standards, CI/CD validation, templates, permissions, and governance"
author: "Joseph Streeter"
tags: ["azure devops", "documentation", "documentation as code", "wiki", "das"]
category: "development"
difficulty: "intermediate"
last_updated: "2026-08-01"
---
## Documentation as Code in Azure DevOps

A complete implementation guide for treating documentation the way you treat code — in version control, reviewed through pull requests, and validated by pipelines. Start with the basics (wiki types, Markdown), then adopt CI/CD, templates, and governance as the estate grows.

| Page | Covers |
|------|--------|
| [Azure DevOps Wiki Types](wiki-types.md) | Project wiki vs code wiki, capabilities, and selection criteria |
| [Architecture and Organization](architecture.md) | Repository layout, information architecture, ownership boundaries |
| [Project Wiki Implementation](project-wiki.md) | Provisioning, page hierarchy, editing workflow, and publishing |
| [Code Wiki Implementation](code-wiki.md) | Publishing from a repo, folder structure, .order files, branch selection |
| [Markdown Standards and Best Practices](markdown-standards.md) | Syntax conventions, headings, tables, Mermaid diagrams, accessibility |
| [Version Control Workflow](version-control.md) | Branching model, PR process, merge strategies, CODEOWNERS, protected branches |
| [CI/CD Pipelines for Documentation](cicd-pipelines.md) | Validation pipelines, status checks, publishing, notifications, generated docs |
| [Documentation Templates](templates.md) | Service README, operations runbook, and architecture document templates |
| [Template Repository and Automation](automation.md) | Template repository, auto-generated content, snippets |
| [Access Control and Permissions](access-control.md) | Permission levels, recommended structure, branch policies, sensitive documentation |
| [Search and Discoverability](search.md) | Wiki search, page titles and structure, cross-linking, external indexing |
| [Migration Strategy](migration.md) | Migration approach, phased rollout, communication, rollback |
| [Maintenance and Governance](governance.md) | Governance model, quality metrics, review process, stale detection, deprecation |
| [Appendices](appendices.md) | Quick reference, troubleshooting, glossary, resources, sample project structure |


**Organization:** [Organization Name]  
**Document Version:** 1.0  
**Date:** [Date]  
**Document Owner:** [Documentation Team / DevOps Team]

---

## Executive Summary

### Purpose

This document provides comprehensive guidance for implementing a Documentation-as-Code approach using Azure DevOps. This strategy treats documentation with the same rigor as source code: version controlled, peer-reviewed, tested, and automatically published.

### Approach

- **Project Wikis:** Centralized documentation repository for cross-cutting, organizational, and operational documentation
- **Code Wikis:** Service-specific technical documentation published from code repositories
- **Markdown-based:** All documentation written in Markdown for portability and version control
- **Git-backed:** Full version control with branching, pull requests, and history
- **Automated:** CI/CD pipelines for validation, publishing, and notifications

### Benefits

- **Version Control:** Full history of all documentation changes
- **Peer Review:** Pull request workflow ensures documentation quality
- **Discoverability:** Centralized location with search capability
- **Consistency:** Templates and automated validation enforce standards
- **Integration:** Links directly to code, work items, pipelines
- **Automation:** Reduce manual effort through CI/CD
- **Collaboration:** Multiple contributors with approval workflows

### Key Concepts

**Documentation-as-Code means:**

- Documentation stored as Markdown files in Git repositories
- Changes go through same workflow as code (branch → pull request → review → merge)
- Automated testing for broken links, formatting, standards compliance
- Automated publishing to wiki when changes are approved
- Documentation versioned alongside the code it describes

---

## Document Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-01-15 | [Author Name] | Initial comprehensive guide |

---

This guide provides everything needed to implement Documentation-as-Code in Azure DevOps. Start with the basics (creating wikis, using Markdown), then progressively adopt advanced features (CI/CD pipelines, templates, automation) as your organization matures.

## Related Topics

- [Documentation as Code](../index.md) - The wider DaC section
- [Document Plan](document_plan.md) - Planning a documentation set
- [Requirements Template](requirements_template.md) - Requirements capture template
- [DocFX](../../docfx/index.md) - Static site generation from Markdown
