---
title: "Appendices"
description: "Quick reference, troubleshooting, glossary, additional resources, and a sample project structure"
author: "Joseph Streeter"
tags: ["azure devops", "documentation", "reference", "troubleshooting", "glossary"]
category: "development"
last_updated: "2026-08-01"
---
## 13. Appendices

### Appendix A: Quick Reference

**Common Tasks:**

| Task | Command/Action |
|------|----------------|
| Clone Project Wiki | `git clone https://dev.azure.com/org/project/_git/project.wiki` |
| Clone Code Wiki | `git clone https://dev.azure.com/org/project/_git/repo.wiki` |
| Create branch | `git checkout -b docs/my-changes` |
| Commit changes | `git commit -m "docs: description"` |
| Push branch | `git push origin docs/my-changes` |
| Create pull request | Azure DevOps web UI → Repos → Pull Requests → New |
| Publish code wiki | Wiki → Publish code as wiki → Select repo and /docs folder |
| Check for broken links | `markdown-link-check docs/**/*.md` |
| Lint Markdown | `markdownlint docs/**/*.md` |
| Spell check | `cspell "docs/**/*.md"` |

### Appendix B: Troubleshooting

#### Issue: Wiki not updating after merge

**Symptoms:** Merged PR but wiki still shows old content

**Causes:**

- Caching (wait 1-2 minutes)
- Published from wrong branch
- `/docs` folder not in published path

**Solutions:**

1. Wait 2-3 minutes, refresh browser
2. Clear browser cache
3. Verify wiki published from correct branch and folder
4. Republish wiki (Wiki → settings → re-publish)

---

#### Issue: Images not loading in wiki

**Symptoms:** `![Alt text](.attachments/image.png)` shows broken image

**Causes:**

- Image not in `.attachments` folder
- Wrong path
- Image file not committed

**Solutions:**

1. Verify image is in correct `.attachments` folder
2. Check path: `![Alt text](.attachments/image.png)` (relative path)
3. Verify image committed and pushed to Git
4. Check file extension matches (case-sensitive on Linux)

---

#### Issue: Links broken after renaming page

**Symptoms:** Links show 404 after renaming markdown file

**Causes:**

- Other pages still link to old filename
- `.order` file not updated

**Solutions:**

1. Search wiki for old filename: `grep -r "Old-Name" docs/`
2. Update all references to new filename
3. Update `.order` file if present
4. Use validation pipeline to catch broken links

---

#### Issue: Page order not reflecting `.order` file

**Symptoms:** Pages appear in wrong order in navigation

**Causes:**

- `.order` file syntax incorrect
- `.order` file not committed
- Filenames in `.order` don't match actual files

**Solutions:**

1. Verify `.order` file format: one filename per line, no `.md` extension
2. Verify all filenames in `.order` exactly match files (case-sensitive)
3. Commit and push `.order` file
4. Wait 1-2 minutes for wiki to update

---

#### Issue: Pull request validation pipeline failing

**Symptoms:** PR blocked due to failing pipeline

**Common Causes:**

- Broken links
- Markdown linting errors
- Spelling errors
- Missing required sections

**Solutions:**

1. Review pipeline logs for specific errors
2. Run checks locally before pushing:

   ```bash
   markdownlint docs/**/*.md
   markdown-link-check docs/**/*.md
   cspell "docs/**/*.md"
   ```

3. Fix issues and push again

### Appendix C: Glossary

| Term | Definition |
|------|------------|
| **Project Wiki** | Wiki provisioned for an entire Azure DevOps project, backed by hidden Git repository |
| **Code Wiki** | Wiki published from `/docs` folder in a code repository |
| **Markdown** | Lightweight markup language used for wiki content |
| **CommonMark** | Standard specification for Markdown that Azure DevOps follows |
| **Documentation-as-Code** | Treating documentation like source code (version controlled, reviewed, tested) |
| **Pull Request (PR)** | Proposed changes to be reviewed before merging |
| **Branch Policy** | Rules enforced on branches (e.g., require PR, require reviewers) |
| **CI/CD** | Continuous Integration / Continuous Deployment - automated pipelines |
| **.order file** | File controlling page order in wiki navigation |
| **.attachments folder** | Folder containing images and files referenced in wiki |
| **Squash merge** | Combining all commits in a branch into single commit when merging |

