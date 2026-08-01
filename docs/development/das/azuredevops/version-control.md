---
title: "Version Control Workflow"
description: "Branching, pull requests, merge strategies, and code owners for documentation"
author: "Joseph Streeter"
tags: ["azure devops", "documentation", "version control", "git", "pull requests"]
category: "development"
last_updated: "2026-08-01"
---
## 6. Version Control Workflow

### 6.1 Branching Strategy

#### Recommended approach: Feature branch workflow

```text
main (or master)
  ├── docs/update-api-docs          # Feature branch
  ├── docs/fix-broken-links          # Feature branch
  └── docs/add-troubleshooting       # Feature branch
```

**Branch naming convention:**

```text
docs/<short-description>
```

Examples:

- `docs/update-runbook`
- `docs/add-api-examples`
- `docs/fix-architecture-diagram`

**Workflow:**

1. **Create branch from main**

   ```bash
   git checkout main
   git pull
   git checkout -b docs/update-runbook
   ```

2. **Make changes**

   ```bash
   # Edit files
   code docs/Operations/Runbook.md
   
   # Add new images
   cp ~/new-diagram.png docs/.attachments/
   ```

3. **Commit changes**

   ```bash
   git add docs/
   git commit -m "docs: update runbook with new escalation procedure"
   ```

4. **Push to remote**

   ```bash
   git push origin docs/update-runbook
   ```

5. **Create pull request** (via Azure DevOps web UI)

6. **Review and merge**
   - Reviewers approve
   - Complete pull request
   - Delete source branch

7. **Wiki updates automatically** (for code wikis)

### 6.2 Commit Message Standards

**Format:**

```text
docs: <short description>

[Optional longer description]

[Optional footer with references]
```

**Examples:**

```text
docs: add troubleshooting section for timeout errors
```

```text
docs: update API authentication examples

Added examples for OAuth 2.0 flow and API key usage.
Updated outdated endpoint URLs.

Closes #1234
```

**Prefix:**

- Use `docs:` prefix for documentation changes
- Keeps documentation commits separate from code commits
- Helps with automated changelog generation

**Best practices:**

- Use imperative mood: "add" not "added" or "adds"
- Keep first line under 50 characters
- Capitalize first word
- No period at the end of first line
- Provide context in body if needed
- Reference work items: `Closes #1234` or `Related to #5678`

### 6.3 Pull Request Process

**Pull request template (configure in repository):**

`.azuredevops/pull_request_template.md`:

```markdown
## Description

[Describe what documentation changes are included and why]

## Type of Change

- [ ] New documentation
- [ ] Update existing documentation
- [ ] Fix broken links or typos
- [ ] Reorganization/restructuring
- [ ] Add diagrams or images

## Checklist

- [ ] Markdown syntax is valid
- [ ] Links work (internal and external)
- [ ] Images load correctly and have alt text
- [ ] Spelling and grammar checked
- [ ] Follows documentation standards
- [ ] Related documentation updated
- [ ] Tested locally (if applicable)

## Related Work Items

Closes #[work-item-number]

## Screenshots (if applicable)

[Add screenshots of new/updated content]

## Reviewer Notes

[Any special instructions for reviewers]
```

**Pull request process:**

1. **Author creates PR**
   - Uses template above
   - Adds reviewers (at least 1)
   - Links to work item
   - Provides context

2. **Reviewers review**
   - Check for accuracy
   - Verify completeness
   - Test links
   - Check formatting
   - Provide constructive feedback

3. **Author addresses feedback**
   - Make requested changes
   - Push updates to same branch
   - Respond to comments

4. **Approval and merge**
   - Reviewer(s) approve
   - Author or reviewer completes PR
   - Choose merge strategy (see below)
   - Delete source branch

### 6.4 Merge Strategies

**Azure DevOps offers several merge strategies:**

#### Option 1: Squash Commit (Recommended for Documentation)

**What it does:**

- Combines all commits in branch into single commit on main
- Keeps history clean

**When to use:**

- Documentation updates (most cases)
- Feature branches with many small commits

**Example:**

```text
Before:
  main: A -- B -- C
  docs/update: -- D -- E -- F -- G

After:
  main: A -- B -- C -- H (squashed D-G)
```

**Configure in Azure DevOps:**

- Repos → Repositories → [repo] → Policies → Branch Policies (main)
- Under "Limit merge types" → Check "Squash merge"

#### Option 2: Merge Commit

**What it does:**

- Creates merge commit preserving all individual commits

**When to use:**

- When commit history in branch is important

**Example:**

```text
Before:
  main: A -- B -- C
  docs/update: -- D -- E -- F

After:
  main: A -- B -- C -- M (merge commit)
                    \  /
                     D -- E -- F
```

#### Option 3: Rebase and Fast-Forward

**What it does:**

- Replays commits from branch onto main
- No merge commit created

**When to use:**

- Small, clean changes
- Want linear history

**Example:**

```text
Before:
  main: A -- B -- C
  docs/update: -- D -- E

After:
  main: A -- B -- C -- D -- E
```

**Recommendation:** Use **Squash Commit** for documentation. Keeps main branch history clean and easy to understand.

### 6.5 Code Owners for Documentation

**Create a `CODEOWNERS` file to automatically assign reviewers:**

`.azuredevops/CODEOWNERS`:

```markdown
# Documentation code owners
# These people will automatically be requested for review on PRs

# All documentation
/docs/ @documentation-team

# Operations documentation requires ops team review
/docs/Operations/ @operations-team

# API documentation requires API team review
/docs/API/ @api-team

# Specific files
/docs/Architecture.md @architecture-team
/docs/Operations/Runbook.md @operations-lead
```

**Benefits:**

- Automatic reviewer assignment
- Ensures right people review relevant changes
- Distributes review load

**Configure in Azure DevOps:**

- Repos → Repositories → [repo] → Policies → Branch Policies (main)
- Enable "Automatically include code reviewers"

### 6.6 Protected Branches

**Protect main branch to enforce quality:**

**Azure DevOps Branch Policies for `main`:**

1. **Require pull requests**
   - Minimum number of reviewers: 1 (or 2 for critical documentation)
   - Allow requestor to approve their own changes: No

2. **Check for linked work items**
   - Required (ensures traceability)

3. **Check for comment resolution**
   - Required (all discussions must be resolved)

4. **Limit merge types**
   - Allow only: Squash merge

5. **Build validation** (optional)
   - Run documentation linting pipeline on PR
   - Required to pass before merge

**Configure:**

- Repos → Branches → main → Branch Policies → Configure policies above

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
