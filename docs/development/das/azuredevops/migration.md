---
title: "Migration Strategy"
description: "Moving existing documentation into Azure DevOps in phases, with communication and rollback plans"
author: "Joseph Streeter"
tags: ["azure devops", "documentation", "migration", "rollout"]
category: "development"
last_updated: "2026-08-01"
---
## 11. Migration Strategy

### 11.1 Migrating from Existing Documentation

**Common migration scenarios:**

#### Scenario 1: From Confluence/SharePoint to Azure DevOps Wiki

**Challenges:**

- Different markup languages (Confluence uses its own, SharePoint uses varied formats)
- Attachments and embedded media
- Permissions mapping
- Maintaining links

**Migration approach:**

#### Step 1: Export from source system

- Confluence: Use built-in export to Markdown (via plugins like "Markdown Exporter")
- SharePoint: Manual copy or use migration tools

#### Step 2: Convert to Markdown

```bash
# If exporting HTML, convert to Markdown with Pandoc
pandoc input.html -f html -t markdown -o output.md
```

#### Step 3: Clean up Markdown

- Fix heading levels
- Convert links to relative paths
- Move images to `.attachments/` folder
- Update internal links

#### Step 4: Organize in Git repository

- Create folder structure (`/docs`, subfolders)
- Create `.order` files
- Commit to Git repository

#### Step 5: Publish as wiki

- Create Project Wiki or publish Code Wiki
- Verify all pages render correctly
- Fix broken links

#### Step 6: Update references

- Update external links to point to new wiki
- Notify users of new location
- Keep old documentation for 30-90 days with redirect notice

#### Scenario 2: From File Shares / Word Docs to Azure DevOps Wiki

**Migration approach:**

#### Step 1: Inventory existing documentation

- List all Word docs, PDFs, Excel files
- Categorize by type (architecture, runbooks, procedures)
- Identify owners

#### Step 2: Prioritize migration

- Start with most frequently accessed documents
- Start with operational documentation (highest impact)
- Defer rarely-accessed or obsolete content

#### Step 3: Convert to Markdown

```bash
# Convert Word to Markdown
pandoc document.docx -f docx -t markdown -o document.md --extract-media=.attachments
```

**Manual conversion may be needed for:**

- Complex tables
- Embedded objects
- Custom formatting

#### Step 4: Enhance during migration

- Update outdated information
- Add missing sections (using templates)
- Improve structure and formatting
- Add cross-links

#### Step 5: Validate and publish

- Review converted content
- Commit to Git
- Publish as wiki
- Test links and attachments

#### Scenario 3: From README files to Comprehensive Docs

**Current state:** Single README.md in repository root

**Goal:** Comprehensive `/docs` folder with code wiki

**Migration approach:**

#### Step 1: Create `/docs` structure

```bash
mkdir docs
mkdir docs/.attachments
mkdir docs/API
mkdir docs/Operations
mkdir docs/Development
```

#### Step 2: Split README into multiple files

- Extract architecture section → `docs/Architecture.md`
- Extract API section → `docs/API/Overview.md`
- Extract deployment section → `docs/Operations/Deployment.md`
- Keep brief overview in `docs/README.md`

#### Step 3: Expand with templates

- Use templates (Section 8.1) to create complete documentation
- Fill in gaps (troubleshooting, runbooks, etc.)

#### Step 4: Publish as code wiki

#### Step 5: Update root README

Keep root `README.md` brief, link to wiki:

```markdown
# Service Name

Brief 2-3 sentence description.

## Documentation

Comprehensive documentation is available in the [Service Wiki](https://dev.azure.com/org/project/_wiki/wikis/service-docs).

Quick links:
- [Getting Started](https://dev.azure.com/org/project/_wiki/wikis/service-docs?pagePath=/Getting-Started)
- [API Documentation](https://dev.azure.com/org/project/_wiki/wikis/service-docs?pagePath=/API/Overview)
- [Operations Runbook](https://dev.azure.com/org/project/_wiki/wikis/service-docs?pagePath=/Operations/Runbook)
```

### 11.2 Phased Migration Approach

**For large organizations with extensive existing documentation:**

#### Phase 1: Foundation (Month 1-2)

- Set up Azure DevOps project and repositories
- Create documentation standards and templates
- Train documentation owners
- Set up CI/CD pipelines for validation
- Migrate 1-2 pilot services (end-to-end)
- Gather feedback and refine approach

#### Phase 2: Critical Documentation (Month 3-4)

- Migrate operational runbooks (highest impact)
- Migrate incident response procedures
- Migrate architecture documentation for core services
- Set up Project Wiki with operational procedures
- Ensure old and new documentation clearly marked

#### Phase 3: Service Documentation (Month 5-8)

- Migrate service-specific documentation (10-20 services per month)
- Prioritize by: usage frequency, team size, complexity
- Use scaffolding scripts to accelerate
- Train teams on maintaining documentation

#### Phase 4: Remaining Content (Month 9-12)

- Migrate remaining documentation
- Archive obsolete content
- Decommission old documentation systems
- Conduct retrospective and continuous improvement

#### Phase 5: Optimization (Ongoing)

- Improve based on feedback
- Add automation (auto-generation, etc.)
- Enhance search and discoverability
- Measure and improve documentation quality

### 11.3 Communication During Migration

**Announce migration plan:**

```markdown
# Documentation Migration Announcement

We are migrating our documentation to Azure DevOps wikis for:
- Better version control
- Improved search
- Closer integration with our code

**Timeline:**
- Jan 2025: Pilot migration (2 services)
- Feb 2025: Operational procedures migration
- Mar-Jun 2025: All service documentation

**Old Documentation:**
- Will remain available (read-only) until July 2025
- Will have banner linking to new location

**New Documentation:**
- Azure DevOps Project Wiki: [link]
- Service-specific Code Wikis: [links]

**Training:**
- Documentation-as-code workshop: Jan 15
- Office hours: Every Friday 2-3 PM

**Questions:** Contact documentation-team@company.com
```

**During migration:**

- Add banner to old documentation pages:

  ```markdown
  > **⚠️ This documentation has moved to [Azure DevOps Wiki](link). Please update your bookmarks. This page will be removed on July 1, 2025.**
  ```

**After migration:**

- Keep old documentation read-only for 30-90 days
- Redirect or replace with link to new location
- Archive old system

### 11.4 Rollback Plan

**If migration encounters major issues:**

**Rollback triggers:**

- Users unable to find critical documentation
- Performance issues with Azure DevOps
- Major gaps in migrated content
- Stakeholder resistance

**Rollback procedure:**

1. Pause migration
2. Keep old system operational
3. Assess issues
4. Remediate problems
5. Resume migration when ready

**Mitigation:**

- Pilot migration first (test with 1-2 services)
- Keep old system running in parallel during migration
- Don't decommission old system until migration validated
- Gather user feedback continuously

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
