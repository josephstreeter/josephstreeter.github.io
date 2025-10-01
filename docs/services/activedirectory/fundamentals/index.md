---
title: "Active Directory Fundamentals"
description: "Core concepts and architecture of Active Directory Domain Services including forests, domains, domain controllers, and sites."
tags: ["active-directory", "fundamentals", "architecture", "domain-services"]
category: "Services"
subcategory: "Active Directory"
difficulty: "Beginner"
last_updated: "2025-09-25"
author: "Documentation Team"
---

## Overview

This section covers the fundamental concepts and architecture of Active Directory Domain Services (AD DS). Understanding these core concepts is essential for effective Active Directory administration, planning, and troubleshooting.

## What You'll Learn

- **Forest and Domain Architecture**: Understand the hierarchical structure of AD DS
- **Domain Controllers**: Learn about DC roles, placement, and management
- **FSMO Roles**: Master the five Flexible Single Master Operation roles
- **Sites and Subnets**: Configure network topology for optimal replication
- **Global Catalogs**: Understand the role of GC servers in multi-domain environments

## Prerequisites

- Basic understanding of Windows networking concepts
- Familiarity with DNS concepts and configuration
- General knowledge of Windows Server administration

## Learning Path

### 1. Start Here: Forest and Domain Concepts

Begin with understanding the logical structure of Active Directory.

**📖 [Forests and Domains](forests-and-domains.md)**

- Forest structure and boundaries
- Domain hierarchy and trust relationships
- Namespace planning and design

### 2. Domain Controller Fundamentals

Learn about the servers that host Active Directory services.

**🖥️ [Domain Controllers](domain-controllers.md)**

- Domain controller roles and responsibilities  
- Installation and configuration
- Health monitoring and maintenance

### 3. FSMO Role Management

Master the single-master operations that ensure consistency.

**⚙️ [FSMO Roles](fsmo-roles.md)**

- Schema Master and Domain Naming Master
- PDC Emulator, RID Master, and Infrastructure Master
- Role placement and transfer procedures

### 4. Network Topology Design

Configure sites and subnets for optimal performance.

**🌐 [Sites and Subnets](sites-and-subnets.md)**

- Site topology design principles
- Subnet configuration and management
- Replication scheduling and optimization

### 5. Global Catalog Services

Understand multi-domain search and authentication.

**🔍 [Global Catalogs](global-catalogs.md)**

- Global catalog server placement
- Partial attribute set configuration
- Universal group membership caching

## Quick Reference

### Common Administrative Tasks

| Task | Primary Tool | Documentation |
|------|-------------|---------------|
| View forest/domain info | `Get-ADForest`, `Get-ADDomain` | [Forests and Domains](forests-and-domains.md) |
| Check DC health | `dcdiag`, `repadmin` | [Domain Controllers](domain-controllers.md) |
| Manage FSMO roles | `netdom query fsmo` | [FSMO Roles](fsmo-roles.md) |
| Configure sites | Active Directory Sites and Services | [Sites and Subnets](sites-and-subnets.md) |
| Global catalog status | `dsquery server -isgc` | [Global Catalogs](global-catalogs.md) |

### Architecture Quick Facts

- **Maximum Forest Functional Level**: Windows Server 2019
- **Maximum Domain Functional Level**: Windows Server 2019
- **Recommended DCs per Site**: Minimum 2 for redundancy
- **Global Catalog Recommendations**: At least one per site
- **FSMO Role Distribution**: Separate infrastructure-critical roles across DCs

## Related Sections

- **🔧 [Operations](../Operations/index.md)**: Day-to-day administration and monitoring
- **🛠️ [Procedures](../procedures/index.md)**: Step-by-step administrative procedures
- **🔒 [Security](../Security/index.md)**: Security policies and best practices
- **⚙️ [Configuration](../configuration/index.md)**: Advanced configuration topics

## Additional Resources

- [Microsoft Active Directory Documentation](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/)
- [Active Directory Best Practices](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/plan/)
- [PowerShell Active Directory Module](https://docs.microsoft.com/en-us/powershell/module/addsadministration/)

---

*This fundamentals section provides the foundation knowledge needed for all other Active Directory administration tasks. Master these concepts before moving to advanced topics.*
