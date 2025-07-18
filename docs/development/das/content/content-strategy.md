---
title: "Content Strategy for Documentation as Code"
description: "A comprehensive approach to organizing and managing content in a Documentation as Code environment"
author: "Joseph Streeter"
ms.date: "2023-07-18"
ms.topic: "conceptual"
ms.service: "documentation"
---

## Content Strategy for Documentation as Code

This guide outlines best practices for organizing and managing documentation content in a Documentation as Code (DaC) workflow with DocFX and Azure DevOps.

## Content Planning

When planning your documentation structure, consider the following:

- **Audience Analysis**: Define your primary and secondary audience
- **Information Architecture**: Create a logical content hierarchy
- **Content Types**: Determine what types of documentation you need
- **Metadata Strategy**: Define consistent metadata for content discovery

## File Organization

A well-structured repository helps maintain and scale your documentation:

```text
/docs
├── development/          # Development documentation
│   ├── das/              # Documentation as Code
│   │   ├── content/      # Content strategy and guidelines
│   │   ├── setup/        # Setup and configuration
│   │   ├── advanced/     # Advanced topics (security, etc.)
│   │   └── index.md      # Landing page
├── infrastructure/       # Infrastructure documentation
├── security/             # Security documentation
└── services/             # Services documentation
```

## Style Guidelines

Consistency in style and formatting creates a professional look and feel:

- Use sentence case for headings
- Keep paragraphs short (3-5 lines)
- Use active voice when possible
- Include code examples where appropriate
- Add alt text to all images

## Version Control Strategy

Managing documentation versions:

- Use semantic versioning for major documentation releases
- Create branches for significant content updates
- Use tags to mark stable documentation versions
- Document breaking changes in release notes

## Metadata Requirements

All content files should include these front matter elements:

```yaml
---
title: "Page Title"
description: "Brief description (140-160 characters)"
author: "Author Name"
ms.date: "YYYY-MM-DD"
ms.topic: "conceptual/tutorial/reference"
ms.service: "service-name"
---
```

## Review Process

Establish a content review workflow:

1. Content planning and outline
2. Initial draft
3. Technical review
4. Editorial review
5. Final approval
6. Publication

## Content Lifecycle Management

Managing content throughout its lifecycle:

- **Creation**: Development of new content
- **Maintenance**: Regular updates and improvements
- **Archiving**: Process for outdated content
- **Retirement**: Removing obsolete content

## Integration with Code Documentation

When documentation includes API or code references:

- Use DocFX's API documentation capabilities
- Ensure code comments follow documentation standards
- Cross-reference between conceptual and API documentation
- Consider automation for code samples

## Related Resources

- [DocFX Configuration](/docs/development/das/setup/docfx-configuration.md)
- [Azure DevOps Integration](/docs/development/das/setup/azure-devops.md)
- [CI/CD Pipeline](/docs/development/das/setup/cicd-pipeline.md)
- [Security Best Practices](/docs/development/das/advanced/security.md)
