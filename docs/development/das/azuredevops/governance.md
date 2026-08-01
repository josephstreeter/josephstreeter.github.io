---
title: "Maintenance and Governance"
description: "Ownership, quality metrics, review cycles, stale-content detection, and deprecation"
author: "Joseph Streeter"
tags: ["azure devops", "documentation", "governance", "maintenance", "metrics"]
category: "development"
last_updated: "2026-08-01"
---
## 12. Maintenance & Governance

### 12.1 Documentation Governance

**Establish governance structure:**

#### 12.1.1 Roles and Responsibilities

| Role | Responsibilities | Who |
|------|------------------|-----|
| **Documentation Owner** | Overall documentation strategy, standards, tooling | [Documentation Lead] |
| **Service Owners** | Maintain documentation for their services | [Each service team] |
| **Subject Matter Experts** | Review technical accuracy | [Technical leads] |
| **Documentation Contributors** | Write and update documentation | [All team members] |
| **Documentation Reviewers** | Review PRs for quality and accuracy | [Designated reviewers per team] |

#### 12.1.2 Documentation Standards Board

**For large organizations:**

**Charter:** Establish and maintain documentation standards

**Members:**

- Documentation lead (chair)
- Representatives from major teams
- Technical writer (if available)
- User experience representative

**Meetings:** Quarterly

**Responsibilities:**

- Review and update documentation standards
- Approve new templates
- Review metrics and identify improvements
- Prioritize documentation initiatives

### 12.2 Documentation Quality Metrics

**Track metrics to ensure documentation remains valuable:**

#### 12.2.1 Coverage Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Services with documentation | 100% | Count services with `/docs` folder |
| Services with published wiki | 100% | Count published code wikis |
| Required sections present | 100% | Automated check in CI/CD |
| Documentation up-to-date (< 6 months) | >90% | Check "last updated" dates |

#### 12.2.2 Quality Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Broken links | 0 | Automated link checker |
| Spelling errors | <5 per page | Automated spell check |
| Pull request review time | <2 days | Azure DevOps metrics |
| Documentation used in incidents | >80% | Post-incident surveys |

#### 12.2.3 Usage Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Wiki page views | Trending up | Azure DevOps analytics |
| Search success rate | >70% | User feedback surveys |
| Time to find information | <5 minutes | User feedback surveys |
| User satisfaction | >4/5 | Quarterly survey |

#### 12.2.4 Maintenance Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Documentation updates per month | >10 | Git commit count |
| Pull requests merged per month | >5 | Azure DevOps metrics |
| Average time docs are out-of-date | <3 months | Last update date tracking |
| Stale documentation flagged | 100% | Automated stale check |

**Dashboard example:**

Create Power BI or Azure DevOps dashboard with:

- Total pages count
- Pages updated this month
- Broken links count
- Page views (top 10)
- Recent updates
- Pull requests pending review

### 12.3 Regular Review Process

#### 12.3.1 Quarterly Documentation Review

**Process:**

#### Week 1-2: Team Reviews

- Each team reviews their service documentation
- Updates outdated information
- Fixes broken links
- Adds missing sections

#### Week 3: Documentation Board Review

- Review metrics
- Identify systemic issues
- Plan improvements
- Update standards if needed

#### Week 4: Action Items

- Teams implement improvements
- Documentation lead updates shared resources

**Checklist per service:**

- [ ] README.md reviewed and updated
- [ ] Architecture.md reflects current state
- [ ] Operations runbook tested (can someone follow it?)
- [ ] API documentation matches current API
- [ ] All links working
- [ ] Images/diagrams up-to-date
- [ ] No outdated information
- [ ] "Last reviewed" date updated

#### 12.3.2 Post-Incident Documentation Updates

**After every significant incident:**

1. **During post-incident review:**
   - Identify documentation gaps
   - Identify inaccurate documentation
   - Identify missing troubleshooting steps

2. **Within 1 week:**
   - Create work items for documentation updates
   - Assign to appropriate owners
   - Prioritize by impact

3. **Within 2 weeks:**
   - Complete documentation updates
   - Get reviews and merge
   - Close work items

**Example:**

- **Incident:** Service outage due to misconfigured firewall rule
- **Documentation gap:** Runbook didn't mention this firewall rule
- **Action:** Update runbook with firewall rule verification step
- **Result:** Next person can prevent/diagnose this issue faster

