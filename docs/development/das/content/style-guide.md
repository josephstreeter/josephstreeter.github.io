---
title: "Style Guide"
description: "Documentation style guide and writing standards for Documentation as Code"
tags: ["style-guide", "writing", "standards", "documentation"]
category: "development"
difficulty: "beginner"
last_updated: "2025-07-06"
---

## Style Guide

A comprehensive style guide ensures consistency, readability, and professionalism across all documentation. This guide establishes standards for writing, formatting, and organizing content within the Documentation as Code framework.

## Writing Principles

### Clarity and Conciseness

**Write for your audience:**

- Use simple, direct language
- Avoid jargon and technical acronyms without explanation
- Write in active voice when possible
- Keep sentences under 25 words

**Examples:**

❌ **Poor:** The utilization of the aforementioned methodology facilitates the optimization of performance metrics.

✅ **Good:** This method improves performance.

### Consistency

**Maintain consistent terminology:**

- Create and maintain a glossary of terms
- Use the same term throughout documentation
- Avoid synonyms for technical concepts

**Consistent formatting:**

- Follow established patterns for headings, lists, and code blocks
- Use standardized templates for similar content types
- Apply uniform spacing and indentation

### Accessibility

**Write for all users:**

- Use descriptive link text (avoid "click here")
- Provide alt text for images
- Structure content with proper headings
- Consider screen reader compatibility

## Content Organization

### Document Structure

**Standard front matter:**

```yaml
---
title: "Clear, Descriptive Title"
description: "Brief summary of the document content (150-160 characters)"
tags: ["tag1", "tag2", "category"]
category: "section-name"
difficulty: "beginner|intermediate|advanced"
last_updated: "YYYY-MM-DD"
author: "Author Name"
reviewers: ["Reviewer1", "Reviewer2"]
---
```

**Heading hierarchy:**

```markdown
## Main Section (H2)
### Subsection (H3)
#### Detail Section (H4)
##### Minor Detail (H5)
```

**Table of contents:**

- Include TOC for documents longer than 1000 words
- Use descriptive section titles
- Maintain consistent depth (typically 2-3 levels)

### Page Layout

**Introduction pattern:**

1. **Overview:** Brief description of the topic
2. **Prerequisites:** What users need before starting
3. **Learning objectives:** What users will accomplish
4. **Estimated time:** How long the content takes to complete

**Body structure:**

1. **Conceptual information:** Background and theory
2. **Step-by-step procedures:** Actionable instructions
3. **Examples:** Real-world applications
4. **Troubleshooting:** Common issues and solutions

**Conclusion pattern:**

1. **Summary:** Key takeaways
2. **Next steps:** Related topics or follow-up actions
3. **Additional resources:** Links to further reading

## Formatting Standards

### Typography

**Emphasis:**

- **Bold** for UI elements, important terms, and warnings
- *Italic* for emphasis and new concepts
- `Code formatting` for technical terms, file names, and commands

**Lists:**

Use bulleted lists for:

- Unordered information
- Features or benefits
- Options or choices

Use numbered lists for:

- Sequential procedures
- Ranked items
- Step-by-step instructions

**Tables:**

```markdown
| Column Header | Data Type | Required |
|---------------|-----------|----------|
| Name          | String    | Yes      |
| Age           | Integer   | No       |
| Email         | String    | Yes      |
```

### Code Blocks

**Inline code:**

- Use backticks for short code snippets: `variable`
- Include language context when helpful: `npm install`

**Code blocks:**

````markdown
```language
// Include language specification
function example() {
    return "Always specify the language";
}
```
````

**Supported languages:**

- `bash` for shell commands
- `powershell` for PowerShell scripts
- `yaml` for configuration files
- `json` for data structures
- `csharp` for C# code
- `javascript` for JavaScript code
- `python` for Python code
- `sql` for database queries

### Links and References

**Internal links:**

```markdown
[Link text](relative-path.md)
[Section reference](#section-heading)
[Cross-reference](../other-section/file.md#specific-section)
```

**External links:**

```markdown
[Microsoft Documentation](https://docs.microsoft.com)
```

**Link best practices:**

- Use descriptive link text
- Avoid "click here" or "read more"
- Open external links in new tabs when appropriate
- Verify links during content reviews

### Images and Media

**Image guidelines:**

```markdown
![Descriptive alt text](images/filename.png)
```

**Best practices:**

- Use descriptive alt text for accessibility
- Optimize images for web (typically under 1MB)
- Include captions when helpful
- Store images in organized directories

**File naming:**

- Use descriptive filenames: `azure-devops-pipeline.png`
- Include version numbers for screenshots: `ui-v2.3.png`
- Use consistent naming conventions

## Voice and Tone