### Appendix D: Additional Resources

**Microsoft Documentation:**

- [Azure DevOps Wiki Documentation](https://learn.microsoft.com/en-us/azure/devops/project/wiki/)
- [Markdown Syntax](https://learn.microsoft.com/en-us/azure/devops/project/wiki/markdown-guidance)
- [Azure Pipelines Documentation](https://learn.microsoft.com/en-us/azure/devops/pipelines/)

**Markdown Tools:**

- [Markdownlint](https://github.com/DavidAnson/markdownlint) - Linting tool
- [markdown-link-check](https://github.com/tcort/markdown-link-check) - Link checker
- [Pandoc](https://pandoc.org/) - Document converter
- [CSpell](https://github.com/streetsidesoftware/cspell) - Spell checker

**Diagram Tools:**

- [Mermaid](https://mermaid.js.org/) - Diagram syntax in Markdown
- [Draw.io](https://www.drawio.com/) - Diagram editor (export to PNG)
- [PlantUML](https://plantuml.com/) - Text-based diagrams

**Static Site Generators (for export):**

- [MkDocs](https://www.mkdocs.org/) - Documentation site generator
- [Jekyll](https://jekyllrb.com/) - Static site generator
- [Hugo](https://gohugo.io/) - Fast static site generator
- [Docusaurus](https://docusaurus.io/) - React-based documentation sites

### Appendix E: Sample Project Structure

**Complete example of well-structured Azure DevOps project:**

```text
Azure DevOps Organization: "Contoso"
│
└── Project: "Enterprise IT"
    │
    ├── Project Wiki: "Enterprise IT Documentation"
    │   ├── Home.md
    │   ├── Getting-Started/
    │   │   ├── Welcome.md
    │   │   ├── Team-Directory.md
    │   │   └── Contributing.md
    │   ├── Standards/
    │   │   ├── Documentation-Standards.md
    │   │   ├── Coding-Standards.md
    │   │   └── Security-Standards.md
    │   ├── Architecture/
    │   │   ├── Overview.md
    │   │   ├── Network.md
    │   │   ├── Security.md
    │   │   └── Cloud.md
    │   ├── Operations/
    │   │   ├── Incident-Response.md
    │   │   ├── Change-Management.md
    │   │   ├── On-Call.md
    │   │   └── Monitoring.md
    │   ├── Services/
    │   │   ├── Catalog.md (links to code wikis)
    │   │   └── [Service pages with links]
    │   └── Policies/
    │       ├── Access-Control.md
    │       └── Data-Classification.md
    │
    ├── Repository: "email-gateway"
    │   ├── src/ (application code)
    │   ├── tests/
    │   ├── docs/ (Published as Code Wiki: "Email Gateway Docs")
    │   │   ├── .order
    │   │   ├── README.md
    │   │   ├── Architecture.md
    │   │   ├── .attachments/
    │   │   ├── API/
    │   │   ├── Operations/
    │   │   ├── Development/
    │   │   └── Integration/
    │   ├── .azuredevops/
    │   │   └── azure-pipelines.yml
    │   └── README.md (brief, links to /docs wiki)
    │
    ├── Repository: "database-platform"
    │   ├── (similar structure)
    │   └── docs/ (Code Wiki: "Database Platform Docs")
    │
    ├── Repository: "documentation-templates"
    │   ├── README.md
    │   ├── Service-Documentation/
    │   ├── Project-Wiki/
    │   ├── ADR-Template/
    │   ├── Scripts/
    │   └── .azuredevops/
    │
    └── Pipelines
        ├── Documentation Validation (runs on PRs)
        ├── Documentation Publishing (generates HTML/PDF)
        └── Documentation Notifications (sends alerts)
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
