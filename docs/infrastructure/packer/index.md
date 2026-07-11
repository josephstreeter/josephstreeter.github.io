---
uid: infrastructure.packer.index
title: Packer Documentation
description: Comprehensive guide to HashiCorp Packer for building automated machine images across multiple platforms
ms.date: 01/18/2026
---

This section provides comprehensive documentation for HashiCorp Packer, an open-source tool for creating identical machine images for multiple platforms from a single source configuration.

## What is Packer?

Packer enables you to automate the creation of machine images for various platforms including AWS, Azure, Google Cloud, VMware, VirtualBox, and more. With Packer, you can define your infrastructure as code and produce consistent, repeatable builds.

### Key Benefits

- **Multi-platform support**: Build images for multiple platforms from a single template
- **Infrastructure as Code**: Version control your image configurations
- **Consistency**: Ensure identical images across environments
- **Speed**: Parallel builds reduce image creation time
- **Integration**: Works seamlessly with provisioning tools like Ansible, Chef, and Puppet

## Topics Covered

This documentation covers the following topics:

- Introduction to Packer and its core concepts
- Installation and setup procedures across different operating systems
- Creating and managing Packer templates
- Understanding builders, provisioners, and post-processors
- Best practices for template design and organization
- Troubleshooting common build issues
- Advanced features including HCL2 templates and parallel builds
- Integrating Packer into CI/CD pipelines
- Security considerations and credential management

## Prerequisites

Before working with Packer, you should have:

- Basic understanding of virtual machines and cloud infrastructure
- Familiarity with command-line interfaces
- Access to target platforms (AWS, Azure, VMware, etc.)
- Basic knowledge of provisioning tools (optional but helpful)

## Getting Started

To get started with Packer:

1. Review the [Introduction to Packer](introduction.md) for core concepts
2. Follow the [Installing Packer](installing-packer.md) guide for your platform
3. Create your [first Packer template](first-packer-template.md)

## Additional Resources

- [Official Packer Documentation](https://www.packer.io/docs)
- [Packer GitHub Repository](https://github.com/hashicorp/packer)
- [HashiCorp Learn - Packer Tutorials](https://learn.hashicorp.com/packer)