### Voice Characteristics

**Professional and friendly:**

- Use "you" to address the reader directly
- Write in second person for instructions
- Maintain a helpful, supportive tone

**Examples:**

✅ **Good:** "You can configure the pipeline by following these steps."

❌ **Poor:** "One should configure the pipeline by following these steps."

### Tone Guidelines

**Instructional content:**

- Be direct and clear
- Use imperative mood for actions
- Provide context for complex steps

**Reference material:**

- Be concise and factual
- Use present tense
- Include complete information

**Troubleshooting:**

- Be empathetic and solution-focused
- Acknowledge user frustration
- Provide multiple solution paths

## Technical Standards

### API Documentation

**Endpoint documentation:**

```markdown
## GET /api/users

Retrieves a list of users from the system.

### Parameters

| Parameter | Type   | Required | Description |
|-----------|--------|----------|-------------|
| page      | number | No       | Page number (default: 1) |
| limit     | number | No       | Items per page (default: 20) |

### Response

```json
{
  "users": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100
  }
}
```

### Configuration Examples

**Include complete, working examples:**

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
    - main
    - develop

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: UseDotNet@2
  inputs:
    version: '6.x'
- script: dotnet build
  displayName: 'Build application'
```

### Error Messages

**Document common errors:**

```markdown
### Error: "Build failed with exit code 1"

**Cause:** Missing dependencies or compilation errors.

**Solution:**
1. Check the build log for specific error messages
2. Verify all dependencies are installed
3. Ensure code compiles locally before pushing
```

## Content Templates

### Tutorial Template

```markdown
---
title: "How to [Action]"
description: "Learn how to [accomplish goal] using [technology]"
tags: ["tutorial", "technology-name"]
category: "tutorials"
difficulty: "beginner"
estimated_time: "30 minutes"
---

## Overview

Brief description of what users will learn and accomplish.

## Prerequisites

- Requirement 1
- Requirement 2
- Requirement 3

## Step 1: [Action]

Detailed instructions with code examples.

## Step 2: [Next Action]

Continue with clear, sequential steps.

## Verification

How to confirm the tutorial worked correctly.

## Next Steps

- Related tutorials
- Advanced topics
- Additional resources
```

### Reference Template

```markdown
---
title: "[Component] Reference"
description: "Complete reference for [component] configuration and usage"
tags: ["reference", "component-name"]
category: "reference"
difficulty: "intermediate"
---

## Overview

Brief description of the component and its purpose.

## Configuration

### Required Settings

| Setting | Type | Description | Default |
|---------|------|-------------|---------|
| name    | string | Component name | null |

### Optional Settings

| Setting | Type | Description | Default |
|---------|------|-------------|---------|
| timeout | number | Request timeout | 30 |

## Usage Examples

Practical examples of common use cases.

## Troubleshooting

Common issues and solutions.
```

## Quality Assurance

### Review Checklist

**Content review:**

- [ ] Accurate and up-to-date information
- [ ] Clear and concise writing
- [ ] Proper grammar and spelling
- [ ] Consistent terminology
- [ ] Complete and actionable instructions

**Technical review:**

- [ ] Working code examples
- [ ] Functional links
- [ ] Accurate screenshots
- [ ] Valid configuration examples
- [ ] Tested procedures

**Accessibility review:**

- [ ] Descriptive headings
- [ ] Alt text for images
- [ ] Proper link text
- [ ] Color contrast compliance
- [ ] Screen reader compatibility

### Automated Checks

**Markdown linting:**

```yaml
# .markdownlint.yml
MD013: false  # Line length
MD033: false  # Inline HTML
MD041: false  # First line in file should be top-level heading
```

**Link validation:**

```bash
# Check internal links
markdown-link-check docs/**/*.md

# Check external links (weekly)
markdown-link-check --config .mlc-config.json docs/**/*.md
```

**Spell checking:**

```bash
# Use cspell for spell checking
npx cspell "docs/**/*.md"
```

## Maintenance

### Regular Review Schedule

**Monthly:**

- Update outdated screenshots
- Verify external links
- Review and update version-specific content

**Quarterly:**

- Style guide compliance audit
- User feedback analysis
- Template updates
- Terminology review

**Annually:**

- Complete style guide review
- Template redesign assessment
- User experience evaluation
- Accessibility audit

### Version Control for Style Guide

**Track changes:**

- Version the style guide itself
- Document rationale for changes
- Communicate updates to the team
- Archive previous versions

**Implementation timeline:**

- Announce changes with 30-day notice
- Provide training for new standards
- Phase in changes over time
- Support legacy content during transition

---

*This style guide ensures consistency and quality across all documentation. Regular reviews and updates keep it relevant and effective for the team's needs.*