#### 12.3.3 New Team Member Feedback

**Use onboarding as documentation quality check:**

**Week 1-2 of onboarding:**

- New team member reads all documentation
- Notes confusing sections, gaps, outdated info
- Provides feedback

**Week 3-4:**

- New team member submits documentation improvements
- Gets guidance from senior team members
- First contribution to team is improving docs

**Benefits:**

- Fresh eyes spot issues veterans miss
- New team member contributes immediately
- Documentation continuously improves

### 12.4 Stale Documentation Detection

**Automated stale documentation flagging:**

**Create: `.azuredevops/scripts/check-stale-docs.py`**

```python
#!/usr/bin/env python3
"""
Check for stale documentation (not updated in 6+ months)
"""

import os
import sys
import re
from datetime import datetime, timedelta
import subprocess

STALE_THRESHOLD_DAYS = 180  # 6 months

def get_last_modified_date(filepath):
    """Get last git commit date for file"""
    try:
        result = subprocess.run(
            ['git', 'log', '-1', '--format=%cd', '--date=iso', filepath],
            capture_output=True,
            text=True,
            check=True
        )
        date_str = result.stdout.strip()
        if date_str:
            # Parse ISO date
            return datetime.fromisoformat(date_str.split()[0])
        return None
    except:
        return None

def check_stale_documentation():
    """Check all markdown files for staleness"""
    stale_files = []
    threshold_date = datetime.now() - timedelta(days=STALE_THRESHOLD_DAYS)
    
    for root, dirs, files in os.walk('docs'):
        for file in files:
            if file.endswith('.md'):
                filepath = os.path.join(root, file)
                last_modified = get_last_modified_date(filepath)
                
                if last_modified and last_modified < threshold_date:
                    days_old = (datetime.now() - last_modified).days
                    stale_files.append((filepath, days_old))
    
    if stale_files:
        print("⚠️  The following documentation files are stale (not updated in 6+ months):\n")
        for filepath, days_old in sorted(stale_files, key=lambda x: x[1], reverse=True):
            months_old = days_old // 30
            print(f"  - {filepath}: {months_old} months old ({days_old} days)")
        
        print(f"\nTotal stale files: {len(stale_files)}")
        print("\n📋 Action: Please review and update these files, or mark as reviewed if still accurate.")
        
        # Don't fail build, just warn
        return 0
    else:
        print("✅ All documentation is up-to-date (updated within last 6 months)")
        return 0

if __name__ == "__main__":
    sys.exit(check_stale_documentation())
```

**Add to validation pipeline:**

```yaml
# In azure-pipelines-docs-validation.yml
- script: |
    python3 .azuredevops/scripts/check-stale-docs.py
  displayName: 'Check for stale documentation'
  continueOnError: true  # Don't fail build, just warn
```

**Alternatively, add "Last Reviewed" metadata to pages:**

```markdown
---
last_reviewed: 2025-01-15
review_frequency: quarterly
---

# Page Title

[Content]
```

Script can check this metadata instead of git history.

### 12.5 Documentation Deprecation Process

**When services are deprecated:**

#### Step 1: Mark as deprecated

Add prominent notice at top of documentation:

```markdown
> **⚠️ DEPRECATED**
> 
> This service is deprecated and will be decommissioned on June 30, 2025.
> 
> **Migration:** Please migrate to [New Service](link-to-new-service).  
> **Migration Guide:** [Migration guide](link).  
> **Support:** Limited support until decommission date.
```

#### Step 2: Update service catalog

```markdown
| Service | Status | Notes |
|---------|--------|-------|
| Old Service | 🔴 Deprecated | Migrate to New Service by June 30 |
```

#### Step 3: Archive after decommission

After service is fully decommissioned:

1. Move documentation to `/Archive` folder in wiki
2. Add "DECOMMISSIONED" to title
3. Include decommission date and reason
4. Keep for compliance/historical reference (typically 1-3 years)
5. Eventually delete

**Example archived page:**

```markdown
# [DECOMMISSIONED] Old Email Service

> **ℹ️ This service was decommissioned on June 30, 2025.**
> 
> **Reason:** Replaced by FortiMail Email Gateway  
> **Migration:** All users migrated to new service  
> **Archive Date:** This documentation will be deleted on June 30, 2026
>
> This documentation is retained for historical reference only.

[Original documentation content preserved below]
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
